import datetime
import os
import io
import json
import cv2
import numpy as np
import pickle
import requests
from flask import Flask, Response, request, jsonify, send_file
from PIL import Image
from dotenv import load_dotenv
from supabase import create_client
import base64
from io import BytesIO
import time
from flask import make_response
from waitress import serve

# Load environment variables
load_dotenv()

# === Flask app ===
app = Flask(__name__)

# === Supabase setup ===
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# === Globals for model configs ===
HAND_API_KEY = None
LINE_API_KEY = None
HAND_MODEL_URL = None
LINE_MODEL_URL = None

# === Constants ===
HAND_CONFIDENCE = 50
HAND_OVERLAP = 0

LINE_CONFIDENCE = 10
LINE_OVERLAP = 10

DEBUG_MODE = True
PROFILE_BUCKET = "palm-models"  

# === Fixed environment check function ===
def check_environment():
    print("\n🔍 ENVIRONMENT CHECK:")
    print(f"✅ SUPABASE_URL: {'Set' if SUPABASE_URL else 'MISSING'}")
    print(f"✅ SUPABASE_KEY: {'Set' if SUPABASE_KEY else 'MISSING'}")
    print(f"✅ PROFILE_BUCKET: {PROFILE_BUCKET}")
    
    # Test supabase connection
    try:
        # Simple query that should work regardless of schema
        test_query = supabase.table("answer_profiles").select("*").limit(1).execute()
        print(f"✅ Connected to Supabase. Retrieved {len(test_query.data)} record(s).")
        
        # Test storage
        try:
            test_file = supabase.storage.from_(PROFILE_BUCKET).list()
            print(f"✅ Storage bucket '{PROFILE_BUCKET}' accessed.")
            print(f"✅ Files in bucket: {len(test_file)} found")
        except Exception as e:
            print(f"❌ Error accessing storage bucket '{PROFILE_BUCKET}': {str(e)}")
    except Exception as e:
        print(f"❌ Supabase connection error: {str(e)}")
    
    print("🔍 END ENVIRONMENT CHECK\n")


# Call this function at the start of your main block
if __name__ == '__main__':
    check_environment()
    # Rest of your code...

# === Fetch model config ===
def get_model_config(model_type):
    model_type = model_type.upper()
    response = supabase.table("Admin").select("*").eq("model_type", model_type).eq("is_active", True).limit(1).execute()
    if response.data:
        return response.data[0]
    else:
        raise Exception(f"No active model config for '{model_type}'")

# === RoboFlow helper ===
def call_roboflow(image_bytes, model_url, api_key, confidence, overlap):
    response = requests.post(
        model_url,
        params={
            "api_key": api_key,
            "confidence": confidence,
            "overlap": overlap
        },
        files={"file": ("image.jpg", image_bytes, "image/jpeg")}
    )
    if response.status_code != 200:
        print(f"❌ RoboFlow Error: {response.status_code} - {response.text}")
        return None
    return response.json()



def compress_image_to_target_size(image_path, target_size_kb=800, step=5, min_quality=10):
    img = Image.open(image_path)
    buffer = io.BytesIO()
    quality = 50
    print("Resizing Mask")
    print(f"🖼 Original image format: {img.format}, size: {img.size}")
    
    while quality >= min_quality:
        buffer.seek(0)
        buffer.truncate(0)
        img.save(buffer, format="JPEG", quality=quality)
        size_kb = len(buffer.getvalue()) / 1024
        print(f"💾 Attempt at quality {quality} produced: {size_kb:.2f} KB")
        if size_kb <= target_size_kb:
            break
        quality -= step

    if len(buffer.getvalue()) == 0:
        print("❌ ERROR: Compressed image is empty! Aborting.")
        raise ValueError("Compressed image is empty")

    print(f"📦 Compressed image size = {len(buffer.getvalue()) / 1024:.2f} KB, quality={quality}")
    buffer.seek(0)
    return buffer




def download_profile_pkl(file_name):
    try:
        # Different versions of the Supabase client might have different APIs
        response = supabase.storage.from_(PROFILE_BUCKET).download(file_name)
        print(f"✅ Downloaded {file_name}")
        
        # Some versions return the data directly, others return a response object
        if hasattr(response, 'read'):
            pkl_bytes = response.read()
        elif hasattr(response, 'content'):
            pkl_bytes = response.content
        else:
            pkl_bytes = response
            
        # Load the pickle data
        db_data = pickle.load(BytesIO(pkl_bytes))
        return db_data
    except Exception as e:
        print(f"❌ Error downloading {file_name}: {str(e)}")
        return None

@app.route('/upload-user-profile', methods=['POST'])
def upload_user_profile():
    try:
        data = request.get_json()
        name = data.get("name")
        passcode = data.get("passcode")
        image_base64 = data.get("image_base64")
        last_updated = data.get("last_updated") or datetime.utcnow().isoformat()

        if not name or not passcode or not image_base64:
            return jsonify({"error": "Missing required fields"}), 400

        # Check if the passcode already exists
        existing = supabase.table("user_profiles").select("id").eq("passcode", passcode).execute()

        if existing.data:
            # Update existing
            profile_id = existing.data[0]['id']
            response = supabase.table("user_profiles").update({
                "name": name,
                "image_base64": image_base64,
                "last_updated": last_updated,
            }).eq("id", profile_id).execute()
        else:
            # Insert new
            response = supabase.table("user_profiles").insert({
                "name": name,
                "passcode": passcode,
                "image_base64": image_base64,
                "last_updated": last_updated,
            }).execute()

        return jsonify({"status": "success", "data": response.data})

    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
# === Palm detection route ===
@app.route('/detect-hand', methods=['POST'])
def detect_hand():
    if 'image' not in request.files:
        return jsonify({"error": "No image provided"}), 400
    file = request.files['image']
    img_bytes = file.read()
    result = call_roboflow(img_bytes, HAND_MODEL_URL, HAND_API_KEY, HAND_CONFIDENCE, HAND_OVERLAP)
    detected = result and result.get("predictions")
    return jsonify({"palm_detected": bool(detected)})

# === SIFT detection ===
def detect_sift_features(image_np):
    gray = cv2.cvtColor(image_np, cv2.COLOR_BGR2GRAY)
    sift = cv2.SIFT_create(nfeatures=5000, contrastThreshold=0.01, edgeThreshold=15, sigma=1.2)
    keypoints, descriptors = sift.detectAndCompute(gray, None)
    if DEBUG_MODE:
        os.makedirs("debug_outputs", exist_ok=True)
        vis = cv2.drawKeypoints(image_np, keypoints, None, flags=cv2.DRAW_MATCHES_FLAGS_DRAW_RICH_KEYPOINTS)
        cv2.imwrite("debug_outputs/debug_sift_all.png", vis)
    return keypoints, descriptors

# === Filter keypoints ===
def filter_keypoints_by_mask(keypoints, descriptors, mask, class_name):
    filtered_kp, filtered_desc = [], []
    for kp, desc in zip(keypoints, descriptors):
        x, y = int(kp.pt[0]), int(kp.pt[1])
        if 0 <= x < mask.shape[1] and 0 <= y < mask.shape[0] and mask[y, x] == 255:
            filtered_kp.append(kp)
            filtered_desc.append(desc)
    if filtered_kp and DEBUG_MODE:
        vis_filtered = cv2.drawKeypoints(mask, filtered_kp, None, flags=cv2.DRAW_MATCHES_FLAGS_DRAW_RICH_KEYPOINTS)
        cv2.imwrite(f"debug_outputs/debug_filtered_{class_name}.png", vis_filtered)
    return filtered_kp, np.array(filtered_desc) if filtered_desc else None

# === Load answer profiles metadata ===
def load_answer_profiles():
    try:
        response = supabase.table("answer_profiles").select("*").execute()
        profiles = response.data if response.data else []
        
        if not profiles:
            print("❌ No answer profiles found in database")
        else:
            print(f"✅ Found {len(profiles)} answer profiles in database")
            # Debug: Print the first profile to see its structure
            if profiles:
                print(f"📄 Example profile structure: {list(profiles[0].keys())}")
                print(f"📄 Example line_type value: '{profiles[0].get('line_type', 'NOT_FOUND')}'")
            
        return profiles
        
    except Exception as e:
        print(f"❌ Error loading answer profiles: {str(e)}")
        return []
    

# === Brute Force matching implementation ===
def match_descriptors_bf(user_des, db_des):
    if user_des is None or db_des is None or len(user_des) == 0 or len(db_des) == 0:
        return []
        
    if user_des.dtype != np.float32:
        user_des = user_des.astype(np.float32)
    if db_des.dtype != np.float32:
        db_des = db_des.astype(np.float32)
        
    bf = cv2.BFMatcher(cv2.NORM_L2, crossCheck=True)
    matches = bf.match(user_des, db_des)
    matches = sorted(matches, key=lambda x: x.distance)
    return matches

# === FLANN matching implementation ===
def match_descriptors_flann(user_des, db_des, min_matches=10):
    if user_des is None or db_des is None or len(user_des) == 0 or len(db_des) == 0:
        return 0.0
        
    if user_des.dtype != np.float32:
        user_des = user_des.astype(np.float32)
    if db_des.dtype != np.float32:
        db_des = db_des.astype(np.float32)
        
    FLANN_INDEX_KDTREE = 1
    index_params = dict(algorithm=FLANN_INDEX_KDTREE, trees=5)
    search_params = dict(checks=50)
    flann = cv2.FlannBasedMatcher(index_params, search_params)
    
    try:
        matches = flann.knnMatch(user_des, db_des, k=2)
    except Exception:
        # Fallback to brute force if FLANN fails
        bf = cv2.BFMatcher()
        matches = bf.knnMatch(user_des, db_des, k=2)
        
    filtered_matches = []
    for pair in matches:
        if len(pair) < 2:
            continue
        m, n = pair
        if m.distance < 0.7 * n.distance:
            filtered_matches.append(m)
            
    if len(filtered_matches) < min_matches:
        return len(filtered_matches) / min_matches * 0.1
    
    # Just return the match ratio for consistent scoring
    flann_match_ratio = len(filtered_matches) / (min(len(user_des), len(db_des)) + 1e-5)    
    return flann_match_ratio

# === Calculate similarity score ===
def calculate_similarity(user_desc, db_desc):
    if user_desc is None or db_desc is None or len(user_desc) == 0 or len(db_desc) == 0:
        return -1.0, 0.0, 0.0, 0.0  # (score, f1, match_ratio, flann_score)
        
    # Get BF matches for match ratio calculation
    bf_matches = match_descriptors_bf(user_desc, db_desc)
    if not bf_matches:
        # If no BF matches found, return zeros
        return 0.0, 0.0, 0.0, 0.0
        
    # Calculate match ratio as the primary score
    match_ratio = len(bf_matches) / min(len(user_desc), len(db_desc))
    
    # Use FLANN as tiebreaker only
    flann_score = match_descriptors_flann(user_desc, db_desc)
    
    # Calculate F1 score for completeness
    precision = len(bf_matches) / len(db_desc)
    recall = len(bf_matches) / len(user_desc)
    f1 = 2 * (precision * recall) / (precision + recall + 1e-5)
    
    # Return match_ratio as the main score
    final_score = match_ratio
    
    # Return all metrics for debugging purposes
    return final_score, f1, match_ratio, flann_score


# === Predict best lines ===
def predict_best_lines(filtered_user_features):
    profiles = load_answer_profiles()
    if not profiles:
        print("⚠️ No profiles available - returning default values")
        return {
            "life-line": "ไม่พบข้อมูล",
            "head-line": "ไม่พบข้อมูล", 
            "heart-line": "ไม่พบข้อมูล"
        }, {}
    
    # Debug: Print what line types are actually in the database    
    found_line_types = set()
    for profile in profiles:
        line_type = profile.get('line_type', '').lower().strip()
        found_line_types.add(line_type)
    print(f"🔍 Line types found in database: {found_line_types}")
    
    predictions = {}
    all_results = {}
    
    line_types_to_check = ['life-line', 'head-line', 'heart-line']
    
    # Check if we need to adapt line type names
    if 'life-line' not in found_line_types and 'life_line' in found_line_types:
        print("⚠️ Adapting line type names: using underscores instead of hyphens")
        line_types_to_check = ['life_line', 'head_line', 'heart_line']
    
    for line_type in line_types_to_check:
        user_desc = filtered_user_features.get(line_type.replace('_', '-'))
        best_match_ratio = -1
        best_flann_score = -1
        best_answer = None
        line_results = []

        print(f"\n🔍 Starting matching for {line_type.upper()}")
        
        # Check if user descriptors are available for this line type
        if user_desc is None or len(user_desc) == 0:
            print(f"⚠️ No user descriptors found for {line_type}")
            predictions[line_type.replace('_', '-')] = "ไม่พบข้อมูล"
            all_results[line_type.replace('_', '-')] = []
            continue

        # Track how many profiles we found for this line type
        profiles_for_line = 0
        
        for profile in profiles:
            profile_line_type = profile.get('line_type', '').lower().strip()
            if profile_line_type != line_type:
                continue
                
            profiles_for_line += 1

            db_data = download_profile_pkl(profile['pkl_name'])
            if db_data is None:
                print(f"⚠️ Could not load profile data for {profile['pkl_name']}")
                continue

            db_desc = db_data.get("descriptors")
            if db_desc is None:
                print(f"⚠️ No descriptors in profile {profile['pkl_name']}")
                continue

            # Calculate similarity metrics
            score, f1, match_ratio, flann_score = calculate_similarity(user_desc, db_desc)

            line_results.append({
                "profile_name": profile['pkl_name'],
                "answer_text": profile['answer_text'],
                "score": match_ratio,  # Use match_ratio as the main score
                "flann_score": flann_score  # Store FLANN score for tie-breaking
            })

            print(f"🧬 Comparing with {profile['pkl_name']}: MatchRatio={match_ratio:.4f}, FLANN={flann_score:.4f}, F1={f1:.4f}")

            # Use match_ratio as primary score
            if match_ratio > best_match_ratio:
                best_match_ratio = match_ratio
                best_flann_score = flann_score
                best_answer = profile['answer_text']
            # Use FLANN for tie-breaking when match ratios are very close
            elif abs(match_ratio - best_match_ratio) < 0.01 and flann_score > best_flann_score:
                best_flann_score = flann_score
                best_answer = profile['answer_text']
        
        # Check if we found any matching profiles
        if profiles_for_line == 0:
            print(f"⚠️ No profiles found for line type {line_type}")
            
        # Sort by match_ratio first, then by flann_score for ties
        line_results.sort(key=lambda x: (x["score"], x.get("flann_score", 0)), reverse=True)

        print(f"\n📊 All matches for {line_type.upper()}:")
        for idx, result in enumerate(line_results):
            print(f"  {idx+1}. {result['profile_name']} - {result['answer_text']} (match_ratio={result['score']:.4f}, flann={result.get('flann_score', 0):.4f})")

        if best_answer is None:
            best_answer = "ไม่พบข้อมูล"

        print(f"✅ Best match for {line_type.upper()} = {best_answer} (match_ratio={best_match_ratio:.4f}, flann={best_flann_score:.4f})")

        predictions[line_type.replace('_', '-')] = best_answer
        all_results[line_type.replace('_', '-')] = line_results

    return predictions, all_results


# === Segment lines route ===
@app.route('/segment-lines', methods=['POST'])
def segment_lines():
    try:
        if request.data:
            img = Image.open(io.BytesIO(request.data)).convert('RGB')
        else:
            return jsonify({"error": "No image data received"}), 400

        img_np = np.array(img)
        height, width = img_np.shape[:2]
        img_bytes = io.BytesIO()
        img.save(img_bytes, format='JPEG')
        img_bytes.seek(0)

        result = call_roboflow(img_bytes.read(), LINE_MODEL_URL, LINE_API_KEY, LINE_CONFIDENCE, LINE_OVERLAP)
        if not result or "predictions" not in result:
            return jsonify({"error": "No lines detected"})

        class_masks = {}
        for pred in result["predictions"]:
            cls = pred["class"].strip().lower()
            mask = np.zeros((height, width), dtype=np.uint8)
            points = np.array([[int(p["x"]), int(p["y"])] for p in pred["points"]], np.int32)
            cv2.fillPoly(mask, [points], color=255)
            class_masks[cls] = cv2.bitwise_or(class_masks.get(cls, mask), mask)

        keypoints, descriptors = detect_sift_features(img_np)
        filtered_sets = {}
        for cls, m in class_masks.items():
            filtered_kp, filtered_desc = filter_keypoints_by_mask(keypoints, descriptors, m, cls)
            filtered_sets[cls] = (filtered_kp, filtered_desc)

        filtered_user_features = {cls: desc for cls, (kp, desc) in filtered_sets.items()}
        predictions, all_results = predict_best_lines(filtered_user_features)

        # === Create masked image with semi-transparent lines ===
        debug_img = img_np.copy()
        overlay = np.zeros_like(debug_img, dtype=np.uint8)

        for cls, mask in class_masks.items():
            color = (0, 255, 0) if cls == "life-line" else (255, 0, 0) if cls == "head-line" else (0, 0, 255)
            overlay[mask == 255] = color

        alpha = 0.4  # transparency level
        debug_img = cv2.addWeighted(overlay, alpha, debug_img, 1 - alpha, 0)

        # Convert BGR to RGB before saving (OpenCV default is BGR)
        debug_img = cv2.cvtColor(debug_img, cv2.COLOR_BGR2RGB)

        os.makedirs("debug_outputs", exist_ok=True)
        token = f"{int(time.time() * 1000)}"
        filename = f"debug_outputs/masked_{token}.jpg"
        cv2.imwrite(filename, debug_img, [cv2.IMWRITE_JPEG_QUALITY, 60])

        return jsonify({
            "life_line": predictions.get("life-line", "ไม่พบข้อมูล"),
            "head_line": predictions.get("head-line", "ไม่พบข้อมูล"),
            "heart_line": predictions.get("heart-line", "ไม่พบข้อมูล"),
            "image_token": token
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# === Get image by token (Step 2) ===
@app.route('/get-mask-image', methods=['GET'])
def get_mask_image():
    token = request.args.get("token")
    filepath = f"debug_outputs/masked_{token}.jpg"
    print(f"🔍 Looking for file: {filepath}")

    if not os.path.exists(filepath):
        return jsonify({"error": "Image not found for token"}), 404

    try:
        compressed_image_io = compress_image_to_target_size(filepath)
        byte_io = io.BytesIO(compressed_image_io.getvalue())
        byte_io.seek(0)

        return send_file(
            byte_io,
            mimetype='image/jpeg',
            as_attachment=False,
            download_name=f"masked_{token}.jpg",  # Only Flask ≥2.0
            max_age=0,
            conditional=False,
            etag=False
        )

    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({"error": f"Failed to process image: {str(e)}"}), 500


# === Run app ===
from waitress import serve

if __name__ == "__main__":
    from dotenv import load_dotenv
    load_dotenv()
    
    # Load model configs etc here
    try:
        hand_config = get_model_config("HAND")
        line_config = get_model_config("LINE")
        HAND_API_KEY = hand_config["ROBOFLOW_API_KEY"].strip()
        LINE_API_KEY = line_config["ROBOFLOW_API_KEY"].strip()
        HAND_MODEL_URL = f"https://detect.roboflow.com/{hand_config['PROJECT'].strip()}/{hand_config['VERSION'].strip()}"
        LINE_MODEL_URL = f"https://detect.roboflow.com/{line_config['PROJECT'].strip()}/{line_config['VERSION'].strip()}"
    except Exception as e:
        print("❌ Failed to load model configs:", e)

    print("🚀 Serving Flask app with waitress...")
    serve(app, host="0.0.0.0", port=5000)

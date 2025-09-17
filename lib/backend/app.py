import os
import io
import json
import time
import cv2
import base64
import pickle
import numpy as np
from io import BytesIO
from PIL import Image
from dotenv import load_dotenv
from flask import Flask, request, jsonify, send_file, make_response

from supabase import create_client
import requests

# ------------------------------------------------------------------
# Environment & Globals (initialized at cold start)
# ------------------------------------------------------------------
load_dotenv()

APP_STAGE = os.getenv("APP_STAGE", "dev")
CORS_ORIGINS = os.getenv("CORS_ORIGINS", "*")

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# Will be filled from Supabase Admin table at cold start
HAND_API_KEY = None
LINE_API_KEY = None
HAND_MODEL_URL = None
LINE_MODEL_URL = None

# Constants
HAND_CONFIDENCE = 50
HAND_OVERLAP = 0
LINE_CONFIDENCE = 10
LINE_OVERLAP = 10
DEBUG_MODE = True

# Use Lambda's writable temp
DEBUG_DIR = "/tmp/debug_outputs"
os.makedirs(DEBUG_DIR, exist_ok=True)

# ------------------------------------------------------------------
# Flask app
# ------------------------------------------------------------------
app = Flask(__name__)

# ---- Simple CORS (keeps your routes unchanged) -------------------
@app.after_request
def add_cors_headers(resp):
    resp.headers["Access-Control-Allow-Origin"] = CORS_ORIGINS
    resp.headers["Access-Control-Allow-Headers"] = "Content-Type,Authorization"
    resp.headers["Access-Control-Allow-Methods"] = "GET,POST,OPTIONS"
    return resp

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"ok": True, "stage": APP_STAGE})

# ------------------------------------------------------------------
# Utility / Setup helpers (unaltered logic)
# ------------------------------------------------------------------
def check_environment():
    print("\n🔍 ENVIRONMENT CHECK:")
    print(f"✅ SUPABASE_URL: {'Set' if SUPABASE_URL else 'MISSING'}")
    print(f"✅ SUPABASE_KEY: {'Set' if SUPABASE_KEY else 'MISSING'}")
    try:
        test_query = supabase.table("answer_profiles").select("*").limit(1).execute()
        print(f"✅ Connected to Supabase. Retrieved {len(test_query.data)} record(s).")
    except Exception as e:
        print(f"❌ Supabase connection error: {str(e)}")
    print("🔍 END ENVIRONMENT CHECK\n")

def get_model_config(model_type):
    model_type = model_type.upper()
    response = supabase.table("Admin").select("*") \
        .eq("model_type", model_type).eq("is_active", True).limit(1).execute()
    if response.data:
        return response.data[0]
    raise Exception(f"No active model config for '{model_type}'")

def call_roboflow(image_bytes, model_url, api_key, confidence, overlap):
    resp = requests.post(
        model_url,
        params={"api_key": api_key, "confidence": confidence, "overlap": overlap},
        files={"file": ("image.jpg", image_bytes, "image/jpeg")}
    )
    if resp.status_code != 200:
        print(f"❌ RoboFlow Error: {resp.status_code} - {resp.text}")
        return None
    return resp.json()

def compress_image_to_target_size(image_path, target_size_kb=800, step=5, min_quality=10):
    img = Image.open(image_path)
    buffer = io.BytesIO()
    quality = 50
    while quality >= min_quality:
        buffer.seek(0), buffer.truncate(0)
        img.save(buffer, format="JPEG", quality=quality)
        if len(buffer.getvalue()) / 1024 <= target_size_kb:
            break
        quality -= step
    if len(buffer.getvalue()) == 0:
        raise ValueError("Compressed image is empty")
    buffer.seek(0)
    return buffer

def download_profile_pkl(file_name):
    try:
        response = supabase.storage.from_("palm-models").download(file_name)
        if hasattr(response, "read"):
            pkl_bytes = response.read()
        elif hasattr(response, "content"):
            pkl_bytes = response.content
        else:
            pkl_bytes = response
        db_data = pickle.load(BytesIO(pkl_bytes))
        return db_data
    except Exception as e:
        print(f"❌ Error downloading {file_name}: {str(e)}")
        return None

def detect_sift_features(image_np):
    gray = cv2.cvtColor(image_np, cv2.COLOR_BGR2GRAY)
    sift = cv2.SIFT_create(nfeatures=5000, contrastThreshold=0.01, edgeThreshold=15, sigma=1.2)
    keypoints, descriptors = sift.detectAndCompute(gray, None)
    if DEBUG_MODE:
        vis = cv2.drawKeypoints(image_np, keypoints, None, flags=cv2.DRAW_MATCHES_FLAGS_DRAW_RICH_KEYPOINTS)
        cv2.imwrite(os.path.join(DEBUG_DIR, "debug_sift_all.png"), vis)
    return keypoints, descriptors

def filter_keypoints_by_mask(keypoints, descriptors, mask, class_name):
    filtered_kp, filtered_desc = [], []
    for kp, desc in zip(keypoints, descriptors):
        x, y = int(kp.pt[0]), int(kp.pt[1])
        if 0 <= x < mask.shape[1] and 0 <= y < mask.shape[0] and mask[y, x] == 255:
            filtered_kp.append(kp)
            filtered_desc.append(desc)
    if filtered_kp and DEBUG_MODE:
        vis_filtered = cv2.drawKeypoints(mask, filtered_kp, None, flags=cv2.DRAW_MATCHES_FLAGS_DRAW_RICH_KEYPOINTS)
        cv2.imwrite(os.path.join(DEBUG_DIR, f"debug_filtered_{class_name}.png"), vis_filtered)
    return filtered_kp, np.array(filtered_desc) if filtered_desc else None

def load_answer_profiles():
    try:
        response = supabase.table("answer_profiles").select("*").execute()
        profiles = response.data if response.data else []
        if not profiles:
            print("❌ No answer profiles found in database")
        return profiles
    except Exception as e:
        print(f"❌ Error loading answer profiles: {str(e)}")
        return []

def match_descriptors_bf(user_des, db_des):
    if user_des is None or db_des is None or len(user_des) == 0 or len(db_des) == 0:
        return []
    if user_des.dtype != np.float32:
        user_des = user_des.astype(np.float32)
    if db_des.dtype != np.float32:
        db_des = db_des.astype(np.float32)
    bf = cv2.BFMatcher(cv2.NORM_L2, crossCheck=True)
    matches = bf.match(user_des, db_des)
    return sorted(matches, key=lambda x: x.distance)

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
        bf = cv2.BFMatcher()
        matches = bf.knnMatch(user_des, db_des, k=2)
    filtered = []
    for pair in matches:
        if len(pair) < 2:
            continue
        m, n = pair
        if m.distance < 0.7 * n.distance:
            filtered.append(m)
    if len(filtered) < min_matches:
        return len(filtered) / min_matches * 0.1
    return len(filtered) / (min(len(user_des), len(db_des)) + 1e-5)

def calculate_similarity(user_desc, db_desc):
    if user_desc is None or db_desc is None or len(user_desc) == 0 or len(db_desc) == 0:
        return -1.0, 0.0, 0.0, 0.0
    bf_matches = match_descriptors_bf(user_desc, db_desc)
    if not bf_matches:
        return 0.0, 0.0, 0.0, 0.0
    match_ratio = len(bf_matches) / min(len(user_desc), len(db_desc))
    flann_score = match_descriptors_flann(user_desc, db_desc)
    precision = len(bf_matches) / len(db_desc)
    recall = len(bf_matches) / len(user_desc)
    f1 = 2 * (precision * recall) / (precision + recall + 1e-5)
    return match_ratio, f1, match_ratio, flann_score

def predict_best_lines(filtered_user_features):
    profiles = load_answer_profiles()
    if not profiles:
        return {"life-line": "ไม่พบข้อมูล", "head-line": "ไม่พบข้อมูล", "heart-line": "ไม่พบข้อมูล"}, {}
    found_line_types = { (p.get('line_type','') or '').lower().strip() for p in profiles }
    line_types_to_check = ['life-line', 'head-line', 'heart-line']
    if 'life-line' not in found_line_types and 'life_line' in found_line_types:
        line_types_to_check = ['life_line', 'head_line', 'heart_line']
    predictions, all_results = {}, {}
    for line_type in line_types_to_check:
        user_desc = filtered_user_features.get(line_type.replace('_', '-'))
        best_match_ratio, best_flann_score, best_answer = -1, -1, None
        line_results = []
        if user_desc is None or len(user_desc) == 0:
            predictions[line_type.replace('_', '-')] = "ไม่พบข้อมูล"
            all_results[line_type.replace('_', '-')] = []
            continue
        profiles_for_line = 0
        for profile in profiles:
            if (profile.get('line_type','') or '').lower().strip() != line_type:
                continue
            profiles_for_line += 1
            db = download_profile_pkl(profile['pkl_name'])
            if db is None: continue
            db_desc = db.get("descriptors")
            if db_desc is None: continue
            score, f1, match_ratio, flann_score = calculate_similarity(user_desc, db_desc)
            line_results.append({
                "profile_name": profile['pkl_name'],
                "answer_text": profile['answer_text'],
                "score": match_ratio,
                "flann_score": flann_score
            })
            if match_ratio > best_match_ratio or (abs(match_ratio - best_match_ratio) < 0.01 and flann_score > best_flann_score):
                best_match_ratio, best_flann_score, best_answer = match_ratio, flann_score, profile['answer_text']
        if profiles_for_line == 0:
            pass
        line_results.sort(key=lambda x: (x["score"], x.get("flann_score", 0)), reverse=True)
        if best_answer is None: best_answer = "ไม่พบข้อมูล"
        predictions[line_type.replace('_', '-')] = best_answer
        all_results[line_type.replace('_', '-')] = line_results
    return predictions, all_results

# ------------------------------------------------------------------
# Routes (UNCHANGED paths)
# ------------------------------------------------------------------
@app.route('/upload-user-profile', methods=['POST'])
def upload_user_profile():
    try:
        data = request.get_json()
        name = data.get("name")
        passcode = data.get("passcode")
        image_base64 = data.get("image_base64")
        last_updated = data.get("last_updated") or time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())
        if not name or not passcode or not image_base64:
            return jsonify({"error": "Missing required fields"}), 400
        existing = supabase.table("user_profiles").select("id").eq("passcode", passcode).execute()
        if existing.data:
            profile_id = existing.data[0]['id']
            response = supabase.table("user_profiles").update({
                "name": name, "image_base64": image_base64, "last_updated": last_updated
            }).eq("id", profile_id).execute()
        else:
            response = supabase.table("user_profiles").insert({
                "name": name, "passcode": passcode, "image_base64": image_base64, "last_updated": last_updated
            }).execute()
        return jsonify({"status": "success", "data": response.data})
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/detect-hand', methods=['POST'])
def detect_hand():
    if 'image' not in request.files:
        return jsonify({"error": "No image provided"}), 400
    file = request.files['image']
    img_bytes = file.read()
    result = call_roboflow(img_bytes, HAND_MODEL_URL, HAND_API_KEY, HAND_CONFIDENCE, HAND_OVERLAP)
    detected = result and result.get("predictions")
    return jsonify({"palm_detected": bool(detected)})

@app.route('/segment-lines', methods=['POST'])
def segment_lines():
    try:
        if request.data:
            img = Image.open(io.BytesIO(request.data)).convert('RGB')
        else:
            return jsonify({"error": "No image data received"}), 400
        img_np = np.array(img)
        height, width = img_np.shape[:2]
        buf = io.BytesIO(); img.save(buf, format='JPEG'); buf.seek(0)
        result = call_roboflow(buf.read(), LINE_MODEL_URL, LINE_API_KEY, LINE_CONFIDENCE, LINE_OVERLAP)
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
            fk, fdesc = filter_keypoints_by_mask(keypoints, descriptors, m, cls)
            filtered_sets[cls] = (fk, fdesc)
        filtered_user_features = {cls: desc for cls, (kp, desc) in filtered_sets.items()}
        predictions, all_results = predict_best_lines(filtered_user_features)

        # overlay
        debug_img = img_np.copy()
        overlay = np.zeros_like(debug_img, dtype=np.uint8)
        for cls, mask in class_masks.items():
            color = (0, 255, 0) if cls == "life-line" else (255, 0, 0) if cls == "head-line" else (0, 0, 255)
            overlay[mask == 255] = color
        debug_img = cv2.addWeighted(overlay, 0.4, debug_img, 0.6, 0)
        debug_img = cv2.cvtColor(debug_img, cv2.COLOR_BGR2RGB)

        token = f"{int(time.time() * 1000)}"
        filename = os.path.join(DEBUG_DIR, f"masked_{token}.jpg")
        cv2.imwrite(filename, debug_img, [cv2.IMWRITE_JPEG_QUALITY, 60])

        return jsonify({
            "life_line": predictions.get("life-line", "ไม่พบข้อมูล"),
            "head_line": predictions.get("head-line", "ไม่พบข้อมูล"),
            "heart_line": predictions.get("heart-line", "ไม่พบข้อมูล"),
            "image_token": token
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/get-mask-image', methods=['GET'])
def get_mask_image():
    token = request.args.get("token")
    filepath = os.path.join(DEBUG_DIR, f"masked_{token}.jpg")
    if not os.path.exists(filepath):
        return jsonify({"error": "Image not found for token"}), 404
    try:
        compressed = compress_image_to_target_size(filepath)
        byte_io = io.BytesIO(compressed.getvalue()); byte_io.seek(0)
        return send_file(
            byte_io,
            mimetype='image/jpeg',
            as_attachment=False,
            download_name=f"masked_{token}.jpg",
            max_age=0,
            conditional=False,
            etag=False
        )
    except Exception as e:
        return jsonify({"error": f"Failed to process image: {str(e)}"}), 500

# ------------------------------------------------------------------
# Cold start init: load model configs once
# ------------------------------------------------------------------
try:
    check_environment()
    hand_cfg = get_model_config("HAND")
    line_cfg = get_model_config("LINE")
    HAND_API_KEY = hand_cfg["ROBOFLOW_API_KEY"].strip()
    LINE_API_KEY = line_cfg["ROBOFLOW_API_KEY"].strip()
    HAND_MODEL_URL = f"https://detect.roboflow.com/{hand_cfg['PROJECT'].strip()}/{hand_cfg['VERSION'].strip()}"
    LINE_MODEL_URL = f"https://detect.roboflow.com/{line_cfg['PROJECT'].strip()}/{line_cfg['VERSION'].strip()}"
    print("✅ Model configs loaded.")
except Exception as e:
    print("❌ Failed to load model configs:", e)

# No `if __name__ == "__main__"` or waitress here — Lambda runs the app module.

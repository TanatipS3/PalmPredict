# test_palm_reading
import requests
import base64
import io
import json
import os
import time
import datetime
from PIL import Image
import numpy as np
import cv2

class PalmReadingTest:
    """
    A test suite for the Hand and Line detection API endpoints.
    """
    def __init__(self, base_url="http://localhost:5000"):
        self.base_url = base_url
        self.session = requests.Session()
        self.test_results = {}
        print(f"🧪 Initializing Palm & Line API tester for: {self.base_url}")
    
    def load_image_from_file(self, file_path):
        if not os.path.exists(file_path):
            print(f"❌ Error: File not found at '{file_path}'")
            return None
        
        try:
            img_pil = Image.open(file_path).convert('RGB')
            return np.array(img_pil)
        except Exception as e:
            print(f"❌ Error loading image from file: {e}")
            return None
    
    def image_to_bytes(self, img_array, format='JPEG'):
        if img_array is None:
            return None
        img_pil = Image.fromarray(img_array)
        img_bytes = io.BytesIO()
        img_pil.save(img_bytes, format=format)
        img_bytes.seek(0)
        return img_bytes.getvalue()
    
    def run_test(self, test_name, func, *args, **kwargs):
        print(f"\n" + "="*50)
        print(f"▶️ Running Test: {test_name}")
        print("="*50)
        
        try:
            result = func(*args, **kwargs)
            self.test_results[test_name] = result
            return result
        except Exception as e:
            print(f"❌ Test Failed due to an unhandled exception: {e}")
            self.test_results[test_name] = False
            return False

    def test_detect_hand(self, img_array, file_path):
        """Tests the /detect-hand endpoint with a file upload."""
        if img_array is None:
            print("❌ Skipping test_detect_hand: Invalid image data.")
            return False
            
        img_bytes = self.image_to_bytes(img_array)
        file_name = os.path.basename(file_path)
        
        try:
            files = {'image': (file_name, img_bytes, 'image/jpeg')}
            response = self.session.post(f"{self.base_url}/detect-hand", files=files)
            
            print(f"📊 Status Code: {response.status_code}")
            
            if response.status_code == 200:
                print("✅ Hand Detection - SUCCESS")
                try:
                    result = response.json()
                    print(f"📄 Response: {json.dumps(result, indent=2)}")
                    if result.get('palm_detected'):
                        print(f"👋 Palm Detected: {result['palm_detected']}")
                    return True
                except json.JSONDecodeError:
                    print(f"⚠️ Received non-JSON response: {response.text}")
                    return False
            else:
                print(f"❌ Hand Detection - FAILED: {response.text}")
                return False
        except Exception as e:
            print(f"❌ Hand Detection - ERROR: {e}")
            return False
    
    def test_segment_lines(self, img_array, file_path):
        """Tests the /segment-lines endpoint and returns the image token."""
        if img_array is None:
            print("❌ Skipping test_segment_lines: Invalid image data.")
            return None
            
        img_bytes = self.image_to_bytes(img_array)
        
        try:
            response = self.session.post(
                f"{self.base_url}/segment-lines",
                data=img_bytes,
                headers={'Content-Type': 'image/jpeg'}
            )
            
            print(f"📊 Status Code: {response.status_code}")
            
            if response.status_code == 200:
                print("✅ Line Segmentation - SUCCESS")
                try:
                    result = response.json()
                    print(f"📄 Response: {json.dumps(result, indent=2)}")
                    token = result.get('image_token')
                    if token:
                        print(f"🎫 Image Token: {token}")
                        return token
                    else:
                        print("❌ Line Segmentation - FAILED: No 'image_token' in response.")
                        return None
                except json.JSONDecodeError:
                    print(f"⚠️ Received non-JSON response: {response.text}")
                    return None
            else:
                print(f"❌ Line Segmentation - FAILED: {response.text}")
                return None
        except Exception as e:
            print(f"❌ Line Segmentation - ERROR: {e}")
            return None
    
    def test_get_mask_image(self, token=None):
        """Tests the /get-mask-image endpoint using a provided token."""
        if not token:
            print("❌ Skipping Get Mask Image test: No valid token was provided.")
            return False
        
        output_filename = f"test_output_mask_{token}.jpg"
        
        try:
            response = self.session.get(f"{self.base_url}/get-mask-image?token={token}")
            
            print(f"📊 Status Code: {response.status_code}")
            
            if response.status_code == 200:
                print("✅ Get Mask Image - SUCCESS")
                print(f"📊 Content Type: {response.headers.get('content-type', 'unknown')}")
                print(f"📏 Content Length: {len(response.content)} bytes")
                
                with open(output_filename, "wb") as f:
                    f.write(response.content)
                print(f"💾 Image saved as: {output_filename}")
                return True
            else:
                print(f"❌ Get Mask Image - FAILED: {response.text}")
                return False
                
        except Exception as e:
            print(f"❌ Get Mask Image - ERROR: {e}")
            return False

    def run_tests(self, file_path):
        print("\n" + "="*60)
        print("🚀 Starting Palm & Line Detection Test Suite")
        print("="*60)
        
        img_array = self.load_image_from_file(file_path)
        if img_array is None:
            print(f"\n❌ Image file '{file_path}' could not be loaded. Cannot proceed with tests.")
            return

        self.run_test("Hand Detection", self.test_detect_hand, img_array=img_array, file_path=file_path)
        token = self.run_test("Line Segmentation", self.test_segment_lines, img_array=img_array, file_path=file_path)
        self.run_test("Get Mask Image", self.test_get_mask_image, token=token)

        self.print_summary()

    def print_summary(self):
        print("\n" + "="*60)
        print("🎯 Test Suite Summary")
        print("="*60)
        for test_name, passed in self.test_results.items():
            status = "✅ PASSED" if passed else "❌ FAILED"
            print(f"[{status}] {test_name}")
        print("="*60)

def main():
    tester = PalmReadingTest()
    file_path = "palm.jpg"
    tester.run_tests(file_path)
    
    for file in os.listdir('.'):
        if file.startswith('test_output_mask_'):
            print(f"Removing generated file: {file}")
            os.remove(file)

if __name__ == "__main__":
    main()
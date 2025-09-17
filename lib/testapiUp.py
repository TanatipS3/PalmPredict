# test_user_profile
import requests
import base64
import io
import json
import os
import datetime
from PIL import Image
import numpy as np

class UserProfileTest:
    """
    A test suite for the User Profile API endpoint.
    """
    def __init__(self, base_url="http://localhost:5000"):
        self.base_url = base_url
        self.session = requests.Session()
        self.test_results = {}
        print(f"🧪 Initializing User Profile tester for: {self.base_url}")

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
            
    def image_to_base64(self, img_array):
        if img_array is None:
            return None
        img_pil = Image.fromarray(img_array)
        img_bytes = io.BytesIO()
        img_pil.save(img_bytes, format='JPEG')
        img_bytes.seek(0)
        return base64.b64encode(img_bytes.getvalue()).decode('utf-8')

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

    def test_upload_user_profile(self, img_array):
        """Tests the /upload-user-profile endpoint."""
        if img_array is None:
            print("❌ Skipping test_upload_user_profile: Invalid image data.")
            return False

        img_base64 = self.image_to_base64(img_array)
        
        test_data = {
            "transfer_code": "ag12sa1f2s1a23f1",
            "user_name": "tester123",
            "image_url": "dd",
            "last_updated": datetime.datetime.utcnow().isoformat(),
            "created_at": datetime.datetime.utcnow().isoformat()
        }
        
        try:
            response = self.session.post(
                f"{self.base_url}/upload-user-profile",
                json=test_data,
                headers={'Content-Type': 'application/json'}
            )
            
            print(f"📊 Status Code: {response.status_code}")
            
            if response.status_code == 200:
                print("✅ Upload User Profile - SUCCESS")
                try:
                    result = response.json()
                    print(f"📄 Response: {json.dumps(result, indent=2)}")
                except json.JSONDecodeError:
                    print(f"⚠️ Received non-JSON response: {response.text}")
                return True
            else:
                print(f"❌ Upload User Profile - FAILED: {response.text}")
                return False
        except Exception as e:
            print(f"❌ Upload User Profile - ERROR: {e}")
            return False
            
    def run_tests(self, file_path):
        print("\n" + "="*60)
        print("🚀 Starting User Profile Test Suite")
        print("="*60)
        
        img_array = self.load_image_from_file(file_path)
        if img_array is None:
            print(f"\n❌ Image file '{file_path}' could not be loaded. Cannot proceed with tests.")
            return

        self.run_test("Upload User Profile", self.test_upload_user_profile, img_array=img_array)
        
        print("\n" + "="*60)
        print("🎯 Test Suite Summary")
        print("="*60)
        for test_name, passed in self.test_results.items():
            status = "✅ PASSED" if passed else "❌ FAILED"
            print(f"[{status}] {test_name}")
        print("="*60)

def main():
    tester = UserProfileTest()
    file_path = "lib/palm.jpg"
    tester.run_tests(file_path)

if __name__ == "__main__":
    main()
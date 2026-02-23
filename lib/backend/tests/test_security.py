import os
import sys
import unittest
from unittest.mock import MagicMock, patch

# === Mock Dependencies ===
# These must be mocked BEFORE importing app
sys.modules["cv2"] = MagicMock()
sys.modules["supabase"] = MagicMock()
sys.modules["numpy"] = MagicMock()
sys.modules["PIL"] = MagicMock()
sys.modules["PIL.Image"] = MagicMock()
sys.modules["dotenv"] = MagicMock()
sys.modules["requests"] = MagicMock()

# === Set Environment Variables ===
os.environ["SUPABASE_URL"] = "https://example.com"
os.environ["SUPABASE_KEY"] = "dummy"
os.environ["APP_STAGE"] = "test"

# === Import App ===
# Ensure lib/backend is in path
current_dir = os.path.dirname(os.path.abspath(__file__))
backend_dir = os.path.abspath(os.path.join(current_dir, ".."))
if backend_dir not in sys.path:
    sys.path.append(backend_dir)

from app import app

class TestSecurity(unittest.TestCase):
    def setUp(self):
        self.client = app.test_client()
        app.testing = True

    def test_path_traversal_sanitization(self):
        """
        Test that get_mask_image sanitizes the token.
        """
        token = "../etc/passwd"
        with patch("os.path.exists") as mock_exists:
            mock_exists.return_value = False # Force 404 to exit early

            self.client.get(f"/get-mask-image?token={token}")

            if mock_exists.called:
                args, _ = mock_exists.call_args
                path = args[0]
                print(f"DEBUG: Checked path: {path}")
                self.assertNotIn("..", path, "Path traversal vulnerability: '..' found in path")

    def test_large_payload_upload(self):
        """
        Test that a payload > 5MB is rejected with 413.
        """
        large_data = "a" * (6 * 1024 * 1024)
        response = self.client.post(
            "/upload-user-profile",
            data=large_data,
            content_type="application/json"
        )
        print(f"DEBUG: Upload response status: {response.status_code}")
        print(f"DEBUG: Upload response data: {response.data}")
        self.assertEqual(response.status_code, 413, "Should reject large payload with 413")

    def test_large_payload_segment(self):
        """
        Test that a payload > 5MB is rejected with 413.
        """
        large_data = b"a" * (6 * 1024 * 1024)
        response = self.client.post(
            "/segment-lines",
            data=large_data,
            content_type="application/octet-stream"
        )
        print(f"DEBUG: Segment response status: {response.status_code}")
        print(f"DEBUG: Segment response data: {response.data}")
        self.assertEqual(response.status_code, 413, "Should reject large payload with 413")

if __name__ == "__main__":
    unittest.main()

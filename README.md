# PalmPredict

An AI-powered palm reading app. Take a photo of your palm and get predictions for your life, head, and heart lines — powered by computer vision and a Python/Flask backend on AWS Lambda.

---

## Part 1 — Run it locally (beginner-friendly)

You need **two things running at the same time**: the Python backend server and the Flutter app.

### What you need to install first

| Tool | Why | Download |
|------|-----|----------|
| Python 3.10+ | Runs the backend server | https://www.python.org/downloads/ |
| Flutter SDK | Runs the mobile app | https://docs.flutter.dev/get-started/install |
| Android emulator or a physical phone | To run the Flutter app | Android Studio → Virtual Device Manager |

---

### Step 1 — Set up the backend

Open a terminal and run these commands one by one:

```bash
# Go into the backend folder
cd lib/backend

# Create an isolated Python environment (do this only once)
python -m venv .venv

# Activate it
# On Windows:
.venv\Scripts\activate
# On Mac/Linux:
source .venv/bin/activate

# Install all dependencies (do this only once, or after pulling new changes)
pip install -r requirements.txt
```

Next, create a `.env` file in the `lib/backend` folder. Copy the example and fill in your keys:

```bash
# Still inside lib/backend/
copy .env.example .env      # Windows
# cp .env.example .env      # Mac/Linux
```

Open `.env` and fill in these values (get them from your Supabase project):

```env
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_KEY=your_supabase_service_role_key
CORS_ORIGINS=*
```

> **Where to get these values:**
> - `SUPABASE_URL` and `SUPABASE_KEY` — go to your Supabase project → Settings → API
> - The Roboflow model URLs and keys are loaded automatically from the `Admin` table in Supabase (the backend reads them at startup — no extra env vars needed)

Now start the backend:

```bash
python app.py
```

You should see output ending with something like:
```
✅ Model configs loaded.
 * Running on http://0.0.0.0:5000
```

Leave this terminal open. The backend is now running.

---

### Step 2 — Run the Flutter app

Open a **second** terminal at the project root (the folder that contains `pubspec.yaml`):

```bash
# Install Flutter packages (do this only once, or after pulling new changes)
flutter pub get

# Check your setup is correct
flutter doctor
```

If `flutter doctor` shows errors, fix them before continuing (usually missing Android SDK or a missing device).

Connect your phone or start an Android emulator, then:

```bash
flutter run
```

The app will build and launch. The first build takes a few minutes.

> **Android emulator users:** The app automatically connects to `http://10.0.2.2:5000` (the emulator's alias for your computer's localhost), so it finds the backend with no extra setup.
>
> **iOS Simulator users:** The app connects to `http://127.0.0.1:5000` automatically.
>
> **Physical Android device:** You need to be on the same Wi-Fi as your computer. Edit `lib/services/api_service.dart` and replace the Android URL with your computer's local IP address (e.g. `http://192.168.1.x:5000`).

---

### Quick checklist if something doesn't work

- **Backend won't start** → check your `.env` file has `SUPABASE_URL` and `SUPABASE_KEY` filled in
- **App connects but palm detection fails** → the Roboflow model URLs/keys must be in the `Admin` table in Supabase with `is_active = true`
- **`flutter doctor` shows issues** → follow Flutter's own instructions to resolve them
- **iOS HTTP connection error** → already handled: `NSAppTransportSecurity` is configured in `ios/Runner/Info.plist`

---

## Part 2 — How this project works (for developers)

### Architecture overview

```
User picks a palm photo (Flutter)
        │
        ▼
Step 1: POST /detect-hand  ──► Roboflow hand detection model
        │                       (is a hand present?)
        ▼
Step 2: POST /segment-lines ──► Roboflow line segmentation model
        │                        (polygon masks for life/head/heart lines)
        │
        ├── SIFT feature extraction per line mask (OpenCV)
        ├── Match features against answer profiles stored in Supabase
        └── Returns: prediction text + image token
                │
                ▼
        GET /get-mask-image?token=... ──► serves the debug overlay JPEG
                │
                ▼
        Flutter displays predictions + overlay image
```

### Frontend — Flutter (`lib/`)

The app has three pages navigated by a bottom nav bar:

| File | Role |
|------|------|
| `main.dart` | App entry, initializes Supabase SDK |
| `pages/Mainmenu.dart` | Home screen, camera access |
| `pages/PalmScreen.dart` | Core flow: image → API calls → results |
| `pages/Userprofile.dart` | Profile, transfer code generation and sync |
| `pages/history.dart` | Local history of past predictions |
| `services/api_service.dart` | All HTTP calls; auto-selects the right URL per platform |
| `services/image_utils.dart` | Image preprocessing before upload |
| `components/custom_button.dart` | Shared widget |

**Targeting production at build time:**
```bash
flutter run --dart-define=API_BASE_URL=https://r6z1dwdcl0.execute-api.ap-southeast-1.amazonaws.com
```
Without that flag the app uses local dev URLs automatically.

### Backend — Python Flask (`lib/backend/`)

| File | Role |
|------|------|
| `app.py` | All routes, Roboflow calls, SIFT matching, Supabase reads/writes |
| `handler.py` | AWS Lambda entry point (serverless-wsgi adapter) |
| `Dockerfile` | Lambda container image (Python 3.12) |
| `tests/test_security.py` | Security tests (path traversal, payload size rejection) |

**Routes:**

| Route | Method | Input | Output |
|-------|--------|-------|--------|
| `/health` | GET | — | `{"ok": true}` |
| `/detect-hand` | POST | multipart `image` field | `{"palm_detected": bool}` |
| `/segment-lines` | POST | raw JPEG bytes | `{life_line, head_line, heart_line, image_token}` |
| `/get-mask-image` | GET | `?token=<token>` | JPEG image |
| `/upload-user-profile` | POST | JSON body | upsert result |

**Cold-start:** On startup `app.py` reads Roboflow API keys and model URLs from the `Admin` Supabase table (`is_active=true` rows). Change models without redeploying by updating that table.

**Caching:** `download_profile_pkl` and `load_answer_profiles` use `@lru_cache` to avoid repeated Supabase calls within the same Lambda container.

**Security:** 5 MB upload limit (`MAX_CONTENT_LENGTH`), path traversal sanitization on the token parameter via `werkzeug.utils.secure_filename`.

### Database — Supabase

| Table | Purpose |
|-------|---------|
| `Admin` | Roboflow model configs (`model_type`, `PROJECT`, `VERSION`, `ROBOFLOW_API_KEY`, `is_active`) |
| `answer_profiles` | SIFT descriptor profiles for matching (`line_type`, `pkl_name`, `answer_text`) |
| `user_profiles` | User data, indexed by `transfer_code` |
| `prediction_history` | Per-user prediction history |

Storage buckets: `palm-models` (`.pkl` descriptor files), `user-profiles` (profile images), `user-history` (history images).

### CI/CD (`.github/workflows/`)

| File | What it does |
|------|-------------|
| `dart2.02.yml` | `flutter analyze` + build check on push to main |
| `backend.yml` | Builds Lambda container and deploys to AWS on push to main |
| `OIDC.yml` | AWS OIDC role configuration for keyless Lambda deploys |

### Running backend tests

```bash
cd lib/backend
python -m pytest tests/
```

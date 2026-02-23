# Palm Project 🖐️

Welcome to the **Palm Project**! This application uses advanced palm reading technology (AI) to analyze your palm lines and provide insights. The project consists of a **Flutter frontend** for the mobile app and a **Python Flask backend** for processing images.

## 🚀 Getting Started

This guide will help you set up and run the project locally on your machine.

### Prerequisites

Before you begin, ensure you have the following installed:
- **[Flutter SDK](https://docs.flutter.dev/get-started/install)** (for the mobile app)
- **[Python 3](https://www.python.org/downloads/)** (for the backend)
- **pip** (Python package installer)

---

## 📂 Project Structure

- `lib/`: Contains the Flutter frontend code.
  - `pages/`: UI screens (e.g., Main Menu, Palm Screen, User Profile).
  - `components/`: Reusable UI widgets.
  - `services/`: API services and helper functions.
- `lib/backend/`: Contains the Python backend code.
  - `app.py`: The main Flask application.
  - `requirements.txt`: Python dependencies.

---

## 🛠️ Backend Setup (Python)

The backend handles image processing and connects to Supabase.

1.  **Navigate to the backend directory:**
    ```bash
    cd lib/backend
    ```

2.  **Create a virtual environment (optional but recommended):**
    ```bash
    python3 -m venv .venv
    source .venv/bin/activate  # On Windows: .venv\Scripts\activate
    ```

3.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Configure Environment Variables:**
    - Create a `.env` file in the `lib/backend` directory.
    - Copy the contents of `.env.example` into `.env`.
    - Fill in your API keys (Supabase, Roboflow, etc.).

    Example `.env` content:
    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_KEY=your_supabase_key
    CORS_ORIGINS=*
    ROBOFLOW_API_KEY=xxxx
    ```

5.  **Run the Backend:**
    ```bash
    python app.py
    ```
    The server will start at `http://127.0.0.1:5000` (or `0.0.0.0:5000`).

---

## 📱 Frontend Setup (Flutter)

The frontend is the mobile application user interface.

1.  **Navigate to the project root:**
    ```bash
    cd ../..  # Go back to the root folder if you are in lib/backend
    # or just open a new terminal in the project root
    ```

2.  **Install Flutter dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Run the App:**
    - Connect a device or start an emulator/simulator.
    - Run the following command:
    ```bash
    flutter run
    ```

    **Note for Android Emulator:** The backend running on `localhost` is accessible via `10.0.2.2`. Ensure your API service in Flutter points to the correct address.

---

## 🎨 UX Improvements

We are constantly improving the user experience. Recent updates include:
- **Loading States:** Added visual feedback (loading spinners) for critical async operations like generating transfer codes and syncing data in the User Profile page. This prevents user confusion and double submissions.

---

## 🤝 Contributing

1.  Fork the repository.
2.  Create your feature branch (`git checkout -b feature/amazing-feature`).
3.  Commit your changes (`git commit -m 'Add some amazing feature'`).
4.  Push to the branch (`git push origin feature/amazing-feature`).
5.  Open a Pull Request.

Happy Coding! 🎨

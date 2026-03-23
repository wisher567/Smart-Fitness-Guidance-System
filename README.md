# FitFusion — Smart Fitness Guidance System

Group 26 | PUSL 2021 Computing Group Project | NSBM / Plymouth University

---

##Before You Start

You need these files that are NOT included in the source code:

### serviceAccountKey.json
Download from Firebase Console:
```
Firebase Console
→ Project Settings
→ Service Accounts
→ Generate new private key
→ Save as serviceAccountKey.json
→ Place it inside fitfusion-backend/ folder
```

---

##Project has 4 Parts

```
Fitfusion/
├── fitfusion-backend/      ← Node.js API
├── fitfusion-ai/           ← Python Posture Detection
├── fitfusion-admin/        ← React Admin Website
└── fitfusion-frontend/     ← Flutter Mobile App
```

---

## fitfusion-backend (Node.js)

### Create .env file inside fitfusion-backend/
```env
PORT=3000
GROQ_API_KEY=get from console.groq.com (free)
AI_SERVICE_URL=http://localhost:8000
EMAIL_USER=your_gmail@gmail.com
EMAIL_PASS=your_gmail_app_password
EMAIL_FROM=FitFusion Gym <your_gmail@gmail.com>
```

> Get Gmail App Password:
> Google Account → Security → 2-Step Verification → App Passwords

### Install & Run
```bash
cd fitfusion-backend
npm install
npm run dev
```
Runs at: **http://localhost:3000**

---

## fitfusion-ai (Python)

### No .env needed

### Install & Run
```bash
cd fitfusion-ai

# Create virtual environment
python -m venv venv

# Activate (Windows)
venv\Scripts\activate

# Install packages
pip install -r requirements.txt

# Run
uvicorn main:app --reload --port 8000
```
Runs at: **http://localhost:8000**

> Use Python 3.11 

---

## fitfusion-admin (React)

### Create .env file inside fitfusion-admin/
```env
VITE_API_URL=http://localhost:3000/api
VITE_FIREBASE_API_KEY=from Firebase Console
VITE_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your-project-id
```

> Get Firebase config:
> Firebase Console → Project Settings → Your Apps → Web App → Config

### Install & Run
```bash
cd fitfusion-admin
npm install
npm run dev
```
Runs at: **http://localhost:5173**

> First login: go to Firebase Console → Firestore → users → your document → set role to `admin`

---

## fitfusion-frontend (Flutter)

### No .env needed

### Before running — update your PC IP address:
Open `lib/services/api_service.dart` and change:
```dart
static const String baseUrl = 'http://YOUR_PC_IP:3000/api';
```

Find your IP: run `ipconfig` in terminal → look for IPv4 Address under Wi-Fi

### Install & Run
```bash
cd fitfusion-frontend
flutter pub get
flutter run
```

> Phone and PC must be on same WiFi network

---

## Run All 4 Together

Open 4 separate terminals:

```bash
# Terminal 1
cd fitfusion-backend && npm run dev

# Terminal 2
cd fitfusion-ai && venv\Scripts\activate && uvicorn main:app --reload --port 8000

# Terminal 3
cd fitfusion-admin && npm run dev

# Terminal 4
cd fitfusion-frontend && flutter run
```

---

##  Dependencies Summary


| fitfusion-backend | `npm install` | Node.js 18+ |
| fitfusion-ai | `pip install -r requirements.txt` | Python 3.11 |
| fitfusion-admin | `npm install` | Node.js 18+ |
| fitfusion-frontend | `flutter pub get` | Flutter 3.0+ |

---

## Keys You Need to Get


 serviceAccountKey.json 
 GROQ_API_KEY
 Gmail App Password 
 Firebase Config 

---

*© 2026 FitFusion — Group 26*

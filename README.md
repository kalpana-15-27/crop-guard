# CropGuard AI — Intelligent Pest Detection & Crop Protection

[![Flutter](https://img.shields.io/badge/Flutter-3.47.9-blue.svg?logo=flutter)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688.svg?logo=fastapi)](https://fastapi.tiangolo.com)
[![YOLO11s](https://img.shields.io/badge/Model-YOLO11s-FF6F00.svg?logo=ultralytics)](https://docs.ultralytics.com)
[![Supabase](https://img.shields.io/badge/Database-Supabase_PostgreSQL-3ECF8E.svg?logo=supabase)](https://supabase.com)
[![Bilingual](https://img.shields.io/badge/Language-English_%26_Telugu-brightgreen.svg)](#)
[![Tests](https://img.shields.io/badge/Tests-31%2F31_Passed-success.svg)](#)

> **B.Tech Computer Science & Engineering Final Year Capstone Project**  
> *Empowering Indian smallholder farmers with state-of-the-art deep learning for rapid agricultural insect detection, localized bilingual advisories, and crop loss prevention.*

---

## 1. Project Abstract & Problem Statement

Agricultural pest infestations account for up to **30–40% of annual crop yield losses** in India, directly impacting the livelihoods of millions of smallholder farmers cultivating staple and cash crops such as **Paddy/Rice, Cotton, Tomato, and Chilli**. Conventional agricultural scouting requires extensive botanical knowledge or access to agricultural extension officers, who are often unavailable during early pest outbreaks. Misidentification frequently leads to improper chemical pesticide application, incurring unnecessary financial burdens, accelerating pesticide resistance, and damaging soil ecosystems.

**CropGuard AI** solves this critical challenge by providing an accessible, production-minded cross-platform mobile application powered by an ultra-fast **YOLO11s** deep learning object detection model. A farmer simply captures a photograph of an affected crop leaf or stem using their smartphone camera. Within milliseconds, CropGuard AI:
1. Detects and localizes harmful insect pests using color-coded bounding boxes.
2. Identifies the specific insect taxonomy and severity level.
3. Delivers actionable, localized **Integrated Pest Management (IPM)** preventive guidance in both **English and Telugu (తెలుగు)**.
4. Archives scan history securely on a multi-tenant PostgreSQL cloud database.

---

## 2. Key Features

- **High-Accuracy Object Detection (YOLO11s):** Anchor-free architecture with C3k2/C2PSA attention mechanisms optimized for small-scale insect identification.
- **Bilingual Interface & Agricultural Guidance:** Instant in-memory switching between **English** and **Telugu (తెలుగు)** without application reloading.
- **Target Crop Specialization:** Tailored detection pipelines and crop contextualization for **Paddy/Rice**, **Cotton**, **Tomato**, and **Chilli**.
- **6 Critical Harmful Pest Categories:** Detects sap-sucking insects and internal borers with zero fabrication of unverified classes.
- **Annotated Visual Feedback:** Overlays detected insect bounding boxes, confidence tags, and crop risk badges directly onto camera imagery.
- **Secure Cloud Storage & Scan History:** Backed by Supabase PostgreSQL with strict **Row Level Security (RLS)** ensuring complete tenant data isolation.
- **Offline / Low-Connectivity Resilience:** Provides local cached advisory guidance and offline fallback inference when cellular data is unavailable in remote fields.
- **Farmer-Centric UI/UX:** Built on Flutter with Material 3, following the *Premium Agricultural Technology* green palette with large tactile touch targets.

---

## 3. Target Crops & Pest Classes

| Class ID | Common English Name | Telugu Name (తెలుగు) | Scientific Binomial Name | Primary Host Crops |
|:---:|---|---|---|---|
| `0` | **Aphids** | **పేనుబంక (Aphids)** | *Aphis gossypii* | Cotton, Chilli, Tomato |
| `1` | **Whitefly** | **తెల్లదోమ (Whitefly)** | *Bemisia tabaci* | Cotton, Tomato, Chilli |
| `2` | **Brown Planthopper** | **సుడిదోమ (Brown Planthopper)** | *Nilaparvata lugens* | Paddy / Rice |
| `3` | **Yellow Stem Borer** | **కాండం తొలుచు పురుగు (Stem Borer)** | *Scirpophaga incertulas* | Paddy / Rice |
| `4` | **Thrips** | **తామర పురుగులు (Thrips)** | *Scirtothrips dorsalis* | Chilli, Cotton, Tomato |
| `5` | **Helicoverpa armigera** | **శనగపచ్చ పురుగు (Fruit Borer)** | *Helicoverpa armigera* | Tomato, Cotton, Chilli |

---

## 4. System Architecture

```text
  +-------------------------------------------------------------------------+
  |                        Mobile Client Tier (Flutter)                     |
  |  - Material 3 UI Screens (Splash, Auth, Home, Scan, Result, History)    |
  |  - Bilingual Localization Provider (English & Telugu)                  |
  |  - Camera & Gallery Image Acquisition Pipeline                          |
  |  - Supabase Flutter SDK (GoTrue Authentication)                         |
  +------------------------------------+------------------------------------+
                                       | Multipart POST / REST API
                                       v
  +-------------------------------------------------------------------------+
  |                    Inference Backend Tier (FastAPI / ASGI)              |
  |  - Security & Image Validation Middleware (MIME, EXIF, <=10MB)          |
  |  - YOLO11s Inference Engine (PyTorch / Ultralytics / ONNX)              |
  |  - Dynamic Bounding-Box Annotation & Rendering Engine (Pillow)          |
  |  - Bilingual Integrated Pest Management (IPM) Advisory Service          |
  +------------------------------------+------------------------------------+
                                       | Database Driver (asyncpg / postgrest)
                                       v
  +-------------------------------------------------------------------------+
  |                   Data Tier (Supabase Cloud PostgreSQL)                 |
  |  - auth.users (Secure Encrypted Credential Vault)                       |
  |  - profiles, pest_categories, uploaded_images, predictions              |
  |  - Row-Level Security (RLS) Tenant Isolation Policies                   |
  |  - Supabase Storage Bucket ('cropguard-images')                         |
  +-------------------------------------------------------------------------+
```

For complete architectural specifications, see [docs/architecture.md](file:///c:/Users/Dell/Desktop/crop_guard/docs/architecture.md).

---

## 5. Technology Stack

* **Mobile Application:** Flutter 3.47.9, Dart 3.13.7, Material 3, Provider, Image Picker, Supabase Flutter SDK, Flutter SVG.
* **Backend Gateway:** Python 3.14, FastAPI, Uvicorn (ASGI), Pydantic v2, HTTPX.
* **Computer Vision & ML:** PyTorch, Ultralytics YOLO11s, Pillow, OpenCV, NumPy.
* **Database & Cloud:** Supabase PostgreSQL, GoTrue Authentication, Supabase Storage, Row Level Security.
* **Model Training Infrastructure:** Google Colab GPU (Tesla T4 16GB VRAM) / Kaggle GPU.

---

## 6. Project Directory Structure

```text
crop_guard/
├── mobile/                        # Cross-platform Flutter mobile client
│   ├── lib/
│   │   ├── config/                # Environment and Supabase constants
│   │   ├── core/                  # Material 3 theme & color palette
│   │   ├── localization/          # English & Telugu bilingual dictionary
│   │   ├── models/                # PestCategory, DetectionResult, User models
│   │   ├── providers/             # AuthProvider state management
│   │   ├── screens/               # 8 production screens + navigation
│   │   ├── services/              # API and Supabase network services
│   │   └── widgets/               # Reusable agricultural UI components
│   ├── test/                      # 13 automated Flutter unit & widget tests
│   └── pubspec.yaml               # Flutter package dependencies
│
├── backend/                       # High-performance FastAPI server
│   ├── app/
│   │   ├── api/v1/endpoints/      # REST endpoints (health, pests, detect, history)
│   │   ├── core/                  # Settings and CORS configuration
│   │   ├── database/              # Supabase PostgreSQL client wrapper
│   │   ├── inference/             # YOLO11s detector with fallback pipeline
│   │   ├── schemas/               # Pydantic request/response schemas
│   │   └── services/              # Storage, advisory, and history services
│   ├── tests/                     # 18 automated backend & ML unit tests
│   ├── requirements.txt           # Python dependencies
│   ├── .env.example               # Configuration template
│   └── .env                       # Local environment variables (uncommitted)
│
├── ml/                            # Machine learning & YOLO11s pipeline
│   ├── configs/                   # dataset.yaml & hyp_cropguard.yaml
│   ├── dataset/                   # Raw & processed bounding-box storage
│   ├── evaluation/                # Evaluation & metric calculation scripts
│   ├── notebooks/                 # Google Colab GPU training notebook (.ipynb)
│   ├── sample_images/             # Test foliage images for all 4 crops
│   ├── training/                  # Dataset prep & YOLO11s training scripts
│   └── weights/                   # Model weight checkpoints (.pt / .onnx)
│
├── supabase/                      # Cloud database configuration
│   └── migrations/
│       └── 001_initial_schema.sql # Non-destructive PostgreSQL schema & RLS
│
├── docs/                          # Comprehensive academic deliverables
│   ├── architecture.md            # System architecture and data flow diagrams
│   ├── database-design.md         # ER diagram, table schemas, and RLS matrix
│   ├── api-documentation.md       # Full OpenAPI REST endpoint specifications
│   ├── model-evaluation.md        # YOLO11s training & evaluation report
│   └── testing-report.md          # 31-test QA report with 100% pass rate
│
├── .gitignore                     # Git ignore rules protecting keys and builds
└── README.md                      # Master project documentation
```

---

## 7. Setup & Installation Guide

### 7.1 Prerequisites
* **Operating System:** Windows 10/11, macOS, or Linux.
* **Python:** Python 3.10+ (tested with Python 3.14).
* **Flutter SDK:** Flutter 3.24+ (tested with Flutter 3.47.9 / Dart 3.13.7).
* **Java Development Kit:** JDK 17 or JDK 21 (`C:\Program Files\Java\jdk-21`).
* **Android SDK:** Android SDK Platform-tools & Build-tools (API 34+).

---

### 7.2 Backend Setup & Execution

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```

2. Create and activate a Python virtual environment:
   ```bash
   python -m venv venv
   # On Windows (PowerShell):
   .\venv\Scripts\Activate.ps1
   # On Linux/macOS:
   source venv/bin/activate
   ```

3. Install required Python packages:
   ```bash
   pip install -r requirements.txt
   ```

4. Configure environment variables in `backend/.env`:
   ```env
   SUPABASE_URL=https://cxzayeoqbocryekkqiyk.supabase.co
   SUPABASE_PUBLISHABLE_KEY=sb_publishable_ndB59weEGKDben6iY6odMg_hkNruZ3k
   HOST=0.0.0.0
   PORT=8000
   ```

5. Run the FastAPI development server:
   ```bash
   python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
   ```
   * Access API documentation at `http://localhost:8000/docs`
   * Health check endpoint at `http://localhost:8000/health`

---

### 7.3 Google Colab GPU Training Workflow (YOLO11s)

1. Open Google Colab: [colab.research.google.com](https://colab.research.google.com)
2. Upload the notebook: `ml/notebooks/cropguard_yolo11s_training.ipynb`.
3. Set the Colab runtime to **GPU** (`Runtime -> Change runtime type -> T4 GPU`).
4. Execute the step-by-step cells:
   * Cell 1: Environment verification (`nvidia-smi`, `ultralytics` install).
   * Cell 2: Dataset download and annotation boundary verification.
   * Cell 3: Fine-tuning YOLO11s for 50 epochs with `hyp_cropguard.yaml`.
   * Cell 4: Evaluation on held-out test split (mAP@50, mAP@50:95, Confusion Matrix).
   * Cell 5: Download trained weights (`best.pt`) and place them in `ml/weights/best.pt`.

---

### 7.4 Supabase Database Schema Migration

To apply the database schema to your Supabase project:
1. Log in to your Supabase dashboard: `https://supabase.com/dashboard/project/cxzayeoqbocryekkqiyk`.
2. Open the **SQL Editor** tab from the left sidebar.
3. Open `supabase/migrations/001_initial_schema.sql` in this repository.
4. Paste the SQL script and click **Run**.
5. The migration creates the 5 core tables, auto-trigger functions, RLS policies, and inserts bilingual Telugu/English seed advisories for all 6 pests.

---

### 7.5 Mobile Application Setup & Physical Android Run

1. Navigate to the mobile directory:
   ```bash
   cd mobile
   ```

2. Fetch Flutter dependencies:
   ```powershell
   $env:PATH = "C:\Users\Dell\develop\flutter\bin;C:\Users\Dell\AppData\Local\Android\Sdk\platform-tools;$env:PATH"
   flutter pub get
   ```

3. Run static analyzer and automated tests:
   ```powershell
   flutter analyze
   flutter test
   ```

4. Run the app on your connected physical Android phone:
   ```powershell
   # Identify device ID (e.g. 10BE7Q1HEH000N6)
   flutter devices

   # Launch directly on phone with hot reload:
   flutter run -d 10BE7Q1HEH000N6
   ```

---

## 8. Automated Test Suite Execution

Run all 31 automated tests across backend and mobile:

### Backend Unit & Integration Tests (18 Tests)
```bash
python -m unittest discover -s backend/tests -p "test_*.py"
```
```text
Ran 18 tests in 3.592s
OK
```

### Mobile Unit & Widget Tests (13 Tests)
```powershell
Set-Location mobile
flutter test
```
```text
00:01 +13: All tests passed!
```

---

## 9. Live Demonstration & Viva Presentation Guide

For project viva, follow this 8-step live walkthrough:

1. **Launch Screen & Bilingual Switch:**
   * Open the app to view the Splash screen with brand tagline.
   * On the Profile screen or top bar, tap the **EN / తెలుగు** toggle to demonstrate dynamic bilingual string rendering.
2. **Crop Selection:**
   * On the Home Dashboard, select one of the target crops (**Paddy/Rice, Cotton, Tomato, Chilli**).
3. **Image Acquisition:**
   * Tap **Scan Crop** to open the Image Capture screen.
   * Select an infested leaf image from gallery or capture with camera (use samples in `ml/sample_images/`).
4. **Real-Time Detection:**
   * Tap **Detect Pests**. The app communicates with the FastAPI backend.
   * View the interactive result screen displaying total pest count, highest confidence score, and bounding boxes.
5. **Interactive Bounding Box Inspection:**
   * Toggle between the original captured image and the YOLO-annotated bounding-box image.
6. **Bilingual Advisory Inspection:**
   * Review scientific binomial name, vernacular symptoms, and preventive IPM chemical/organic controls in Telugu and English.
7. **History Dashboard:**
   * Navigate to the **History** tab to verify that the scan is persisted in Supabase with thumbnail, timestamp, and crop type.
8. **Security & Profile:**
   * Review the user profile, verify sign-out functionality, and demonstrate tenant isolation under Supabase RLS.

---

## 10. Academic Project Documentation Links

- **[System Architecture](file:///c:/Users/Dell/Desktop/crop_guard/docs/architecture.md):** Complete component breakdown, data flow, and Mermaid sequence diagrams.
- **[Database Design & RLS](file:///c:/Users/Dell/Desktop/crop_guard/docs/database-design.md):** Relational ER diagram, table schemas, and security matrix.
- **[REST API Specification](file:///c:/Users/Dell/Desktop/crop_guard/docs/api-documentation.md):** Detailed OpenAPI endpoints, request schemas, curl examples, and error codes.
- **[Model Evaluation Report](file:///c:/Users/Dell/Desktop/crop_guard/docs/model-evaluation.md):** YOLO11s architecture, per-class mAP, precision-recall curves, and Colab GPU training.
- **[Testing & QA Report](file:///c:/Users/Dell/Desktop/crop_guard/docs/testing-report.md):** Complete 31-test verification report with 100% pass rate.

---

## 11. Authors & Acknowledgments

* **Project Title:** CropGuard AI — Intelligent Pest Detection & Crop Protection
* **Degree:** Bachelor of Technology (B.Tech) in Computer Science & Engineering
* **Dataset Acknowledgments:** Roboflow Universe Agricultural Benchmarks, IP102 Agricultural Pest Dataset, Mendeley Paddy Pest Benchmark.
* **Supervised By:** Department of Computer Science & Engineering.

# CropGuard AI — FastAPI Inference Backend

The **CropGuard AI Backend** is a high-performance Python FastAPI service providing real-time agricultural pest detection and localized bilingual advisory guidance. Powered by an Ultralytics YOLO11s deep learning model, it analyzes crop imagery, predicts insect bounding boxes and confidence scores, renders visual annotations, and delivers Integrated Pest Management (IPM) recommendations in English and Telugu (తెలుగు).

---

## 1. Architecture & Model Integration

- **Framework:** FastAPI 0.115+ (ASGI) running on Uvicorn
- **Object Detection Model:** Ultralytics YOLO11s (`yolo11s-v1.0`)
- **Default Weights Location:** `ml/weights/best.pt` (19.2 MB)
- **Inference Runtime:** PyTorch on CUDA GPU (if available) or multi-threaded CPU
- **Default Inference Parameters:**
  - `CONFIDENCE_THRESHOLD`: `0.35`
  - `IOU_THRESHOLD`: `0.45`
  - `YOLO_IMGSZ`: `640`

### Class Taxonomy & Reverse Mapping

The application maintains a canonical 6-class pest taxonomy across the mobile client and database. The YOLO11s model trained on public open-source agricultural pest datasets incorporates 5 target insect classes. The backend performs an explicit reverse class mapping during inference:

| YOLO Model Class | Detected Pest Name | Canonical Class ID | Canonical Pest Name | Scientific Binomial Name | Host Crops |
|:---:|---|:---:|---|---|---|
| `0` | Aphids | `0` | Aphids | *Aphis gossypii* | Cotton, Chilli, Tomato |
| `1` | Whitefly | `1` | Whitefly | *Bemisia tabaci* | Cotton, Tomato, Chilli |
| `2` | Brown Planthopper | `2` | Brown Planthopper | *Nilaparvata lugens* | Paddy / Rice |
| `3` | Thrips | `4` | Thrips | *Scirtothrips dorsalis* | Chilli, Cotton, Tomato |
| `4` | Helicoverpa armigera | `5` | Helicoverpa armigera | *Helicoverpa armigera* | Tomato, Cotton, Chilli |
| — | *Not in model* | `3` | **Yellow Stem Borer** | *Scirpophaga incertulas* | Paddy / Rice *(Unsupported)* |

> **Biological Integrity Protocol:**
> - YOLO Class `3` maps strictly to **Canonical Class 4 (Thrips)**. It is **never** mapped to Yellow Stem Borer.
> - **Yellow Stem Borer (Class 3)** is strictly unsupported in this 5-class model. The detector never fabricates, hallucinates, or falsely assigns this pest class.
> - Any detection with an unexpected class ID is logged with a warning and safely dropped.

---

## 2. Prerequisites & Setup

### Environment Requirements
- Python 3.10–3.13 (or Miniconda / Anaconda environment with PyTorch & Ultralytics installed)
- PyTorch 2.0+
- Ultralytics 8.4+
- Pillow 11.0+
- FastAPI & Uvicorn

### Environment Configuration (.env)
Create or verify `backend/.env`:
```env
PROJECT_NAME="CropGuard AI Backend"
ENVIRONMENT="development"
HOST="0.0.0.0"
PORT=8000
API_V1_STR="/api/v1"

# Supabase Cloud Configuration
SUPABASE_URL="https://cxzayeoqbocryekkqiyk.supabase.co"
SUPABASE_PUBLISHABLE_KEY="sb_publishable_ndB59weEGKDben6iY6odMg_hkNruZ3k"
SUPABASE_SERVICE_ROLE_KEY=""

# Model Inference Configuration
MODEL_PATH="ml/weights/best.pt"
CONFIDENCE_THRESHOLD=0.35
IOU_THRESHOLD=0.45
YOLO_IMGSZ=640
```

---

## 3. Starting the Server

From the `backend/` directory:
```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

Or from the repository root:
```bash
python -m uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Interactive Documentation
Once started, explore the interactive OpenAPI documentation:
- **Swagger UI:** [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- **ReDoc:** [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)

---

## 4. API Endpoints & Testing

### 1. Health & Model Readiness Check
```bash
curl -X GET "http://127.0.0.1:8000/health"
```
**Response:**
```json
{
  "status": "healthy",
  "app_name": "CropGuard AI Backend",
  "environment": "development",
  "version": "1.0.0",
  "model": {
    "version": "yolo11s-v1.0",
    "weights_path": "C:\\Users\\Dell\\Desktop\\crop_guard\\ml\\weights\\best.pt",
    "loaded": true,
    "status": "ready"
  },
  "supabase": {
    "url": "https://cxzayeoqbocryekkqiyk.supabase.co",
    "status": "healthy"
  }
}
```

### 2. Pest Detection (`POST /api/v1/detect`)
Upload an image of a suspected pest infestation on a leaf or stem:
```bash
curl -X POST "http://127.0.0.1:8000/api/v1/detect" \
  -F "file=@ml/sample_images/chilli_thrips.jpg;type=image/jpeg" \
  -F "crop_type=Chilli"
```
**Response:**
```json
{
  "id": "812a6a7b-6b00-4cf1-841c-32c543c40817",
  "crop_type": "Chilli",
  "detection_status": "detected",
  "total_detections": 1,
  "highest_confidence": 0.9008,
  "processing_time_sec": 0.12,
  "model_version": "yolo11s-v1.0",
  "annotated_image_url": "/uploads/annotated/annotated_a46f71328dee.jpg",
  "pest_category": {
    "id": "pest-aphids-001",
    "pest_name": "Aphids",
    "scientific_name": "Aphis gossypii",
    "affected_crops": ["Cotton", "Chilli", "Tomato"],
    "description": "Small, soft-bodied sap-sucking insects...",
    "description_te": "ఆకు అడుగు భాగంలో మరియు లేత కొమ్మలపై రసం పీల్చే చిన్న పురుగులు...",
    "symptoms": "Curled, yellowed leaves, stunted crop growth...",
    "symptoms_te": "ఆకులు ముడుచుకుపోవడం, పసుపు రంగులోకి మారడం...",
    "preventive_guidance": "Install yellow sticky traps (15-20 per acre)...",
    "preventive_guidance_te": "ఎకరాకు 15-20 పసుపు రంగు జిగురు అట్టలను ఏర్పాటు చేయండి..."
  },
  "detections": [
    {
      "class_id": 0,
      "pest_name": "Aphids",
      "confidence": 0.9008,
      "x_min": 0.0,
      "y_min": 0.0001,
      "x_max": 1.0,
      "y_max": 0.9986
    }
  ]
}
```

### 3. Pest Knowledge Base (`GET /api/v1/pests`)
```bash
curl -X GET "http://127.0.0.1:8000/api/v1/pests"
```

### 4. Scan History (`GET /api/v1/history`)
```bash
curl -X GET "http://127.0.0.1:8000/api/v1/history" \
  -H "Authorization: Bearer <SUPABASE_JWT_TOKEN>"
```

---

## 5. Running the Test Suite

Execute the complete backend test suite:
```bash
python -m unittest discover -s backend/tests -p "test_*.py"
```

The test suite covers:
- Model loading from disk and device initialization (CPU/CUDA)
- 5-class to canonical 6-class reverse mapping integrity
- Explicit exclusion and non-mapping of Yellow Stem Borer
- Dropping of unsupported/unknown classes without crashing
- Clamping of bounding box coordinates to `[0.0, 1.0]`
- Strict HTTP 503 `MODEL_NOT_TRAINED` rejection when weights are missing
- Clean `no_pest_detected` response for pest-free foliage
- End-to-end multipart detection, visualization rendering, and bilingual advisory attachment

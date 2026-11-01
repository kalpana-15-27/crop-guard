# CropGuard AI — REST API Documentation & Specification

**API Gateway:** FastAPI (Asynchronous Python 3)  
**Base URL (Local Development):** `http://localhost:8000`  
**API Prefix:** `/api/v1`  
**Interactive Swagger UI:** `http://localhost:8000/docs`  
**Interactive ReDoc:** `http://localhost:8000/redoc`  
**Academic Level:** B.Tech Computer Science & Engineering Final Project  

---

## 1. Authentication & Headers

Protected endpoints require a Supabase JWT Bearer token issued upon mobile client login:

```http
Authorization: Bearer <supabase_jwt_access_token>
```

*Note:* If the `Authorization` header is omitted or token validation is bypassed in offline/guest mode, requests default to an anonymous tenant partition (`anon-farmer-uuid`), permitting unhindered offline field demonstrations without forcing user registration.

---

## 2. API Endpoints Catalog

### 2.1 System Health & Service Status

#### `GET /health` or `GET /api/v1/health`
Checks backend service availability, YOLO model status, and Supabase database connectivity.

**Request:**
```bash
curl -X GET http://localhost:8000/health
```

**Response (`200 OK`):**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "timestamp": "2026-11-01T07:15:30.124Z",
  "services": {
    "api": "online",
    "detector": "yolo11s-v1.0",
    "database": "connected"
  },
  "supabase": {
    "status": "healthy",
    "project_url": "https://cxzayeoqbocryekkqiyk.supabase.co"
  }
}
```

---

### 2.2 Pest Taxonomy & Agricultural Advisories

#### `GET /api/v1/pests`
Retrieves the comprehensive catalog of harmful agricultural pests with botanical details and bilingual advisories.

**Query Parameters:**
* `lang` (optional, default: `en`): `en` for English, `te` for Telugu.

**Request:**
```bash
curl -X GET "http://localhost:8000/api/v1/pests?lang=te"
```

**Response (`200 OK`):**
```json
{
  "total": 6,
  "language": "te",
  "items": [
    {
      "id": "aphids",
      "pest_name": "Aphids",
      "scientific_name": "Aphis gossypii",
      "affected_crops": ["Cotton", "Chilli", "Tomato"],
      "description": "చిన్న, గుండ్రని రసం పీల్చే పురుగులు.",
      "symptoms": "ఆకులు ముడుచుకుపోవడం, తేనెలాంటి జిగట స్రవించడం.",
      "preventive_guidance": "పసుపు రంగు జిగురు అట్టలు అమర్చండి. తీవ్రత ఎక్కువగా ఉంటే డైమిథోయేట్ 2 మి.లీ/లీటర్ పిచికారీ చేయండి."
    },
    {
      "id": "whitefly",
      "pest_name": "Whitefly",
      "scientific_name": "Bemisia tabaci",
      "affected_crops": ["Cotton", "Tomato", "Chilli"],
      "description": "తెల్లటి రెక్కలు కలిగిన చిన్న పురుగులు.",
      "symptoms": "ఆకుల పసుపు రంగు మచ్చలు, వైరస్ వ్యాప్తి.",
      "preventive_guidance": "వేప నూనె 5 మి.లీ/లీటర్ పిచికారీ చేయండి."
    }
  ]
}
```

#### `GET /api/v1/pests/{pest_id}`
Retrieves in-depth botanical morphology and Integrated Pest Management (IPM) guidelines for a single specific pest.

**Parameters:**
* `pest_id` (path, string): Common pest name or identifier (e.g. `Aphids`, `Helicoverpa armigera`).

**Request:**
```bash
curl -X GET "http://localhost:8000/api/v1/pests/Aphids"
```

**Response (`200 OK`):**
```json
{
  "id": "aphids",
  "pest_name": "Aphids",
  "scientific_name": "Aphis gossypii",
  "affected_crops": ["Cotton", "Chilli", "Tomato"],
  "description": "Small soft-bodied pear-shaped insects that congregate on the underside of young leaves and shoots, sucking vital sap.",
  "description_te": "చిన్న, గుండ్రని రసం పీల్చే పురుగులు. ఇవి లేత ఆకుల వెనుక చేరి రసం పీల్చుతాయి.",
  "symptoms": "Curling of leaves, stunted shoot growth, sticky honeydew excretions promoting black sooty mold growth.",
  "symptoms_te": "ఆకులు ముడుచుకుపోవడం, తేనెలాంటి జిగట స్రవించడం మరియు నల్లటి బూజు తెగులు సోకడం.",
  "preventive_guidance": "Install yellow sticky traps (10-15 per acre). Spray 5% Neem Seed Kernel Extract (NSKE). In severe infestation, spray Dimethoate 30 EC @ 2ml/L.",
  "preventive_guidance_te": "పసుపు రంగు జిగురు అట్టలు అమర్చండి. వేప గింజల కషాయం 5% లేదా డైమిథోయేట్ 2 మి.లీ/లీటర్ నీటిలో కలిపి పిచికారీ చేయండి."
}
```

---

### 2.3 Object Detection & Image Analysis

#### `POST /api/v1/detect`
Uploads a foliage image, validates format/dimensions, executes the YOLO11s detection pipeline, renders labeled bounding boxes, records history, and returns IPM guidance.

**Content-Type:** `multipart/form-data`

**Form Parameters:**
* `file` (file, required): Image file (`JPEG`, `PNG`, `WEBP`), max 10MB.
* `crop_type` (string, required): One of `Paddy/Rice`, `Cotton`, `Tomato`, `Chilli`.

**Request:**
```bash
curl -X POST "http://localhost:8000/api/v1/detect" \
  -H "Authorization: Bearer <supabase_token>" \
  -F "file=@ml/sample_images/cotton_aphids.jpg" \
  -F "crop_type=Cotton"
```

**Response (`200 OK`):**
```json
{
  "id": "b3e944df-d438-4b71-b089-a29d5b78ca91",
  "crop_type": "Cotton",
  "detection_status": "detected",
  "total_detections": 2,
  "highest_confidence": 0.8950,
  "processing_time_sec": 0.042,
  "model_version": "yolo11s-v1.0",
  "annotated_image_url": "/uploads/annotated/annotated_1d681ed760a1.jpg",
  "created_at": "2026-11-01T07:16:14.391Z",
  "detections": [
    {
      "pest_name": "Aphids",
      "confidence": 0.8950,
      "x_min": 0.352,
      "y_min": 0.410,
      "x_max": 0.485,
      "y_max": 0.540
    },
    {
      "pest_name": "Aphids",
      "confidence": 0.8620,
      "x_min": 0.512,
      "y_min": 0.450,
      "x_max": 0.620,
      "y_max": 0.580
    }
  ],
  "pest_category": {
    "id": "aphids",
    "pest_name": "Aphids",
    "scientific_name": "Aphis gossypii",
    "affected_crops": ["Cotton", "Chilli", "Tomato"],
    "description": "Small soft-bodied pear-shaped insects that congregate on the underside of young leaves.",
    "description_te": "చిన్న, గుండ్రని రసం పీల్చే పురుగులు.",
    "symptoms": "Curling of leaves, stunted shoot growth.",
    "symptoms_te": "ఆకులు ముడుచుకుపోవడం, తేనెలాంటి జిగట స్రవించడం.",
    "preventive_guidance": "Install yellow sticky traps (10-15 per acre). Spray Neem Seed Kernel Extract.",
    "preventive_guidance_te": "పసుపు రంగు జిగురు అట్టలు అమర్చండి. వేప గింజల కషాయం పిచికారీ చేయండి."
  }
}
```

---

### 2.4 Farmer Scan History Management

#### `GET /api/v1/history`
Returns chronological scan history for the authenticated farmer.

**Request:**
```bash
curl -X GET "http://localhost:8000/api/v1/history" \
  -H "Authorization: Bearer <supabase_token>"
```

**Response (`200 OK`):**
```json
{
  "total": 1,
  "items": [
    {
      "id": "b3e944df-d438-4b71-b089-a29d5b78ca91",
      "crop_type": "Cotton",
      "detection_status": "detected",
      "total_detections": 2,
      "highest_confidence": 0.8950,
      "primary_pest_name": "Aphids",
      "annotated_image_url": "/uploads/annotated/annotated_1d681ed760a1.jpg",
      "created_at": "2026-11-01T07:16:14.391Z"
    }
  ]
}
```

#### `GET /api/v1/history/{id}`
Returns complete details of a past scan including individual bounding box coordinates.

**Request:**
```bash
curl -X GET "http://localhost:8000/api/v1/history/b3e944df-d438-4b71-b089-a29d5b78ca91" \
  -H "Authorization: Bearer <supabase_token>"
```

#### `DELETE /api/v1/history/{id}`
Deletes a scan record and its associated annotated image.

**Request:**
```bash
curl -X DELETE "http://localhost:8000/api/v1/history/b3e944df-d438-4b71-b089-a29d5b78ca91" \
  -H "Authorization: Bearer <supabase_token>"
```

**Response (`200 OK`):**
```json
{
  "status": "deleted",
  "id": "b3e944df-d438-4b71-b089-a29d5b78ca91"
}
```

---

## 3. Error Codes & Handling

| HTTP Code | Error Reason | Example Cause | Client Remediation |
|---|---|---|---|
| `400 Bad Request` | Corrupt or empty image payload | File uploaded is 0 bytes or damaged | Recapture image with camera |
| `404 Not Found` | Pest or scan record missing | Pest ID does not exist in taxonomy | Verify pest common name |
| `413 Payload Too Large`| Image exceeds 10MB limit | Raw uncompressed high-resolution photo | Compress image before upload |
| `415 Unsupported Media`| Non-image file type | Uploaded `.pdf`, `.exe`, or `.txt` | Select `.jpg`, `.png`, or `.webp` |
| `500 Server Error` | Model or GPU pipeline failure | Internal memory fault | Retry or report server logs |

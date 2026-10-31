import logging
from typing import Optional
from fastapi import APIRouter, UploadFile, File, Form, Header, HTTPException, status
from app.schemas.detection import DetectionResponse, DetectionBoxSchema
from app.services.storage_service import storage_service
from app.services.auth_service import auth_service
from app.services.pest_service import pest_service
from app.services.history_service import history_service
from app.inference.detector import detector

logger = logging.getLogger("cropguard.api.detect")
router = APIRouter()


@router.post("", response_model=DetectionResponse, summary="Detect agricultural pests in uploaded image")
async def detect_pest(
    file: UploadFile = File(..., description="Uploaded crop leaf or pest image file (JPG, PNG, WEBP)"),
    crop_type: str = Form("Paddy/Rice", description="Target crop: Paddy/Rice, Cotton, Tomato, Chilli"),
    authorization: Optional[str] = Header(None, description="Optional Supabase Auth Bearer token"),
):
    """Core Pest Detection Endpoint:
    1. Validates file format, MIME type, and size limit (<= 10MB).
    2. Preprocesses image and handles orientation.
    3. Executes YOLO object detection.
    4. Computes bounding boxes, confidence values, and class identifications.
    5. Generates annotated image with detection bounding boxes.
    6. Attaches bilingual agricultural advisory and preventive guidance.
    7. Saves scan record under authenticated user ID if provided.
    """
    # Read file bytes
    try:
        file_bytes = await file.read()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Could not read uploaded file: {str(e)}"
        )

    # 1. Validation
    storage_service.validate_image_file(file, file_bytes)

    # 2. Preprocess image
    image = storage_service.preprocess_image(file_bytes)
    original_id, original_path = storage_service.save_local_image(image, prefix="orig")

    # 3. Model Inference
    raw_detections, latency, model_version = detector.detect(image, crop_type=crop_type)

    total_detections = len(raw_detections)
    detection_status = "detected" if total_detections > 0 else "no_pest_detected"
    highest_confidence = max([d["confidence"] for d in raw_detections], default=0.0)

    # 4. Generate annotated visualization
    annotated_id, annotated_path = storage_service.create_annotated_image(image, raw_detections)

    # 5. Fetch Pest Advisory for primary detected pest
    primary_pest = None
    if total_detections > 0:
        primary_pest_name = raw_detections[0]["pest_name"]
        primary_pest = pest_service.find_pest_by_name(primary_pest_name)
    else:
        primary_pest_name = None

    # 6. User Authentication check
    user_id = auth_service.get_current_user_id(authorization)

    # 7. Save Scan Record to History
    prediction_id = history_service.save_prediction(
        user_id=user_id,
        crop_type=crop_type,
        detection_status=detection_status,
        total_detections=total_detections,
        highest_confidence=highest_confidence,
        processing_time_sec=latency,
        model_version=model_version,
        detections=raw_detections,
        image_url=f"/uploads/{original_id}",
        annotated_image_url=f"/uploads/annotated/{annotated_id}",
        primary_pest_name=primary_pest_name,
    )

    box_schemas = [
        DetectionBoxSchema(
            pest_name=d["pest_name"],
            confidence=d["confidence"],
            x_min=d["x_min"],
            y_min=d["y_min"],
            x_max=d["x_max"],
            y_max=d["y_max"],
        )
        for d in raw_detections
    ]

    return DetectionResponse(
        id=prediction_id,
        crop_type=crop_type,
        detection_status=detection_status,
        total_detections=total_detections,
        highest_confidence=highest_confidence,
        processing_time_sec=latency,
        model_version=model_version,
        image_url=f"/uploads/{original_id}",
        annotated_image_url=f"/uploads/annotated/{annotated_id}",
        pest_category=primary_pest,
        detections=box_schemas,
    )

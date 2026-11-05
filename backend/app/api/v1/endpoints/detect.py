import logging
from datetime import datetime, timezone
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
    x_user_id: Optional[str] = Header(None, alias="X-User-Id", description="Optional Supabase User ID"),
):
    """Core Pest Detection Endpoint:
    1. Validates file format, MIME type, and size limit (<= 10MB).
    2. Verifies whether the trained YOLO model is loaded; returns HTTP 503 if not trained.
    3. Preprocesses image and normalizes orientation.
    4. Executes genuine YOLO object detection.
    5. Computes bounding boxes, confidence values, and class identifications.
    6. Generates annotated image with detection bounding boxes if pests found.
    7. Attaches bilingual agricultural advisory and preventive guidance.
    8. Saves scan record under authenticated user ID if provided.
    """
    # Read file bytes
    try:
        file_bytes = await file.read()
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Could not read uploaded file: {str(e)}"
        )

    # 1. Validation (size, extension, MIME, corrupt bytes)
    storage_service.validate_image_file(file, file_bytes)

    # 2. Model Availability Check
    if not detector.is_model_loaded():
        logger.warning("Pest detection requested but YOLO weights are not loaded.")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail={
                "error_code": "MODEL_NOT_TRAINED",
                "message": "The pest detection model has not been trained or configured yet."
            }
        )

    # 3. Preprocess image
    image = storage_service.preprocess_image(file_bytes)
    original_id, original_path = storage_service.save_local_image(image, prefix="orig")

    # 4. Genuine Model Inference
    raw_detections, latency, model_version = detector.detect(image, crop_type=crop_type)

    total_detections = len(raw_detections)
    detection_status = "detected" if total_detections > 0 else "no_pest_detected"
    highest_confidence = max([d["confidence"] for d in raw_detections], default=0.0)

    # 5. Generate annotated visualization if detections found
    if total_detections > 0:
        annotated_id, annotated_path = storage_service.create_annotated_image(image, raw_detections)
        annotated_url = f"/uploads/annotated/{annotated_id}"
    else:
        annotated_url = None

    # 6. Fetch Pest Advisory for primary detected pest
    primary_pest = None
    if total_detections > 0:
        primary_pest_name = raw_detections[0]["pest_name"]
        primary_pest = pest_service.find_pest_by_name(primary_pest_name)
    else:
        primary_pest_name = None

    # 7. User Authentication check
    user_id = auth_service.get_current_user_id(authorization=authorization, x_user_id=x_user_id)

    # 8. Save Scan Record to History
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
        annotated_image_url=annotated_url,
        primary_pest_name=primary_pest_name,
        primary_pest=primary_pest,
    )

    box_schemas = [
        DetectionBoxSchema(
            class_id=d.get("class_id"),
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
        annotated_image_url=annotated_url,
        created_at=datetime.now(timezone.utc),
        detections=box_schemas,
        pest_category=primary_pest,
    )

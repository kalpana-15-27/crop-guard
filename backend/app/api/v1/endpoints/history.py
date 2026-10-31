from typing import Optional
from fastapi import APIRouter, Header, HTTPException, status
from app.schemas.detection import DetectionHistoryList, DetectionResponse, DetectionBoxSchema
from app.services.auth_service import auth_service
from app.services.history_service import history_service
from app.services.pest_service import pest_service

router = APIRouter()


@router.get("", response_model=DetectionHistoryList, summary="List scan history records")
async def get_history(authorization: Optional[str] = Header(None)):
    """Retrieve scan history for the current user. Returns public/session scans if unauthenticated."""
    user_id = auth_service.get_current_user_id(authorization)
    items = history_service.get_user_history(user_id)
    return DetectionHistoryList(total=len(items), items=items)


@router.get("/{prediction_id}", response_model=DetectionResponse, summary="Get details of a past prediction scan")
async def get_prediction_detail(prediction_id: str, authorization: Optional[str] = Header(None)):
    """Fetch complete prediction details, including bounding boxes and pest guidance."""
    user_id = auth_service.get_current_user_id(authorization)
    record = history_service.get_prediction_by_id(prediction_id, user_id)
    if not record:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Scan record '{prediction_id}' not found or access denied."
        )

    primary_pest = None
    if record.get("pest_name"):
        primary_pest = pest_service.find_pest_by_name(record["pest_name"])

    boxes = [
        DetectionBoxSchema(
            pest_name=d["pest_name"],
            confidence=d["confidence"],
            x_min=d["x_min"],
            y_min=d["y_min"],
            x_max=d["x_max"],
            y_max=d["y_max"],
        )
        for d in record.get("detections", [])
    ]

    return DetectionResponse(
        id=record["id"],
        crop_type=record["crop_type"],
        detection_status=record["detection_status"],
        total_detections=record["total_detections"],
        highest_confidence=record["highest_confidence"],
        processing_time_sec=record.get("processing_time_sec", 0.0),
        model_version=record["model_version"],
        image_url=record.get("image_url"),
        annotated_image_url=record.get("annotated_image_url"),
        pest_category=primary_pest,
        detections=boxes,
        created_at=record["created_at"],
    )


@router.delete("/{prediction_id}", summary="Delete a scan record")
async def delete_prediction(prediction_id: str, authorization: Optional[str] = Header(None)):
    """Delete a scan record from the history."""
    user_id = auth_service.get_current_user_id(authorization)
    deleted = history_service.delete_prediction(prediction_id, user_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Scan record '{prediction_id}' could not be deleted or does not exist."
        )
    return {"message": "Scan record deleted successfully", "id": prediction_id}

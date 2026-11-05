from typing import List, Optional
from datetime import datetime, timezone
from pydantic import BaseModel, Field
from app.schemas.pest import PestCategoryResponse


class DetectionBoxSchema(BaseModel):
    class_id: Optional[int] = Field(None, description="Canonical pest class ID (0..5)")
    pest_name: str = Field(..., description="Detected insect class label")
    confidence: float = Field(..., ge=0.0, le=1.0, description="Detection confidence score")
    x_min: float = Field(..., description="Normalized top-left bounding box X")
    y_min: float = Field(..., description="Normalized top-left bounding box Y")
    x_max: float = Field(..., description="Normalized bottom-right bounding box X")
    y_max: float = Field(..., description="Normalized bottom-right bounding box Y")


class DetectionResponse(BaseModel):
    id: str = Field(..., description="Unique prediction scan ID")
    crop_type: str = Field(..., description="Crop specified during scan")
    detection_status: str = Field(..., description="'detected', 'no_pest_detected', or 'failed'")
    total_detections: int = Field(..., description="Number of detected insect objects")
    highest_confidence: float = Field(..., description="Highest confidence among detections")
    processing_time_sec: float = Field(..., description="Inference and preprocessing latency in seconds")
    model_version: str = Field(..., description="YOLO model architecture and version tag")
    image_url: Optional[str] = Field(None, description="URL or reference to original photo")
    annotated_image_url: Optional[str] = Field(None, description="URL or reference to bounding-box annotated photo")
    pest_category: Optional[PestCategoryResponse] = Field(None, description="Detailed guidance for primary detected pest")
    detections: List[DetectionBoxSchema] = Field(default_factory=list, description="List of all detected bounding boxes")
    created_at: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))


class DetectionHistoryItem(BaseModel):
    id: str
    uploaded_image_id: Optional[str] = None
    crop_type: str
    detection_status: str
    total_detections: int
    highest_confidence: float
    processing_time_sec: Optional[float] = 0.0
    model_version: Optional[str] = "yolo11s-v1.0"
    image_url: Optional[str] = None
    annotated_image_url: Optional[str] = None
    pest_name: Optional[str] = None
    pest_category: Optional[PestCategoryResponse] = None
    detections: List[DetectionBoxSchema] = Field(default_factory=list)
    created_at: datetime


class DetectionHistoryList(BaseModel):
    total: int
    items: List[DetectionHistoryItem]

import io
import os
import uuid
import logging
from typing import Tuple, List, Optional
from fastapi import UploadFile, HTTPException, status
from PIL import Image, ImageDraw, ImageFont, ImageOps
from app.core.config import settings

logger = logging.getLogger("cropguard.storage")

# Maximum permitted file size: 10MB
MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024

# Allowed MIME types and extensions
ALLOWED_EXTENSIONS = {".jpg", ".jpeg", ".png", ".webp"}
ALLOWED_MIME_TYPES = {"image/jpeg", "image/png", "image/webp"}

# Local fallback storage directories
LOCAL_UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "uploads")
LOCAL_ANNOTATED_DIR = os.path.join(LOCAL_UPLOAD_DIR, "annotated")
os.makedirs(LOCAL_UPLOAD_DIR, exist_ok=True)
os.makedirs(LOCAL_ANNOTATED_DIR, exist_ok=True)


class StorageService:
    """Handles image validation, file size checks, preprocessing, and bounding-box annotation."""

    @staticmethod
    def validate_image_file(file: UploadFile, file_bytes: bytes) -> str:
        """Validates file extension, MIME type, payload size, and image integrity."""
        # Check size
        if len(file_bytes) > MAX_FILE_SIZE_BYTES:
            raise HTTPException(
                status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
                detail=f"Uploaded image exceeds maximum size limit of {MAX_FILE_SIZE_BYTES // (1024 * 1024)}MB."
            )

        if len(file_bytes) == 0:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Empty image file received."
            )

        # Check extension
        filename = file.filename or "upload.jpg"
        ext = os.path.splitext(filename)[1].lower()
        if ext not in ALLOWED_EXTENSIONS:
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail=f"Unsupported file format '{ext}'. Allowed formats: JPG, JPEG, PNG, WEBP."
            )

        # Check MIME type
        content_type = file.content_type or "application/octet-stream"
        if content_type not in ALLOWED_MIME_TYPES and content_type != "application/octet-stream":
            raise HTTPException(
                status_code=status.HTTP_415_UNSUPPORTED_MEDIA_TYPE,
                detail=f"Unsupported MIME type '{content_type}'."
            )

        # Verify Pillow can open and decode the image
        try:
            image = Image.open(io.BytesIO(file_bytes))
            image.verify()
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Corrupted or invalid image data: {str(e)}"
            )

        return ext

    @staticmethod
    def preprocess_image(file_bytes: bytes) -> Image.Image:
        """Opens image, handles EXIF orientation, and converts to standard RGB."""
        image = Image.open(io.BytesIO(file_bytes))
        try:
            image = ImageOps.exif_transpose(image)
        except Exception:
            pass
        return image.convert("RGB")

    @staticmethod
    def save_local_image(image: Image.Image, prefix: str = "img") -> Tuple[str, str]:
        """Saves image to local storage directory. Returns (file_id, absolute_path)."""
        file_id = f"{prefix}_{uuid.uuid4().hex[:12]}.jpg"
        file_path = os.path.join(LOCAL_UPLOAD_DIR, file_id)
        image.save(file_path, format="JPEG", quality=90)
        return file_id, file_path

    @staticmethod
    def create_annotated_image(
        original_image: Image.Image,
        detections: List[dict],
        prefix: str = "annotated"
    ) -> Tuple[str, str]:
        """Draws bounding boxes, labels, and confidence tags on image copy."""
        annotated = original_image.copy()
        draw = ImageDraw.Draw(annotated)
        width, height = annotated.size

        for det in detections:
            # Normalized coordinates (0.0 to 1.0)
            x_min = int(det["x_min"] * width)
            y_min = int(det["y_min"] * height)
            x_max = int(det["x_max"] * width)
            y_max = int(det["y_max"] * height)
            conf_pct = int(det.get("confidence", 0.0) * 100)
            label = f"{det.get('pest_name', 'Pest')} {conf_pct}%"

            # Draw outer rectangle
            box_color = (201, 76, 76)  # AppTheme errorRed
            for outline_thickness in range(3):
                draw.rectangle(
                    [x_min - outline_thickness, y_min - outline_thickness, x_max + outline_thickness, y_max + outline_thickness],
                    outline=box_color
                )

            # Draw label banner
            text_size = 14
            banner_height = text_size + 6
            banner_width = len(label) * 8 + 12
            draw.rectangle(
                [x_min, max(0, y_min - banner_height), x_min + banner_width, y_min],
                fill=box_color
            )
            draw.text(
                (x_min + 4, max(0, y_min - banner_height) + 2),
                label,
                fill=(255, 255, 255)
            )

        file_id = f"{prefix}_{uuid.uuid4().hex[:12]}.jpg"
        file_path = os.path.join(LOCAL_ANNOTATED_DIR, file_id)
        annotated.save(file_path, format="JPEG", quality=90)
        return file_id, file_path


storage_service = StorageService()

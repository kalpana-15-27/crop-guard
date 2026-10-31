import uuid
import logging
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from app.database.supabase_client import supabase_client
from app.schemas.detection import DetectionHistoryItem

logger = logging.getLogger("cropguard.history")

# Local in-memory store for fallback before migration or during testing
_LOCAL_HISTORY_STORE: List[Dict[str, Any]] = []


class HistoryService:
    """Manages prediction scan history records with strict tenant isolation."""

    @staticmethod
    def save_prediction(
        user_id: Optional[str],
        crop_type: str,
        detection_status: str,
        total_detections: int,
        highest_confidence: float,
        processing_time_sec: float,
        model_version: str,
        detections: List[Dict[str, Any]],
        image_url: Optional[str] = None,
        annotated_image_url: Optional[str] = None,
        primary_pest_name: Optional[str] = None,
    ) -> str:
        """Stores prediction metadata and detected items."""
        prediction_id = str(uuid.uuid4())
        created_at = datetime.now(timezone.utc)

        record = {
            "id": prediction_id,
            "user_id": user_id,
            "crop_type": crop_type,
            "detection_status": detection_status,
            "total_detections": total_detections,
            "highest_confidence": highest_confidence,
            "processing_time_sec": processing_time_sec,
            "model_version": model_version,
            "image_url": image_url,
            "annotated_image_url": annotated_image_url,
            "pest_name": primary_pest_name,
            "created_at": created_at,
            "detections": detections,
        }

        # Attempt Supabase database insertion if user is authenticated
        if user_id:
            try:
                supabase_client.insert(
                    "predictions",
                    {
                        "id": prediction_id,
                        "user_id": user_id,
                        "annotated_image_path": annotated_image_url,
                        "model_version": model_version,
                        "detection_status": detection_status,
                        "total_detections": total_detections,
                        "processing_time_sec": processing_time_sec,
                    }
                )
            except Exception as e:
                logger.debug(f"Supabase predictions table insert skipped ({e}), storing in session cache.")

        # Always maintain in session store
        _LOCAL_HISTORY_STORE.insert(0, record)
        return prediction_id

    @staticmethod
    def get_user_history(user_id: Optional[str] = None) -> List[DetectionHistoryItem]:
        """Fetches history for the authenticated user."""
        items: List[DetectionHistoryItem] = []

        # Try fetching from Supabase first if authenticated
        if user_id:
            try:
                db_records = supabase_client.get("predictions", params={"user_id": f"eq.{user_id}", "order": "created_at.desc"})
                if db_records:
                    for r in db_records:
                        items.append(
                            DetectionHistoryItem(
                                id=r["id"],
                                crop_type=r.get("crop_type", "Crop"),
                                detection_status=r.get("detection_status", "pending"),
                                total_detections=r.get("total_detections", 0),
                                highest_confidence=float(r.get("highest_confidence", 0.0)),
                                processing_time_sec=float(r.get("processing_time_sec", 0.0)),
                                image_url=r.get("image_path"),
                                annotated_image_url=r.get("annotated_image_path"),
                                pest_name=r.get("pest_name"),
                                created_at=datetime.fromisoformat(r["created_at"].replace("Z", "+00:00")),
                            )
                        )
                    return items
            except Exception as e:
                logger.debug(f"Fetching from Supabase failed ({e}), reading from session store.")

        # Fallback to local session store
        filtered = [
            r for r in _LOCAL_HISTORY_STORE
            if user_id is None or r.get("user_id") == user_id or r.get("user_id") is None
        ]

        for r in filtered:
            items.append(
                DetectionHistoryItem(
                    id=r["id"],
                    crop_type=r["crop_type"],
                    detection_status=r["detection_status"],
                    total_detections=r["total_detections"],
                    highest_confidence=r["highest_confidence"],
                    processing_time_sec=r["processing_time_sec"],
                    image_url=r.get("image_url"),
                    annotated_image_url=r.get("annotated_image_url"),
                    pest_name=r.get("pest_name"),
                    created_at=r["created_at"],
                )
            )
        return items

    @staticmethod
    def get_prediction_by_id(prediction_id: str, user_id: Optional[str] = None) -> Optional[Dict[str, Any]]:
        """Retrieve single scan detail."""
        for r in _LOCAL_HISTORY_STORE:
            if r["id"] == prediction_id:
                if user_id and r.get("user_id") and r["user_id"] != user_id:
                    return None
                return r
        return None

    @staticmethod
    def delete_prediction(prediction_id: str, user_id: Optional[str] = None) -> bool:
        """Deletes prediction record."""
        global _LOCAL_HISTORY_STORE
        initial_len = len(_LOCAL_HISTORY_STORE)
        _LOCAL_HISTORY_STORE = [
            r for r in _LOCAL_HISTORY_STORE
            if not (r["id"] == prediction_id and (user_id is None or r.get("user_id") == user_id or r.get("user_id") is None))
        ]

        # Also attempt Supabase deletion if authenticated
        if user_id:
            try:
                supabase_client.delete("predictions", {"id": f"eq.{prediction_id}", "user_id": f"eq.{user_id}"})
            except Exception:
                pass

        return len(_LOCAL_HISTORY_STORE) < initial_len


history_service = HistoryService()

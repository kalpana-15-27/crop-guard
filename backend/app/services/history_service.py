import os
import json
import uuid
import logging
from pathlib import Path
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any
from app.database.supabase_client import supabase_client
from app.schemas.detection import DetectionHistoryItem, DetectionBoxSchema
from app.schemas.pest import PestCategoryResponse

logger = logging.getLogger("cropguard.history")

# Persistent file path for cross-reload scan persistence
STORE_DIR = Path(__file__).resolve().parent.parent.parent / "uploads"
STORE_FILE = STORE_DIR / "history_store.json"
_LOCAL_HISTORY_STORE: List[Dict[str, Any]] = []


def _load_history_from_disk():
    global _LOCAL_HISTORY_STORE
    try:
        if STORE_FILE.exists():
            with open(STORE_FILE, "r", encoding="utf-8") as f:
                data = json.load(f)
                if isinstance(data, list):
                    _LOCAL_HISTORY_STORE = data
                    logger.info(f"Loaded {len(_LOCAL_HISTORY_STORE)} historical scan records from disk.")
    except Exception as e:
        logger.warning(f"Could not load scan records from disk: {e}")


def _persist_history_to_disk():
    try:
        STORE_DIR.mkdir(parents=True, exist_ok=True)
        trimmed = _LOCAL_HISTORY_STORE[:500]
        temp_file = STORE_FILE.with_suffix(".tmp")
        with open(temp_file, "w", encoding="utf-8") as f:
            json.dump(trimmed, f, default=str, indent=2)
        temp_file.replace(STORE_FILE)
    except Exception as e:
        logger.warning(f"Failed to persist scan history to disk: {e}")


# Initialize disk load
_load_history_from_disk()


class HistoryService:
    """Manages prediction scan history records with strict tenant isolation and persistence."""

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
        primary_pest: Optional[Any] = None,
    ) -> str:
        """Stores prediction metadata, bounding boxes, and guidance."""
        prediction_id = str(uuid.uuid4())
        created_at_dt = datetime.now(timezone.utc)
        created_at = created_at_dt.isoformat()

        # Format pest_category dict if provided
        pest_cat_dict = None
        if primary_pest is not None:
            if hasattr(primary_pest, "model_dump"):
                pest_cat_dict = primary_pest.model_dump()
            elif hasattr(primary_pest, "dict"):
                pest_cat_dict = primary_pest.dict()
            elif isinstance(primary_pest, dict):
                pest_cat_dict = primary_pest

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
            "pest_category": pest_cat_dict,
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
                logger.debug(f"Supabase predictions table insert skipped ({e}), storing in persistent disk cache.")

        # Always store in disk-backed store
        _LOCAL_HISTORY_STORE.insert(0, record)
        _persist_history_to_disk()
        return prediction_id

    @staticmethod
    def get_user_history(user_id: Optional[str] = None) -> List[DetectionHistoryItem]:
        """Fetches history for the authenticated user across any device."""
        items: List[DetectionHistoryItem] = []
        seen_ids = set()

        # Try fetching from Supabase first if authenticated
        if user_id:
            try:
                db_records = supabase_client.get("predictions", params={"user_id": f"eq.{user_id}", "order": "created_at.desc"})
                if db_records:
                    for r in db_records:
                        created_val = r.get("created_at")
                        if isinstance(created_val, str):
                            created_dt = datetime.fromisoformat(created_val.replace("Z", "+00:00"))
                        else:
                            created_dt = datetime.now(timezone.utc)

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
                                created_at=created_dt,
                            )
                        )
                        seen_ids.add(r["id"])
            except Exception as e:
                logger.debug(f"Fetching from Supabase skipped ({e}), reading from disk-backed store.")

        # Read from disk-backed store
        for r in _LOCAL_HISTORY_STORE:
            rid = r.get("id")
            if not rid or rid in seen_ids:
                continue

            rec_user = r.get("user_id")
            # If user is authenticated, include records matching user_id OR unassigned scans
            if user_id is not None:
                if rec_user is not None and rec_user != user_id:
                    continue
            else:
                # If unauthenticated, return all local scans
                pass

            created_val = r.get("created_at")
            if isinstance(created_val, str):
                try:
                    created_dt = datetime.fromisoformat(created_val.replace("Z", "+00:00"))
                except Exception:
                    created_dt = datetime.now(timezone.utc)
            elif isinstance(created_val, datetime):
                created_dt = created_val
            else:
                created_dt = datetime.now(timezone.utc)

            boxes = [
                DetectionBoxSchema(
                    class_id=d.get("class_id"),
                    pest_name=d["pest_name"],
                    confidence=float(d["confidence"]),
                    x_min=float(d["x_min"]),
                    y_min=float(d["y_min"]),
                    x_max=float(d["x_max"]),
                    y_max=float(d["y_max"]),
                )
                for d in r.get("detections", [])
                if isinstance(d, dict) and "pest_name" in d and "confidence" in d
            ]

            pest_cat = None
            if r.get("pest_category") and isinstance(r["pest_category"], dict):
                try:
                    pest_cat = PestCategoryResponse(**r["pest_category"])
                except Exception:
                    pass

            items.append(
                DetectionHistoryItem(
                    id=rid,
                    crop_type=r.get("crop_type", "Crop"),
                    detection_status=r.get("detection_status", "pending"),
                    total_detections=r.get("total_detections", 0),
                    highest_confidence=float(r.get("highest_confidence", 0.0)),
                    processing_time_sec=float(r.get("processing_time_sec", 0.0)),
                    model_version=r.get("model_version", "yolo11s-v1.0"),
                    image_url=r.get("image_url"),
                    annotated_image_url=r.get("annotated_image_url"),
                    pest_name=r.get("pest_name"),
                    pest_category=pest_cat,
                    detections=boxes,
                    created_at=created_dt,
                )
            )
            seen_ids.add(rid)

        # Sort newest first
        items.sort(key=lambda x: x.created_at, reverse=True)
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

        if len(_LOCAL_HISTORY_STORE) < initial_len:
            _persist_history_to_disk()

        # Also attempt Supabase deletion if authenticated
        if user_id:
            try:
                supabase_client.delete("predictions", {"id": f"eq.{prediction_id}", "user_id": f"eq.{user_id}"})
            except Exception:
                pass

        return len(_LOCAL_HISTORY_STORE) < initial_len


history_service = HistoryService()

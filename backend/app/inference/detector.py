import os
import time
import logging
from typing import List, Dict, Any, Tuple
from PIL import Image
from app.core.config import settings

logger = logging.getLogger("cropguard.detector")


class YOLOPestDetector:
    """YOLO Object Detection Pipeline for Agricultural Pest Identification."""

    def __init__(self, model_path: str = settings.MODEL_PATH):
        self.model_path = model_path
        self.confidence_threshold = settings.CONFIDENCE_THRESHOLD
        self.iou_threshold = settings.IOU_THRESHOLD
        self.model = None
        self.model_version = "yolo11s-v1.0"
        self._load_model()

    def _load_model(self):
        """Attempts to load PyTorch/Ultralytics YOLO weights if present on disk."""
        if os.path.exists(self.model_path):
            try:
                from ultralytics import YOLO
                self.model = YOLO(self.model_path)
                logger.info(f"Loaded YOLO weights successfully from {self.model_path}")
            except Exception as e:
                logger.error(f"Could not initialize Ultralytics YOLO runtime from '{self.model_path}': {e}")
                self.model = None
        else:
            logger.warning(
                f"YOLO weights at '{self.model_path}' not found. "
                "Pest detection model is not trained yet."
            )
            self.model = None

    def is_model_loaded(self) -> bool:
        """Returns True only if actual YOLO weights are present and successfully initialized."""
        return self.model is not None

    def reload_model(self):
        """Reloads model from disk (e.g. after training completes)."""
        self._load_model()

    def detect(self, image: Image.Image, crop_type: str = "Paddy/Rice") -> Tuple[List[Dict[str, Any]], float, str]:
        """Runs genuine YOLO pest object detection on a PIL Image.
        
        Raises RuntimeError if model weights are not loaded.
        Returns:
            Tuple of (detections_list, latency_seconds, model_version_string)
        """
        if self.model is None:
            raise RuntimeError(
                f"Model weights '{self.model_path}' are not available. "
                "Cannot perform inference without a trained YOLO model."
            )

        start_time = time.time()
        detections: List[Dict[str, Any]] = []

        try:
            # Genuine YOLO11s inference
            results = self.model.predict(
                source=image,
                conf=self.confidence_threshold,
                iou=self.iou_threshold,
                verbose=False
            )
            for r in results:
                boxes = r.boxes
                for box in boxes:
                    cls_id = int(box.cls[0].item())
                    cls_name = r.names.get(cls_id, "Unknown Pest")
                    conf = float(box.conf[0].item())
                    # Normalized xyxy coordinates [0.0, 1.0]
                    xyxyn_item = box.xyxyn[0]
                    xyxy_norm = xyxyn_item.tolist() if hasattr(xyxyn_item, "tolist") else list(xyxyn_item)
                    detections.append({
                        "pest_name": cls_name,
                        "confidence": round(conf, 4),
                        "x_min": round(xyxy_norm[0], 4),
                        "y_min": round(xyxy_norm[1], 4),
                        "x_max": round(xyxy_norm[2], 4),
                        "y_max": round(xyxy_norm[3], 4),
                    })
        except Exception as e:
            logger.error(f"Inference error with loaded YOLO model: {e}")
            raise e

        latency = round(time.time() - start_time, 3)
        return detections, latency, self.model_version


detector = YOLOPestDetector()

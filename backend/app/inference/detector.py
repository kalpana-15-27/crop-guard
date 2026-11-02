import os
import time
import logging
from typing import List, Dict, Any, Tuple, Optional, Set
from PIL import Image
from app.core.config import settings

logger = logging.getLogger("cropguard.detector")

# Reverse Class Mapping from trained 5-class YOLO11s model to Application Canonical 6-class Schema:
# Canonical IDs:
#   0: Aphids
#   1: Whitefly
#   2: Brown Planthopper
#   3: Yellow Stem Borer (NOT in trained model; strictly unsupported)
#   4: Thrips
#   5: Helicoverpa armigera
#
# Trained YOLO11s Classes:
#   0: Aphids -> Canonical 0
#   1: Whitefly -> Canonical 1
#   2: Brown Planthopper -> Canonical 2
#   3: Thrips -> Canonical 4 (CRITICAL: NEVER map to Yellow Stem Borer)
#   4: Helicoverpa armigera -> Canonical 5
YOLO_TO_CANONICAL_MAPPING: Dict[int, Dict[str, Any]] = {
    0: {
        "canonical_id": 0,
        "pest_name": "Aphids",
        "scientific_name": "Aphis gossypii",
    },
    1: {
        "canonical_id": 1,
        "pest_name": "Whitefly",
        "scientific_name": "Bemisia tabaci",
    },
    2: {
        "canonical_id": 2,
        "pest_name": "Brown Planthopper",
        "scientific_name": "Nilaparvata lugens",
    },
    3: {
        "canonical_id": 4,
        "pest_name": "Thrips",
        "scientific_name": "Scirtothrips dorsalis",
    },
    4: {
        "canonical_id": 5,
        "pest_name": "Helicoverpa armigera",
        "scientific_name": "Helicoverpa armigera",
    },
}

# Lookup by normalized lowercase name for resilient fallback matching
NAME_TO_CANONICAL_MAPPING: Dict[str, Dict[str, Any]] = {
    "aphids": YOLO_TO_CANONICAL_MAPPING[0],
    "aphid": YOLO_TO_CANONICAL_MAPPING[0],
    "whitefly": YOLO_TO_CANONICAL_MAPPING[1],
    "whiteflies": YOLO_TO_CANONICAL_MAPPING[1],
    "brown planthopper": YOLO_TO_CANONICAL_MAPPING[2],
    "brown-planthopper": YOLO_TO_CANONICAL_MAPPING[2],
    "bph": YOLO_TO_CANONICAL_MAPPING[2],
    "thrips": YOLO_TO_CANONICAL_MAPPING[3],
    "thrip": YOLO_TO_CANONICAL_MAPPING[3],
    "helicoverpa armigera": YOLO_TO_CANONICAL_MAPPING[4],
    "helicoverpa": YOLO_TO_CANONICAL_MAPPING[4],
    "american bollworm": YOLO_TO_CANONICAL_MAPPING[4],
    "fruit borer": YOLO_TO_CANONICAL_MAPPING[4],
}


class YOLOPestDetector:
    """YOLO Object Detection Pipeline for Agricultural Pest Identification."""

    def __init__(self, model_path: Optional[str] = None):
        self.model_path = model_path or settings.MODEL_PATH
        self.confidence_threshold = settings.CONFIDENCE_THRESHOLD
        self.iou_threshold = settings.IOU_THRESHOLD
        self.imgsz = getattr(settings, "YOLO_IMGSZ", 640)
        self.model = None
        self.model_version = "yolo11s-v1.0"
        self.device = "cpu"
        self._load_model()

    def _load_model(self):
        """Attempts to load PyTorch/Ultralytics YOLO weights if present on disk."""
        if not os.path.exists(self.model_path):
            if hasattr(settings, "_resolve_model_path"):
                resolved = settings._resolve_model_path(self.model_path)
                if os.path.exists(resolved):
                    self.model_path = resolved

        if os.path.exists(self.model_path):
            try:
                import torch
                if not torch.cuda.is_available():
                    # Free tier cloud containers (Render) allocate 0.1 vCPU.
                    # Single-threading prevents excessive thread switching overhead.
                    torch.set_num_threads(1)
                self.device = "cuda:0" if torch.cuda.is_available() else "cpu"
            except Exception:
                self.device = "cpu"

            try:
                from ultralytics import YOLO
                self.model = YOLO(self.model_path)
                logger.info(
                    f"Loaded YOLO weights successfully from '{self.model_path}' on device '{self.device}'. "
                    f"Model classes: {getattr(self.model, 'names', {})}"
                )
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
            # Genuine YOLO11s inference with kwargs
            predict_kwargs = {
                "source": image,
                "conf": self.confidence_threshold,
                "iou": self.iou_threshold,
                "verbose": False,
            }
            if hasattr(self, "imgsz") and self.imgsz:
                predict_kwargs["imgsz"] = self.imgsz
            if hasattr(self, "device") and self.device:
                predict_kwargs["device"] = self.device

            try:
                results = self.model.predict(**predict_kwargs)
            except TypeError:
                results = self.model.predict(
                    source=image,
                    conf=self.confidence_threshold,
                    iou=self.iou_threshold,
                    verbose=False
                )

            for r in results:
                boxes = getattr(r, "boxes", None)
                if boxes is None:
                    continue
                for box in boxes:
                    cls_id = int(box.cls[0].item() if hasattr(box.cls[0], "item") else box.cls[0])
                    conf = float(box.conf[0].item() if hasattr(box.conf[0], "item") else box.conf[0])

                    # Reverse mapping to canonical schema
                    mapping = YOLO_TO_CANONICAL_MAPPING.get(cls_id)
                    if mapping is None:
                        # Fallback to model's name dict if cls_id is re-indexed
                        model_names = getattr(r, "names", {}) or getattr(self.model, "names", {})
                        raw_name = str(model_names.get(cls_id, "")).strip().lower()
                        mapping = NAME_TO_CANONICAL_MAPPING.get(raw_name)

                    if mapping is None:
                        # Safely drop unexpected / unsupported class; never invent a false pest identity
                        logger.warning(
                            f"Detected YOLO class {cls_id} has no valid canonical pest mapping. Skipping detection."
                        )
                        continue

                    # Normalized xyxy coordinates [0.0, 1.0]
                    xyxyn_item = box.xyxyn[0]
                    xyxy_raw = xyxyn_item.tolist() if hasattr(xyxyn_item, "tolist") else list(xyxyn_item)

                    # Clamp to [0.0, 1.0]
                    x_min = max(0.0, min(1.0, float(xyxy_raw[0])))
                    y_min = max(0.0, min(1.0, float(xyxy_raw[1])))
                    x_max = max(0.0, min(1.0, float(xyxy_raw[2])))
                    y_max = max(0.0, min(1.0, float(xyxy_raw[3])))

                    detections.append({
                        "class_id": mapping["canonical_id"],
                        "pest_name": mapping["pest_name"],
                        "scientific_name": mapping["scientific_name"],
                        "confidence": round(conf, 4),
                        "x_min": round(x_min, 4),
                        "y_min": round(y_min, 4),
                        "x_max": round(x_max, 4),
                        "y_max": round(y_max, 4),
                    })
        except Exception as e:
            logger.error(f"Inference error with loaded YOLO model: {e}")
            raise e

        # Sort detections descending by confidence score
        detections.sort(key=lambda d: d["confidence"], reverse=True)

        latency = round(time.time() - start_time, 3)
        return detections, latency, self.model_version


detector = YOLOPestDetector()

"""CropGuard AI: Dataset Preparation Module Shim
Re-exports functionality from ml/dataset_prep.py for backward compatibility.
"""
import os
from typing import Tuple, List, Dict, Any
from ml.dataset_prep import (
    UNIFIED_CLASSES,
    CLASS_NAME_TO_ID,
    MissingClassError,
    DatasetPreparer,
    build_source_class_mapping,
    compute_file_sha256,
    extract_parent_group_id,
    verify_image,
    parse_and_remap_annotation,
    write_dataset_yaml
)

TARGET_CLASSES = UNIFIED_CLASSES


def verify_image_file(image_path: str) -> bool:
    """Convenience wrapper returning boolean validity of image file."""
    valid, _, _ = verify_image(image_path)
    return valid


def validate_yolo_annotation(label_file: str) -> Tuple[bool, List[Dict[str, Any]]]:
    """Validates YOLO annotation file lines: <class_id> <x_center> <y_center> <width> <height>."""
    if not os.path.exists(label_file):
        return False, []

    boxes = []
    with open(label_file, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split()
            if len(parts) != 5:
                return False, []
            try:
                cls_id = int(parts[0])
                xc, yc, w, h = map(float, parts[1:])
            except ValueError:
                return False, []

            if cls_id not in UNIFIED_CLASSES:
                return False, []
            if not (0.0 <= xc <= 1.0 and 0.0 <= yc <= 1.0 and 0.0 < w <= 1.0 and 0.0 < h <= 1.0):
                return False, []

            boxes.append({
                "class_id": cls_id,
                "class_name": UNIFIED_CLASSES[cls_id],
                "x_center": xc,
                "y_center": yc,
                "width": w,
                "height": h
            })
    return True, boxes


__all__ = [
    "UNIFIED_CLASSES",
    "TARGET_CLASSES",
    "CLASS_NAME_TO_ID",
    "MissingClassError",
    "DatasetPreparer",
    "build_source_class_mapping",
    "compute_file_sha256",
    "extract_parent_group_id",
    "verify_image",
    "verify_image_file",
    "validate_yolo_annotation",
    "parse_and_remap_annotation",
    "write_dataset_yaml"
]

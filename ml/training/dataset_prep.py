"""CropGuard AI: Dataset Preparation, Verification & Splitting Pipeline

Validates open-source bounding-box pest annotations, filters corrupted images,
and partitions data into 70% Train, 20% Val, 10% Test for YOLO11s.
"""

import os
import shutil
import random
import logging
from typing import Dict, List, Tuple
from PIL import Image

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("CropGuard.DatasetPrep")

# Target Pest Categories
TARGET_CLASSES = {
    0: "Aphids",
    1: "Whitefly",
    2: "Brown Planthopper",
    3: "Yellow Stem Borer",
    4: "Thrips",
    5: "Helicoverpa armigera"
}


def validate_yolo_annotation(label_file_path: str, num_classes: int = 6) -> Tuple[bool, List[Dict]]:
    """Validates YOLO normalized bounding box coordinates:
    Format: <class_id> <x_center> <y_center> <width> <height>
    Coordinates must be float numbers in range [0.0, 1.0].
    """
    valid_boxes = []
    if not os.path.exists(label_file_path):
        return False, []

    with open(label_file_path, "r", encoding="utf-8") as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            parts = line.split()
            if len(parts) != 5:
                logger.warning(f"{label_file_path}:{line_num} Invalid parts count ({len(parts)} != 5)")
                return False, []

            try:
                class_id = int(parts[0])
                xc, yc, w, h = map(float, parts[1:])
            except ValueError:
                logger.warning(f"{label_file_path}:{line_num} Non-numeric values found")
                return False, []

            if not (0 <= class_id < num_classes):
                logger.warning(f"{label_file_path}:{line_num} Class ID {class_id} outside [0, {num_classes-1}]")
                return False, []

            # Check normalized bounds
            if not all(0.0 <= val <= 1.0 for val in [xc, yc, w, h]):
                logger.warning(f"{label_file_path}:{line_num} Coordinates not normalized: {[xc, yc, w, h]}")
                return False, []

            valid_boxes.append({
                "class_id": class_id,
                "class_name": TARGET_CLASSES.get(class_id, "Unknown"),
                "bbox": [xc, yc, w, h]
            })

    return len(valid_boxes) > 0, valid_boxes


def verify_image_file(image_path: str) -> bool:
    """Verifies that an image exists, has non-zero size, and can be decoded by Pillow."""
    if not os.path.exists(image_path) or os.path.getsize(image_path) == 0:
        return False
    try:
        with Image.open(image_path) as img:
            img.verify()
        return True
    except Exception:
        return False


def partition_dataset(
    source_images_dir: str,
    source_labels_dir: str,
    output_dir: str,
    train_ratio: float = 0.70,
    val_ratio: float = 0.20,
    test_ratio: float = 0.10,
    seed: int = 42
):
    """Splits dataset into Train/Val/Test subsets preserving paired images and labels."""
    random.seed(seed)
    assert abs((train_ratio + val_ratio + test_ratio) - 1.0) < 1e-5, "Ratios must sum to 1.0"

    subsets = ["train", "val", "test"]
    for sub in subsets:
        os.makedirs(os.path.join(output_dir, "images", sub), exist_ok=True)
        os.makedirs(os.path.join(output_dir, "labels", sub), exist_ok=True)

    # Collect valid paired samples
    valid_samples = []
    class_distribution = {c: 0 for c in TARGET_CLASSES.values()}

    image_exts = {".jpg", ".jpeg", ".png", ".webp"}
    for img_name in os.listdir(source_images_dir):
        ext = os.path.splitext(img_name)[1].lower()
        if ext not in image_exts:
            continue

        base_name = os.path.splitext(img_name)[0]
        img_path = os.path.join(source_images_dir, img_name)
        lbl_path = os.path.join(source_labels_dir, f"{base_name}.txt")

        if not verify_image_file(img_path):
            logger.warning(f"Skipping corrupted image: {img_path}")
            continue

        is_valid_label, boxes = validate_yolo_annotation(lbl_path, num_classes=len(TARGET_CLASSES))
        if not is_valid_label:
            logger.warning(f"Skipping missing or invalid label for {img_name}")
            continue

        for b in boxes:
            class_distribution[b["class_name"]] += 1

        valid_samples.append((img_path, lbl_path, base_name, ext))

    logger.info(f"Verified {len(valid_samples)} valid image-annotation pairs.")
    for cname, count in class_distribution.items():
        logger.info(f"  Class '{cname}': {count} bounding boxes")

    # Shuffle and partition
    random.shuffle(valid_samples)
    total = len(valid_samples)
    n_train = int(total * train_ratio)
    n_val = int(total * val_ratio)

    train_set = valid_samples[:n_train]
    val_set = valid_samples[n_train:n_train + n_val]
    test_set = valid_samples[n_train + n_val:]

    logger.info(f"Dataset Split: Train={len(train_set)}, Val={len(val_set)}, Test={len(test_set)}")

    def _copy_subset(samples: List[Tuple], subset_name: str):
        for img_p, lbl_p, base, ext in samples:
            shutil.copy2(img_p, os.path.join(output_dir, "images", subset_name, f"{base}{ext}"))
            shutil.copy2(lbl_p, os.path.join(output_dir, "labels", subset_name, f"{base}.txt"))

    _copy_subset(train_set, "train")
    _copy_subset(val_set, "val")
    _copy_subset(test_set, "test")
    logger.info("Dataset partitioning complete.")


if __name__ == "__main__":
    logger.info("CropGuard AI Dataset Preparation Module initialized.")

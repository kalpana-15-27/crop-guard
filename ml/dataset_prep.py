"""CropGuard AI: Automated Multi-Source Dataset Preparation & Validation Pipeline

Unifies, validates, and partitions multi-source agricultural pest datasets:
1. 'teppybugz/recognition-for-pest' (Aphids, Whitefly, Thrips)
2. 'ishtar-slt5o/rice-pest-detection-p0ptq' (Brown Planthopper; generic stem-borer unmapped)
3. 'asphyxiasea/helicoverpa-armigera-l5tar' (Helicoverpa armigera, Version 4)

Unified 6-Class Taxonomy (Preserved):
  0: Aphids
  1: Whitefly
  2: Brown Planthopper
  3: Yellow Stem Borer
  4: Thrips
  5: Helicoverpa armigera

Core Engineering & Scientific Protocols:
- Hard validation gate: Blocks 6-class training if any class (especially Class 3) has 0 annotations.
- Generic stem-borer is NOT mapped to Yellow Stem Borer (Class 3) without biological verification.
- HEALTHY class is never converted to a pest class. Handled consistently as background or excluded.
- SHA-256 duplicate elimination and Roboflow parent-hash near-duplicate grouping.
- Group-aware deterministic train (70%) / val (20%) / test (10%) partitioning (seed 42).
"""

import os
import re
import struct
import shutil
import random
import hashlib
import logging
from typing import Dict, List, Tuple, Set, Optional
from collections import defaultdict

try:
    import yaml
except ImportError:
    yaml = None

try:
    from PIL import Image
except ImportError:
    Image = None

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger("CropGuard.DatasetPrep")

# Target Pest Categories (Strict 6-Class Schema)
UNIFIED_CLASSES = {
    0: "Aphids",
    1: "Whitefly",
    2: "Brown Planthopper",
    3: "Yellow Stem Borer",
    4: "Thrips",
    5: "Helicoverpa armigera"
}

CLASS_NAME_TO_ID = {name.lower(): cid for cid, name in UNIFIED_CLASSES.items()}


class MissingClassError(RuntimeError):
    """Raised when one or more required target classes have zero annotations."""
    pass


def compute_file_sha256(filepath: str) -> str:
    """Computes SHA-256 hash of a file for exact duplicate detection."""
    hasher = hashlib.sha256()
    with open(filepath, "rb") as f:
        while chunk := f.read(65536):
            hasher.update(chunk)
    return hasher.hexdigest()


def extract_parent_group_id(filename: str) -> str:
    """Extracts base parent identifier by stripping Roboflow augmentation hashes and suffixes.
    Prevents augmented variations of the same original photograph from leaking across splits.
    
    Examples:
        'cotton_aphid_12_jpg.rf.8a3b5c4d.jpg' -> 'cotton_aphid_12'
        'img_45.rf.9f8e7d.png' -> 'img_45'
    """
    base = os.path.splitext(filename)[0]
    # Remove Roboflow hash patterns like _jpg.rf.xxxx or .rf.xxxx
    cleaned = re.sub(r'(_(jpg|jpeg|png))?\.rf\.[a-z0-9]+$', '', base, flags=re.IGNORECASE)
    # Remove common rotation/augmentation tags
    cleaned = re.sub(r'_(rot\d+|flip|bright\d+|crop\d+)$', '', cleaned, flags=re.IGNORECASE)
    return cleaned.strip()


def verify_image(image_path: str) -> Tuple[bool, Optional[Tuple[int, int]], str]:
    """Verifies that an image file exists, has non-zero size, and can be decoded."""
    if not os.path.exists(image_path):
        return False, None, "File does not exist"
    size = os.path.getsize(image_path)
    if size == 0:
        return False, None, "Zero-byte empty file"

    # Use Pillow if available
    if Image is not None:
        try:
            with Image.open(image_path) as img:
                img.verify()
            with Image.open(image_path) as img:
                w, h = img.size
                if w <= 0 or h <= 0:
                    return False, None, f"Invalid dimensions ({w}x{h})"
            return True, (w, h), "OK"
        except Exception as e:
            return False, None, f"Corrupt image: {str(e)}"

    # Standard library fallback: inspect header bytes for common image types
    try:
        with open(image_path, "rb") as f:
            header = f.read(32)
            if header.startswith(b"\xff\xd8"):  # JPEG
                return True, (640, 640), "OK"
            elif header.startswith(b"\x89PNG\r\n\x1a\n"):  # PNG
                w, h = struct.unpack(">LL", header[16:24])
                return True, (w, h), "OK"
            elif header.startswith(b"RIFF") and header[8:12] == b"WEBP":  # WebP
                return True, (640, 640), "OK"
            else:
                return False, None, "Unrecognized image format"
    except Exception as e:
        return False, None, f"Error reading header: {str(e)}"


def parse_and_remap_annotation(
    label_path: str,
    class_mapping: Dict[int, int]
) -> Tuple[bool, List[Tuple[int, float, float, float, float]], str]:
    """Parses a YOLO annotation file, remaps class IDs, and validates bounding box geometry.
    
    Coordinates must be normalized floats in [0.0, 1.0] with width > 0 and height > 0.
    Unmapped classes (such as HEALTHY or non-target insects) are safely dropped.
    Returns (is_valid, list_of_remapped_boxes, error_reason).
    """
    if not os.path.exists(label_path):
        return True, [], "No annotations file"

    remapped_boxes = []
    with open(label_path, "r", encoding="utf-8") as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            parts = line.split()
            if len(parts) != 5:
                return False, [], f"Line {line_num}: Expected 5 fields, got {len(parts)}"

            try:
                src_cls = int(parts[0])
                xc, yc, w, h = map(float, parts[1:])
            except ValueError:
                return False, [], f"Line {line_num}: Non-numeric bounding box values"

            # Check if source class is explicitly mapped to our target classes
            if src_cls not in class_mapping:
                # Class filtered out (e.g. HEALTHY, green leafhopper, generic stem-borer)
                continue

            target_cls = class_mapping[src_cls]

            # Validate coordinate range
            if not (0.0 <= xc <= 1.0 and 0.0 <= yc <= 1.0 and 0.0 < w <= 1.0 and 0.0 < h <= 1.0):
                return False, [], f"Line {line_num}: Coordinates not normalized in [0, 1]: {[xc, yc, w, h]}"

            remapped_boxes.append((target_cls, xc, yc, w, h))

    return True, remapped_boxes, "OK"


def build_source_class_mapping(source_names: List[str]) -> Dict[int, int]:
    """Dynamically builds a source-to-unified class index map based on source class names.
    
    Rules:
    - 'aphids' / 'aphid' -> 0
    - 'whitefly' / 'whiteflies' -> 1
    - 'brown-planthopper' / 'brown planthopper' -> 2
    - 'yellow-stem-borer' / 'yellow stem borer' -> 3
      * NOTE: Generic 'stem-borer' or 'stem borer' is NOT mapped to 3!
    - 'thrips' / 'thrip' -> 4
    - 'helicoverpa-armigera' / 'helicoverpa' / 'bollworm' -> 5
    - 'healthy' is explicitly unmapped (never converted to a pest class)
    """
    mapping = {}
    for idx, raw_name in enumerate(source_names):
        name = raw_name.lower().strip()

        # Healthy is explicitly skipped
        if "healthy" in name:
            logger.debug(f"Source class {idx} '{raw_name}' identified as HEALTHY; safely excluded from pest mapping.")
            continue

        if "aphid" in name:
            mapping[idx] = 0
        elif "whitefl" in name:
            mapping[idx] = 1
        elif "brown" in name and ("planthopper" in name or "hopper" in name):
            mapping[idx] = 2
        elif "yellow" in name and ("stem" in name and "borer" in name):
            # Strict biological match for Yellow Stem Borer
            mapping[idx] = 3
        elif "stem" in name and "borer" in name:
            # Generic stem-borer without 'yellow': DO NOT MAP to 3!
            logger.warning(
                f"Source class {idx} '{raw_name}' is generic 'stem-borer'. "
                f"Per biological verification protocol, NOT mapped to Yellow Stem Borer (Class 3)."
            )
            continue
        elif "thrip" in name:
            mapping[idx] = 4
        elif "helicoverpa" in name or "armigera" in name or "bollworm" in name:
            mapping[idx] = 5
        else:
            logger.debug(f"Source class {idx} '{raw_name}' is non-target; excluded from mapping.")

    return mapping


class DatasetPreparer:
    """Manages multi-source dataset unification, deduplication, and group-aware partitioning."""

    def __init__(self, output_root: str, retain_background_images: bool = False):
        self.output_root = output_root
        self.retain_background_images = retain_background_images
        self.images_out = os.path.join(output_root, "images")
        self.labels_out = os.path.join(output_root, "labels")
        self.seen_sha256: Dict[str, str] = {}   # sha256 -> original_image_path
        self.samples: List[Dict] = []           # List of processed sample metadata
        self.excluded_images_count = 0          # Images excluded due to 0 target boxes

    def process_source_directory(
        self,
        source_name: str,
        images_dir: str,
        labels_dir: str,
        class_mapping: Dict[int, int]
    ) -> Dict[str, int]:
        """Ingests images and labels from a source dataset, remaps classes, and prunes duplicates."""
        stats = {
            "scanned": 0,
            "corrupt": 0,
            "exact_duplicates": 0,
            "retained": 0,
            "excluded_no_pest_boxes": 0,
            "total_boxes": 0
        }

        if not os.path.exists(images_dir):
            logger.warning(f"Images directory not found for {source_name}: {images_dir}")
            return stats

        image_extensions = {".jpg", ".jpeg", ".png", ".webp"}
        for fname in os.listdir(images_dir):
            ext = os.path.splitext(fname)[1].lower()
            if ext not in image_extensions:
                continue

            stats["scanned"] += 1
            img_path = os.path.join(images_dir, fname)
            base_name = os.path.splitext(fname)[0]
            lbl_path = os.path.join(labels_dir, f"{base_name}.txt")

            # Verify image file integrity
            is_valid_img, dims, img_err = verify_image(img_path)
            if not is_valid_img:
                logger.warning(f"[{source_name}] Corrupt image {fname}: {img_err}")
                stats["corrupt"] += 1
                continue

            # Check exact SHA-256 duplicate
            sha256_hash = compute_file_sha256(img_path)
            if sha256_hash in self.seen_sha256:
                stats["exact_duplicates"] += 1
                continue
            self.seen_sha256[sha256_hash] = img_path

            # Parse and remap annotations
            is_valid_lbl, boxes, lbl_err = parse_and_remap_annotation(lbl_path, class_mapping)
            if not is_valid_lbl:
                logger.warning(f"[{source_name}] Invalid label {lbl_path}: {lbl_err}")
                continue

            # Handle images with 0 target pest bounding boxes (e.g. HEALTHY crops)
            if not boxes:
                if not self.retain_background_images:
                    stats["excluded_no_pest_boxes"] += 1
                    self.excluded_images_count += 1
                    continue
                # If background images are retained, they have empty boxes (0 boxes)
                # which will produce a valid empty .txt label file

            parent_group = extract_parent_group_id(fname)
            self.samples.append({
                "source": source_name,
                "image_path": img_path,
                "filename": fname,
                "parent_group": parent_group,
                "sha256": sha256_hash,
                "dimensions": dims,
                "boxes": boxes,
                "classes": list(set(b[0] for b in boxes))
            })

            stats["retained"] += 1
            stats["total_boxes"] += len(boxes)

        logger.info(
            f"[{source_name}] Ingested {stats['retained']} images "
            f"({stats['total_boxes']} boxes, {stats['exact_duplicates']} dupes skipped, "
            f"{stats['excluded_no_pest_boxes']} excluded with 0 target boxes)"
        )
        return stats

    def analyze_dataset_statistics(self) -> Dict:
        """Computes comprehensive class distributions, co-occurrences, and balance ratios."""
        box_counts = defaultdict(int)
        image_counts = defaultdict(int)
        multi_class_images = 0
        background_images = 0

        for sample in self.samples:
            classes_in_sample = set()
            for b in sample["boxes"]:
                cid = b[0]
                box_counts[cid] += 1
                classes_in_sample.add(cid)

            for cid in classes_in_sample:
                image_counts[cid] += 1

            if len(classes_in_sample) > 1:
                multi_class_images += 1
            elif len(classes_in_sample) == 0:
                background_images += 1

        total_images = len(self.samples)
        total_boxes = sum(box_counts.values())

        report = {
            "total_images": total_images,
            "total_boxes": total_boxes,
            "multi_class_images": multi_class_images,
            "background_images": background_images,
            "excluded_no_pest_images": self.excluded_images_count,
            "box_counts_per_class": {UNIFIED_CLASSES[cid]: box_counts[cid] for cid in range(6)},
            "image_counts_per_class": {UNIFIED_CLASSES[cid]: image_counts[cid] for cid in range(6)},
            "available_classes": [UNIFIED_CLASSES[cid] for cid in range(6) if box_counts[cid] > 0],
            "missing_classes": [UNIFIED_CLASSES[cid] for cid in range(6) if box_counts[cid] == 0]
        }
        return report

    def partition_group_aware(
        self,
        train_ratio: float = 0.70,
        val_ratio: float = 0.20,
        test_ratio: float = 0.10,
        seed: int = 42
    ) -> Dict[str, int]:
        """Partitions samples into train/val/test splits at the parent_group level.
        Guarantees that no augmented variants or sequences of the same original capture leak across splits.
        """
        assert abs((train_ratio + val_ratio + test_ratio) - 1.0) < 1e-5, "Ratios must sum to 1.0"
        random.seed(seed)

        group_to_samples = defaultdict(list)
        for s in self.samples:
            group_to_samples[s["parent_group"]].append(s)

        groups = list(group_to_samples.keys())
        random.shuffle(groups)

        total_groups = len(groups)
        if total_groups == 0:
            logger.warning("No sample groups available to partition.")
            return {"train": 0, "val": 0, "test": 0}

        # Calculate group counts ensuring non-empty val/test if enough groups exist
        n_train_groups = int(total_groups * train_ratio)
        n_val_groups = int(total_groups * val_ratio)
        
        # Guard against 0 val/test groups when sample count is modest
        if total_groups >= 3:
            if n_val_groups == 0:
                n_val_groups = 1
                n_train_groups -= 1
            if (total_groups - n_train_groups - n_val_groups) == 0:
                n_train_groups -= 1

        train_groups = set(groups[:n_train_groups])
        val_groups = set(groups[n_train_groups:n_train_groups + n_val_groups])
        test_groups = set(groups[n_train_groups + n_val_groups:])

        for sub in ["train", "val", "test"]:
            os.makedirs(os.path.join(self.images_out, sub), exist_ok=True)
            os.makedirs(os.path.join(self.labels_out, sub), exist_ok=True)

        counts = {"train": 0, "val": 0, "test": 0}

        def _write_samples(sample_list: List[Dict], subset_name: str):
            for s in sample_list:
                fname = s["filename"]
                base_name = os.path.splitext(fname)[0]
                dst_img = os.path.join(self.images_out, subset_name, fname)
                dst_lbl = os.path.join(self.labels_out, subset_name, f"{base_name}.txt")

                shutil.copy2(s["image_path"], dst_img)

                # Write label file (empty .txt if 0 boxes, or valid remapped lines)
                with open(dst_lbl, "w", encoding="utf-8") as f:
                    for b in s["boxes"]:
                        cid, xc, yc, w, h = b
                        f.write(f"{cid} {xc:.6f} {yc:.6f} {w:.6f} {h:.6f}\n")

                counts[subset_name] += 1

        for g in train_groups:
            _write_samples(group_to_samples[g], "train")
        for g in val_groups:
            _write_samples(group_to_samples[g], "val")
        for g in test_groups:
            _write_samples(group_to_samples[g], "test")

        logger.info(f"Partition complete: Train={counts['train']}, Val={counts['val']}, Test={counts['test']}")
        return counts

    def verify_split_integrity(self) -> Tuple[bool, List[str]]:
        """Verifies split independence, absence of data leakage across splits."""
        errors = []
        train_dir = os.path.join(self.images_out, "train")
        val_dir = os.path.join(self.images_out, "val")
        test_dir = os.path.join(self.images_out, "test")

        train_imgs = set(os.listdir(train_dir)) if os.path.exists(train_dir) else set()
        val_imgs = set(os.listdir(val_dir)) if os.path.exists(val_dir) else set()
        test_imgs = set(os.listdir(test_dir)) if os.path.exists(test_dir) else set()

        # 1. Exact filename overlap
        tv_overlap = train_imgs.intersection(val_imgs)
        tt_overlap = train_imgs.intersection(test_imgs)
        vt_overlap = val_imgs.intersection(test_imgs)

        if tv_overlap:
            errors.append(f"Train-Val filename collision: {len(tv_overlap)} items")
        if tt_overlap:
            errors.append(f"Train-Test filename collision: {len(tt_overlap)} items")
        if vt_overlap:
            errors.append(f"Val-Test filename collision: {len(vt_overlap)} items")

        # 2. Parent group leakage
        train_parents = {extract_parent_group_id(f) for f in train_imgs}
        val_parents = {extract_parent_group_id(f) for f in val_imgs}
        test_parents = {extract_parent_group_id(f) for f in test_imgs}

        if train_parents.intersection(val_parents):
            errors.append("Parent group leakage detected between Train and Val")
        if train_parents.intersection(test_parents):
            errors.append("Parent group leakage detected between Train and Test")
        if val_parents.intersection(test_parents):
            errors.append("Parent group leakage detected between Val and Test")

        is_valid = len(errors) == 0
        return is_valid, errors

    def check_class_representation(self) -> Set[int]:
        """Returns the set of class IDs actually present in the partitioned training split."""
        train_classes_present = set()
        labels_train_dir = os.path.join(self.labels_out, "train")
        if os.path.exists(labels_train_dir):
            for lbl_file in os.listdir(labels_train_dir):
                with open(os.path.join(labels_train_dir, lbl_file), "r", encoding="utf-8") as f:
                    for line in f:
                        parts = line.strip().split()
                        if parts:
                            try:
                                train_classes_present.add(int(parts[0]))
                            except ValueError:
                                pass
        return train_classes_present

    def validate_six_class_training_gate(self) -> Tuple[bool, str]:
        """Hard validation gate: Verifies all 6 target classes are present before training.
        
        Strictly prevents training a 6-class model if Class 3 ('Yellow Stem Borer') or any
        other class has zero verified training instances.
        """
        train_classes = self.check_class_representation()
        missing = set(range(6)) - train_classes

        if missing:
            missing_details = [f"Class {c} ({UNIFIED_CLASSES[c]})" for c in sorted(missing)]
            msg = (
                f"[TRAINING GATE BLOCKED] Cannot train 6-class CropGuard AI model!\n"
                f"Missing classes in training dataset: {missing_details}.\n"
            )
            if 3 in missing:
                msg += (
                    "CRITICAL BLOCKER: Class 3 ('Yellow Stem Borer') has ZERO verified annotations.\n"
                    "The downloaded rice dataset contains generic 'stem-borer', which cannot be\n"
                    "scientifically mapped to Scirpophaga incertulas without biological evidence.\n"
                    "Six-class model training is strictly halted until verified annotations are obtained."
                )
            return False, msg

        return True, "All 6 classes verified in training set. Training gate passed."


def write_dataset_yaml(output_path: str, dataset_root: str):
    """Generates the standardized Ultralytics YOLO11 dataset YAML configuration."""
    if yaml is not None:
        config = {
            "path": dataset_root,
            "train": "images/train",
            "val": "images/val",
            "test": "images/test",
            "nc": 6,
            "names": UNIFIED_CLASSES
        }
        with open(output_path, "w", encoding="utf-8") as f:
            yaml.dump(config, f, default_flow_style=False, sort_keys=False)
    else:
        # Fallback pure-python YAML generator
        content = f"""# CropGuard AI: YOLO11s Agricultural Pest Detection Dataset Configuration
path: {dataset_root}
train: images/train
val: images/val
test: images/test
nc: 6
names:
  0: Aphids
  1: Whitefly
  2: Brown Planthopper
  3: Yellow Stem Borer
  4: Thrips
  5: Helicoverpa armigera
"""
        with open(output_path, "w", encoding="utf-8") as f:
            f.write(content)
    logger.info(f"Dataset YAML written to {output_path}")


if __name__ == "__main__":
    logger.info("CropGuard AI Dataset Preparation Module ready.")

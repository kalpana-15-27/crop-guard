"""Synthetic Unit Tests for CropGuard AI Dataset Preparation & Training Gate Pipeline

NOTE: All tests in this module use synthetic mock images and label files to verify
pipeline mechanics (remapping, deduplication, group isolation, and gate validation).
None of these tests represent or claim execution against the real downloaded datasets.
"""

import os
import shutil
import tempfile
import unittest
from ml.dataset_prep import (
    UNIFIED_CLASSES,
    compute_file_sha256,
    extract_parent_group_id,
    verify_image,
    parse_and_remap_annotation,
    build_source_class_mapping,
    DatasetPreparer,
    write_dataset_yaml
)

# Minimal valid JPEG binary header for synthetic test files
SYNTHETIC_JPEG_HEADER = b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x01\x00`\x00`\x00\x00\xff\xdb"


class TestSyntheticDatasetPipeline(unittest.TestCase):

    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.output_dir = os.path.join(self.test_dir, "processed")

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_synthetic_source_to_unified_remapping(self):
        """[SYNTHETIC TEST] Verifies dynamic class name parsing and strict biological mapping."""
        # 1. TeppyBugz classes
        teppy_classes = ["HEALTHY", "WHITEFLY", "APHIDS", "THRIPS"]
        teppy_map = build_source_class_mapping(teppy_classes)
        self.assertNotIn(0, teppy_map, "HEALTHY must NOT be mapped to any pest class!")
        self.assertEqual(teppy_map[1], 1, "WHITEFLY must map to unified 1")
        self.assertEqual(teppy_map[2], 0, "APHIDS must map to unified 0")
        self.assertEqual(teppy_map[3], 4, "THRIPS must map to unified 4")

        # 2. Ishtar Rice classes
        ishtar_classes = [
            "brown-planthopper",
            "green-leafhopper",
            "leaf-folder",
            "rice-bug",
            "stem-borer",
            "whorl-maggot"
        ]
        ishtar_map = build_source_class_mapping(ishtar_classes)
        self.assertEqual(ishtar_map[0], 2, "brown-planthopper must map to unified 2")
        self.assertNotIn(1, ishtar_map, "green-leafhopper must be unmapped")
        self.assertNotIn(2, ishtar_map, "leaf-folder must be unmapped")
        self.assertNotIn(3, ishtar_map, "rice-bug must be unmapped")
        
        # CRITICAL TEST: Generic stem-borer must NOT map to Yellow Stem Borer (Class 3)
        self.assertNotIn(4, ishtar_map, "Generic 'stem-borer' MUST NOT be mapped to Yellow Stem Borer (Class 3)!")

        # 3. Verified Yellow Stem Borer test
        verified_rice_classes = ["brown-planthopper", "yellow-stem-borer"]
        verified_map = build_source_class_mapping(verified_rice_classes)
        self.assertEqual(verified_map[0], 2)
        self.assertEqual(verified_map[1], 3, "'yellow-stem-borer' must map to unified 3")

        # 4. Helicoverpa class
        heli_classes = ["helicoverpa-armigera"]
        heli_map = build_source_class_mapping(heli_classes)
        self.assertEqual(heli_map[0], 5, "helicoverpa-armigera must map to unified 5")

    def test_synthetic_healthy_class_handling(self):
        """[SYNTHETIC TEST] Verifies healthy images never convert to pests and handle negative samples correctly."""
        label_file = os.path.join(self.test_dir, "healthy_sample.txt")
        # Class 0: HEALTHY (source class 0)
        # Class 2: APHIDS (source class 2)
        with open(label_file, "w") as f:
            f.write("0 0.5 0.5 0.2 0.2\n")  # HEALTHY
            f.write("2 0.3 0.3 0.1 0.1\n")  # APHIDS

        mapping = {2: 0}  # Source class 0 (HEALTHY) is NOT in mapping
        is_valid, boxes, err = parse_and_remap_annotation(label_file, mapping)

        self.assertTrue(is_valid)
        self.assertEqual(len(boxes), 1, "HEALTHY box must be dropped, keeping only APHIDS box")
        self.assertEqual(boxes[0][0], 0, "Retained box must be unified Class 0 (Aphids)")

        # Test purely healthy label (no pest boxes)
        pure_healthy_label = os.path.join(self.test_dir, "pure_healthy.txt")
        with open(pure_healthy_label, "w") as f:
            f.write("0 0.5 0.5 0.2 0.2\n")  # HEALTHY only

        is_valid_pure, pure_boxes, _ = parse_and_remap_annotation(pure_healthy_label, mapping)
        self.assertTrue(is_valid_pure)
        self.assertEqual(len(pure_boxes), 0, "Pure healthy image must produce 0 pest boxes")

    def test_synthetic_missing_class_training_gate(self):
        """[SYNTHETIC TEST] Hard validation gate must halt execution when Class 3 is missing."""
        preparer = DatasetPreparer(self.output_dir)

        # Ingest samples covering classes 0, 1, 2, 4, 5 (Class 3 'Yellow Stem Borer' intentionally missing)
        src_dir = os.path.join(self.test_dir, "src_missing_gate")
        imgs_dir = os.path.join(src_dir, "images")
        lbls_dir = os.path.join(src_dir, "labels")
        os.makedirs(imgs_dir, exist_ok=True)
        os.makedirs(lbls_dir, exist_ok=True)

        classes_to_add = [0, 1, 2, 4, 5]  # Missing 3!
        for i, cid in enumerate(classes_to_add):
            fname = f"sample_{i}.jpg"
            with open(os.path.join(imgs_dir, fname), "wb") as f:
                f.write(SYNTHETIC_JPEG_HEADER + f"sample_{i}".encode())
            with open(os.path.join(lbls_dir, f"sample_{i}.txt"), "w") as f:
                f.write(f"{cid} 0.5 0.5 0.2 0.2\n")

        preparer.process_source_directory("missing_class_src", imgs_dir, lbls_dir, {c: c for c in classes_to_add})
        preparer.partition_group_aware(train_ratio=0.70, val_ratio=0.20, test_ratio=0.10, seed=42)

        # Hard validation gate check
        passed, gate_msg = preparer.validate_six_class_training_gate()
        self.assertFalse(passed, "Training gate MUST fail when Class 3 is missing!")
        self.assertIn("CRITICAL BLOCKER", gate_msg)
        self.assertIn("Yellow Stem Borer", gate_msg)
        self.assertIn("TRAINING GATE BLOCKED", gate_msg)

    def test_synthetic_duplicate_and_near_duplicate_leakage(self):
        """[SYNTHETIC TEST] Verifies exact SHA-256 duplicate elimination and parent group isolation."""
        preparer = DatasetPreparer(self.output_dir)
        src_dir = os.path.join(self.test_dir, "dupe_test")
        imgs_dir = os.path.join(src_dir, "images")
        lbls_dir = os.path.join(src_dir, "labels")
        os.makedirs(imgs_dir, exist_ok=True)
        os.makedirs(lbls_dir, exist_ok=True)

        # 1. Create exact duplicate image files (same SHA-256 payload)
        dupe_payload = SYNTHETIC_JPEG_HEADER + b"identical_bytes_12345"
        with open(os.path.join(imgs_dir, "img_original.jpg"), "wb") as f:
            f.write(dupe_payload)
        with open(os.path.join(lbls_dir, "img_original.txt"), "w") as f:
            f.write("0 0.5 0.5 0.2 0.2\n")

        with open(os.path.join(imgs_dir, "img_duplicate.jpg"), "wb") as f:
            f.write(dupe_payload)
        with open(os.path.join(lbls_dir, "img_duplicate.txt"), "w") as f:
            f.write("0 0.5 0.5 0.2 0.2\n")

        # 2. Create Roboflow augmented near-duplicates of a parent image
        for aug_idx in range(3):
            fname = f"leaf_parent_01_jpg.rf.hash{aug_idx}.jpg"
            with open(os.path.join(imgs_dir, fname), "wb") as f:
                f.write(SYNTHETIC_JPEG_HEADER + f"unique_aug_{aug_idx}".encode())
            with open(os.path.join(lbls_dir, f"leaf_parent_01_jpg.rf.hash{aug_idx}.txt"), "w") as f:
                f.write("0 0.5 0.5 0.2 0.2\n")

        stats = preparer.process_source_directory("dupe_src", imgs_dir, lbls_dir, {0: 0})
        self.assertEqual(stats["exact_duplicates"], 1, "Exactly 1 duplicate must be skipped via SHA-256")
        self.assertEqual(stats["retained"], 4)  # 1 original + 3 augmented variants of leaf_parent_01

        # Partition and verify anti-leakage
        preparer.partition_group_aware(train_ratio=0.70, val_ratio=0.20, test_ratio=0.10, seed=42)
        is_valid, errors = preparer.verify_split_integrity()
        self.assertTrue(is_valid, f"Anti-leakage split integrity check failed: {errors}")

    def test_synthetic_single_folder_split_helicoverpa(self):
        """[SYNTHETIC TEST] Simulates single-folder dataset (like Helicoverpa 202 images) to ensure non-empty splits."""
        preparer = DatasetPreparer(self.output_dir)
        src_dir = os.path.join(self.test_dir, "heli_test")
        imgs_dir = os.path.join(src_dir, "images")
        lbls_dir = os.path.join(src_dir, "labels")
        os.makedirs(imgs_dir, exist_ok=True)
        os.makedirs(lbls_dir, exist_ok=True)

        # Create 50 synthetic Helicoverpa images all in single folder
        for i in range(50):
            fname = f"heli_{i:03d}.jpg"
            with open(os.path.join(imgs_dir, fname), "wb") as f:
                f.write(SYNTHETIC_JPEG_HEADER + f"heli_payload_{i}".encode())
            with open(os.path.join(lbls_dir, f"heli_{i:03d}.txt"), "w") as f:
                f.write("5 0.5 0.5 0.3 0.3\n")

        preparer.process_source_directory("heli_src", imgs_dir, lbls_dir, {5: 5})
        counts = preparer.partition_group_aware(train_ratio=0.70, val_ratio=0.20, test_ratio=0.10, seed=42)

        self.assertGreater(counts["train"], 0, "Train split must not be empty")
        self.assertGreater(counts["val"], 0, "Validation split must not be empty")
        self.assertGreater(counts["test"], 0, "Test split must not be empty")
        self.assertEqual(counts["train"] + counts["val"] + counts["test"], 50)

    def test_synthetic_invalid_geometry_and_corrupt_labels(self):
        """[SYNTHETIC TEST] Verifies out-of-bounds coordinates and corrupt entries are caught."""
        label_bad_coords = os.path.join(self.test_dir, "bad_coords.txt")
        with open(label_bad_coords, "w") as f:
            f.write("0 1.25 0.5 0.2 0.2\n")  # xc > 1.0

        is_valid, _, err = parse_and_remap_annotation(label_bad_coords, {0: 0})
        self.assertFalse(is_valid)
        self.assertIn("Coordinates not normalized", err)

        label_non_numeric = os.path.join(self.test_dir, "bad_num.txt")
        with open(label_non_numeric, "w") as f:
            f.write("0 abc 0.5 0.2 0.2\n")

        is_valid_num, _, err_num = parse_and_remap_annotation(label_non_numeric, {0: 0})
        self.assertFalse(is_valid_num)
        self.assertIn("Non-numeric", err_num)


if __name__ == "__main__":
    unittest.main()

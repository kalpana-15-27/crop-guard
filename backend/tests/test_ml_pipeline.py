"""CropGuard AI: ML Pipeline and Annotation Validation Tests

Validates dataset utilities, YOLO coordinate checking, and multi-crop inference.
"""

import os
import sys
import tempfile
import unittest
from PIL import Image

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", ".."))

from ml.training.dataset_prep import validate_yolo_annotation, verify_image_file, TARGET_CLASSES
from app.inference.detector import detector


class TestMLPipeline(unittest.TestCase):
    def setUp(self):
        self.temp_dir = tempfile.mkdtemp()

    def tearDown(self):
        import shutil
        shutil.rmtree(self.temp_dir, ignore_errors=True)

    def test_target_classes_structure(self):
        self.assertEqual(len(TARGET_CLASSES), 6)
        self.assertEqual(TARGET_CLASSES[0], "Aphids")
        self.assertEqual(TARGET_CLASSES[1], "Whitefly")
        self.assertEqual(TARGET_CLASSES[2], "Brown Planthopper")
        self.assertEqual(TARGET_CLASSES[3], "Yellow Stem Borer")
        self.assertEqual(TARGET_CLASSES[4], "Thrips")
        self.assertEqual(TARGET_CLASSES[5], "Helicoverpa armigera")

    def test_valid_yolo_annotation(self):
        label_file = os.path.join(self.temp_dir, "sample.txt")
        with open(label_file, "w", encoding="utf-8") as f:
            f.write("0 0.5 0.5 0.2 0.3\n")
            f.write("5 0.3 0.4 0.15 0.25\n")

        valid, boxes = validate_yolo_annotation(label_file)
        self.assertTrue(valid)
        self.assertEqual(len(boxes), 2)
        self.assertEqual(boxes[0]["class_name"], "Aphids")
        self.assertEqual(boxes[1]["class_name"], "Helicoverpa armigera")

    def test_invalid_yolo_annotation_out_of_bounds(self):
        label_file = os.path.join(self.temp_dir, "invalid.txt")
        with open(label_file, "w", encoding="utf-8") as f:
            # 1.5 is > 1.0 (out of bounds)
            f.write("0 1.5 0.5 0.2 0.3\n")

        valid, boxes = validate_yolo_annotation(label_file)
        self.assertFalse(valid)
        self.assertEqual(len(boxes), 0)

    def test_invalid_yolo_annotation_unknown_class(self):
        label_file = os.path.join(self.temp_dir, "invalid_class.txt")
        with open(label_file, "w", encoding="utf-8") as f:
            # 9 is not in [0, 5]
            f.write("9 0.5 0.5 0.2 0.3\n")

        valid, boxes = validate_yolo_annotation(label_file)
        self.assertFalse(valid)
        self.assertEqual(len(boxes), 0)

    def test_verify_image_file(self):
        good_img_path = os.path.join(self.temp_dir, "good.jpg")
        img = Image.new("RGB", (100, 100), color=(50, 150, 50))
        img.save(good_img_path)
        self.assertTrue(verify_image_file(good_img_path))

        bad_img_path = os.path.join(self.temp_dir, "corrupt.jpg")
        with open(bad_img_path, "wb") as f:
            f.write(b"NOT_AN_IMAGE_DATA_BYTES")
        self.assertFalse(verify_image_file(bad_img_path))

    def test_multi_crop_inference(self):
        class MockTensor:
            def __init__(self, val):
                self._val = val
            def item(self):
                return self._val

        class MockBox:
            cls = [MockTensor(0)]
            conf = [MockTensor(0.85)]
            xyxyn = [[0.1, 0.1, 0.4, 0.4]]

        class MockResult:
            boxes = [MockBox()]
            names = {0: "Aphids"}

        class MockModel:
            names = {0: "Aphids"}
            def predict(self, **kwargs):
                return [MockResult()]

        original_model = detector.model
        detector.model = MockModel()
        try:
            target_crops = ["Paddy/Rice", "Cotton", "Tomato", "Chilli"]
            test_img = Image.new("RGB", (400, 400), color=(30, 100, 40))

            for crop in target_crops:
                detections, latency, version = detector.detect(test_img, crop_type=crop)
                self.assertIsInstance(detections, list)
                self.assertGreater(len(detections), 0)
                self.assertGreaterEqual(latency, 0.0)
                self.assertTrue(detections[0]["confidence"] >= 0.5)
                # Verify coordinates are valid normalized floats
                for det in detections:
                    self.assertGreaterEqual(det["x_min"], 0.0)
                    self.assertLessEqual(det["x_max"], 1.0)
                    self.assertGreaterEqual(det["y_min"], 0.0)
                    self.assertLessEqual(det["y_max"], 1.0)
        finally:
            detector.model = original_model


if __name__ == "__main__":
    unittest.main()

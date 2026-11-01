import unittest
import io
import sys
import os
from PIL import Image
from fastapi import UploadFile, HTTPException

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from app.services.storage_service import storage_service
from app.inference.detector import detector


class TestDetectionPipeline(unittest.TestCase):
    def setUp(self):
        # Create a sample in-memory RGB JPEG image
        img = Image.new("RGB", (640, 640), color=(34, 139, 34))
        buf = io.BytesIO()
        img.save(buf, format="JPEG")
        self.valid_bytes = buf.getvalue()

    def test_validate_valid_image(self):
        upload = UploadFile(filename="leaf.jpg", file=io.BytesIO(self.valid_bytes))
        ext = storage_service.validate_image_file(upload, self.valid_bytes)
        self.assertEqual(ext, ".jpg")

    def test_reject_invalid_extension(self):
        upload = UploadFile(filename="script.exe", file=io.BytesIO(b"fake binary"))
        with self.assertRaises(HTTPException) as ctx:
            storage_service.validate_image_file(upload, b"fake binary")
        self.assertEqual(ctx.exception.status_code, 415)

    def test_reject_empty_image(self):
        upload = UploadFile(filename="empty.jpg", file=io.BytesIO(b""))
        with self.assertRaises(HTTPException) as ctx:
            storage_service.validate_image_file(upload, b"")
        self.assertEqual(ctx.exception.status_code, 400)

    def test_preprocess_and_annotation(self):
        image = storage_service.preprocess_image(self.valid_bytes)
        self.assertEqual(image.mode, "RGB")

        detections = [
            {
                "pest_name": "Aphids",
                "confidence": 0.92,
                "x_min": 0.2,
                "y_min": 0.2,
                "x_max": 0.5,
                "y_max": 0.5,
            }
        ]
        file_id, file_path = storage_service.create_annotated_image(image, detections)
        self.assertTrue(os.path.exists(file_path))
        self.assertTrue(file_id.endswith(".jpg"))

    def test_detector_raises_error_when_model_not_trained(self):
        """Verifies that without trained weights, the detector strictly refuses to fabricate fake results."""
        detector.model = None
        self.assertFalse(detector.is_model_loaded())
        image = Image.new("RGB", (300, 300), color=(100, 200, 100))
        with self.assertRaises(RuntimeError) as ctx:
            detector.detect(image, crop_type="Cotton")
        self.assertIn("not available", str(ctx.exception))

    def test_detector_inference_with_loaded_weights(self):
        """Verifies that when a valid YOLO model is loaded, inference outputs real bounding box structures."""
        class MockTensor:
            def __init__(self, val):
                self._val = val
            def item(self):
                return self._val

        class MockBox:
            cls = [MockTensor(0)]
            conf = [MockTensor(0.89)]
            xyxyn = [[0.15, 0.25, 0.45, 0.55]]

        class MockYOLOResult:
            boxes = [MockBox()]
            names = {0: "Aphids"}

        class MockYOLOModel:
            names = {0: "Aphids"}
            def predict(self, **kwargs):
                return [MockYOLOResult()]

        detector.model = MockYOLOModel()
        try:
            self.assertTrue(detector.is_model_loaded())
            image = Image.new("RGB", (300, 300), color=(100, 200, 100))
            dets, latency, version = detector.detect(image, crop_type="Cotton")
            self.assertEqual(len(dets), 1)
            self.assertEqual(dets[0]["pest_name"], "Aphids")
            self.assertEqual(dets[0]["confidence"], 0.89)
            self.assertEqual(dets[0]["x_min"], 0.15)
            self.assertGreaterEqual(latency, 0.0)
        finally:
            detector.model = None


if __name__ == "__main__":
    unittest.main()

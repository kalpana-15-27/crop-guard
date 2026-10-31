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

        # Mock detection box
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

    def test_detector_latency_and_format(self):
        image = Image.new("RGB", (300, 300), color=(100, 200, 100))
        dets, latency, version = detector.detect(image, crop_type="Cotton")
        self.assertIsInstance(dets, list)
        self.assertGreaterEqual(latency, 0.0)
        self.assertIn("yolo11s", version)


if __name__ == "__main__":
    unittest.main()

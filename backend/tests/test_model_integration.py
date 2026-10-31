import unittest
import asyncio
import io
import os
import sys
from PIL import Image
from fastapi import UploadFile

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from app.api.v1.endpoints.detect import detect_pest
from app.api.v1.endpoints.history import get_history, get_prediction_detail


class TestEndToEndModelIntegration(unittest.TestCase):
    def setUp(self):
        # Create a sample test leaf image
        img = Image.new("RGB", (640, 640), color=(46, 125, 74))
        buf = io.BytesIO()
        img.save(buf, format="JPEG")
        self.image_bytes = buf.getvalue()

    def test_end_to_end_detection_and_annotation_pipeline(self):
        # 1. Run detection on Cotton
        upload = UploadFile(filename="infected_leaf.jpg", file=io.BytesIO(self.image_bytes))
        result = asyncio.run(
            detect_pest(
                file=upload,
                crop_type="Cotton",
                authorization=None
            )
        )

        # 2. Verify Structured Detection Output
        self.assertIsNotNone(result.id)
        self.assertEqual(result.crop_type, "Cotton")
        self.assertEqual(result.detection_status, "detected")
        self.assertGreater(result.total_detections, 0)
        self.assertGreaterEqual(result.highest_confidence, 0.8)
        self.assertIsNotNone(result.annotated_image_url)

        # 3. Verify Annotated Image was rendered and exists on filesystem
        backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
        # URL is formatted like /uploads/annotated/annotated_xxxx.jpg
        rel_path = result.annotated_image_url.lstrip("/")
        full_annotated_path = os.path.join(backend_dir, rel_path)
        self.assertTrue(os.path.exists(full_annotated_path), f"Annotated image not found at {full_annotated_path}")
        self.assertGreater(os.path.getsize(full_annotated_path), 0)

        # 4. Verify Pest Guidance Integration (English & Telugu)
        self.assertIsNotNone(result.pest_category)
        self.assertEqual(result.pest_category.pest_name, "Aphids")
        self.assertEqual(result.pest_category.scientific_name, "Aphis gossypii")
        self.assertTrue(len(result.pest_category.description_te) > 0)
        self.assertTrue(len(result.pest_category.preventive_guidance_te) > 0)

        # 5. Verify History Persistence
        history_list = asyncio.run(get_history(authorization=None))
        self.assertGreater(history_list.total, 0)
        matching = [item for item in history_list.items if item.id == result.id]
        self.assertEqual(len(matching), 1)
        self.assertEqual(matching[0].crop_type, "Cotton")

        # 6. Verify History Detail Retrieval
        detail = asyncio.run(get_prediction_detail(result.id, authorization=None))
        self.assertEqual(detail.id, result.id)
        self.assertEqual(len(detail.detections), result.total_detections)


if __name__ == "__main__":
    unittest.main()

import unittest
import asyncio
import io
import os
import sys
from PIL import Image
from fastapi import UploadFile, HTTPException

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from app.api.v1.endpoints.detect import detect_pest
from app.api.v1.endpoints.history import get_history, get_prediction_detail
from app.inference.detector import detector, YOLOPestDetector, YOLO_TO_CANONICAL_MAPPING
from app.core.config import settings


class TestEndToEndModelIntegration(unittest.TestCase):
    def setUp(self):
        # Create a sample test leaf image
        img = Image.new("RGB", (640, 640), color=(46, 125, 74))
        buf = io.BytesIO()
        img.save(buf, format="JPEG")
        self.image_bytes = buf.getvalue()

    def test_detect_endpoint_returns_503_when_model_not_trained(self):
        """Verifies that the endpoint strictly returns HTTP 503 MODEL_NOT_TRAINED when weights are missing."""
        original_model = detector.model
        detector.model = None
        try:
            upload = UploadFile(filename="leaf.jpg", file=io.BytesIO(self.image_bytes))
            with self.assertRaises(HTTPException) as ctx:
                asyncio.run(
                    detect_pest(
                        file=upload,
                        crop_type="Cotton",
                        authorization=None
                    )
                )
            self.assertEqual(ctx.exception.status_code, 503)
            self.assertIsInstance(ctx.exception.detail, dict)
            self.assertEqual(ctx.exception.detail.get("error_code"), "MODEL_NOT_TRAINED")
            self.assertIn("not been trained", ctx.exception.detail.get("message", ""))
        finally:
            detector.model = original_model

    def test_end_to_end_detection_and_annotation_pipeline(self):
        """Verifies full pipeline when a valid YOLO model is loaded."""
        class MockTensor:
            def __init__(self, val):
                self._val = val
            def item(self):
                return self._val

        class MockBox:
            cls = [MockTensor(0)]
            conf = [MockTensor(0.91)]
            xyxyn = [[0.2, 0.2, 0.5, 0.5]]

        class MockYOLOResult:
            boxes = [MockBox()]
            names = {0: "Aphids"}

        class MockYOLOModel:
            names = {0: "Aphids"}
            def predict(self, **kwargs):
                return [MockYOLOResult()]

        original_model = detector.model
        detector.model = MockYOLOModel()
        try:
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
            self.assertEqual(result.total_detections, 1)
            self.assertEqual(result.highest_confidence, 0.91)
            self.assertIsNotNone(result.annotated_image_url)
            self.assertEqual(result.detections[0].class_id, 0)
            self.assertEqual(result.detections[0].pest_name, "Aphids")

            # 3. Verify Annotated Image was rendered on filesystem
            backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
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
        finally:
            detector.model = original_model

    def test_genuine_zero_detections_flow(self):
        """Verifies clean handling when a trained model processes an image and finds 0 pests."""
        class MockEmptyYOLOModel:
            names = {0: "Aphids"}
            def predict(self, **kwargs):
                class EmptyResult:
                    boxes = []
                    names = {0: "Aphids"}
                return [EmptyResult()]

        original_model = detector.model
        detector.model = MockEmptyYOLOModel()
        try:
            upload = UploadFile(filename="clean_leaf.jpg", file=io.BytesIO(self.image_bytes))
            result = asyncio.run(
                detect_pest(
                    file=upload,
                    crop_type="Tomato",
                    authorization=None
                )
            )

            self.assertEqual(result.detection_status, "no_pest_detected")
            self.assertEqual(result.total_detections, 0)
            self.assertEqual(result.highest_confidence, 0.0)
            self.assertEqual(len(result.detections), 0)
            self.assertIsNone(result.pest_category)
            self.assertIsNone(result.annotated_image_url)
        finally:
            detector.model = original_model

    def test_reverse_class_mapping_integrity(self):
        """Verifies all 5 YOLO classes reverse map to their exact canonical IDs, and Yellow Stem Borer is NOT mapped."""
        self.assertEqual(YOLO_TO_CANONICAL_MAPPING[0]["canonical_id"], 0)
        self.assertEqual(YOLO_TO_CANONICAL_MAPPING[0]["pest_name"], "Aphids")

        self.assertEqual(YOLO_TO_CANONICAL_MAPPING[1]["canonical_id"], 1)
        self.assertEqual(YOLO_TO_CANONICAL_MAPPING[1]["pest_name"], "Whitefly")

        self.assertEqual(YOLO_TO_CANONICAL_MAPPING[2]["canonical_id"], 2)
        self.assertEqual(YOLO_TO_CANONICAL_MAPPING[2]["pest_name"], "Brown Planthopper")

        # CRITICAL: YOLO Class 3 MUST map to Canonical 4 (Thrips), NEVER to Yellow Stem Borer (3)
        self.assertEqual(YOLO_TO_CANONICAL_MAPPING[3]["canonical_id"], 4)
        self.assertEqual(YOLO_TO_CANONICAL_MAPPING[3]["pest_name"], "Thrips")

        self.assertEqual(YOLO_TO_CANONICAL_MAPPING[4]["canonical_id"], 5)
        self.assertEqual(YOLO_TO_CANONICAL_MAPPING[4]["pest_name"], "Helicoverpa armigera")

        # Canonical class 3 (Yellow Stem Borer) must NEVER be in the mapped targets
        mapped_canonical_ids = [m["canonical_id"] for m in YOLO_TO_CANONICAL_MAPPING.values()]
        self.assertNotIn(3, mapped_canonical_ids)
        self.assertEqual(sorted(mapped_canonical_ids), [0, 1, 2, 4, 5])

    def test_unmapped_class_dropped_safely(self):
        """Verifies that an unmapped class (e.g. class 99 or 5) is safely dropped and not fabricated."""
        class MockTensor:
            def __init__(self, val):
                self._val = val
            def item(self):
                return self._val

        class MockBox:
            cls = [MockTensor(99)]
            conf = [MockTensor(0.95)]
            xyxyn = [[0.1, 0.1, 0.5, 0.5]]

        class MockResult:
            boxes = [MockBox()]
            names = {99: "Unmapped Insect"}

        class MockModel:
            names = {99: "Unmapped Insect"}
            def predict(self, **kwargs):
                return [MockResult()]

        original_model = detector.model
        detector.model = MockModel()
        try:
            img = Image.new("RGB", (300, 300), color=(100, 150, 100))
            dets, latency, version = detector.detect(img)
            self.assertEqual(len(dets), 0, "Unmapped class must be dropped safely without crashing or guessing")
        finally:
            detector.model = original_model

    def test_coordinate_clamping(self):
        """Verifies that out-of-bounds bounding box coordinates are clamped to [0.0, 1.0]."""
        class MockTensor:
            def __init__(self, val):
                self._val = val
            def item(self):
                return self._val

        class MockBox:
            cls = [MockTensor(3)]  # Thrips -> Canonical 4
            conf = [MockTensor(0.88)]
            xyxyn = [[-0.05, -0.1, 1.15, 1.05]]

        class MockResult:
            boxes = [MockBox()]
            names = {3: "Thrips"}

        class MockModel:
            names = {3: "Thrips"}
            def predict(self, **kwargs):
                return [MockResult()]

        original_model = detector.model
        detector.model = MockModel()
        try:
            img = Image.new("RGB", (300, 300), color=(100, 150, 100))
            dets, latency, version = detector.detect(img)
            self.assertEqual(len(dets), 1)
            self.assertEqual(dets[0]["class_id"], 4)
            self.assertEqual(dets[0]["pest_name"], "Thrips")
            self.assertEqual(dets[0]["x_min"], 0.0)
            self.assertEqual(dets[0]["y_min"], 0.0)
            self.assertEqual(dets[0]["x_max"], 1.0)
            self.assertEqual(dets[0]["y_max"], 1.0)
        finally:
            detector.model = original_model


if __name__ == "__main__":
    unittest.main()

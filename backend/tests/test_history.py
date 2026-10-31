import unittest
import asyncio
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from app.services.history_service import history_service
from app.api.v1.endpoints.history import get_history, get_prediction_detail, delete_prediction
from fastapi import HTTPException


class TestHistoryEndpoints(unittest.TestCase):
    def test_save_and_retrieve_history(self):
        # Save a test prediction
        pred_id = history_service.save_prediction(
            user_id="test-user-123",
            crop_type="Tomato",
            detection_status="detected",
            total_detections=2,
            highest_confidence=0.88,
            processing_time_sec=0.15,
            model_version="yolo11s-v1.0",
            detections=[{"pest_name": "Helicoverpa armigera", "confidence": 0.88, "x_min": 0.1, "y_min": 0.1, "x_max": 0.4, "y_max": 0.4}],
            primary_pest_name="Helicoverpa armigera",
        )
        self.assertIsNotNone(pred_id)

        # Retrieve detail
        detail = asyncio.run(get_prediction_detail(pred_id, authorization=None))
        self.assertEqual(detail.id, pred_id)
        self.assertEqual(detail.crop_type, "Tomato")
        self.assertEqual(detail.total_detections, 2)
        self.assertEqual(detail.highest_confidence, 0.88)
        self.assertIsNotNone(detail.pest_category)
        self.assertEqual(detail.pest_category.pest_name, "Helicoverpa armigera")

        # Delete prediction
        del_res = asyncio.run(delete_prediction(pred_id, authorization=None))
        self.assertEqual(del_res["id"], pred_id)

        # Confirm 404 after deletion
        with self.assertRaises(HTTPException) as ctx:
            asyncio.run(get_prediction_detail(pred_id, authorization=None))
        self.assertEqual(ctx.exception.status_code, 404)


if __name__ == "__main__":
    unittest.main()

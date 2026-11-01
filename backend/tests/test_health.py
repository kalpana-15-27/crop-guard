import unittest
import asyncio
from unittest.mock import patch
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from app.main import root, root_health


class TestHealthEndpoints(unittest.TestCase):
    def test_root_endpoint(self):
        res = asyncio.run(root())
        self.assertIn("message", res)
        self.assertEqual(res["docs"], "/docs")

    @patch("app.database.supabase_client.supabase_client.check_health")
    def test_health_endpoint_mocked(self, mock_health):
        mock_health.return_value = {"status": "healthy", "code": 200}
        res = asyncio.run(root_health())
        self.assertEqual(res["status"], "healthy")
        self.assertIn("supabase", res)
        self.assertIn("model", res)
        self.assertFalse(res["model"]["loaded"])
        self.assertEqual(res["model"]["status"], "not_trained")
        self.assertEqual(res["supabase"]["status"], "healthy")
        self.assertEqual(res["version"], "1.0.0")


if __name__ == "__main__":
    unittest.main()

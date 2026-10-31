import unittest
import asyncio
import sys
import os

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from app.api.v1.endpoints.pests import list_pests, get_pest
from fastapi import HTTPException


class TestPestEndpoints(unittest.TestCase):
    def test_list_pests(self):
        res = asyncio.run(list_pests())
        self.assertGreaterEqual(res.total, 6)
        pest_names = [p.pest_name for p in res.items]
        self.assertIn("Aphids", pest_names)
        self.assertIn("Whitefly", pest_names)
        self.assertIn("Brown Planthopper", pest_names)
        self.assertIn("Yellow Stem Borer", pest_names)
        self.assertIn("Thrips", pest_names)
        self.assertIn("Helicoverpa armigera", pest_names)

    def test_get_pest_by_valid_id(self):
        res = asyncio.run(get_pest("Aphids"))
        self.assertEqual(res.pest_name, "Aphids")
        self.assertEqual(res.scientific_name, "Aphis gossypii")
        self.assertIsNotNone(res.description_te)
        self.assertIsNotNone(res.preventive_guidance)

    def test_get_pest_by_invalid_id_raises_404(self):
        with self.assertRaises(HTTPException) as ctx:
            asyncio.run(get_pest("non_existent_pest_xyz"))
        self.assertEqual(ctx.exception.status_code, 404)


if __name__ == "__main__":
    unittest.main()

import os
from typing import List


def _load_env_file(env_path: str):
    """Lightweight .env parser without requiring external python-dotenv."""
    if not os.path.exists(env_path):
        return
    with open(env_path, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            if "=" in line:
                key, val = line.split("=", 1)
                key = key.strip()
                val = val.strip().strip("'\"")
                if key not in os.environ:
                    os.environ[key] = val


# Locate .env in backend directory
_backend_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
_env_file = os.path.join(_backend_dir, ".env")
_load_env_file(_env_file)


class Settings:
    PROJECT_NAME: str = os.getenv("PROJECT_NAME", "CropGuard AI Backend")
    API_V1_STR: str = os.getenv("API_V1_STR", "/api/v1")
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    HOST: str = os.getenv("HOST", "0.0.0.0")
    PORT: int = int(os.getenv("PORT", "8000"))

    # Supabase Configuration
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "https://cxzayeoqbocryekkqiyk.supabase.co")
    SUPABASE_PUBLISHABLE_KEY: str = os.getenv("SUPABASE_PUBLISHABLE_KEY", "sb_publishable_ndB59weEGKDben6iY6odMg_hkNruZ3k")
    SUPABASE_SERVICE_ROLE_KEY: str = os.getenv("SUPABASE_SERVICE_ROLE_KEY", "")

    # Storage Buckets
    STORAGE_BUCKET_NAME: str = "cropguard-images"

    # ML Model Configuration
    MODEL_PATH: str = os.getenv("MODEL_PATH", "ml/weights/best.pt")
    CONFIDENCE_THRESHOLD: float = float(os.getenv("CONFIDENCE_THRESHOLD", "0.35"))
    IOU_THRESHOLD: float = float(os.getenv("IOU_THRESHOLD", "0.45"))

    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["*"]


settings = Settings()

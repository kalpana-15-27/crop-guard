import os
import sys
from typing import List

# Automatically include local conda site-packages if available and needed
_miniconda_pkgs = r"C:\Users\Dell\miniconda3\Lib\site-packages"
if os.path.exists(_miniconda_pkgs) and _miniconda_pkgs not in sys.path:
    sys.path.insert(0, _miniconda_pkgs)

# Suppress Ultralytics network autoinstall and telemetry in offline/production environments
os.environ["YOLO_AUTOINSTALL"] = "0"
os.environ["YOLO_VERBOSE"] = "False"


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
_repo_root = os.path.dirname(_backend_dir)
_env_file = os.path.join(_backend_dir, ".env")
_load_env_file(_env_file)


def _resolve_model_path(path_str: str) -> str:
    """Robustly resolve model path whether running from root, backend, or custom directory."""
    if os.path.isabs(path_str) and os.path.exists(path_str):
        return os.path.abspath(path_str)
    # Check current working directory
    if os.path.exists(path_str):
        return os.path.abspath(path_str)
    # Check repo root
    from_root = os.path.join(_repo_root, path_str)
    if os.path.exists(from_root):
        return os.path.abspath(from_root)
    # Check backend dir
    from_backend = os.path.join(_backend_dir, path_str)
    if os.path.exists(from_backend):
        return os.path.abspath(from_backend)
    # Default to repo root candidate
    return os.path.abspath(from_root)


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
    MODEL_PATH: str = _resolve_model_path(os.getenv("MODEL_PATH", "ml/weights/best.pt"))
    CONFIDENCE_THRESHOLD: float = float(os.getenv("CONFIDENCE_THRESHOLD", "0.35"))
    IOU_THRESHOLD: float = float(os.getenv("IOU_THRESHOLD", "0.45"))
    YOLO_IMGSZ: int = int(os.getenv("YOLO_IMGSZ", "640"))

    # CORS
    BACKEND_CORS_ORIGINS: List[str] = ["*"]


settings = Settings()

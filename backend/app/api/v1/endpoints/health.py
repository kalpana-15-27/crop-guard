from fastapi import APIRouter
from app.core.config import settings
from app.database.supabase_client import supabase_client
from app.inference.detector import detector

router = APIRouter()


@router.get("/health", summary="Health Check")
async def health_check():
    """Returns the operational status of CropGuard AI Backend and external dependencies."""
    supabase_status = "unreachable"
    try:
        supabase_health = supabase_client.check_health()
        supabase_status = supabase_health.get("status", "unknown")
    except Exception as e:
        supabase_status = f"error: {str(e)}"

    return {
        "status": "healthy",
        "app_name": settings.PROJECT_NAME,
        "environment": settings.ENVIRONMENT,
        "version": "1.0.0",
        "model": {
            "version": detector.model_version,
            "weights_path": detector.model_path,
            "loaded": detector.is_model_loaded(),
            "status": "ready" if detector.is_model_loaded() else "not_trained"
        },
        "supabase": {
            "url": settings.SUPABASE_URL,
            "status": supabase_status
        }
    }

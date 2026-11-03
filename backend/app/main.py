import os
import sys

# Ensure backend directory is in sys.path for direct module resolution
_backend_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if _backend_dir not in sys.path:
    sys.path.insert(0, _backend_dir)

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from app.core.config import settings
from app.api.v1.api import api_router
from app.services.storage_service import LOCAL_UPLOAD_DIR

app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Intelligent Pest Detection & Crop Protection Backend API powered by YOLO and Supabase",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json"
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.BACKEND_CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Static Files for Uploads and Annotated Images
if os.path.exists(LOCAL_UPLOAD_DIR):
    app.mount("/uploads", StaticFiles(directory=LOCAL_UPLOAD_DIR), name="uploads")

# Top-level /health endpoint
@app.get("/health", tags=["Health"])
async def root_health():
    from app.api.v1.endpoints.health import health_check
    return await health_check()

# Include versioned API routes
app.include_router(api_router, prefix=settings.API_V1_STR)

# Mount Flutter Web Application (PWA for iOS/Safari/Android/Desktop)
_web_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "static_web")
if os.path.exists(_web_dir):
    app.mount("/", StaticFiles(directory=_web_dir, html=True), name="flutter_web")
else:
    # Fallback root endpoint if static_web is not compiled
    @app.get("/", tags=["Root"])
    async def root():
        return {
            "message": "Welcome to CropGuard AI Backend API",
            "docs": "/docs",
            "health": "/health",
            "api_v1": settings.API_V1_STR
        }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=settings.HOST, port=settings.PORT, reload=True)

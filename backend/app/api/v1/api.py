from fastapi import APIRouter
from app.api.v1.endpoints import health, pests, detect, history

api_router = APIRouter()

api_router.include_router(health.router, tags=["Health"])
api_router.include_router(pests.router, prefix="/pests", tags=["Pests"])
api_router.include_router(detect.router, prefix="/detect", tags=["Detect"])
api_router.include_router(history.router, prefix="/history", tags=["History"])

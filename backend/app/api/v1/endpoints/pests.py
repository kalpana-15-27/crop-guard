from fastapi import APIRouter, HTTPException, status
from app.schemas.pest import PestCategoryResponse, PestCategoryListResponse
from app.services.pest_service import pest_service

router = APIRouter()


@router.get("", response_model=PestCategoryListResponse, summary="List all supported crop pests")
async def list_pests():
    """Returns all verified agricultural pests along with identification details,
    damage symptoms, and preventive guidance in English and Telugu.
    """
    items = pest_service.get_all_pests()
    return PestCategoryListResponse(total=len(items), items=items)


@router.get("/{pest_id}", response_model=PestCategoryResponse, summary="Get details for a specific pest")
async def get_pest(pest_id: str):
    """Retrieve detailed scientific, identification, and preventive information for a single pest."""
    pest = pest_service.get_pest_by_id(pest_id)
    if not pest:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Pest category '{pest_id}' not found."
        )
    return pest

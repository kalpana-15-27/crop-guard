from typing import List, Optional
from pydantic import BaseModel, Field


class PestCategoryBase(BaseModel):
    pest_name: str = Field(..., description="Common agricultural name of pest")
    scientific_name: str = Field(..., description="Binomial scientific classification")
    affected_crops: List[str] = Field(default_factory=list, description="Target host crops")
    description: str = Field(..., description="English identification description")
    description_te: Optional[str] = Field(None, description="Telugu description")
    symptoms: str = Field(..., description="Foliage & crop damage symptoms")
    symptoms_te: Optional[str] = Field(None, description="Telugu damage symptoms")
    preventive_guidance: str = Field(..., description="Safe, sustainable preventive practices")
    preventive_guidance_te: Optional[str] = Field(None, description="Telugu preventive guidance")


class PestCategoryResponse(PestCategoryBase):
    id: str = Field(..., description="Unique pest identifier")

    class Config:
        from_attributes = True


class PestCategoryListResponse(BaseModel):
    total: int
    items: List[PestCategoryResponse]

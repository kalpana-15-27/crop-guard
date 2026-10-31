from typing import Optional
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


class UserProfileResponse(BaseModel):
    id: str = Field(..., description="Supabase Auth UUID")
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    preferred_language: str = "en"
    created_at: Optional[datetime] = None


class TokenPayload(BaseModel):
    sub: str
    email: Optional[str] = None
    role: Optional[str] = None
    exp: Optional[int] = None

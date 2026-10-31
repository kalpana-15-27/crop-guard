import logging
from typing import Optional
from fastapi import Header, HTTPException, status
import requests
from app.core.config import settings

logger = logging.getLogger("cropguard.auth")


class AuthService:
    """Supabase JWT Authentication Service"""

    @staticmethod
    def get_current_user_id(authorization: Optional[str] = Header(None)) -> Optional[str]:
        """Validates the Authorization Bearer token with Supabase GoTrue Auth.
        Returns user_id (UUID) if authenticated, or None if anonymous.
        """
        if not authorization or not authorization.startswith("Bearer "):
            return None

        token = authorization.split("Bearer ", 1)[1].strip()
        if not token:
            return None

        # Verify token with Supabase Auth endpoint
        try:
            url = f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1/user"
            headers = {
                "apikey": settings.SUPABASE_PUBLISHABLE_KEY,
                "Authorization": f"Bearer {token}",
            }
            res = requests.get(url, headers=headers, timeout=5)
            if res.status_code == 200:
                user_data = res.json()
                return user_data.get("id")
            else:
                logger.warning(f"Supabase auth verification failed: {res.status_code} - {res.text}")
                return None
        except Exception as e:
            logger.error(f"Error connecting to Supabase Auth: {e}")
            return None

    @staticmethod
    def require_authenticated_user(authorization: Optional[str] = Header(None)) -> str:
        """Enforces authentication and raises 401 if token is missing or invalid."""
        user_id = AuthService.get_current_user_id(authorization)
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Authentication token is missing, expired, or invalid",
                headers={"WWW-Authenticate": "Bearer"},
            )
        return user_id


auth_service = AuthService()

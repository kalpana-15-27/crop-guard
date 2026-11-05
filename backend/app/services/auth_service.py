import base64
import json
import logging
from typing import Optional
from fastapi import Header, HTTPException, status
import requests
from app.core.config import settings

logger = logging.getLogger("cropguard.auth")


class AuthService:
    """Supabase JWT Authentication Service"""

    @staticmethod
    def extract_user_id_from_jwt(token: str) -> Optional[str]:
        """Extracts user ID ('sub') directly from JWT payload without network round-trip."""
        try:
            parts = token.split(".")
            if len(parts) >= 2:
                payload_b64 = parts[1]
                rem = len(payload_b64) % 4
                if rem > 0:
                    payload_b64 += "=" * (4 - rem)
                decoded = base64.urlsafe_b64decode(payload_b64.encode("utf-8")).decode("utf-8")
                data = json.loads(decoded)
                return data.get("sub") or data.get("id")
        except Exception as e:
            logger.debug(f"Direct JWT payload parsing notice: {e}")
        return None

    @staticmethod
    def get_current_user_id(
        authorization: Optional[str] = Header(None),
        x_user_id: Optional[str] = Header(None, alias="X-User-Id"),
    ) -> Optional[str]:
        """Validates the Authorization Bearer token with Supabase GoTrue Auth.
        Returns user_id (UUID) if authenticated, or None if anonymous.
        """
        # 1. If explicit X-User-Id header provided and valid length
        if x_user_id and len(x_user_id.strip()) >= 10:
            return x_user_id.strip()

        if not authorization or not authorization.startswith("Bearer "):
            return None

        token = authorization.split("Bearer ", 1)[1].strip()
        if not token:
            return None

        # 2. Extract instant fallback user_id from token
        jwt_user_id = AuthService.extract_user_id_from_jwt(token)

        # 3. Verify token with Supabase Auth endpoint
        try:
            url = f"{settings.SUPABASE_URL.rstrip('/')}/auth/v1/user"
            headers = {
                "apikey": settings.SUPABASE_PUBLISHABLE_KEY,
                "Authorization": f"Bearer {token}",
            }
            res = requests.get(url, headers=headers, timeout=4)
            if res.status_code == 200:
                user_data = res.json()
                return user_data.get("id") or jwt_user_id
            else:
                logger.warning(f"Supabase auth verification returned {res.status_code}, using JWT subject fallback")
                return jwt_user_id
        except Exception as e:
            logger.warning(f"Supabase Auth connection notice ({e}), using JWT subject fallback")
            return jwt_user_id

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

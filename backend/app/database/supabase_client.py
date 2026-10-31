import json
import logging
from typing import Any, Dict, List, Optional
import requests
from app.core.config import settings

logger = logging.getLogger("cropguard.supabase")


class SupabaseClient:
    """Lightweight and robust client for interacting with Supabase REST and Storage APIs."""

    def __init__(self):
        self.base_url = settings.SUPABASE_URL.rstrip("/")
        self.publishable_key = settings.SUPABASE_PUBLISHABLE_KEY
        self.service_role_key = settings.SUPABASE_SERVICE_ROLE_KEY

    def _get_headers(self, user_token: Optional[str] = None, use_service_role: bool = False) -> Dict[str, str]:
        key = self.service_role_key if (use_service_role and self.service_role_key) else self.publishable_key
        token = user_token if user_token else key

        headers = {
            "apikey": key,
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
            "Prefer": "return=representation"
        }
        return headers

    def get(self, table: str, params: Optional[Dict[str, Any]] = None, user_token: Optional[str] = None) -> List[Dict[str, Any]]:
        url = f"{self.base_url}/rest/v1/{table}"
        headers = self._get_headers(user_token)
        response = requests.get(url, headers=headers, params=params, timeout=15)
        response.raise_for_status()
        return response.json()

    def insert(self, table: str, data: Dict[str, Any], user_token: Optional[str] = None) -> List[Dict[str, Any]]:
        url = f"{self.base_url}/rest/v1/{table}"
        headers = self._get_headers(user_token)
        response = requests.post(url, headers=headers, json=data, timeout=15)
        response.raise_for_status()
        return response.json()

    def update(self, table: str, data: Dict[str, Any], query_params: Dict[str, Any], user_token: Optional[str] = None) -> List[Dict[str, Any]]:
        url = f"{self.base_url}/rest/v1/{table}"
        headers = self._get_headers(user_token)
        response = requests.patch(url, headers=headers, params=query_params, json=data, timeout=15)
        response.raise_for_status()
        return response.json()

    def delete(self, table: str, query_params: Dict[str, Any], user_token: Optional[str] = None) -> List[Dict[str, Any]]:
        url = f"{self.base_url}/rest/v1/{table}"
        headers = self._get_headers(user_token)
        response = requests.delete(url, headers=headers, params=query_params, timeout=15)
        response.raise_for_status()
        return response.json()

    def upload_image(self, bucket: str, path: str, file_bytes: bytes, content_type: str = "image/jpeg", user_token: Optional[str] = None) -> str:
        url = f"{self.base_url}/storage/v1/object/{bucket}/{path}"
        headers = {
            "apikey": self.publishable_key,
            "Authorization": f"Bearer {user_token or self.publishable_key}",
            "Content-Type": content_type
        }
        response = requests.post(url, headers=headers, data=file_bytes, timeout=30)
        response.raise_for_status()
        # Return public URL or path
        return f"{self.base_url}/storage/v1/object/public/{bucket}/{path}"

    def check_health(self) -> Dict[str, Any]:
        url = f"{self.base_url}/auth/v1/health"
        headers = {"apikey": self.publishable_key}
        response = requests.get(url, headers=headers, timeout=5)
        return {
            "status": "healthy" if response.status_code == 200 else "degraded",
            "code": response.status_code,
            "details": response.json() if response.status_code == 200 else response.text
        }


supabase_client = SupabaseClient()

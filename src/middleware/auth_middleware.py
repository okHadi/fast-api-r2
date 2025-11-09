from fastapi import Request, HTTPException, status
from fastapi.security import HTTPBearer
from typing import Optional
from ..utils.settings import settings


security = HTTPBearer()


async def auth_middleware(request: Request) -> Optional[str]:
    """Validate API key from request headers."""
    api_key_header = request.headers.get("X-API-Key")

    if not api_key_header:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing API key header"
        )

    try:
        if api_key_header != settings.api_key:
            print("Invalid API key:", api_key_header)
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid API key"
            )
        return api_key_header

    except ValueError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid API key format"
        )

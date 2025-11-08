from fastapi import Request
from typing import List, Dict, Any


async def get_thumbnails(request: Request) -> Dict[str, Any]:
    return {
        "success": True,
        "message": "Thumbnails retrieved successfully",
        "data": []
    }


async def create_thumbnail(request: Request) -> Dict[str, Any]:
    return {
        "success": True,
        "message": "Thumbnail created successfully",
        "data": None
    }

from .thumbnail_route import thumbnail_router
from typing import List, Tuple
from fastapi import APIRouter, FastAPI
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))


_routes: List[Tuple[str, APIRouter]] = [
    ("/thumbnails", thumbnail_router),
]


def register_routes(app: FastAPI) -> None:
    for path, router in _routes:
        app.include_router(router, prefix=f"/api{path}")

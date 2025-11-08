from ..middleware.auth_middleware import auth_middleware
from ..controllers.thumbnail_controller import get_thumbnails, upload_thumbnails
from fastapi import APIRouter, Depends
import sys
import os

sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))


thumbnail_router = APIRouter()

thumbnail_router.get(
    "/", dependencies=[Depends(auth_middleware)])(get_thumbnails)
thumbnail_router.post(
    "/", dependencies=[Depends(auth_middleware)])(upload_thumbnails)

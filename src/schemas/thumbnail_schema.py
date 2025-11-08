from pydantic import BaseModel
from datetime import datetime


class Thumbnail(BaseModel):
    id: str
    file_key: str
    url: str
    created_at: datetime = datetime.now()
    updated_at: datetime = datetime.now()

    class Config:
        json_schema_extra = {
            "example": {
                "id": "thumbnail_12345",
                "file_key": "file_key_67890",
                "url": "https://example.com/thumbnail.jpg",
                "created_at": "2024-01-01T12:00:00Z",
                "updated_at": "2024-01-01T12:00:00Z"
            }
        }

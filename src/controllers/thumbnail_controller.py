from fastapi import Request, UploadFile, File
from typing import Dict, Any
from ..utils.boto3 import s3
from ..database import database


async def get_thumbnails(request: Request) -> Dict[str, Any]:
    try:
        bucket = s3.Bucket('thumbnails-bucket')

        return {
            "success": True,
            "message": "Thumbnails retrieved successfully",
            "data": []
        }
    except Exception as e:
        return {
            "success": False,
            "message": "Error retrieving thumbnails",
            "data": str(e)
        }

# https://fastapi.tiangolo.com/tutorial/request-files/#multiple-file-uploads


async def upload_thumbnails(files: list[UploadFile]):
    try:
        if files.len == 0:
            return {
                "success": False,
                "message": "No files uploaded",
                "data": None
            }
        bucket = s3.Bucket('thumbnails')
        try:
            for file in files:
                await bucket.upload_fileobj(
                    file.file,
                    file.filename,
                    ExtraArgs={"ContentType": file.content_type}
                )
            return {
                "success": True,
                "message": "Thumbnails uploaded successfully",
                "data": [file.filename for file in files]
            }
        except Exception as e:
            return {
                "success": False,
                "message": "Error uploading files to R2",
                "data": str(e)
            }

    except Exception as e:
        return {
            "success": False,
            "message": "Error uploading thumbnails",
            "data": str(e)
        }

from fastapi import Request, UploadFile, File
from typing import Dict, Any
from ..utils.boto3 import s3
from ..database import database
from ..utils.settings import settings


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
        if len(files) == 0:
            return {
                "success": False,
                "message": "No files uploaded",
                "data": None
            }

        # some validation checks
        for file in files:
            if file.content_type not in ["image/jpeg", "image/png"]:
                return {
                    "success": False,
                    "message": f"Invalid file type: {file.content_type}. Only JPEG and PNG are allowed.",
                    "data": None
                }
            if file.size > 2 * 1024 * 1024:  # 2MB limit
                return {
                    "success": False,
                    "message": f"File size exceeds limit: {file.size}. Max size is 2MB.",
                    "data": None
                }

        print(files)
        bucket = s3.Bucket('thumbnails')
        try:
            conn = await database.pool.acquire()
            transaction = conn.transaction()
            await transaction.start()
            for file in files:
                bucket.upload_fileobj(
                    file.file,
                    file.filename,
                    ExtraArgs={"ContentType": file.content_type}
                )
                query = "INSERT INTO thumbnails (file_key, url, created_at, updated_at) VALUES ($1, $2, NOW(), NOW())"
                await conn.execute(query, file.filename, f"https://{settings.r2_endpoint_url}/thumbnails/{file.filename}")
            await transaction.commit()
            await database.pool.release(conn)
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

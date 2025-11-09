from fastapi import Request, UploadFile, File
from typing import Dict, Any
from ..utils.boto3 import get_s3_client
from ..database import database
from ..utils.settings import settings


async def get_thumbnails(request: Request) -> Dict[str, Any]:
    try:
        conn = await database.pool.acquire()
        try:
            query = "SELECT id, file_key, url, created_at, updated_at FROM thumbnails ORDER BY created_at DESC LIMIT $1"
            rows = await conn.fetch(query, request.query_params.get("limit", 100))

            thumbnails = [
                {
                    "id": row["id"],
                    "file_key": row["file_key"],
                    "url": row["url"],
                    "created_at": row["created_at"].isoformat(),
                    "updated_at": row["updated_at"].isoformat()
                }
                for row in rows
            ]

            return {
                "success": True,
                "message": "Thumbnails retrieved successfully",
                "data": thumbnails
            }
        finally:
            await database.pool.release(conn)

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
            if file.content_type not in ["image/jpeg", "image/png", "image/jpg", "image/webp"]:
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

        async with get_s3_client() as s3:
            try:
                conn = await database.pool.acquire()
                transaction = conn.transaction()
                await transaction.start()

                for file in files:
                    file_content = await file.read()

                    await s3.put_object(
                        Bucket="thumbnails",
                        Key=file.filename,
                        Body=file_content,
                        ContentType=file.content_type
                    )

                    # upsert
                    query = """
                        INSERT INTO thumbnails (file_key, url, created_at, updated_at) 
                        VALUES ($1, $2, NOW(), NOW())
                        ON CONFLICT (file_key) 
                        DO UPDATE SET updated_at = NOW()
                    """
                    await conn.execute(query, file.filename, f"https://{settings.r2_endpoint_url}/thumbnails/{file.filename}")

                await transaction.commit()
                await database.pool.release(conn)

                return {
                    "success": True,
                    "message": "Thumbnails uploaded successfully",
                    "data": [file.filename for file in files]
                }
            except Exception as e:
                await transaction.rollback()
                await database.pool.release(conn)
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

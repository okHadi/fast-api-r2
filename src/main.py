import datetime
from fastapi import FastAPI
from contextlib import asynccontextmanager
from .database import database
from .routers.routes import register_routes
import uvicorn


@asynccontextmanager
async def lifespan(app: FastAPI):
    await database.connect()
    yield
    await database.disconnect()


app = FastAPI(
    title="R2 Uploader",
    description="Application for uploading files to R2 storage",
    version="1.0.0",
    lifespan=lifespan
)

register_routes(app)


@app.get("/health", status_code=200, description="Simple health check endpoint")
def health_check():
    return {"success": True, "message": "Service is healthy"}


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)

# https://fastapi.tiangolo.com/advanced/settings/#settings-in-another-module

from pydantic_settings import BaseSettings
import os
# https://pypi.org/project/python-dotenv/
from dotenv import load_dotenv
load_dotenv()


class Settings(BaseSettings):
    database_url: str = os.environ.get(
        "DATABASE_URL", "postgresql://user:password@localhost:5432/mydatabase")
    api_key: str = os.environ.get("API_KEY", "default_api_key")
    r2_endpoint_url: str = os.environ.get(
        "R2_ENDPOINT_URL", "https://example.r2.cloudflarestorage.com")
    r2_access_key_id: str = os.environ.get(
        "R2_ACCESS_KEY_ID", "your_access_key_id")
    r2_secret_access_key: str = os.environ.get(
        "R2_SECRET_ACCESS_KEY", "your_secret_access_key")


settings = Settings()

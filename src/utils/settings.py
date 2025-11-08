# https://fastapi.tiangolo.com/advanced/settings/#settings-in-another-module

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql://user:password@localhost:5432/mydatabase"


settings = Settings()

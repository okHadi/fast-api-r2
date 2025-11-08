# https://fastapi.tiangolo.com/advanced/settings/#settings-in-another-module

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    # make sure to have these defined as environment variables or in a .env file
    database_url: str = "postgresql://postgres:postgres@localhost:5432/coupons_db"
    api_key: str = "secret_api_key"


settings = Settings()

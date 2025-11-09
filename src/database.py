# https://www.sheshbabu.com/posts/fastapi-without-orm-getting-started-with-asyncpg/
import asyncpg
from .utils.settings import settings


DATABASE_URL = settings.database_url


class Database:
    def __init__(self, database_url: str):
        self.database_url = database_url

    async def connect(self):
        self.pool = await asyncpg.create_pool(self.database_url)

    # create the thumbnails table
    async def create_tables(self):
        async with self.pool.acquire() as conn:
            await conn.execute("""
            CREATE TABLE IF NOT EXISTS thumbnails (
                id SERIAL PRIMARY KEY,
                file_key TEXT NOT NULL UNIQUE,
                url TEXT NOT NULL,
                created_at TIMESTAMP DEFAULT NOW(),
                updated_at TIMESTAMP DEFAULT NOW()
            );
            """)

    async def disconnect(self):
        self.pool.close()


database = Database(DATABASE_URL)

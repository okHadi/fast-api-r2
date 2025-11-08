# https://www.sheshbabu.com/posts/fastapi-without-orm-getting-started-with-asyncpg/
import asyncpg
from utils.settings import settings


DATABASE_URL = settings.database_url


class Database:
    def __init__(self, database_url: str):
        self.database_url = database_url

    async def connect(self):
        self.pool = await asyncpg.create_pool(self.database_url)

    async def disconnect(self):
        self.pool.close()


database = Database(DATABASE_URL)

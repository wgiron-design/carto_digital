import asyncio
from app.database import init_db, close_db, get_db_pool

async def test():
    await init_db()
    pool = await get_db_pool()
    async with pool.acquire() as conn:
        users = await conn.fetch("SELECT * FROM users;")
        print(f"[TEST DB] Conexión exitosa. Usuarios en BD: {len(users)}")
    await close_db()

if __name__ == "__main__":
    asyncio.run(test())

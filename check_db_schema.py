import asyncio
import asyncpg
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent / 'backend_python'))
from app.config import DATABASE_URL

async def check_schema():
    db_url = DATABASE_URL.split('?')[0] if 'sslmode=' in DATABASE_URL else DATABASE_URL
    conn = await asyncpg.connect(dsn=db_url, ssl='require')
    
    tables = ['estructuras', 'niveles', 'locales', 'hogares']
    for t in tables:
        rows = await conn.fetch("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = $1", t)
        cols = [f"{r['column_name']} ({r['data_type']})" for r in rows]
        print(f"=== TABLA: {t} ===")
        print(", ".join(cols))
        print()

    await conn.close()

if __name__ == '__main__':
    asyncio.run(check_schema())

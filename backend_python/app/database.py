import os
import asyncpg
from fastapi import HTTPException, status
from app.config import DATABASE_URL

pool: asyncpg.Pool | None = None

async def init_db():
    global pool
    if pool is not None and not pool._closed:
        return pool

    db_url = DATABASE_URL
    if "sslmode=" in db_url:
        db_url = db_url.split("?")[0]
    
    try:
        pool = await asyncpg.create_pool(
            dsn=db_url,
            ssl="require",
            min_size=1,
            max_size=10,
            max_inactive_connection_lifetime=300,
            command_timeout=30
        )
        print("[DB] Pool de conexiones PostgreSQL/Neon iniciado correctamente.")
    except Exception as e:
        print(f"[DB ERROR] Error iniciando pool de PostgreSQL: {e}")
        pool = None
        raise e

    # Verificar e inicializar esquemas si es necesario
    try:
        async with pool.acquire() as conn:
            table_exists = await conn.fetchval("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = 'capas_registro'
                );
            """)
            if not table_exists:
                sql_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "sql", "001_create_postgis_schema.sql")
                if os.path.exists(sql_path):
                    with open(sql_path, "r", encoding="utf-8") as f:
                        sql = f.read()
                    await conn.execute(sql)
                    print("[DB] Esquema PostGIS inicializado automáticamente.")

            users_exists = await conn.fetchval("""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = 'users'
                );
            """)
            if not users_exists:
                auth_sql_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "sql", "002_create_auth_schema.sql")
                if os.path.exists(auth_sql_path):
                    with open(auth_sql_path, "r", encoding="utf-8") as f:
                        sql = f.read()
                    await conn.execute(sql)
                    print("[DB] Esquema de Autenticación inicializado automáticamente.")
    except Exception as e:
        print(f"[DB ERROR] Error verificando esquemas de BD: {e}")

async def close_db():
    global pool
    if pool and not pool._closed:
        await pool.close()
        pool = None
        print("[DB] Pool de conexiones cerrado.")

async def get_db_pool() -> asyncpg.Pool:
    global pool
    if pool is None or pool._closed:
        try:
            await init_db()
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"No se pudo establecer conexión con la base de datos PostgreSQL: {str(e)}"
            )
    return pool

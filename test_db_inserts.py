import asyncio
import asyncpg
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent / 'backend_python'))
from app.config import DATABASE_URL

async def test_insert():
    db_url = DATABASE_URL.split('?')[0] if 'sslmode=' in DATABASE_URL else DATABASE_URL
    conn = await asyncpg.connect(dsn=db_url, ssl='require')
    
    est_id = await conn.fetchval("SELECT id FROM estructuras LIMIT 1")
    print("Estructura ID:", est_id)
    
    niv_id = await conn.fetchval(
        "INSERT INTO niveles (estructura_id, numero, numero_locales, descripcion) VALUES ($1, 999, 2, $2) RETURNING id",
        est_id, "Piso de prueba"
    )
    print("Nivel insertado ID:", niv_id)
    
    loc_id = await conn.fetchval(
        "INSERT INTO locales (nivel_id, nombre, uso_actual, descripcion) VALUES ($1, $2, $3, $4) RETURNING id",
        niv_id, "Local 1", "Comercial", "Tienda de conveniencia"
    )
    print("Local insertado ID:", loc_id)
    
    await conn.execute("DELETE FROM niveles WHERE id = $1", niv_id)
    print("Limpieza realizada con éxito")
    
    await conn.close()

if __name__ == '__main__':
    asyncio.run(test_insert())

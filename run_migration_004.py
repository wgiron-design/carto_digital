"""
Script para ejecutar la migración 004 en la base de datos Neon PostgreSQL.
"""
import asyncio
import asyncpg
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent / 'backend_python'))
from app.config import DATABASE_URL

STATEMENTS = [
    "ALTER TABLE niveles ADD COLUMN IF NOT EXISTS descripcion VARCHAR(50) NULL",
    "ALTER TABLE niveles ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL",
    "ALTER TABLE niveles ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES users(id) ON DELETE SET NULL",
    "ALTER TABLE niveles ADD COLUMN IF NOT EXISTS sync_version INTEGER NOT NULL DEFAULT 0",
    "CREATE INDEX IF NOT EXISTS idx_niveles_estructura_id ON niveles (estructura_id)",
    "CREATE INDEX IF NOT EXISTS idx_niveles_updated_at ON niveles (updated_at)",
]

async def run_migration():
    db_url = DATABASE_URL
    if 'sslmode=' in db_url:
        db_url = db_url.split('?')[0]

    print("=" * 60)
    print(" EJECUTANDO MIGRACIÓN 004 (Niveles)")
    print("=" * 60)

    try:
        conn = await asyncpg.connect(dsn=db_url, ssl='require')
    except Exception as e:
        print(f"[ERROR] No se pudo conectar a la BD: {e}")
        return

    ok, skipped = 0, 0
    try:
        for i, stmt in enumerate(STATEMENTS, 1):
            try:
                await conn.execute(stmt)
                short = ' '.join(stmt.split()[:7])
                print(f"[OK]   {i:02d}. {short}...")
                ok += 1
            except Exception as e:
                short = ' '.join(stmt.split()[:7])
                print(f"[SKIP] {i:02d}. {short} → {e}")
                skipped += 1
        
        # Unique constraint separado
        try:
            await conn.execute("ALTER TABLE niveles ADD CONSTRAINT uq_niveles_estructura_numero UNIQUE (estructura_id, numero)")
            print("[OK]   Constraint uq_niveles_estructura_numero agregada.")
            ok += 1
        except Exception as e:
            print(f"[SKIP] Constraint uq_niveles_estructura_numero → {e}")
            skipped += 1

    finally:
        await conn.close()

    print(f"\n[RESULTADO] OK={ok} | Omitidos={skipped}")
    print("[EXITO] Migración 004 finalizada.")
    print("=" * 60)

if __name__ == '__main__':
    asyncio.run(run_migration())

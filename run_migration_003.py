"""
Script para ejecutar la migración 003 directamente sobre Neon PostgreSQL.
Ejecuta cada ALTER TABLE por separado para evitar fallos en bloque.
"""
import asyncio
import asyncpg
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent / 'backend_python'))
from app.config import DATABASE_URL

STATEMENTS = [
    # estructuras
    "ALTER TABLE estructuras ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL",
    "ALTER TABLE estructuras ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES users(id) ON DELETE SET NULL",
    "ALTER TABLE estructuras ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ NULL",
    "ALTER TABLE estructuras ADD COLUMN IF NOT EXISTS device_id VARCHAR(100) NULL",
    "ALTER TABLE estructuras ADD COLUMN IF NOT EXISTS sync_version INTEGER NOT NULL DEFAULT 0",
    # caminos
    "ALTER TABLE caminos ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL",
    "ALTER TABLE caminos ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES users(id) ON DELETE SET NULL",
    "ALTER TABLE caminos ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ NULL",
    "ALTER TABLE caminos ADD COLUMN IF NOT EXISTS device_id VARCHAR(100) NULL",
    "ALTER TABLE caminos ADD COLUMN IF NOT EXISTS sync_version INTEGER NOT NULL DEFAULT 0",
    # upms
    "ALTER TABLE upms ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES users(id) ON DELETE SET NULL",
    "ALTER TABLE upms ADD COLUMN IF NOT EXISTS updated_by UUID REFERENCES users(id) ON DELETE SET NULL",
    "ALTER TABLE upms ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ NULL",
    "ALTER TABLE upms ADD COLUMN IF NOT EXISTS device_id VARCHAR(100) NULL",
    "ALTER TABLE upms ADD COLUMN IF NOT EXISTS sync_version INTEGER NOT NULL DEFAULT 0",
    # Índices updated_at
    "CREATE INDEX IF NOT EXISTS idx_estructuras_updated_at ON estructuras (updated_at)",
    "CREATE INDEX IF NOT EXISTS idx_caminos_updated_at ON caminos (updated_at)",
    "CREATE INDEX IF NOT EXISTS idx_upms_updated_at ON upms (updated_at)",
]

async def run_migration():
    db_url = DATABASE_URL
    if 'sslmode=' in db_url:
        db_url = db_url.split('?')[0]

    print("=" * 60)
    print(" EJECUTANDO MIGRACIÓN 003 (Sentencias Individuales)")
    print("=" * 60)

    conn = await asyncpg.connect(dsn=db_url, ssl='require')
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
    finally:
        await conn.close()

    print(f"\n[RESULTADO] OK={ok} | Omitidos={skipped}")
    print("[EXITO] Migración 003 finalizada.")
    print("=" * 60)

if __name__ == '__main__':
    asyncio.run(run_migration())

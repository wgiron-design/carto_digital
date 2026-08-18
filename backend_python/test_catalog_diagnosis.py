import asyncio
import sys
sys.stdout.reconfigure(encoding='utf-8')
from app.database import init_db, close_db, get_db_pool

async def diag():
    await init_db()
    pool = await get_db_pool()
    async with pool.acquire() as conn:
        for tabla in ['cat_locales_tipo', 'cat_locales_condicion', 'cat_hogares_idioma', 'cat_sexo']:
            print(f'\n=== {tabla} ===')
            cols = await conn.fetch(
                "SELECT column_name, data_type, is_nullable "
                "FROM information_schema.columns "
                "WHERE table_name=$1 AND table_schema='public' "
                "ORDER BY ordinal_position",
                tabla
            )
            for c in cols:
                n = 'NULL' if c['is_nullable'] == 'YES' else 'NOT NULL'
                print(f"  {c['column_name']:30s} {c['data_type']:20s} {n}")
            rows = await conn.fetch(f'SELECT * FROM {tabla} ORDER BY id ASC LIMIT 30')
            print(f'  DATOS ({len(rows)} filas):')
            for r in rows:
                print(f'    {dict(r)}')

        print('\n=== locales: columnas y FKs ===')
        cols = await conn.fetch(
            "SELECT column_name, data_type, is_nullable "
            "FROM information_schema.columns "
            "WHERE table_name='locales' AND table_schema='public' "
            "ORDER BY ordinal_position"
        )
        for c in cols:
            n = 'NULL' if c['is_nullable'] == 'YES' else 'NOT NULL'
            print(f"  {c['column_name']:30s} {c['data_type']:20s} {n}")
        fks = await conn.fetch(
            "SELECT kcu.column_name, ccu.table_name AS ft, ccu.column_name AS fc "
            "FROM information_schema.table_constraints tc "
            "JOIN information_schema.key_column_usage kcu "
            "  ON tc.constraint_name=kcu.constraint_name AND tc.table_schema=kcu.table_schema "
            "JOIN information_schema.constraint_column_usage ccu "
            "  ON tc.constraint_name=ccu.constraint_name AND tc.table_schema=ccu.table_schema "
            "WHERE tc.table_name='locales' AND tc.table_schema='public' AND tc.constraint_type='FOREIGN KEY'"
        )
        for f in fks:
            print(f"  FK: {f['column_name']} -> {f['ft']}.{f['fc']}")

        print('\n=== hogares: columnas y FKs ===')
        cols = await conn.fetch(
            "SELECT column_name, data_type, is_nullable "
            "FROM information_schema.columns "
            "WHERE table_name='hogares' AND table_schema='public' "
            "ORDER BY ordinal_position"
        )
        for c in cols:
            n = 'NULL' if c['is_nullable'] == 'YES' else 'NOT NULL'
            print(f"  {c['column_name']:30s} {c['data_type']:20s} {n}")
        fks = await conn.fetch(
            "SELECT kcu.column_name, ccu.table_name AS ft, ccu.column_name AS fc "
            "FROM information_schema.table_constraints tc "
            "JOIN information_schema.key_column_usage kcu "
            "  ON tc.constraint_name=kcu.constraint_name AND tc.table_schema=kcu.table_schema "
            "JOIN information_schema.constraint_column_usage ccu "
            "  ON tc.constraint_name=ccu.constraint_name AND tc.table_schema=ccu.table_schema "
            "WHERE tc.table_name='hogares' AND tc.table_schema='public' AND tc.constraint_type='FOREIGN KEY'"
        )
        for f in fks:
            print(f"  FK: {f['column_name']} -> {f['ft']}.{f['fc']}")

    await close_db()
    print('\n[OK] Diagnostico completado.')

asyncio.run(diag())

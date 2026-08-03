import json
from fastapi import APIRouter, HTTPException
from typing import Dict, Any, List
from app.database import get_db_pool

router = APIRouter(prefix="/api/sync", tags=["Sincronizacion Offline"])

@router.post("")
async def batch_sync(payload: Dict[str, Any]):
    pool = await get_db_pool()
    puntos: List[Dict[str, Any]] = payload.get("puntos", [])
    lineas: List[Dict[str, Any]] = payload.get("lineas", [])
    poligonos: List[Dict[str, Any]] = payload.get("poligonos", [])

    synced_ids = {"puntos": [], "lineas": [], "poligonos": []}

    async with pool.acquire() as conn:
        async with conn.transaction():
            # Sync Puntos
            for p in puntos:
                fid = p.get("id")
                geom = p.get("geometry")
                props = p.get("properties", {})
                if fid and geom:
                    geom_json = json.dumps(geom)
                    await conn.execute("""
                        INSERT INTO estructuras (id, geom, nombre, notas, categoria, tipo_formal, tipo_referencia, estado, niveles_cantidad, sync_dirty, updated_at)
                        VALUES ($1::uuid, ST_GeomFromGeoJSON($2), $3, $4, $5, $6, $7, $8, $9, false, NOW())
                        ON CONFLICT (id) DO UPDATE SET
                            geom = EXCLUDED.geom,
                            nombre = EXCLUDED.nombre,
                            notas = EXCLUDED.notas,
                            categoria = EXCLUDED.categoria,
                            tipo_formal = EXCLUDED.tipo_formal,
                            tipo_referencia = EXCLUDED.tipo_referencia,
                            estado = EXCLUDED.estado,
                            niveles_cantidad = EXCLUDED.niveles_cantidad,
                            sync_dirty = false,
                            updated_at = NOW();
                    """, fid, geom_json, props.get("nombre"), props.get("notas"), props.get("categoria"), props.get("tipo_formal"), props.get("tipo_referencia"), props.get("estado"), props.get("niveles_cantidad", 1))
                    synced_ids["puntos"].append(fid)

            # Sync Caminos
            for l in lineas:
                fid = l.get("id")
                geom = l.get("geometry")
                props = l.get("properties", {})
                if fid and geom:
                    geom_json = json.dumps(geom)
                    await conn.execute("""
                        INSERT INTO caminos (id, geom, nombre, tipo, notas, sync_dirty, updated_at)
                        VALUES ($1::uuid, ST_GeomFromGeoJSON($2), $3, $4, $5, false, NOW())
                        ON CONFLICT (id) DO UPDATE SET
                            geom = EXCLUDED.geom,
                            nombre = EXCLUDED.nombre,
                            tipo = EXCLUDED.tipo,
                            notas = EXCLUDED.notas,
                            sync_dirty = false,
                            updated_at = NOW();
                    """, fid, geom_json, props.get("nombre"), props.get("tipo"), props.get("notas"))
                    synced_ids["lineas"].append(fid)

            # Sync Poligonos
            for pol in poligonos:
                fid = pol.get("id")
                geom = pol.get("geometry")
                props = pol.get("properties", {})
                if fid and geom:
                    geom_json = json.dumps(geom)
                    await conn.execute("""
                        INSERT INTO upms (id, geom, nombre, codigo_upm, notas, sync_dirty, updated_at)
                        VALUES ($1::uuid, ST_GeomFromGeoJSON($2), $3, $4, $5, false, NOW())
                        ON CONFLICT (id) DO UPDATE SET
                            geom = EXCLUDED.geom,
                            nombre = EXCLUDED.nombre,
                            codigo_upm = EXCLUDED.codigo_upm,
                            notas = EXCLUDED.notas,
                            sync_dirty = false,
                            updated_at = NOW();
                    """, fid, geom_json, props.get("nombre"), props.get("codigo_upm"), props.get("notas"))
                    synced_ids["poligonos"].append(fid)

    return {"status": "ok", "synced": synced_ids}

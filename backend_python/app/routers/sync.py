import json
from fastapi import APIRouter, HTTPException
from typing import Any, Dict, List, Optional
from app.database import get_db_pool
from app.schemas.feature import SyncBatchPayload, SyncResult, SyncedItem

router = APIRouter(prefix="/api/sync", tags=["Sincronizacion Offline"])


@router.post("", response_model=SyncResult)
async def batch_sync(payload: SyncBatchPayload):
    """
    Sincronización por lotes (offline-first).
    Acepta puntos, líneas y polígonos pendientes del dispositivo.
    Incluye user_id y device_id para auditoría.
    Retorna los id, sync_version y updated_at de cada registro sincronizado.
    """
    pool = await get_db_pool()

    user_id   = payload.user_id or None
    device_id = payload.device_id or None

    result: Dict[str, List[SyncedItem]] = {
        "puntos": [],
        "lineas": [],
        "poligonos": [],
    }

    async with pool.acquire() as conn:
        async with conn.transaction():
            # ── Sync Puntos (estructuras) ─────────────────────────────────────
            for p in payload.puntos:
                fid  = p.id
                geom = p.geometry
                props = p.properties
                if not geom:
                    continue
                geom_json = json.dumps(geom)
                row = await conn.fetchrow("""
                    INSERT INTO estructuras (
                        id, geom, nombre, notas, categoria,
                        tipo_formal, tipo_referencia, estado, niveles_cantidad,
                        created_by, updated_by, device_id, sync_version,
                        sync_dirty, updated_at
                    )
                    VALUES (
                        COALESCE($1::uuid, uuid_generate_v4()),
                        ST_GeomFromGeoJSON($2), $3, $4, $5, $6, $7, $8, $9,
                        $10::uuid, $10::uuid, $11, 0, false, NOW()
                    )
                    ON CONFLICT (id) DO UPDATE SET
                        geom = EXCLUDED.geom,
                        nombre = EXCLUDED.nombre,
                        notas = EXCLUDED.notas,
                        categoria = EXCLUDED.categoria,
                        tipo_formal = EXCLUDED.tipo_formal,
                        tipo_referencia = EXCLUDED.tipo_referencia,
                        estado = EXCLUDED.estado,
                        niveles_cantidad = EXCLUDED.niveles_cantidad,
                        updated_by = $10::uuid,
                        device_id = $11,
                        sync_version = estructuras.sync_version + 1,
                        sync_dirty = false,
                        updated_at = NOW(),
                        deleted_at = NULL
                    RETURNING id::text, sync_version, updated_at
                """,
                fid, geom_json,
                props.get("nombre"), props.get("notas"), props.get("categoria"),
                props.get("tipo_formal"), props.get("tipo_referencia"),
                props.get("estado"), props.get("niveles_cantidad", 1),
                user_id, device_id)

                if row:
                    result["puntos"].append(SyncedItem(
                        id=row['id'],
                        sync_version=row['sync_version'],
                        updated_at=row['updated_at'],
                    ))

            # ── Sync Líneas (caminos) ─────────────────────────────────────────
            for l in payload.lineas:
                fid  = l.id
                geom = l.geometry
                props = l.properties
                if not geom:
                    continue
                geom_json = json.dumps(geom)
                row = await conn.fetchrow("""
                    INSERT INTO caminos (
                        id, geom, nombre, tipo, notas,
                        created_by, updated_by, device_id, sync_version,
                        sync_dirty, updated_at
                    )
                    VALUES (
                        COALESCE($1::uuid, uuid_generate_v4()),
                        ST_GeomFromGeoJSON($2), $3, $4, $5,
                        $6::uuid, $6::uuid, $7, 0, false, NOW()
                    )
                    ON CONFLICT (id) DO UPDATE SET
                        geom = EXCLUDED.geom,
                        nombre = EXCLUDED.nombre,
                        tipo = EXCLUDED.tipo,
                        notas = EXCLUDED.notas,
                        updated_by = $6::uuid,
                        device_id = $7,
                        sync_version = caminos.sync_version + 1,
                        sync_dirty = false,
                        updated_at = NOW(),
                        deleted_at = NULL
                    RETURNING id::text, sync_version, updated_at
                """,
                fid, geom_json,
                props.get("nombre"), props.get("tipo"), props.get("notas"),
                user_id, device_id)

                if row:
                    result["lineas"].append(SyncedItem(
                        id=row['id'],
                        sync_version=row['sync_version'],
                        updated_at=row['updated_at'],
                    ))

            # ── Sync Polígonos (upms) ─────────────────────────────────────────
            for pol in payload.poligonos:
                fid  = pol.id
                geom = pol.geometry
                props = pol.properties
                if not geom:
                    continue
                geom_json = json.dumps(geom)
                row = await conn.fetchrow("""
                    INSERT INTO upms (
                        id, geom, nombre, codigo_upm, notas,
                        created_by, updated_by, device_id, sync_version,
                        sync_dirty, updated_at
                    )
                    VALUES (
                        COALESCE($1::uuid, uuid_generate_v4()),
                        ST_GeomFromGeoJSON($2), $3, $4, $5,
                        $6::uuid, $6::uuid, $7, 0, false, NOW()
                    )
                    ON CONFLICT (id) DO UPDATE SET
                        geom = EXCLUDED.geom,
                        nombre = EXCLUDED.nombre,
                        codigo_upm = EXCLUDED.codigo_upm,
                        notas = EXCLUDED.notas,
                        updated_by = $6::uuid,
                        device_id = $7,
                        sync_version = upms.sync_version + 1,
                        sync_dirty = false,
                        updated_at = NOW(),
                        deleted_at = NULL
                    RETURNING id::text, sync_version, updated_at
                """,
                fid, geom_json,
                props.get("nombre"), props.get("codigo_upm"), props.get("notas"),
                user_id, device_id)

                if row:
                    result["poligonos"].append(SyncedItem(
                        id=row['id'],
                        sync_version=row['sync_version'],
                        updated_at=row['updated_at'],
                    ))

    return SyncResult(status="ok", synced=result)

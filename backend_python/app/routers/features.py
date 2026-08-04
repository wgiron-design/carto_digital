import json
from fastapi import APIRouter, HTTPException, Query
from typing import Optional, Dict, Any
from datetime import datetime
from app.database import get_db_pool

router = APIRouter(prefix="/api/capas", tags=["Geometrias GeoJSON"])

TABLAS_PERMITIDAS = {"estructuras", "caminos", "upms"}


@router.get("/{tabla}/features")
async def get_features(tabla: str, bbox: Optional[str] = None):
    """Retorna features activos (excluye soft-deleted) como GeoJSON FeatureCollection."""
    if tabla not in TABLAS_PERMITIDAS:
        raise HTTPException(status_code=400, detail="Tabla no autorizada")

    pool = await get_db_pool()
    async with pool.acquire() as conn:
        where_parts = ["deleted_at IS NULL"]
        args = []
        arg_idx = 1

        if bbox:
            try:
                parts = [float(x) for x in bbox.split(",")]
                if len(parts) == 4:
                    where_parts.append(
                        f"ST_Intersects(geom, ST_MakeEnvelope(${arg_idx}, ${arg_idx+1}, ${arg_idx+2}, ${arg_idx+3}, 4326))"
                    )
                    args.extend(parts)
                    arg_idx += 4
            except Exception:
                pass

        where_clause = "WHERE " + " AND ".join(where_parts)

        sql = f"""
        SELECT json_build_object(
            'type', 'FeatureCollection',
            'features', COALESCE(json_agg(
                json_build_object(
                    'type', 'Feature',
                    'id', id::text,
                    'geometry', ST_AsGeoJSON(geom)::json,
                    'properties', to_jsonb(t.*) - 'geom'
                )
            ), '[]'::json)
        ) AS geojson
        FROM {tabla} t {where_clause};
        """
        row = await conn.fetchrow(sql, *args)
        return json.loads(row['geojson'])


@router.get("/{tabla}/features/changes")
async def get_changes(
    tabla: str,
    since: str = Query(..., description="ISO 8601 timestamp. Retorna registros modificados o eliminados desde esta fecha.")
):
    """
    Delta-sync: retorna todos los registros (activos y soft-deleted) modificados desde `since`.
    La app usa esto para sincronizar cambios del servidor hacia el dispositivo.
    """
    if tabla not in TABLAS_PERMITIDAS:
        raise HTTPException(status_code=400, detail="Tabla no autorizada")

    try:
        since_dt = datetime.fromisoformat(since.replace("Z", "+00:00"))
    except ValueError:
        raise HTTPException(status_code=400, detail="Formato de fecha inválido. Use ISO 8601 (ej: 2026-08-01T00:00:00Z)")

    pool = await get_db_pool()
    async with pool.acquire() as conn:
        sql = f"""
        SELECT json_build_object(
            'type', 'FeatureCollection',
            'features', COALESCE(json_agg(
                json_build_object(
                    'type', 'Feature',
                    'id', id::text,
                    'geometry', CASE WHEN deleted_at IS NULL THEN ST_AsGeoJSON(geom)::json ELSE NULL END,
                    'properties', to_jsonb(t.*) - 'geom',
                    'deleted', (deleted_at IS NOT NULL)
                )
            ), '[]'::json)
        ) AS geojson
        FROM {tabla} t
        WHERE updated_at > $1;
        """
        row = await conn.fetchrow(sql, since_dt)
        return json.loads(row['geojson'])


@router.get("/{tabla}/count")
async def get_count(tabla: str):
    """Retorna el conteo de features activos."""
    if tabla not in TABLAS_PERMITIDAS:
        raise HTTPException(status_code=400, detail="Tabla no autorizada")

    pool = await get_db_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(f"SELECT COUNT(*) as count FROM {tabla} WHERE deleted_at IS NULL;")
        return {"count": row['count']}


@router.post("/{tabla}/features")
async def create_feature(tabla: str, payload: Dict[str, Any]):
    """
    Crea o actualiza un feature. Si se provee `id`, hace UPSERT.
    Acepta `created_by`, `updated_by` y `device_id` en `properties`.
    """
    if tabla not in TABLAS_PERMITIDAS:
        raise HTTPException(status_code=400, detail="Tabla no autorizada")

    geometry = payload.get("geometry")
    properties = payload.get("properties", {})
    feature_id = payload.get("id")

    if not geometry:
        raise HTTPException(status_code=400, detail="Geometría requerida")

    geom_json = json.dumps(geometry)
    created_by = properties.get("created_by") or None
    updated_by = properties.get("updated_by") or None
    device_id  = properties.get("device_id") or None

    pool = await get_db_pool()

    async with pool.acquire() as conn:
        if tabla == "estructuras":
            sql = """
            INSERT INTO estructuras (
                id, geom, nombre, notas, categoria, tipo_formal, tipo_referencia,
                estado, niveles_cantidad, created_by, updated_by, device_id, sync_version
            )
            VALUES (
                COALESCE($1::uuid, uuid_generate_v4()), ST_GeomFromGeoJSON($2),
                $3, $4, $5, $6, $7, $8, $9,
                $10::uuid, $11::uuid, $12, 0
            )
            ON CONFLICT (id) DO UPDATE SET
                geom = ST_GeomFromGeoJSON($2),
                nombre = $3, notas = $4, categoria = $5,
                tipo_formal = $6, tipo_referencia = $7, estado = $8,
                niveles_cantidad = $9,
                updated_by = $11::uuid, device_id = $12,
                sync_version = estructuras.sync_version + 1,
                updated_at = NOW(),
                deleted_at = NULL
            RETURNING
                id::text, ST_AsGeoJSON(geom)::json AS geometry,
                nombre, notas, categoria, tipo_formal, tipo_referencia,
                estado, niveles_cantidad, sync_version,
                created_by::text, updated_by::text, device_id;
            """
            row = await conn.fetchrow(
                sql, feature_id, geom_json,
                properties.get("nombre"), properties.get("notas"),
                properties.get("categoria"), properties.get("tipo_formal"),
                properties.get("tipo_referencia"), properties.get("estado"),
                properties.get("niveles_cantidad", 1),
                created_by, updated_by, device_id
            )
        elif tabla == "caminos":
            sql = """
            INSERT INTO caminos (id, geom, nombre, tipo, notas, created_by, updated_by, device_id, sync_version)
            VALUES (COALESCE($1::uuid, uuid_generate_v4()), ST_GeomFromGeoJSON($2), $3, $4, $5, $6::uuid, $7::uuid, $8, 0)
            ON CONFLICT (id) DO UPDATE SET
                geom = ST_GeomFromGeoJSON($2), nombre = $3, tipo = $4, notas = $5,
                updated_by = $7::uuid, device_id = $8,
                sync_version = caminos.sync_version + 1,
                updated_at = NOW(), deleted_at = NULL
            RETURNING id::text, ST_AsGeoJSON(geom)::json AS geometry,
                nombre, tipo, notas, sync_version,
                created_by::text, updated_by::text, device_id;
            """
            row = await conn.fetchrow(
                sql, feature_id, geom_json,
                properties.get("nombre"), properties.get("tipo"), properties.get("notas"),
                created_by, updated_by, device_id
            )
        elif tabla == "upms":
            sql = """
            INSERT INTO upms (id, geom, nombre, codigo_upm, notas, created_by, updated_by, device_id, sync_version)
            VALUES (COALESCE($1::uuid, uuid_generate_v4()), ST_GeomFromGeoJSON($2), $3, $4, $5, $6::uuid, $7::uuid, $8, 0)
            ON CONFLICT (id) DO UPDATE SET
                geom = ST_GeomFromGeoJSON($2), nombre = $3, codigo_upm = $4, notas = $5,
                updated_by = $7::uuid, device_id = $8,
                sync_version = upms.sync_version + 1,
                updated_at = NOW(), deleted_at = NULL
            RETURNING id::text, ST_AsGeoJSON(geom)::json AS geometry,
                nombre, codigo_upm, notas, sync_version,
                created_by::text, updated_by::text, device_id;
            """
            row = await conn.fetchrow(
                sql, feature_id, geom_json,
                properties.get("nombre"), properties.get("codigo_upm"), properties.get("notas"),
                created_by, updated_by, device_id
            )

        res = dict(row)
        geom = json.loads(res.pop("geometry"))
        fid = res.pop("id")
        return {"type": "Feature", "id": fid, "geometry": geom, "properties": res}


@router.delete("/{tabla}/features/{feature_id}")
async def delete_feature(tabla: str, feature_id: str, updated_by: Optional[str] = Query(None)):
    """
    Soft-delete: marca `deleted_at = NOW()` en lugar de borrar físicamente.
    El registro persiste en la BD para sincronización con dispositivos offline.
    """
    if tabla not in TABLAS_PERMITIDAS:
        raise HTTPException(status_code=400, detail="Tabla no autorizada")

    updated_by = updated_by or None
    pool = await get_db_pool()
    async with pool.acquire() as conn:
        sql = f"""
            UPDATE {tabla}
            SET deleted_at = NOW(),
                updated_at = NOW(),
                updated_by = $2::uuid,
                sync_version = {tabla}.sync_version + 1
            WHERE id = $1::uuid AND deleted_at IS NULL
            RETURNING id::text, deleted_at
        """
        row = await conn.fetchrow(sql, feature_id, updated_by)
        if not row:
            raise HTTPException(status_code=404, detail="Elemento no encontrado o ya eliminado")
        return {
            "ok": True,
            "deleted_id": row['id'],
            "deleted_at": row['deleted_at'].isoformat()
        }

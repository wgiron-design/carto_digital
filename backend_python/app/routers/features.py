import json
from fastapi import APIRouter, HTTPException, Query
from typing import Optional, Dict, Any
from app.database import get_db_pool

router = APIRouter(prefix="/api/capas", tags=["Geometrias GeoJSON"])

TABLAS_PERMITIDAS = {"estructuras", "caminos", "upms"}

@router.get("/{tabla}/features")
async def get_features(tabla: str, bbox: Optional[str] = None):
    if tabla not in TABLAS_PERMITIDAS:
        raise HTTPException(status_code=400, detail="Tabla no autorizada")

    pool = await get_db_pool()
    async with pool.acquire() as conn:
        where_clause = ""
        args = []
        if bbox:
            try:
                parts = [float(x) for x in bbox.split(",")]
                if len(parts) == 4:
                    where_clause = "WHERE ST_Intersects(geom, ST_MakeEnvelope($1, $2, $3, $4, 4326))"
                    args = parts
            except Exception:
                pass

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

@router.get("/{tabla}/count")
async def get_count(tabla: str):
    if tabla not in TABLAS_PERMITIDAS:
        raise HTTPException(status_code=400, detail="Tabla no autorizada")

    pool = await get_db_pool()
    async with pool.acquire() as conn:
        row = await conn.fetchrow(f"SELECT COUNT(*) as count FROM {tabla};")
        return {"count": row['count']}


@router.post("/{tabla}/features")
async def create_feature(tabla: str, payload: Dict[str, Any]):
    if tabla not in TABLAS_PERMITIDAS:
        raise HTTPException(status_code=400, detail="Tabla no autorizada")

    geometry = payload.get("geometry")
    properties = payload.get("properties", {})
    feature_id = payload.get("id")

    if not geometry:
        raise HTTPException(status_code=400, detail="Geometría requerida")

    geom_json = json.dumps(geometry)
    pool = await get_db_pool()

    async with pool.acquire() as conn:
        if tabla == "estructuras":
            sql = """
            INSERT INTO estructuras (id, geom, nombre, notas, categoria, tipo_formal, tipo_referencia, estado, niveles_cantidad)
            VALUES (COALESCE($1::uuid, uuid_generate_v4()), ST_GeomFromGeoJSON($2), $3, $4, $5, $6, $7, $8, $9)
            ON CONFLICT (id) DO UPDATE SET
                geom = ST_GeomFromGeoJSON($2), nombre = $3, notas = $4,
                categoria = $5, tipo_formal = $6, tipo_referencia = $7,
                estado = $8, niveles_cantidad = $9
            RETURNING id::text, ST_AsGeoJSON(geom)::json AS geometry, nombre, notas, categoria, tipo_formal, tipo_referencia, estado, niveles_cantidad;
            """
            row = await conn.fetchrow(sql, 
                feature_id, geom_json,
                properties.get("nombre"), properties.get("notas"),
                properties.get("categoria"), properties.get("tipo_formal"),
                properties.get("tipo_referencia"), properties.get("estado"),
                properties.get("niveles_cantidad", 1)
            )
        elif tabla == "caminos":
            sql = """
            INSERT INTO caminos (id, geom, nombre, tipo, notas)
            VALUES (COALESCE($1::uuid, uuid_generate_v4()), ST_GeomFromGeoJSON($2), $3, $4, $5)
            ON CONFLICT (id) DO UPDATE SET
                geom = ST_GeomFromGeoJSON($2), nombre = $3, tipo = $4, notas = $5
            RETURNING id::text, ST_AsGeoJSON(geom)::json AS geometry, nombre, tipo, notas;
            """
            row = await conn.fetchrow(sql, feature_id, geom_json, properties.get("nombre"), properties.get("tipo"), properties.get("notas"))
        elif tabla == "upms":
            sql = """
            INSERT INTO upms (id, geom, nombre, codigo_upm, notas)
            VALUES (COALESCE($1::uuid, uuid_generate_v4()), ST_GeomFromGeoJSON($2), $3, $4, $5)
            ON CONFLICT (id) DO UPDATE SET
                geom = ST_GeomFromGeoJSON($2), nombre = $3, codigo_upm = $4, notas = $5
            RETURNING id::text, ST_AsGeoJSON(geom)::json AS geometry, nombre, codigo_upm, notas;
            """
            row = await conn.fetchrow(sql, feature_id, geom_json, properties.get("nombre"), properties.get("codigo_upm"), properties.get("notas"))

        res = dict(row)
        geom = json.loads(res.pop("geometry"))
        fid = res.pop("id")
        return {"type": "Feature", "id": fid, "geometry": geom, "properties": res}


@router.delete("/{tabla}/features/{feature_id}")
async def delete_feature(tabla: str, feature_id: str):
    if tabla not in TABLAS_PERMITIDAS:
        raise HTTPException(status_code=400, detail="Tabla no autorizada")

    pool = await get_db_pool()
    async with pool.acquire() as conn:
        res = await conn.execute(f"DELETE FROM {tabla} WHERE id = $1::uuid", feature_id)
        if res == "DELETE 0":
            raise HTTPException(status_code=404, detail="Elemento no encontrado")
        return {"ok": True, "deleted_id": feature_id}

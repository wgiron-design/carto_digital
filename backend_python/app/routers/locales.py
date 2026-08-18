from fastapi import APIRouter, HTTPException, status
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime
from app.database import get_db_pool
from app.routers.features import parse_uuid_or_none
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/locales", tags=["Locales"])

class LocalCreateSchema(BaseModel):
    nombre_local: Optional[str] = Field(default=None, max_length=100)
    id_tipo: int
    id_condicion_local: Optional[int] = None
    numero_hogares: Optional[int] = Field(default=None, ge=1)
    descripcion: Optional[str] = Field(default=None, max_length=150)

class LocalPatchSchema(BaseModel):
    nombre_local: Optional[str] = Field(default=None, max_length=100)
    id_tipo: Optional[int] = None
    id_condicion_local: Optional[int] = None
    numero_hogares: Optional[int] = Field(default=None, ge=1)
    descripcion: Optional[str] = Field(default=None, max_length=150)


@router.get("/nivel/{nivel_id}")
async def get_locales_by_nivel(nivel_id: str):
    """
    Obtiene la lista de locales pertenecientes a un nivel con detalles de sus catálogos.
    """
    clean_nid = parse_uuid_or_none(nivel_id)
    if not clean_nid:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": "nivel_no_encontrado", "message": "El nivel especificado no existe"}
        )

    pool = await get_db_pool()
    async with pool.acquire() as conn:
        nivel_row = await conn.fetchrow(
            "SELECT id::text, numero, numero_locales FROM niveles WHERE id = $1::uuid",
            clean_nid
        )
        if not nivel_row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail={"error": "nivel_no_encontrado", "message": "El nivel especificado no existe"}
            )

        sql = """
        SELECT 
            l.id::text,
            l.nivel_id::text,
            l.nombre_local,
            l.numero_hogares,
            l.descripcion,
            l.id_tipo,
            t.nombre AS nombre_tipo,
            l.id_condicion_local,
            c.nombre AS nombre_condicion,
            l.updated_at,
            COUNT(DISTINCT h.id)::int AS hogares_registrados
        FROM locales l
        LEFT JOIN cat_locales_tipo t ON t.id = l.id_tipo
        LEFT JOIN cat_locales_condicion c ON c.id = l.id_condicion_local
        LEFT JOIN hogares h ON h.local_id = l.id
        WHERE l.nivel_id = $1::uuid
        GROUP BY l.id, l.nivel_id, l.nombre_local, l.numero_hogares, l.descripcion, l.id_tipo, t.nombre, l.id_condicion_local, c.nombre, l.updated_at
        ORDER BY l.updated_at ASC, l.id ASC;
        """
        rows = await conn.fetch(sql, clean_nid)
        locales_list = []
        for r in rows:
            item = dict(r)
            if item['updated_at']:
                item['updated_at'] = item['updated_at'].isoformat()
            locales_list.append(item)

        return {
            "nivel_id": clean_nid,
            "numero_nivel": nivel_row['numero'],
            "numero_locales_esperados": nivel_row['numero_locales'],
            "locales_registrados": len(locales_list),
            "locales": locales_list
        }


@router.post("/nivel/{nivel_id}", status_code=status.HTTP_201_CREATED)
async def create_local(nivel_id: str, payload: LocalCreateSchema):
    """
    Crea un nuevo local dentro de un nivel.
    Valida el límite máximo de locales esperados según numero_locales del nivel.
    """
    clean_nid = parse_uuid_or_none(nivel_id)
    if not clean_nid:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": "nivel_no_encontrado", "message": "El nivel especificado no existe"}
        )

    pool = await get_db_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            nivel_row = await conn.fetchrow(
                "SELECT id::text, numero_locales FROM niveles WHERE id = $1::uuid FOR UPDATE",
                clean_nid
            )
            if not nivel_row:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail={"error": "nivel_no_encontrado", "message": "El nivel especificado no existe"}
                )

            max_locales = nivel_row['numero_locales'] or 1
            count_actual = await conn.fetchval(
                "SELECT COUNT(*) FROM locales WHERE nivel_id = $1::uuid",
                clean_nid
            ) or 0

            if count_actual >= max_locales:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail={
                        "error": "local_tope_alcanzado",
                        "message": f"No se pueden crear más locales. El límite para este nivel es {max_locales}.",
                        "data": {
                            "numero_locales_esperados": max_locales,
                            "locales_registrados": count_actual
                        }
                    }
                )

            # Validar existencia de id_tipo
            tipo_exists = await conn.fetchval("SELECT 1 FROM cat_locales_tipo WHERE id = $1", payload.id_tipo)
            if not tipo_exists:
                raise HTTPException(
                    status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                    detail={"error": "tipo_invalido", "message": f"El id_tipo {payload.id_tipo} no existe en el catálogo."}
                )

            # Validar id_condicion_local si se proporciona
            if payload.id_condicion_local is not None:
                cond_exists = await conn.fetchval("SELECT 1 FROM cat_locales_condicion WHERE id = $1", payload.id_condicion_local)
                if not cond_exists:
                    raise HTTPException(
                        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                        detail={"error": "condicion_invalida", "message": f"El id_condicion_local {payload.id_condicion_local} no existe."}
                    )

            insert_sql = """
            INSERT INTO locales (nivel_id, nombre_local, id_tipo, id_condicion_local, numero_hogares, descripcion, updated_at)
            VALUES ($1::uuid, $2, $3, $4, $5, $6, NOW())
            RETURNING id::text, nivel_id::text, nombre_local, id_tipo, id_condicion_local, numero_hogares, descripcion, updated_at;
            """
            row = await conn.fetchrow(
                insert_sql,
                clean_nid,
                payload.nombre_local,
                payload.id_tipo,
                payload.id_condicion_local,
                payload.numero_hogares,
                payload.descripcion
            )
            res = dict(row)
            if res['updated_at']:
                res['updated_at'] = res['updated_at'].isoformat()
            return res


@router.patch("/{local_id}")
async def patch_local(local_id: str, payload: LocalPatchSchema):
    """
    Edita la información de un local.
    """
    clean_lid = parse_uuid_or_none(local_id)
    if not clean_lid:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": "local_no_encontrado", "message": "El local especificado no existe"}
        )

    pool = await get_db_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            local_row = await conn.fetchrow(
                "SELECT id::text FROM locales WHERE id = $1::uuid FOR UPDATE",
                clean_lid
            )
            if not local_row:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail={"error": "local_no_encontrado", "message": "El local especificado no existe"}
                )

            updates = []
            args = [clean_lid]
            idx = 2

            if payload.nombre_local is not None:
                updates.append(f"nombre_local = ${idx}")
                args.append(payload.nombre_local)
                idx += 1

            if payload.id_tipo is not None:
                tipo_exists = await conn.fetchval("SELECT 1 FROM cat_locales_tipo WHERE id = $1", payload.id_tipo)
                if not tipo_exists:
                    raise HTTPException(
                        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                        detail={"error": "tipo_invalido", "message": f"El id_tipo {payload.id_tipo} no existe."}
                    )
                updates.append(f"id_tipo = ${idx}")
                args.append(payload.id_tipo)
                idx += 1

            if payload.id_condicion_local is not None:
                cond_exists = await conn.fetchval("SELECT 1 FROM cat_locales_condicion WHERE id = $1", payload.id_condicion_local)
                if not cond_exists:
                    raise HTTPException(
                        status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                        detail={"error": "condicion_invalida", "message": f"El id_condicion_local {payload.id_condicion_local} no existe."}
                    )
                updates.append(f"id_condicion_local = ${idx}")
                args.append(payload.id_condicion_local)
                idx += 1

            if payload.numero_hogares is not None:
                updates.append(f"numero_hogares = ${idx}")
                args.append(payload.numero_hogares)
                idx += 1

            if payload.descripcion is not None:
                updates.append(f"descripcion = ${idx}")
                args.append(payload.descripcion)
                idx += 1

            if not updates:
                raise HTTPException(status_code=400, detail="No se enviaron campos a actualizar")

            updates.append("updated_at = NOW()")

            update_sql = f"""
            UPDATE locales
            SET {", ".join(updates)}
            WHERE id = $1::uuid
            RETURNING id::text, nivel_id::text, nombre_local, id_tipo, id_condicion_local, numero_hogares, descripcion, updated_at;
            """
            row = await conn.fetchrow(update_sql, *args)
            res = dict(row)
            if res['updated_at']:
                res['updated_at'] = res['updated_at'].isoformat()
            return res


@router.delete("/{local_id}", status_code=status.HTTP_200_OK)
async def delete_local(local_id: str):
    """
    Elimina un local y sus hogares asociados en cascada.
    """
    clean_lid = parse_uuid_or_none(local_id)
    if not clean_lid:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": "local_no_encontrado", "message": "El local especificado no existe"}
        )

    pool = await get_db_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            row = await conn.fetchrow(
                "DELETE FROM locales WHERE id = $1::uuid RETURNING id::text, nivel_id::text;",
                clean_lid
            )
            if not row:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail={"error": "local_no_encontrado", "message": "El local especificado no existe"}
                )
            return {"ok": True, "deleted_id": row['id'], "nivel_id": row['nivel_id']}

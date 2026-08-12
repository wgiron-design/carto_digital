from fastapi import APIRouter, HTTPException, status
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from datetime import datetime
from app.database import get_db_pool
from app.routers.features import parse_uuid_or_none
import logging

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/api/niveles", tags=["Niveles"])

class NivelCreateSchema(BaseModel):
    numero_locales: int = Field(default=1, ge=1)
    descripcion: Optional[str] = Field(default=None, max_length=50)

class NivelPatchSchema(BaseModel):
    numero_locales: Optional[int] = Field(default=None, ge=1)
    descripcion: Optional[str] = Field(default=None, max_length=50)

class ConfirmDeleteSchema(BaseModel):
    numero_locales_nuevo: int = Field(..., ge=1)


@router.get("/estructura/{estructura_id}")
async def get_niveles_by_estructura(estructura_id: str):
    """
    Obtiene la lista de niveles de una estructura con sus métricas agregadas
    y la información del tope permitido (niveles_cantidad).
    """
    clean_eid = parse_uuid_or_none(estructura_id)
    if not clean_eid:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": "estructura_no_encontrada", "message": "La estructura especificada no existe"}
        )

    pool = await get_db_pool()
    for attempt in range(2):
        try:
            async with pool.acquire() as conn:
                # 1. Obtener datos de la estructura
                est_row = await conn.fetchrow(
                    "SELECT id::text, nombre, niveles_cantidad FROM estructuras WHERE id = $1::uuid AND deleted_at IS NULL",
                    clean_eid
                )
                if not est_row:
                    raise HTTPException(
                        status_code=status.HTTP_404_NOT_FOUND,
                        detail={"error": "estructura_no_encontrada", "message": "La estructura especificada no existe"}
                    )
                
                niveles_cantidad = est_row['niveles_cantidad'] or 1

                # 2. Consultar niveles con agregados de completitud
                sql = """
                SELECT 
                    n.id::text,
                    n.numero,
                    n.numero_locales,
                    n.descripcion,
                    n.updated_at,
                    COUNT(DISTINCT l.id)::int AS locales_registrados,
                    COUNT(DISTINCT h.id)::int AS hogares_registrados,
                    COALESCE(SUM(h.total_habitantes), 0)::int AS personas_registradas
                FROM niveles n
                LEFT JOIN locales l ON l.nivel_id = n.id
                LEFT JOIN hogares h ON h.local_id = l.id
                WHERE n.estructura_id = $1::uuid
                GROUP BY n.id, n.numero, n.numero_locales, n.descripcion, n.updated_at
                ORDER BY n.numero ASC;
                """
                rows = await conn.fetch(sql, clean_eid)
                
                niveles_list = []
                for r in rows:
                    item = dict(r)
                    item['updated_at'] = item['updated_at'].isoformat()
                    niveles_list.append(item)

                return {
                    "estructura_id": clean_eid,
                    "nombre_estructura": est_row['nombre'],
                    "niveles_cantidad": niveles_cantidad,
                    "niveles_registrados": len(niveles_list),
                    "niveles": niveles_list
                }
        except Exception as e:
            if attempt == 1:
                raise
            logger.warning(f"Reintentando consulta get_niveles_by_estructura por reconexión pool: {e}")


@router.post("/estructura/{estructura_id}", status_code=status.HTTP_201_CREATED)
async def create_nivel(estructura_id: str, payload: NivelCreateSchema):
    """
    Crea un nuevo nivel asignando automáticamente el consecutivo siguiente.
    Valida que no se supere niveles_cantidad.
    """
    clean_eid = parse_uuid_or_none(estructura_id)
    if not clean_eid:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail={"error": "estructura_no_encontrada", "message": "La estructura especificada no existe"}
        )

    pool = await get_db_pool()
    async with pool.acquire() as conn:
        async with conn.transaction():
            # Validar existencia de estructura y tope
            est_row = await conn.fetchrow(
                "SELECT id::text, niveles_cantidad FROM estructuras WHERE id = $1::uuid AND deleted_at IS NULL FOR UPDATE",
                clean_eid
            )
            if not est_row:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail={"error": "estructura_no_encontrada", "message": "La estructura especificada no existe"}
                )

            niveles_cantidad = est_row['niveles_cantidad'] or 1
            
            # Contar niveles existentes
            count_row = await conn.fetchval(
                "SELECT COUNT(*) FROM niveles WHERE estructura_id = $1::uuid",
                clean_eid
            )
            niveles_registrados = count_row or 0

            if niveles_registrados >= niveles_cantidad:
                raise HTTPException(
                    status_code=status.HTTP_409_CONFLICT,
                    detail={
                        "error": "nivel_tope_alcanzado",
                        "message": f"No se pueden crear más niveles. El límite configurado para esta estructura es de {niveles_cantidad}.",
                        "data": {
                            "niveles_cantidad": niveles_cantidad,
                            "niveles_registrados": niveles_registrados
                        }
                    }
                )

            # Autoasociar consecutivo siguiente
            max_num = await conn.fetchval(
                "SELECT COALESCE(MAX(numero), 0) FROM niveles WHERE estructura_id = $1::uuid",
                clean_eid
            )
            siguiente_numero = max_num + 1

            # Insertar nuevo nivel
            desc_val = payload.descripcion[:50] if payload.descripcion else None
            insert_sql = """
            INSERT INTO niveles (estructura_id, numero, numero_locales, descripcion, updated_at)
            VALUES ($1::uuid, $2, $3, $4, NOW())
            RETURNING id::text, estructura_id::text, numero, numero_locales, descripcion, updated_at;
            """
            row = await conn.fetchrow(insert_sql, clean_eid, siguiente_numero, payload.numero_locales, desc_val)
            res = dict(row)
            res['updated_at'] = res['updated_at'].isoformat()
            return res


@router.patch("/{nivel_id}")
async def patch_nivel(nivel_id: str, payload: NivelPatchSchema):
    """
    Edita la información de un nivel (numero_locales, descripcion).
    Si se intenta reducir numero_locales por debajo de los locales ya registrados con datos,
    rechaza con un error 409 estructurado detallando la cantidad de datos que se perderían.
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
            # 1. Obtener nivel actual
            nivel_row = await conn.fetchrow(
                "SELECT id::text, estructura_id::text, numero, numero_locales, descripcion FROM niveles WHERE id = $1::uuid FOR UPDATE",
                clean_nid
            )
            if not nivel_row:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail={"error": "nivel_no_encontrado", "message": "El nivel especificado no existe"}
                )

            numero_locales_actual = nivel_row['numero_locales']
            nuevo_numero_locales = payload.numero_locales if payload.numero_locales is not None else numero_locales_actual
            nueva_descripcion = payload.descripcion if payload.descripcion is not None else nivel_row['descripcion']
            if nueva_descripcion:
                nueva_descripcion = nueva_descripcion[:50]

            # 2. Si se reduce numero_locales, validar pérdida de datos
            if nuevo_numero_locales < numero_locales_actual:
                # Obtener locales que quedarían excedentes (locales cuyo orden/índice supere el nuevo límite)
                # Para simplificar y mantener consistencia, seleccionamos locales ordenados y tomamos los sobrantes
                locales_existentes = await conn.fetch(
                    "SELECT id::text FROM locales WHERE nivel_id = $1::uuid ORDER BY updated_at ASC, id ASC",
                    clean_nid
                )
                
                locales_count = len(locales_existentes)
                if locales_count > nuevo_numero_locales:
                    # Hay locales registrados por encima del nuevo límite
                    locales_excedentes_ids = [l['id'] for l in locales_existentes[nuevo_numero_locales:]]
                    
                    # Contar hogares y personas afectadas en esos locales
                    metrics = await conn.fetchrow(
                        """
                        SELECT 
                            COUNT(DISTINCT h.id)::int as hogares_afectados,
                            COALESCE(SUM(h.total_habitantes), 0)::int as personas_afectadas
                        FROM hogares h
                        WHERE h.local_id = ANY($1::uuid[])
                        """,
                        locales_excedentes_ids
                    )
                    
                    locales_afectados = len(locales_excedentes_ids)
                    hogares_afectados = metrics['hogares_afectados'] if metrics else 0
                    personas_afectadas = metrics['personas_afectadas'] if metrics else 0

                    raise HTTPException(
                        status_code=status.HTTP_409_CONFLICT,
                        detail={
                            "error": "perdida_de_datos_local",
                            "message": "Reducir el número de locales causaría la pérdida de locales y hogares registrados.",
                            "data": {
                                "nivel_id": nivel_id,
                                "numero_locales_actual": numero_locales_actual,
                                "numero_locales_solicitado": nuevo_numero_locales,
                                "locales_afectados": locales_afectados,
                                "hogares_afectados": hogares_afectados,
                                "personas_afectadas": personas_afectadas
                            }
                        }
                    )

            # 3. Aplicar actualización si no hay conflicto
            update_sql = """
            UPDATE niveles
            SET numero_locales = $2,
                descripcion = $3,
                updated_at = NOW(),
                sync_version = sync_version + 1
            WHERE id = $1::uuid
            RETURNING id::text, estructura_id::text, numero, numero_locales, descripcion, updated_at;
            """
            row = await conn.fetchrow(update_sql, clean_nid, nuevo_numero_locales, nueva_descripcion)
            res = dict(row)
            res['updated_at'] = res['updated_at'].isoformat()
            return res


@router.delete("/{nivel_id}/locales-excedentes")
async def delete_locales_excedentes(nivel_id: str, payload: ConfirmDeleteSchema):
    """
    Endpoint de confirmación explícita para reducir numero_locales y eliminar en cascada
    los locales y hogares sobrantes.
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

            nuevo_numero = payload.numero_locales_nuevo

            # Obtener locales sobrantes (ordenados por fecha o id)
            locales_existentes = await conn.fetch(
                "SELECT id::text FROM locales WHERE nivel_id = $1::uuid ORDER BY updated_at ASC, id ASC",
                clean_nid
            )
            
            if len(locales_existentes) > nuevo_numero:
                locales_eliminar = [l['id'] for l in locales_existentes[nuevo_numero:]]
                # Borrado en cascada manual por seguridad (aunque FK CASCADE esté activa)
                await conn.execute("DELETE FROM hogares WHERE local_id = ANY($1::uuid[])", locales_eliminar)
                await conn.execute("DELETE FROM locales WHERE id = ANY($1::uuid[])", locales_eliminar)

            # Actualizar nivel
            update_sql = """
            UPDATE niveles
            SET numero_locales = $2,
                updated_at = NOW(),
                sync_version = sync_version + 1
            WHERE id = $1::uuid
            RETURNING id::text, estructura_id::text, numero, numero_locales, descripcion, updated_at;
            """
            row = await conn.fetchrow(update_sql, clean_nid, nuevo_numero)
            res = dict(row)
            res['updated_at'] = res['updated_at'].isoformat()
            return res

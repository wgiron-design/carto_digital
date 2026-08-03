from fastapi import APIRouter, HTTPException
from typing import List
from app.database import get_db_pool
from app.schemas.capa import CapaRegistroOut, CapaRegistroUpdate

router = APIRouter(prefix="/api/capas", tags=["Capas Catalogo"])

@router.get("", response_model=List[CapaRegistroOut])
async def get_capas_activas():
    pool = await get_db_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch("""
            SELECT id::text, nombre, tipo_geometria, tabla_origen, descripcion, icono, color, activa, orden_visualizacion
            FROM capas_registro
            WHERE activa = true
            ORDER BY orden_visualizacion ASC
        """)
        return [dict(row) for row in rows]

@router.get("/todas", response_model=List[CapaRegistroOut])
async def get_todas_capas():
    pool = await get_db_pool()
    async with pool.acquire() as conn:
        rows = await conn.fetch("""
            SELECT id::text, nombre, tipo_geometria, tabla_origen, descripcion, icono, color, activa, orden_visualizacion
            FROM capas_registro
            ORDER BY orden_visualizacion ASC
        """)
        return [dict(row) for row in rows]

@router.put("/{capa_id}", response_model=CapaRegistroOut)
async def update_capa(capa_id: str, payload: CapaRegistroUpdate):
    pool = await get_db_pool()
    async with pool.acquire() as conn:
        updates = []
        args = []
        idx = 1
        
        if payload.nombre is not None:
            updates.append(f"nombre = ${idx}")
            args.append(payload.nombre)
            idx += 1
        if payload.descripcion is not None:
            updates.append(f"descripcion = ${idx}")
            args.append(payload.descripcion)
            idx += 1
        if payload.icono is not None:
            updates.append(f"icono = ${idx}")
            args.append(payload.icono)
            idx += 1
        if payload.color is not None:
            updates.append(f"color = ${idx}")
            args.append(payload.color)
            idx += 1
        if payload.activa is not None:
            updates.append(f"activa = ${idx}")
            args.append(payload.activa)
            idx += 1
        if payload.orden_visualizacion is not None:
            updates.append(f"orden_visualizacion = ${idx}")
            args.append(payload.orden_visualizacion)
            idx += 1

        if not updates:
            raise HTTPException(status_code=400, detail="No se enviaron campos a actualizar")

        updates.append("updated_at = NOW()")
        args.append(capa_id)
        
        query = f"""
            UPDATE capas_registro
            SET {", ".join(updates)}
            WHERE id = ${idx}::uuid
            RETURNING id::text, nombre, tipo_geometria, tabla_origen, descripcion, icono, color, activa, orden_visualizacion
        """
        row = await conn.fetchrow(query, *args)
        if not row:
            raise HTTPException(status_code=404, detail="Capa no encontrada")
        return dict(row)

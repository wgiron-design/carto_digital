"""
Schemas Pydantic para Features cartográficas con soporte de auditoría y sincronización.
"""
from pydantic import BaseModel
from typing import Any, Dict, List, Optional
from datetime import datetime


class FeatureProperties(BaseModel):
    """Propiedades base para cualquier feature cartográfico."""
    # Campos de auditoría
    created_by: Optional[str] = None   # UUID del usuario que creó el registro
    updated_by: Optional[str] = None   # UUID del último usuario que modificó
    device_id:  Optional[str] = None   # Identificador del dispositivo móvil
    sync_version: int = 0              # Versión para resolución de conflictos

    class Config:
        extra = "allow"  # Permitir campos adicionales específicos de cada tabla


class SyncBatchItem(BaseModel):
    """Un ítem en el batch de sincronización offline."""
    id: Optional[str] = None
    geometry: Dict[str, Any]
    properties: Dict[str, Any] = {}


class SyncBatchPayload(BaseModel):
    """Payload completo del endpoint POST /api/sync."""
    puntos:   List[SyncBatchItem] = []
    lineas:   List[SyncBatchItem] = []
    poligonos: List[SyncBatchItem] = []
    # Metadatos de auditoría del dispositivo
    user_id:  Optional[str] = None   # UUID del usuario autenticado en el dispositivo
    device_id: Optional[str] = None  # Identificador único del dispositivo


class SyncedItem(BaseModel):
    """Resultado de sincronización de un ítem individual."""
    id: str
    sync_version: int
    updated_at: datetime


class SyncResult(BaseModel):
    """Respuesta completa del endpoint de sincronización."""
    status: str = "ok"
    synced: Dict[str, List[SyncedItem]] = {
        "puntos": [],
        "lineas": [],
        "poligonos": [],
    }

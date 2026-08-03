from pydantic import BaseModel
from typing import Optional

class CapaRegistroBase(BaseModel):
    nombre: str
    tipo_geometria: str
    tabla_origen: str
    descripcion: Optional[str] = None
    icono: Optional[str] = 'layers'
    color: Optional[str] = '#4FC3F7'
    activa: bool = True
    orden_visualizacion: int = 0

class CapaRegistroUpdate(BaseModel):
    nombre: Optional[str] = None
    descripcion: Optional[str] = None
    icono: Optional[str] = None
    color: Optional[str] = None
    activa: Optional[bool] = None
    orden_visualizacion: Optional[int] = None

class CapaRegistroOut(CapaRegistroBase):
    id: str

    class Config:
        from_attributes = True

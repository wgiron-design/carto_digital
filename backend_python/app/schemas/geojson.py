from pydantic import BaseModel
from typing import List, Dict, Any, Optional

class Geometry(BaseModel):
    type: str
    coordinates: Any

class Feature(BaseModel):
    type: str = "Feature"
    id: Optional[str] = None
    geometry: Geometry
    properties: Dict[str, Any] = {}

class FeatureCollection(BaseModel):
    type: str = "FeatureCollection"
    features: List[Feature] = []

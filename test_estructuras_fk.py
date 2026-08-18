"""
Script de prueba de integración para validar la refactorización de estructuras (id_categoria, id_tipo).
"""
import uuid
import json

def build_test_payload(id_cat: int, id_tipo: int, valid_uuid: str = None):
    fid = valid_uuid or str(uuid.uuid4())
    return {
        "id": fid,
        "geometry": {
            "type": "Point",
            "coordinates": [-90.5132, 14.6407]
        },
        "properties": {
            "nombre": "Estructura de Prueba Integration",
            "id_categoria": id_cat,
            "id_tipo": id_tipo,
            "estado": "presente",
            "niveles_cantidad": 2,
            "notas": "Test de integración FK"
        }
    }

if __name__ == "__main__":
    print("[TEST] Payload de prueba generado:")
    print(json.dumps(build_test_payload(1, 1), indent=2))

import asyncio
import uuid
import httpx
from app.main import app
from app.database import init_db, close_db, get_db_pool

async def run_features_qa_verification():
    print("=" * 60)
    print(" [QA TEST] DIAGNOSTICO Y VERIFICACION DE FEATURES & CATALOGOS")
    print("=" * 60)

    try:
        await init_db()
        pool = await get_db_pool()
        print("[OK] Pool PostgreSQL iniciado.")
    except Exception as e:
        print(f"[ERROR] No se pudo conectar a la base de datos: {e}")
        return

    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        
        # 1. Probar GET /api/capas/catalogos/estructuras/tipos
        print("\n--- 1. GET /api/capas/catalogos/estructuras/tipos ---")
        res_tipos = await client.get("/api/capas/catalogos/estructuras/tipos")
        print(f"Status: {res_tipos.status_code}")
        print(f"Body: {res_tipos.json()}")

        # 2. Probar GET /api/capas/catalogos/estructuras/categorias (sin filtro)
        print("\n--- 2. GET /api/capas/catalogos/estructuras/categorias ---")
        res_cat_all = await client.get("/api/capas/catalogos/estructuras/categorias")
        print(f"Status: {res_cat_all.status_code}")
        print(f"Body: {res_cat_all.json()}")

        # 3. Probar GET /api/capas/catalogos/estructuras/categorias?tipo=1
        print("\n--- 3. GET /api/capas/catalogos/estructuras/categorias?tipo=1 ---")
        res_cat_t1 = await client.get("/api/capas/catalogos/estructuras/categorias?tipo=1")
        print(f"Status: {res_cat_t1.status_code}")
        print(f"Body: {res_cat_t1.json()}")

        # 4. Probar GET con tipo inválido (debe dar 422)
        print("\n--- 4. GET /api/capas/catalogos/estructuras/categorias?tipo=999 (Validación 422) ---")
        res_cat_inv = await client.get("/api/capas/catalogos/estructuras/categorias?tipo=999")
        print(f"Status: {res_cat_inv.status_code}")
        print(f"Body: {res_cat_inv.json()}")

        # 5. Probar POST /api/capas/estructuras/features (Creación válida)
        print("\n--- 5. POST /api/capas/estructuras/features (Creación Válida) ---")
        feature_id = str(uuid.uuid4())
        payload_valido = {
            "id": feature_id,
            "geometry": {
                "type": "Point",
                "coordinates": [-90.5132, 14.6407]
            },
            "properties": {
                "nombre": "Estructura QA Test",
                "id_categoria": 1,
                "id_tipo": 1,
                "estado": "presente",
                "niveles_cantidad": 2,
                "notas": "Prueba QA backend"
            }
        }
        res_post = await client.post("/api/capas/estructuras/features", json=payload_valido)
        print(f"Status: {res_post.status_code}")
        print(f"Body: {res_post.json()}")

        # 6. Probar POST /api/capas/estructuras/features (Validación cruzada inválida id_categoria/id_tipo)
        print("\n--- 6. POST /api/capas/estructuras/features (Validación Cruzada Inválida -> 422) ---")
        payload_invalido = {
            "id": str(uuid.uuid4()),
            "geometry": {
                "type": "Point",
                "coordinates": [-90.5132, 14.6407]
            },
            "properties": {
                "nombre": "Estructura Inconsistente",
                "id_categoria": 999,
                "id_tipo": 1,
                "estado": "presente",
                "niveles_cantidad": 1
            }
        }
        res_post_inv = await client.post("/api/capas/estructuras/features", json=payload_invalido)
        print(f"Status: {res_post_inv.status_code}")
        print(f"Body: {res_post_inv.json()}")

        # 7. GET /api/capas/estructuras/features
        print("\n--- 7. GET /api/capas/estructuras/features ---")
        res_get_features = await client.get("/api/capas/estructuras/features")
        print(f"Status: {res_get_features.status_code}")
        print(f"FeatureCollection type: {res_get_features.json().get('type')}")
        print(f"Cantidad de features: {len(res_get_features.json().get('features', []))}")

    await close_db()
    print("\n" + "=" * 60)
    print(" [OK] DIAGNOSTICO COMPLETADO SIN CRASHES NI EXCEPCIONES EN EL SERVIDOR")
    print("=" * 60)

if __name__ == "__main__":
    asyncio.run(run_features_qa_verification())

import asyncio
import sys
sys.stdout.reconfigure(encoding='utf-8')
import httpx

BASE_URL = "http://localhost:8000"

async def test_niveles_deep():
    print("=" * 60)
    print(" [QA TEST] PRUEBA EXHAUSTIVA DE ROUTER NIVELES Y ESTRUCTURAS")
    print("=" * 60)

    async with httpx.AsyncClient(base_url=BASE_URL, timeout=10.0) as client:
        # 1. Crear estructura de prueba
        payload_est = {
            "type": "Feature",
            "geometry": {
                "type": "Point",
                "coordinates": [-90.5, 14.6]
            },
            "properties": {
                "nombre": "Estructura Test Niveles",
                "id_tipo": 1,
                "id_categoria": 1,
                "niveles_cantidad": 3,
                "estado": "presente"
            }
        }
        r_create_est = await client.post("/api/capas/estructuras/features", json=payload_est)

        print(f"Crear Estructura ({r_create_est.status_code}): {r_create_est.json()}")
        assert r_create_est.status_code in (200, 201)

        est_data = r_create_est.json()
        est_id = est_data['id']

        # 2. Consultar Niveles de la estructura recien creada
        r_niveles = await client.get(f"/api/niveles/estructura/{est_id}")
        print(f"GET Niveles de Estructura ({r_niveles.status_code}): {r_niveles.json()}")
        assert r_niveles.status_code == 200

        # 3. Crear primer Nivel
        payload_niv1 = {
            "numero_locales": 2,
            "descripcion": "Planta Baja"
        }
        r_post_niv1 = await client.post(f"/api/niveles/estructura/{est_id}", json=payload_niv1)
        print(f"Crear Nivel 1 ({r_post_niv1.status_code}): {r_post_niv1.json()}")
        assert r_post_niv1.status_code == 201
        niv1_id = r_post_niv1.json()['id']

        # 4. Patch Nivel 1
        payload_patch = {
            "numero_locales": 3,
            "descripcion": "Planta Baja Editada"
        }
        r_patch_niv1 = await client.patch(f"/api/niveles/{niv1_id}", json=payload_patch)
        print(f"PATCH Nivel 1 ({r_patch_niv1.status_code}): {r_patch_niv1.json()}")
        assert r_patch_niv1.status_code == 200

        # 5. Crear locales en ese Nivel
        r_post_loc1 = await client.post(f"/api/locales/nivel/{niv1_id}", json={
            "id_tipo": 1,
            "id_condicion_local": 1,
            "nombre_local": "Local 101",
            "numero_hogares": 1
        })
        print(f"Crear Local 101 ({r_post_loc1.status_code}): {r_post_loc1.json()}")
        assert r_post_loc1.status_code == 201

        # 6. Intentar reducir numero_locales a 0 o menos del registrado para probar conflicto 409
        r_patch_conflict = await client.patch(f"/api/niveles/{niv1_id}", json={"numero_locales": 0})
        print(f"PATCH Nivel 1 Conflicto ({r_patch_conflict.status_code}): {r_patch_conflict.json()}")

        # Clean up: Eliminar estructura
        r_del = await client.delete(f"/api/capas/estructuras/features/{est_id}")
        print(f"Eliminar Estructura ({r_del.status_code}): {r_del.json()}")
        assert r_del.status_code == 200


    print("\n" + "=" * 60)
    print(" [OK] PRUEBA NIVELES Y ESTRUCTURAS FINALIZADA EXITOSAMENTE")
    print("=" * 60)

if __name__ == "__main__":
    asyncio.run(test_niveles_deep())

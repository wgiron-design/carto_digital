import asyncio
import sys
sys.stdout.reconfigure(encoding='utf-8')
import httpx

BASE_URL = "http://localhost:8000"

async def run_locales_qa():
    print("=" * 60)
    print(" [QA TEST] VERIFICACION ENDPOINTS LOCALES Y CATALOGOS")
    print("=" * 60)

    async with httpx.AsyncClient(base_url=BASE_URL, timeout=10.0) as client:
        # 1. Probar catalogos
        r_tipos = await client.get("/api/capas/catalogos/locales/tipos")
        print(f"Catalogos Locales Tipos ({r_tipos.status_code}): {r_tipos.json()}")
        assert r_tipos.status_code == 200

        r_cond = await client.get("/api/capas/catalogos/locales/condiciones")
        print(f"Catalogos Locales Condiciones ({r_cond.status_code}): {r_cond.json()}")
        assert r_cond.status_code == 200

        # 2. Obtener un nivel existente
        # Primero buscar estructuras
        r_capas = await client.get("/api/capas")
        assert r_capas.status_code == 200

        # Crear estructura de prueba si es necesario o consultar niveles
        # Para QA rápido, llamemos endpoint de niveles sobre un UUID dummy
        r_niv = await client.get("/api/locales/nivel/00000000-0000-0000-0000-000000000000")
        print(f"Get Locales Nivel Inexistente ({r_niv.status_code}): {r_niv.json()}")
        assert r_niv.status_code == 404

    print("\n" + "=" * 60)
    print(" [OK] QA PRUEBAS DE ENDPOINTS COMPLETADAS EXITOSAMENTE")
    print("=" * 60)

if __name__ == "__main__":
    asyncio.run(run_locales_qa())

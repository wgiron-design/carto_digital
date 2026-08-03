import asyncio
import uuid
import sys
import httpx
from app.main import app
from app.database import init_db, close_db, get_db_pool

async def run_full_qa_verification():
    print("=" * 60)
    print(" [QA TEST] INICIANDO VERIFICACION DE CONEXION POSTGRESQL & FASTAPI")
    print("=" * 60)

    # 1. Probar inicialización de BD
    try:
        await init_db()
        pool = await get_db_pool()
        print("[OK] 1. Pool de conexiones PostgreSQL/Neon iniciado correctamente.")
    except Exception as e:
        print(f"[ERROR] 1. Error de conexión con PostgreSQL: {e}")
        return False

    # 2. Verificar tablas requeridas
    async with pool.acquire() as conn:
        tables = await conn.fetch("""
            SELECT table_name FROM information_schema.tables 
            WHERE table_schema = 'public';
        """)
        table_names = [t['table_name'] for t in tables]
        print(f"[OK] 2. Tablas en PostgreSQL ({len(table_names)}): {', '.join(table_names)}")
        
        if 'users' not in table_names:
            print("[ERROR] 2. La tabla 'users' no fue encontrada.")
            return False

    # 3. Probar cliente HTTP AsyncClient con ASGITransport
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        test_username = f"testuser_{uuid.uuid4().hex[:6]}"
        test_email = f"{test_username}@cartodigital.com"
        test_password = "password123"

        print("\n--- PRUEBA 3: Registro de Nuevo Usuario ---")
        reg_resp = await client.post("/api/v1/auth/register", json={
            "username": test_username,
            "email": test_email,
            "password": test_password
        })
        print(f"HTTP Status: {reg_resp.status_code}")
        print(f"Body: {reg_resp.json()}")
        if reg_resp.status_code not in (200, 201):
            print("[ERROR] Falló la prueba de registro de usuario.")
            return False
        print("[OK] Registro de usuario completado exitosamente en PostgreSQL.")

        print("\n--- PRUEBA 4: Login de Usuario Activo ---")
        login_resp = await client.post("/api/v1/auth/login", json={
            "username": test_username,
            "password": test_password
        })
        print(f"HTTP Status: {login_resp.status_code}")
        if login_resp.status_code != 200:
            print("[ERROR] Falló la prueba de inicio de sesión.")
            return False
        
        token = login_resp.json()["access_token"]
        user_data = login_resp.json()["user"]
        print(f"[OK] Login exitoso. Token emitido. Usuario: {user_data['username']}, Rol: {user_data['role']}")

        print("\n--- PRUEBA 5: Consulta de Perfil (/api/v1/auth/me) ---")
        me_resp = await client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
        print(f"HTTP Status: {me_resp.status_code}")
        print(f"Perfil: {me_resp.json()}")
        if me_resp.status_code != 200:
            print("[ERROR] Falló la consulta de perfil /me.")
            return False

        print("\n--- PRUEBA 6: Recuperación de Contraseña y Página Web ---")
        forgot_resp = await client.post("/api/v1/auth/forgot-password", json={
            "username": test_username,
            "email": test_email
        })
        print(f"HTTP Status: {forgot_resp.status_code}")
        print(f"Mensaje: {forgot_resp.json()}")

        # Verificar que la página HTML de restablecimiento de contraseña carga correctamente
        page_resp = await client.get("/reset-password-page?token=test_token_sample")
        print(f"Página HTML /reset-password-page HTTP Status: {page_resp.status_code}")
        if page_resp.status_code != 200 or "Restablecer Contraseña" not in page_resp.text:
            print("[ERROR] Falló la carga de la página HTML /reset-password-page.")
            return False
        print("[OK] Página Web HTML /reset-password-page renderizada correctamente.")

        # Probar flujo completo de cambio de contraseña mediante token válido
        from app.security import create_access_token
        test_reset_token = create_access_token({"sub": str(user_data["id"]), "scope": "reset_password"})
        new_pwd = "new_password_123"

        reset_resp = await client.post("/api/v1/auth/reset-password", json={
            "token": test_reset_token,
            "new_password": new_pwd
        })
        print(f"Reset Password API Status: {reset_resp.status_code}")
        print(f"Body: {reset_resp.json()}")
        if reset_resp.status_code != 200:
            print("[ERROR] Falló el endpoint /reset-password.")
            return False

        # Verificar login con nueva contraseña
        new_login_resp = await client.post("/api/v1/auth/login", json={
            "username": test_username,
            "password": new_pwd
        })
        if new_login_resp.status_code == 200:
            print("[OK] Login con la NUEVA contraseña fue exitoso.")
        else:
            print("[ERROR] No se pudo iniciar sesión con la nueva contraseña.")
            return False

        print("\n--- PRUEBA 7: Control de Usuario Inactivo (Mensaje exacto 'usuario inactivo') ---")
        # Desactivar usuario en BD
        async with pool.acquire() as conn:
            await conn.execute("UPDATE users SET is_active = false WHERE username = $1", test_username)
        
        inactive_login_resp = await client.post("/api/v1/auth/login", json={
            "username": test_username,
            "password": new_pwd
        })
        print(f"HTTP Status: {inactive_login_resp.status_code}")
        detail = inactive_login_resp.json().get("detail", "")
        print(f"Detalle retornado: '{detail}'")

        if inactive_login_resp.status_code == 403 and detail == "usuario inactivo":
            print("[OK] REGLA CRITICA CUMPLIDA: Usuario inactivo rechazado con mensaje exacto 'usuario inactivo'.")
        else:
            print(f"[ERROR] Error en regla de usuario inactivo. Se esperaba 'usuario inactivo', se obtuvo: '{detail}'")
            return False


        # Limpiar registro de prueba
        async with pool.acquire() as conn:
            await conn.execute("DELETE FROM users WHERE username = $1", test_username)

        print("\n--- PRUEBA 8: Consulta de Capas GIS (/api/capas) ---")
        capas_resp = await client.get("/api/capas")
        print(f"HTTP Status: {capas_resp.status_code}")
        print(f"Capas encontradas: {len(capas_resp.json())}")

    await close_db()
    print("\n" + "=" * 60)
    print(" [EXITO] TODAS LAS PRUEBAS QA PASARON EXITOSAMENTE DE EXTREMO A EXTREMO")
    print("=" * 60)
    return True

if __name__ == "__main__":
    success = asyncio.run(run_full_qa_verification())
    if not success:
        sys.exit(1)

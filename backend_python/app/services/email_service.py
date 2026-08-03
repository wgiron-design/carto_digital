import os
import smtplib
import asyncio
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from app.config import (
    SMTP_HOST,
    SMTP_PORT,
    SMTP_USER,
    SMTP_PASSWORD,
    SMTP_FROM,
    SERVER_HOST
)

def _send_email_sync(to_email: str, subject: str, html_content: str):
    """
    Función sincrónica para envío de correo mediante SMTP.
    """
    if not SMTP_HOST or not SMTP_USER or not SMTP_PASSWORD:
        print("\n" + "=" * 60)
        print(" [EMAIL SERVICE - MODO DESARROLLO / CONSOLA]")
        print(f" Para: {to_email}")
        print(f" Asunto: {subject}")
        print(" Mensaje: (Credenciales SMTP no configuradas en .env. Se muestra en consola)")
        print("=" * 60 + "\n")
        return False

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = SMTP_FROM or SMTP_USER
        msg["To"] = to_email

        part_html = MIMEText(html_content, "html", "utf-8")
        msg.attach(part_html)

        server_port = int(SMTP_PORT) if SMTP_PORT else 587
        
        # Conexión SMTP
        if server_port == 465:
            with smtplib.SMTP_SSL(SMTP_HOST, server_port, timeout=10) as server:
                server.login(SMTP_USER, SMTP_PASSWORD)
                server.sendmail(msg["From"], [to_email], msg.as_string())
        else:
            with smtplib.SMTP(SMTP_HOST, server_port, timeout=10) as server:
                server.starttls()
                server.login(SMTP_USER, SMTP_PASSWORD)
                server.sendmail(msg["From"], [to_email], msg.as_string())

        print(f"[EMAIL SERVICE] Correo enviado exitosamente a {to_email}")
        return True
    except Exception as e:
        print(f"[EMAIL SERVICE ERROR] Falló el envío de correo a {to_email}: {e}")
        return False

async def send_reset_password_email(to_email: str, username: str, reset_token: str):
    """
    Construye y envía el correo con el enlace de restablecimiento de contraseña.
    """
    reset_url = f"{SERVER_HOST.rstrip('/')}/reset-password-page?token={reset_token}"
    subject = "CartoDigital - Restablecimiento de Contraseña"

    html_content = f"""
    <!DOCTYPE html>
    <html lang="es">
    <head>
        <meta charset="UTF-8">
        <style>
            body {{ font-family: 'Segoe UI', Arial, sans-serif; background-color: #0f172a; color: #f8fafc; margin: 0; padding: 20px; }}
            .container {{ max-width: 550px; margin: 0 auto; background: #1e293b; border-radius: 12px; padding: 32px; border: 1px solid #334155; shadow: 0 10px 25px rgba(0,0,0,0.5); }}
            .header {{ text-align: center; margin-bottom: 24px; }}
            .header h2 {{ color: #38bdf8; margin: 0; font-size: 24px; }}
            .content {{ line-height: 1.6; color: #cbd5e1; font-size: 15px; }}
            .btn-container {{ text-align: center; margin: 30px 0; }}
            .btn {{ background: linear-gradient(135deg, #0284c7, #2563eb); color: #ffffff !important; text-decoration: none; padding: 14px 28px; border-radius: 8px; font-weight: 600; font-size: 16px; display: inline-block; box-shadow: 0 4px 12px rgba(37,99,235,0.4); }}
            .footer {{ font-size: 12px; color: #64748b; text-align: center; margin-top: 24px; border-top: 1px solid #334155; padding-top: 16px; }}
            .link-text {{ word-break: break-all; color: #38bdf8; font-size: 13px; }}
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <h2>🌐 CartoDigital</h2>
            </div>
            <div class="content">
                <p>Hola <strong>{username}</strong>,</p>
                <p>Hemos recibido una solicitud para restablecer la contraseña de tu cuenta en CartoDigital.</p>
                <p>Haz clic en el siguiente botón para ingresar tu nueva contraseña:</p>
                <div class="btn-container">
                    <a href="{reset_url}" class="btn" target="_blank">Restablecer mi Contraseña</a>
                </div>
                <p>Si el botón no funciona, copia y pega el siguiente enlace en tu navegador web:</p>
                <p class="link-text">{reset_url}</p>
                <p><em>Este enlace expirará en 15 minutos por razones de seguridad. Si no solicitaste este cambio, puedes ignorar este correo.</em></p>
            </div>
            <div class="footer">
                &copy; CartoDigital - Sistema de Gestión Cartográfica y PosGIS
            </div>
        </div>
    </body>
    </html>
    """

    print("\n" + "=" * 60)
    print(f" [EMAIL SERVICE] GENERANDO ENLACE DE RECUPERACION")
    print(f" Usuario: {username}")
    print(f" Correo: {to_email}")
    print(f" Enlace Directo Web: {reset_url}")
    print("=" * 60 + "\n")

    # Ejecutar el envío de correo de forma asíncrona en un hilo separado
    await asyncio.to_thread(_send_email_sync, to_email, subject, html_content)

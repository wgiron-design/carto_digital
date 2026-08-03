import os
from dotenv import load_dotenv

load_dotenv()

DEFAULT_DB_URL = "postgresql://neondb_owner:npg_brSAK56Ugpcl@ep-little-glitter-axbz3nuf.c-4.us-east-2.aws.neon.tech/neondb?sslmode=require"

DATABASE_URL = os.getenv("DATABASE_URL", DEFAULT_DB_URL)
PORT = int(os.getenv("PORT", 8000))
SERVER_HOST = os.getenv("SERVER_HOST", f"http://localhost:{PORT}")

# Configuración SMTP
SMTP_HOST = os.getenv("SMTP_HOST", "")
SMTP_PORT = os.getenv("SMTP_PORT", "587")
SMTP_USER = os.getenv("SMTP_USER", "")
SMTP_PASSWORD = os.getenv("SMTP_PASSWORD", "")
SMTP_FROM = os.getenv("SMTP_FROM", "")


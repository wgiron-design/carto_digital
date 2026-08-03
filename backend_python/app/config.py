import os
from dotenv import load_dotenv

load_dotenv()

DEFAULT_DB_URL = "postgresql://neondb_owner:npg_brSAK56Ugpcl@ep-little-glitter-axbz3nuf.c-4.us-east-2.aws.neon.tech/neondb?sslmode=require"

DATABASE_URL = os.getenv("DATABASE_URL", DEFAULT_DB_URL)
PORT = int(os.getenv("PORT", 8000))

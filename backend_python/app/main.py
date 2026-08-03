from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
from app.database import init_db, close_db
from app.routers import capas, features, sync, admin, auth

@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    yield
    await close_db()

app = FastAPI(
    title="CartoDigital PostGIS API",
    description="API REST asíncrona en Python para gestión de capas geográficas con PostGIS (Neon)",
    version="1.0.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(capas.router)
app.include_router(features.router)
app.include_router(sync.router)
app.include_router(admin.router)

@app.get("/")
def read_root():
    return {
        "app": "CartoDigital PostGIS API",
        "status": "online",
        "docs": "/docs",
        "admin": "/admin"
    }

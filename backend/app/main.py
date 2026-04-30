from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import trans, external_users, pedidos, dashboard, cargas
from .routers import vehiculos
from .routers import intent
from .routers import custom_claims
import os
from dotenv import load_dotenv
from pathlib import Path

# Cargar variables de entorno desde backend/.env independientemente del working directory
BASE_DIR = Path(__file__).resolve().parents[1]  # backend/
load_dotenv(BASE_DIR / ".env")

app = FastAPI(title="Gestión Transporte API")

# Middleware para CORS
frontend_url = os.getenv("FRONTEND_URL", "http://localhost:5500")

origins = [
    frontend_url,
    "http://localhost:5500",
    "http://127.0.0.1:5500",
    "http://localhost:8000",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(custom_claims.router)
app.include_router(trans.router)
app.include_router(vehiculos.router)
app.include_router(external_users.router)
app.include_router(pedidos.router)
app.include_router(cargas.router)
app.include_router(intent.router)
app.include_router(dashboard.router)

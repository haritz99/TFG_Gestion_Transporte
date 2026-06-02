import json
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .middleware.rate_limit import RateLimitMiddleware
from .routers import trans, external_users, pedidos, dashboard, cargas
from .routers import vehiculos
from .routers import custom_claims
import os
import firebase_admin
from firebase_admin import credentials
from dotenv import load_dotenv
from pathlib import Path

# Cargar variables de entorno desde backend/.env independientemente del working directory
BASE_DIR = Path(__file__).resolve().parents[1]  # backend/
load_dotenv(BASE_DIR / ".env")

app = FastAPI(
    title="Gestión Transporte API",
    docs_url="/swagger",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
)

path = os.getenv("FIREBASE_CREDENTIALS_PATH")
cred = credentials.Certificate(path)
with open(path, "r") as f:
    credentials_data = json.load(f)
    project_id = credentials_data.get("project_id")
firebase_admin.initialize_app(cred, {
    'storageBucket': f'{project_id}.firebasestorage.app'
})

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

app.add_middleware(
    RateLimitMiddleware,
    limit=20,
    window_seconds=60,
    path_prefixes=["/auth", "/trans", "/vehi", "/ext", "/pedidos", "/cargas", "/dashboard"],
)

app.include_router(custom_claims.router)
app.include_router(trans.router)
app.include_router(vehiculos.router)
app.include_router(external_users.router)
app.include_router(pedidos.router)
app.include_router(cargas.router)
app.include_router(cargas.router)
app.include_router(dashboard.router)

import json
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.base import BaseHTTPMiddleware
from .middleware.rate_limit import RateLimitMiddleware
from .routers import trans, external_users, pedidos, dashboard, cargas
from .routers import vehiculos
from .routers import auth
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

firebase_json_raw = os.getenv("FIREBASE_CREDENTIALS_JSON")
path = os.getenv("FIREBASE_CREDENTIALS_PATH")
project_id = None
if firebase_json_raw:
    credentials_data = json.loads(firebase_json_raw)
    cred = credentials.Certificate(credentials_data)
    project_id = credentials_data["project_id"]

elif path and os.path.exists(path):
    cred = credentials.Certificate(path)
    with open(path, "r") as f:
        credentials_data = json.load(f)
    project_id = credentials_data["project_id"]
else:
    cred = credentials.ApplicationDefault()
    project_id = os.getenv("GOOGLE_CLOUD_PROJECT") or os.getenv("GCP_PROJECT")

firebase_admin.initialize_app(cred, {
    'storageBucket': f'{project_id}.firebasestorage.app'
})

# Middleware para CORS
frontend_url = os.getenv("FRONTEND_URL", "http://localhost:5500")

origins = [
    frontend_url,
    "https://gestion-transporte-dev.web.app",
    "https://gestion-transporte-dev.firebaseapp.com"
]

class StripTrailingSlashMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request, call_next):
        path = request.scope["path"]
        if len(path) > 1 and path.endswith("/"):
            request.scope["path"] = path.rstrip("/")
        return await call_next(request)

app.add_middleware(StripTrailingSlashMiddleware)

app.add_middleware(
    RateLimitMiddleware,
    limit=100,
    window_seconds=60,
    path_prefixes=["/auth", "/trans", "/vehi", "/ext", "/pedidos", "/cargas", "/dashboard"],
)
app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(trans.router)
app.include_router(vehiculos.router)
app.include_router(external_users.router)
app.include_router(pedidos.router)
app.include_router(cargas.router)
app.include_router(dashboard.router)

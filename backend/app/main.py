from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import auth
from .routers import trans
from .routers import intent
import os
from dotenv import load_dotenv

load_dotenv()

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

app.include_router(auth.router)
app.include_router(trans.router)
app.include_router(intent.router)


@app.get("/")
def root():
    return {"status": "ok"}

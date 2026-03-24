from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .routers import auth
from .routers import trans
from .routers import intent
import os


app = FastAPI(title="Gestión Transporte API")

# Middleware para CORS
origins = [os.getenv("FRONTEND_URL", "")]
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

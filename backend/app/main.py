from fastapi import FastAPI
from app.routers import intent

app = FastAPI(title="Gestión Transporte API")

app.include_router(intent.router)


@app.get("/")
def root():
    return {"status": "ok"}

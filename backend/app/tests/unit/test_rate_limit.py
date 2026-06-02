from __future__ import annotations

from fastapi import Depends, FastAPI
from fastapi.testclient import TestClient

from app.middleware.rate_limit import RateLimitMiddleware


async def _allow():
    return {"ok": True}


def test_rate_limit_global_returns_429_after_limit():
    app = FastAPI()
    app.add_middleware(
        RateLimitMiddleware,
        limit=2,
        window_seconds=60,
        path_prefixes=["/api"],
    )

    @app.get("/api/ping")
    def ping(_: dict = Depends(_allow)):
        return {"pong": True}

    client = TestClient(app)

    assert client.get("/api/ping").status_code == 200
    assert client.get("/api/ping").status_code == 200
    response = client.get("/api/ping")

    assert response.status_code == 429
    assert response.json()["detail"] == "Too Many Requests"
    assert "Retry-After" in response.headers


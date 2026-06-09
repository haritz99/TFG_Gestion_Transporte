from __future__ import annotations

import asyncio
import time
from collections import defaultdict, deque
from typing import Awaitable, Callable, Iterable

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.responses import JSONResponse, Response


class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, limit: int = 60, window_seconds: int = 60, path_prefixes: Iterable[str] | None = None):
        super().__init__(app)
        self.limit = limit
        self.window_seconds = window_seconds
        self.path_prefixes = tuple(path_prefixes or ())
        self._hits: dict[str, deque[float]] = defaultdict(deque)
        self._lock = asyncio.Lock()

    def _is_limited_path(self, path: str) -> bool:
        if not self.path_prefixes:
            return True
        return any(path == prefix or path.startswith(f"{prefix}/") for prefix in self.path_prefixes)

    def _client_key(self, request: Request) -> str:
        forwarded_for = request.headers.get("x-forwarded-for")
        if forwarded_for:
            return forwarded_for.split(",")[0].strip()
        client = request.client
        return client.host if client and client.host else "anonymous"

    async def dispatch(self, request: Request, call_next: Callable[[Request], Awaitable[Response]]) -> Response:
        if not self._is_limited_path(request.url.path):
            return await call_next(request)

        key = self._client_key(request)
        now = time.monotonic()
        async with self._lock:
            hits = self._hits[key]
            cutoff = now - self.window_seconds
            while hits and hits[0] <= cutoff:
                hits.popleft()
            if len(hits) >= self.limit:
                retry_after = self.window_seconds - (now - hits[0]) if hits else self.window_seconds
                return JSONResponse(
                    status_code=429,
                    content={"detail": "Too Many Requests"},
                    headers={"Retry-After": str(max(1, int(retry_after)))},
                )
            hits.append(now)

        return await call_next(request)



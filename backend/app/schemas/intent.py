from __future__ import annotations

from typing import Any

from pydantic import BaseModel, Field


class IntentRequest(BaseModel):
    text: str = Field(..., min_length=1)


class IntentResponse(BaseModel):
    intent: str
    entities: dict[str, Any] = Field(default_factory=dict)
    response: str


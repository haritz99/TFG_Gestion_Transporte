from __future__ import annotations

from typing import Dict, TypeVar

from pydantic import BaseModel

DocT = TypeVar("DocT", bound=BaseModel)


class FirestoreSchema(BaseModel):

    class Config:
        extra = "forbid"


DocumentMap = Dict[str, DocT]


from __future__ import annotations

from typing import Dict, TypeVar

from pydantic import BaseModel
import datetime
DocT = TypeVar("DocT", bound=BaseModel)


def to_utc(dt: datetime.datetime | None) -> datetime.datetime | None:
    if dt is None:
        return dt
    if dt.tzinfo is None:
        return dt.replace(tzinfo=datetime.timezone.utc)
    return dt.astimezone(datetime.timezone.utc)


class FirestoreSchema(BaseModel):

    class Config:
        extra = "allow"


DocumentMap = Dict[str, DocT]

from __future__ import annotations

from typing import Dict, TypeVar

from pydantic import BaseModel, field_validator
import datetime
DocT = TypeVar("DocT", bound=BaseModel)


class DatetimeUTCMixin:
    @field_validator("*", mode="before")
    @classmethod
    def ensure_utc(cls, v):
        if isinstance(v, datetime.datetime):
            if v.tzinfo is None:
                return v.replace(tzinfo=datetime.timezone.utc)
            return v.astimezone(datetime.timezone.utc)
        return v


class FirestoreSchema(BaseModel):

    class Config:
        extra = "allow"


DocumentMap = Dict[str, DocT]

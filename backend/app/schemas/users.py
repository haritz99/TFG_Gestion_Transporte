from __future__ import annotations

from typing import Literal, Optional

from pydantic import Field, field_validator, model_validator

from .base import FirestoreSchema


class UserSchema(FirestoreSchema):
    nombre: str = Field(..., min_length=1)
    apellido: str = Field(..., min_length=1)
    email: str = Field(..., min_length=3)
    tfn: str = Field(..., min_length=3)
    rol: list[Literal["encargado", "transportista"]] = Field(..., min_length=1)
    permisosCond: Optional[list[str]] = None
    vehiculoId: Optional[str] = None

    @field_validator("rol")
    @classmethod
    def normalize_roles(cls, value: list[Literal["encargado", "transportista"]]):
        # Evita duplicados
        return list(dict.fromkeys(value))

    @model_validator(mode="after")
    def validate_transportista_fields(self):
        if "transportista" in self.rol:
            if not self.permisosCond:
                raise ValueError("'permisosCond' es obligatorio para transportista")
        return self


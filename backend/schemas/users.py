from __future__ import annotations

from typing import Literal, Optional

from pydantic import Field, model_validator

from .base import FirestoreSchema


class UserSchema(FirestoreSchema):
    nombre: str = Field(..., min_length=1)
    apellidos: str = Field(..., min_length=1)
    email: str = Field(..., min_length=3)
    tfn: str = Field(..., min_length=3)
    rol: Literal["encargado", "transportista"]
    permisosCond: Optional[list[str]] = None
    disponible: Optional[bool] = None

    @model_validator(mode="after")
    def validate_transportista_fields(self):
        if self.rol == "transportista":
            if not self.permisosCond:
                raise ValueError("'permisosCond' es obligatorio para transportista")
            if self.disponible is None:
                raise ValueError("'disponible' es obligatorio para transportista")
        return self


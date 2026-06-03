from __future__ import annotations

from typing import Literal, Optional, TypeVar, Generic
from datetime import datetime
from fastapi import HTTPException
from pydantic import Field, field_validator, model_validator, BaseModel, ConfigDict
from pydantic.alias_generators import to_camel
from .base import FirestoreSchema
from .company import EmpresaRegisterSchema


class UserSchema(FirestoreSchema):
    uid: Optional[str] = None
    nombre: str = Field(..., min_length=1)
    apellido: str = Field(..., min_length=1)
    email: str = Field(..., min_length=3)
    telefono: str = Field(..., min_length=3)
    rol: list[Literal["encargado", "transportista"]] = Field(..., min_length=1)
    permisosCond: Optional[list[str]] = None
    companyId: str = None
    vehiculoId: Optional[str] = None        # matricula del vehiculo
    cargaId: Optional[str] = None
    estado: Literal['sin_asignar', 'asignacion_parcial', 'asignado', 'en_ruta', 'inactivo'] = 'sin_asignar'
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None

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

    @classmethod
    def from_firestore(cls, doc, company_id: str):
        if not doc.exists:
            raise HTTPException(status_code=404, detail='Usuario no encontrado')
        data = doc.to_dict() or {}
        data['uid'] = doc.id
        if company_id != data.get('companyId'):
            raise HTTPException(status_code=403, detail='No autorizado para usar este usuario')
        return cls(**data)

class RegisterRequest(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)
    nombre: str
    apellido: str
    email: str
    telefono: str
    rol: list[str]
    permisos_cond: list[str] = []
    estado: Optional[str] = None
    empresa: EmpresaRegisterSchema
class UserPaginatedSchema(FirestoreSchema):
    items: list[UserSchema]
    last_doc_id: Optional[str] = None
    has_more: bool

class UserCountSchema(FirestoreSchema):
    total_trans: int
    sin_asignar: int
    asignacion_parcial: int
    en_ruta: int
    inactivos: int

T = TypeVar("T", bound=FirestoreSchema)
class UserCreateResponseSchema(BaseModel, Generic[T]):
    user: T
    temp_password: Optional[str] = None
    password_reset_link: Optional[str] = None


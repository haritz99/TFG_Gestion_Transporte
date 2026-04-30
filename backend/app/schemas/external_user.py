from __future__ import annotations

from datetime import datetime
from typing import Optional, List
from fastapi import HTTPException
from pydantic import Field

from .base import FirestoreSchema
from pydantic import BaseModel


class ExternalUserSchema(FirestoreSchema):
    uid: Optional[str] = None
    email: str = Field(..., min_length=3)
    rol: Optional[List[str]] = Field(default_factory=list)
    companyId: Optional[str] = None
    datosCompletos: bool = Field(default=False)
    createdAt: Optional[datetime] = None
    updatedAt: Optional[datetime] = None

class ClienteSchema(ExternalUserSchema):
    nombreComercial: str = Field(..., min_length=1)
    pedidos: List[str] = Field(default_factory=list)
    companyId: Optional[str] = Field(default=None, min_length=1)
    cif: str = Field(..., min_length=9, max_length=9)           # Ej: B12345678
    telefono: str = Field(..., min_length=9)
    personaContacto: str = Field(..., min_length=1)             # Responsable en carga
    direccionFiscal: DireccionSchema                            # Sede legal
    direccionCarga: Optional[DireccionSchema] = None            # Dónde se recoge la mercanía

    @classmethod
    def from_firestore(cls, doc, company_id):
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Cliente no encontrado")
        data = doc.to_dict()
        data["uid"] = doc.id
        if company_id != data.get("companyId"):
            raise HTTPException(status_code=403, detail="No autorizado para obtener este cliente")
        return cls(**data)

class SubcontratadoSchema(ExternalUserSchema):
    nombre: str = Field(..., min_length=1)
    apellido: str = Field(..., min_length=1)
    cargasCedidas: List[str] = Field(default_factory=list)
    nif: str = Field(..., min_length=9, max_length=9)
    telefono: str = Field(..., min_length=9)
    numeroAutorizacion: str = Field(..., min_length=1)          # Nº LOTT obligatorio
    razonSocial: Optional[str] = None                          # Si opera como empresa, no autónomo
    direccion: DireccionSchema


class DireccionSchema(BaseModel):
    calle: str = Field(..., min_length=1)
    ciudad: str = Field(..., min_length=1)
    provincia: str = Field(..., min_length=1)
    codigoPostal: str = Field(..., min_length=4)
    pais: str = Field(default="España", min_length=1)
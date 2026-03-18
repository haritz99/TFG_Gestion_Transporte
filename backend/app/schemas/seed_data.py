from __future__ import annotations

from typing import Dict

from pydantic import Field

from .base import FirestoreSchema
from .cargas import CargaSchema
from .cartas_de_porte import CartaDePorteSchema
from .incidencias import IncidenciaSchema
from .rutas import RutaSchema
from .tareas import TareaSchema
from .users import UserSchema
from .vehiculos import VehiculoSchema


class SeedDataSchema(FirestoreSchema):
    users: Dict[str, UserSchema] = Field(default_factory=dict)
    vehiculos: Dict[str, VehiculoSchema] = Field(default_factory=dict)
    cargas: Dict[str, CargaSchema] = Field(default_factory=dict)
    rutas: Dict[str, RutaSchema] = Field(default_factory=dict)
    incidencias: Dict[str, IncidenciaSchema] = Field(default_factory=dict)
    tareas: Dict[str, TareaSchema] = Field(default_factory=dict)
    cartasDePorte: Dict[str, CartaDePorteSchema] = Field(default_factory=dict)



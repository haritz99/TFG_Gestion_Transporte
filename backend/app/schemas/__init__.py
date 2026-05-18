from .carga import CargaSchema
from .incidencias import IncidenciaSchema
from .rutas import RutaSchema
from .tareas import TareaSchema
from .users import UserSchema
from .vehiculos import VehiculoSchema, VehiculoPaginatedSchema

__all__ = [
    "UserSchema",
    "VehiculoSchema",
    "VehiculoPaginatedSchema",
    "CargaSchema",
    "RutaSchema",
    "IncidenciaSchema",
    "TareaSchema",
]
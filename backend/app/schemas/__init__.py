from .carga import CargaSchema
from .incidencias import IncidenciaSchema
from .users import UserSchema
from .vehiculos import VehiculoSchema, VehiculoPaginatedSchema

__all__ = [
    "UserSchema",
    "VehiculoSchema",
    "VehiculoPaginatedSchema",
    "CargaSchema",
    "IncidenciaSchema",
]
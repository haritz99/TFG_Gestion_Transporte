from .carga import CargaSchema
from .cartas_de_porte import CartaDePorteSchema
from .incidencias import IncidenciaSchema
from .rutas import RutaSchema
from .tareas import TareaSchema
from .users import UserSchema
from .vehiculos import VehiculoSchema

__all__ = [
    "UserSchema",
    "VehiculoSchema",
    "CargaSchema",
    "RutaSchema",
    "IncidenciaSchema",
    "TareaSchema",
    "CartaDePorteSchema",
]


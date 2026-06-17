from pydantic import BaseModel, ConfigDict
from typing import Optional
from pydantic.alias_generators import to_camel

from app.schemas.direccion import DireccionSchema


class EmpresaRegisterSchema(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    nombre: str
    razon_social: Optional[str] = None
    nif: Optional[str] = None
    telefono: Optional[str] = None
    num_autorizacion: Optional[str] = None
    direccion: Optional[DireccionSchema] = None


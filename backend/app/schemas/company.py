from pydantic import BaseModel, Field, ConfigDict
from typing import Optional
from pydantic.alias_generators import to_camel
class DireccionSchema(BaseModel):
    calle: str = Field(..., min_length=1)
    ciudad: str = Field(..., min_length=1)
    provincia: str = Field(..., min_length=1)
    codigoPostal: str = Field(..., min_length=4)
    pais: str = Field(default="España", min_length=1)

class EmpresaRegisterSchema(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)

    nombre: str
    razon_social: Optional[str] = None
    nif: Optional[str] = None
    telefono: Optional[str] = None
    num_autorizacion: Optional[str] = None
    direccion: Optional[DireccionSchema] = None


from pydantic import Field, BaseModel

class DireccionSchema(BaseModel):
    calle: str = Field(..., min_length=1)
    ciudad: str = Field(..., min_length=1)
    provincia: str = Field(..., min_length=1)
    codigoPostal: str = Field(..., min_length=4)
    pais: str = Field(default="España", min_length=1)


class UbicacionSchema(BaseModel):
    direccion: DireccionSchema
    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)
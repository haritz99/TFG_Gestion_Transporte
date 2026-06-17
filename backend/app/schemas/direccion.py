from pydantic import Field, BaseModel

class DireccionSchema(BaseModel):
    calle: str = Field(..., min_length=1)
    ciudad: str = Field(..., min_length=1)
    provincia: str = Field(..., min_length=1)
    codigoPostal: str = Field(..., min_length=4)
    pais: str = Field(default="España", min_length=1)

    @staticmethod
    def format_direccion(direccion: dict) -> str:

        if not direccion:
            return ""

        calle = direccion.get("calle", "")
        cp = direccion.get("codigo_postal", "")
        ciudad = direccion.get("ciudad", "")
        provincia = direccion.get("provincia", "")

        return f"{calle}, {cp} {ciudad} ({provincia})".strip()


class UbicacionSchema(BaseModel):
    direccion: DireccionSchema
    lat: float = Field(..., ge=-90, le=90)
    lng: float = Field(..., ge=-180, le=180)
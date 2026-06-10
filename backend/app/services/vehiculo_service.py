from fastapi import HTTPException, Depends

from ..schemas import VehiculoSchema, VehiculoPaginatedSchema
from ..crud.vehiculos_crud import VehiculoCRUD


class VehiculoService:
    def __init__(self, crud: VehiculoCRUD = Depends(VehiculoCRUD)):
        self.crud = crud

    def get_all(self, company_id: str, limit: int = 8, last_doc_id: str | None = None) -> VehiculoPaginatedSchema:
        query_stream = self.crud.get_all(company_id, limit=limit + 1, last_doc_id=last_doc_id)
        docs = list(query_stream)

        has_more = len(docs) > limit
        if has_more:
            docs = docs[:limit]

        vehiculos = [VehiculoSchema.from_firestore(doc, company_id) for doc in docs]
        last_id = docs[-1].id if docs else None

        return VehiculoPaginatedSchema(
            items=vehiculos,
            last_doc_id=last_id,
            has_more=has_more
        )

    def get_by_id(self, matr: str, company_id: str) -> VehiculoSchema:
        try:
            doc = self.crud.get_by_id(matr)
            return VehiculoSchema.from_firestore(doc, company_id)
        except HTTPException:
            raise
        except Exception:
            raise HTTPException(status_code=500, detail="Error interno del servidor")

    def create(self, vehiculo_data: VehiculoSchema, company_id: str) -> VehiculoSchema:
        try:
            vehiculo_data.companyId = company_id
            doc = self.crud.get_by_id(vehiculo_data.matricula)

            if doc.exists:
                raise HTTPException(status_code=409, detail="Ya existe un vehículo con esa matrícula")

            self.crud.set_vehiculo(vehiculo_data.matricula, vehiculo_data.model_dump())
            return vehiculo_data
        except HTTPException:
            raise
        except Exception:
            raise HTTPException(status_code=500, detail="Error al crear el vehículo")

    def update(self, matr: str, vehiculo_data: VehiculoSchema, company_id: str) -> VehiculoSchema:
        try:
            doc = self.crud.get_by_id(matr)
            if not doc.exists:
                raise HTTPException(status_code=404, detail="Vehículo no encontrado")

            vehiculo_data.companyId = company_id
            self.crud.update_vehiculo(matr, vehiculo_data.model_dump())
            return vehiculo_data
        except HTTPException:
            raise
        except Exception as e:
            print(f"Error al actualizar el vehículo: {e}")
            raise HTTPException(status_code=500, detail="Error al actualizar el vehículo")

    def delete(self, matr: str) -> None:
        try:
            doc = self.crud.get_by_id(matr)
            if not doc.exists:
                raise HTTPException(status_code=404, detail="Vehículo no encontrado")

            self.crud.delete_vehiculo(matr)
        except HTTPException:
            raise
        except Exception:
            raise HTTPException(status_code=500, detail="Error al eliminar el vehículo")
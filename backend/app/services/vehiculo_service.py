from typing import Any

from fastapi import HTTPException

from ..schemas import VehiculoSchema
from ..crud.vehiculos_crud import VehiculoCRUD


def _build_transportista_name(user_data: dict[str, Any]) -> str:
    nombre = user_data.get("nombre") or ""
    apellido = user_data.get("apellido") or ""
    full_name = nombre.strip() + " " + apellido.strip()
    return full_name


class VehiculoService:
    def __init__(self):
        self.crud = VehiculoCRUD()

    def get_all(self, company_id: str) -> list[VehiculoSchema]:
        try:
            query = self.crud.get_all(company_id)
            vehiculos = []
            for doc in query:
                vehiculo = VehiculoSchema.from_firestore(doc, company_id)
                vehiculos.append(vehiculo)
            return vehiculos
        except HTTPException:
            raise
        except Exception:
            raise HTTPException(status_code=500, detail="Error interno del servidor")

    def get_by_id(self, matr: str, company_id: str) -> VehiculoSchema:
        try:
            doc = self.crud.get_by_id(matr)
            vehiculo = VehiculoSchema.from_firestore(doc, company_id)
            return vehiculo
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

            batch = self.crud.get_batch()
            self.crud.set_vehiculo(batch, vehiculo_data.matricula, vehiculo_data.model_dump())

            if vehiculo_data.transportistaId:
                self.crud.update_user_vehiculo_id(batch, vehiculo_data.transportistaId, vehiculo_data.matricula.upper())

            self.crud.commit_batch(batch)
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

            vehiculo_antiguo = VehiculoSchema.from_firestore(doc, company_id)
            vehiculo_data.companyId = company_id

            batch = self.crud.get_batch()
            self.crud.update_vehiculo(batch, matr, vehiculo_data.model_dump())

            old_tid = vehiculo_antiguo.transportistaId
            new_tid = vehiculo_data.transportistaId

            if old_tid != new_tid:
                if old_tid:
                    self.crud.update_user_vehiculo_id(batch, old_tid, None)
                if new_tid:
                    self.crud.update_user_vehiculo_id(batch, new_tid, matr.upper())

            self.crud.commit_batch(batch)
            return vehiculo_data
        except HTTPException:
            raise
        except Exception:
            raise HTTPException(status_code=500, detail="Error al actualizar el vehículo")

    def delete(self, matr: str, company_id: str) -> None:
        try:
            doc = self.crud.get_by_id(matr)
            if not doc.exists:
                 raise HTTPException(status_code=404, detail="Vehículo no encontrado")

            vehiculo = VehiculoSchema.from_firestore(doc, company_id)

            batch = self.crud.get_batch()
            self.crud.delete_vehiculo(batch, matr)
            if vehiculo.transportistaId:
                self.crud.update_user_vehiculo_id(batch, vehiculo.transportistaId, None)

            self.crud.commit_batch(batch)
        except HTTPException:
            raise
        except Exception:
            raise HTTPException(status_code=500, detail="Error al eliminar el vehículo")

    def assign(self, matr: str, uid: str, company_id: str) -> VehiculoSchema:
        try:
            vehiculo_doc = self.crud.get_by_id(matr)
            if not vehiculo_doc.exists:
                raise HTTPException(status_code=404, detail="Vehículo no encontrado")

            vehiculo = VehiculoSchema.from_firestore(vehiculo_doc, company_id)

            transportista_doc = self.crud.get_user_by_id(uid)
            if not transportista_doc.exists:
                raise HTTPException(status_code=404, detail="Transportista no encontrado")

            transportista_data = transportista_doc.to_dict() or {}
            transportista_nombre = _build_transportista_name(transportista_data)

            batch = self.crud.get_batch()
            self.crud.update_vehiculo(batch, matr, {
                "transportistaId": uid,
                "transportistaNombre": transportista_nombre,
                "estado": "asignado",
            })
            self.crud.update_user_vehiculo_id(batch, uid, matr.upper())
            self.crud.commit_batch(batch)

            return VehiculoSchema(
                **vehiculo.model_dump(),
                transportistaId=uid,
                transportistaNombre=transportista_nombre,
                estado="asignado",
            )
        except HTTPException:
            raise
        except Exception:
            raise HTTPException(status_code=500, detail="Error interno del servidor")


def get_vehiculo_service() -> VehiculoService:
    return VehiculoService()

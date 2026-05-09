import datetime
import pytz
from typing import Optional, List
from fastapi import HTTPException, Depends
from ..schemas.carga import CargaSchema, EstadoCarga, TipoCargaSchema
from app.crud.cargas_crud import CargasCRUD
from app.schemas.pedido import PedidoSchema, CreatePedidoSchema


class CargasService:
    def __init__(self, crud: CargasCRUD = Depends(CargasCRUD)):
        self._crud = crud

    def fetch_cargas(self, company_id: str, cliente_id: Optional[str] = None, pedido_id: Optional[str] = None, transportista_id: Optional[str] = None, estado: Optional[EstadoCarga] = None, fecha_inicio: Optional[datetime.date] = None, fecha_fin: Optional[datetime.date] = None) -> List[CargaSchema]:
        dt_inicio = datetime.datetime.combine(fecha_inicio, datetime.time.min) if fecha_inicio else None
        dt_fin = datetime.datetime.combine(fecha_fin, datetime.time.max) if fecha_fin else None
        
        docs = self._crud.get_todas_las_cargas(company_id, cliente_id, pedido_id, transportista_id, estado.value if estado else None, dt_inicio, dt_fin)
        return [CargaSchema.from_firestore(doc, company_id) for doc in docs]

    def get_tipos_carga(self, company_id: str, cliente_id: str):
        docs = self._crud.get_tipos_cargas(company_id, cliente_id)
        return [TipoCargaSchema.from_firestore(doc, company_id) for doc in docs]

    def calculate_asignados(self, company_id: str):
        result = self._crud.get_cargas_count(company_id, EstadoCarga.ASIGNADO.value)
        return result[0][0].value

    def calculate_sin_asignar(self, company_id: str):
        result = self._crud.get_cargas_count(company_id, EstadoCarga.PENDIENTE.value)
        return result[0][0].value

    def calculate_cargas_hoy(self, company_id: str, sod: datetime.datetime, eod: datetime.datetime, estado: Optional[EstadoCarga] = None):
        if sod.tzinfo is None: sod = pytz.utc.localize(sod)
        if eod.tzinfo is None: eod = pytz.utc.localize(eod)
        result = self._crud.get_cargas_hoy_count(company_id, sod, eod, estado.value if estado else None)
        return result[0][0].value

    def get_carga_by_id(self, carga_id: str, company_id: str) -> CargaSchema:
        doc = self._crud.get_carga_doc(carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")
        return CargaSchema.from_firestore(doc, company_id)

    def create_carga(self, carga: CargaSchema, pedido_schema: CreatePedidoSchema, company_id: str) -> CargaSchema:
        carga.companyId = company_id
        carga.clienteId = pedido_schema.clienteId
        
        carga_id = self._crud.create_carga_doc(carga.model_dump())
        carga.id = carga_id
        return carga

    def assign_carga_transportista(self, carga_id: str, transportista_id: str, company_id: str) -> CargaSchema:
        doc = self._crud.get_carga_doc(carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")

        carga = CargaSchema.from_firestore(doc, company_id)

        trans_doc = self._crud.get_trans_doc(transportista_id)
        trans_data = trans_doc.to_dict() if (trans_doc and trans_doc.exists) else None
        if not trans_data or trans_data.get("companyId") != company_id:
            raise HTTPException(status_code=404, detail="Transportista no encontrado")

        roles = trans_data.get("roles", trans_data.get("rol", []))
        if isinstance(roles, str):
            roles = [roles]
        if not roles or "transportista" not in roles:
            raise HTTPException(status_code=403, detail="El usuario no tiene rol de transportista")
            
        carga.transportistaId = transportista_id
        update_data = {"transportistaId": transportista_id}
        
        if carga.estado == EstadoCarga.PENDIENTE:
            carga.estado = EstadoCarga.ASIGNADO
            update_data["estado"] = EstadoCarga.ASIGNADO.value
            
        self._crud.update_carga_doc(carga_id, update_data)
        return carga

    def update_carga(self, carga_id: str, carga: CargaSchema, pedido_schema: PedidoSchema, company_id: str) -> CargaSchema:
        doc = self._crud.get_carga_doc(carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")

        carga_data = doc.to_dict()
        if carga_data.get("companyId") != company_id:
            raise HTTPException(status_code=403, detail="No autorizado para modificar esta carga")

        carga.companyId = company_id
        carga.id = carga_id
            
        try:
            carga.validar_contra_pedido(pedido_schema)
        except ValueError as e:
            raise HTTPException(status_code=400, detail=str(e))

        carga.clienteId = pedido_schema.clienteId
        update_data = carga.model_dump(exclude={'id'})
        
        self._crud.update_carga_doc(carga_id, update_data)
        return carga

    def delete_carga(self, carga_id: str, company_id: str):
        doc = self._crud.get_carga_doc(carga_id)
        if not doc.exists:
            raise HTTPException(status_code=404, detail="Carga no encontrada")

        carga_data = doc.to_dict()
        if carga_data.get("companyId") != company_id:
            raise HTTPException(status_code=403, detail="No autorizado para eliminar esta carga")

        estado_actual = carga_data.get("estado")
        if estado_actual in [EstadoCarga.EN_TRANSITO.value, EstadoCarga.ENTREGADO.value]:
            raise HTTPException(status_code=400, detail=f"No se puede eliminar una carga en estado {estado_actual}.")

        self._crud.delete_carga_doc(carga_id)

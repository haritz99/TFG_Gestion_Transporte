from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status

from ..schemas.external_user import ClienteSchema, ExternalUserSchema
from ..schemas.users import UserCreateResponseSchema
from ..services.register_service import RegisterService, get_register_service
from ..services.pedidos_service import fetch_pedidos
from ..services.cargas_service import fetch_cargas
from ..dependencies.auth import get_current_encargado
from ..firebase_config import db
from ..schemas.pedido import EstadoPedido

router = APIRouter(prefix="/ext", tags=["external_users"], dependencies=[Depends(get_current_encargado)])


@router.post("/", response_model=UserCreateResponseSchema[ExternalUserSchema])
def create_external_user(
    user_data: ExternalUserSchema,
    rol: str,
    current_user: dict[str, Any] = Depends(get_current_encargado),
    service: RegisterService = Depends(get_register_service),
) -> UserCreateResponseSchema[ExternalUserSchema]:
    company_id = current_user.get("companyId")
    return service.create_external_user(user_data=user_data, company_id=company_id, rol=rol)

@router.get("/cli", response_model=list[ClienteSchema])
def get_clientes(current_user: dict[str, Any] = Depends(get_current_encargado)):
    company_id = current_user.get("companyId")
    clientes_ref = db.collection("clientes")
    query = (
        clientes_ref
        .where("companyId", "==", company_id)
        .stream()
    )

    clientes = []
    for doc in query:
        clientes.append(ClienteSchema.from_firestore(doc, company_id))

    return clientes

@router.delete("/cli/{cliente_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_cliente(cliente_id: str, current_user: dict[str, Any] = Depends(get_current_encargado)):
    company_id = current_user.get("companyId")
    cliente_ref = db.collection("clientes").document(cliente_id)
    cliente_doc = cliente_ref.get()

    if not cliente_doc.exists:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
        
    if cliente_doc.to_dict().get("companyId") != company_id:
        raise HTTPException(status_code=403, detail="No autorizado para eliminar este cliente")

    # Verificar si el cliente tiene pedidos activos
    pedidos_del_cliente = fetch_pedidos(company_id=company_id, cliente_id=cliente_id)
    todos_los_pedidos_del_cliente_ids = []
    
    for p in pedidos_del_cliente:
        pedido_id = p.id
        if pedido_id:
            todos_los_pedidos_del_cliente_ids.append(pedido_id)
            
        if p.estado in {EstadoPedido.PLANIFICADO, EstadoPedido.EN_PROGRESO}:
            raise HTTPException(
                status_code=400,
                detail="No se puede eliminar el cliente. Existen pedidos en estado PLANIFICADO o EN_PROGRESO."
            )

    # TODO: El frontend debe mostrar un popup de confirmación indicando que se borrarán también en cascada todos sus pedidos y cargas asociadas.

    # Borrado en cascada
    batch = db.batch()
    for pedido_id in todos_los_pedidos_del_cliente_ids:
        # 1. Borrar todas las cargas asociadas al pedido
        cargas_asociadas = fetch_cargas(company_id=company_id, pedido_id=pedido_id)
        for carga in cargas_asociadas:
            if carga.id:
                carga_ref = db.collection("cargas").document(carga.id)
                batch.delete(carga_ref)

        # 2. Borrar el pedido
        pedido_ref = db.collection("pedidos").document(pedido_id)
        batch.delete(pedido_ref)

    # 3. Borrar el cliente
    batch.delete(cliente_ref)
    
    try:
        batch.commit()
    except Exception as exc:
        raise HTTPException(
            status_code=500,
            detail=f"Error al eliminar el cliente junto con sus pedidos: {exc}"
        )
    return None

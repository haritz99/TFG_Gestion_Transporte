from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from ..dependencies.auth import get_current_encargado
from ..firebase_config import db
from ..schemas.cliente import ClienteSchema
from ..schemas.pedido import EstadoPedido

router = APIRouter(prefix="/clientes", tags=["clientes"])

@router.get("/")
def get_clientes(current_user: dict[str, Any] = Depends(get_current_encargado)):
    clientes_ref = db.collection("clientes")
    query = (
        clientes_ref
        .where("companyId", "==", current_user.get("companyId"))
        .stream()
    )

    clientes = []
    for doc in query:
        cliente_data = doc.to_dict()
        clientes.append(cliente_data)

    return clientes

@router.post("/", status_code=status.HTTP_201_CREATED)
def create_cliente(cliente: ClienteSchema, current_user: dict[str, Any] = Depends(get_current_encargado)):
    cliente.companyId = current_user.get("companyId")
    
    nuevo_cliente_dict = cliente.model_dump()

    doc_ref = db.collection("clientes").document()
    nuevo_cliente_dict["id"] = doc_ref.id
    doc_ref.set(nuevo_cliente_dict)
    
    return nuevo_cliente_dict

@router.delete("/{cliente_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_cliente(cliente_id: str, current_user: dict[str, Any] = Depends(get_current_encargado)):
    company_id = current_user.get("companyId")
    cliente_ref = db.collection("clientes").document(cliente_id)
    cliente_doc = cliente_ref.get()

    if not cliente_doc.exists:
        raise HTTPException(status_code=404, detail="Cliente no encontrado")
        
    if cliente_doc.to_dict().get("companyId") != company_id:
        raise HTTPException(status_code=403, detail="No autorizado para eliminar este cliente")

    # Verificar si el cliente tiene pedidos activos
    pedidos_ref = db.collection("pedidos")
    pedidos_query = pedidos_ref.where("clienteId", "==", cliente_id).where("companyId", "==", company_id).stream()
    
    pedidos_activos = []
    todos_los_pedidos_del_cliente = []
    # tengo que refactorizar esto para llamar a la funcion que cree en router-pedidos
    for doc in pedidos_query:
        pedido_data = doc.to_dict()
        todos_los_pedidos_del_cliente.append(doc.id)
        if pedido_data.get("estado") in [EstadoPedido.PLANIFICADO.value, EstadoPedido.EN_PROGRESO.value]:
            pedidos_activos.append(pedido_data)
            
    if pedidos_activos:
        raise HTTPException(
            status_code=400, 
            detail="No se puede eliminar el cliente. Existen pedidos en estado PLANIFICADO o EN_PROGRESO."
        )

    # TODO: El frontend debe mostrar un popup de confirmación indicando que se borrarán también en cascada todos sus pedidos y cargas asociadas.

    # Borrado en cascada
    for pedido_id in todos_los_pedidos_del_cliente:
        # 1. Borrar todas las cargas asociadas al pedido
        cargas_ref = db.collection("cargas")
        cargas_query = cargas_ref.where("pedidoId", "==", pedido_id).where("companyId", "==", company_id).stream()
        for carga_doc in cargas_query:
            carga_doc.reference.delete()
            
        # 2. Borrar el pedido
        db.collection("pedidos").document(pedido_id).delete()

    cliente_ref.delete()

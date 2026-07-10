from typing import Any
from datetime import datetime, time, timezone
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from ..dependencies.auth import get_current_encargado
from ..schemas.carga import EstadoCarga
from ..services.cargas_service import CargasService

router = APIRouter(prefix="/dashboard", tags=["dashboard"])

class DashboardSummary(BaseModel):
    cargas_asignadas: int
    cargas_sin_asignar: int
    entregadas_hoy: int
    total_entregas_hoy: int


@router.get("/summary", response_model=DashboardSummary)
def fetch_dashboard_summary(current_user: dict[str, Any] = Depends(get_current_encargado),
                            cargas_service = Depends(CargasService)):
    try:
        company_id = current_user.get("companyId")

        today = datetime.now(timezone.utc).date()
        start_of_day = datetime.combine(today, time.min, tzinfo=timezone.utc)
        end_of_day = datetime.combine(today, time.max, tzinfo=timezone.utc)

        cargas_asignadas = cargas_service.calculate_asignados(company_id)

        cargas_sin_asignar = cargas_service.calculate_sin_asignar(company_id)

        entregadas_hoy = cargas_service.calculate_cargas_hoy(company_id, start_of_day, end_of_day, EstadoCarga.ENTREGADO)

        total_entregas_hoy = cargas_service.calculate_cargas_hoy(company_id, start_of_day, end_of_day)

        return DashboardSummary(
            cargas_asignadas=cargas_asignadas,
            cargas_sin_asignar=cargas_sin_asignar,
            entregadas_hoy=entregadas_hoy,
            total_entregas_hoy=total_entregas_hoy
        )
    except Exception as e:
        print("Error fetching dashboard summary: ", str(e))
        raise HTTPException(status_code=500, detail=str(e))


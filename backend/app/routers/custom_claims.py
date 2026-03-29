from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from firebase_admin import auth as firebase_auth
from pydantic import BaseModel, Field
from ..dependencies.auth import get_current_user

router = APIRouter(prefix="/auth", tags=["custom-claims"])

class InitCustomClaimsRequest(BaseModel):
    companyId: str = Field(..., min_length=1)
    rol: list[str] = Field(..., min_length=1)

def normalize_roles(raw_roles: Any) -> list[str]:
    if isinstance(raw_roles, list):
        return [role for role in raw_roles if isinstance(role, str)]
    if isinstance(raw_roles, str) and raw_roles:
        return [raw_roles]
    return []


@router.post("/customClaims/init")
async def inicializar_custom_claims(
    payload: InitCustomClaimsRequest,
    current_user: dict[str, Any] = Depends(get_current_user),
):
    uid = current_user.get("uid")
    if not isinstance(uid, str) or not uid:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token sin uid válido",
        )

    company_id = payload.companyId.strip()
    if not company_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="companyId es obligatorio",
        )
        
    roles = normalize_roles(payload.rol)
    if not roles:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Se requiere al menos un rol",
        )

    claims = {"rol": roles, "companyId": company_id}

    try:
        firebase_auth.set_custom_user_claims(uid, claims)
        print("claims son: " + str(claims))
        return {
            "message": "Custom claims inicializados correctamente.",
            "uid": uid,
            "claims": claims,
        }
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="No se pudieron inicializar los custom claims",
        )

from __future__ import annotations

import os
from typing import Any

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from firebase_admin import auth as firebase_auth

from ..firebase_config import ensure_firebase_initialized

bearer_scheme = HTTPBearer(auto_error=False)
check_revoked = os.getenv("FIREBASE_CHECK_REVOKED", "false").lower() == "true"


def normalize_roles(raw_roles: Any) -> list[str]:
    if isinstance(raw_roles, list):
        return [role for role in raw_roles if isinstance(role, str)]
    if isinstance(raw_roles, str) and raw_roles:
        return [raw_roles]
    return []


async def get_current_user(
        credentials: HTTPAuthorizationCredentials | None = Depends(bearer_scheme),
) -> dict[str, Any]:

    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing or invalid Authorization header",
        )

    token = credentials.credentials.strip()
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing bearer token",
        )

    try:
        ensure_firebase_initialized()
        return firebase_auth.verify_id_token(token, check_revoked=check_revoked)
    except firebase_auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expired",
        )
    except firebase_auth.RevokedIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token revoked",
        )
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )


def _require_role(required_role: str):
    async def role_checker(current_user: dict[str, Any] = Depends(get_current_user)) -> dict[str, Any]:
        uid = current_user.get("uid")
        if not isinstance(uid, str) or not uid:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Token sin uid válido",
            )

        roles = normalize_roles(current_user.get("rol"))
        company_id = current_user.get("companyId")
        
        if required_role not in roles:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"No tienes permisos de {required_role} para realizar esta acción",
            )

        if not isinstance(company_id, str) or not company_id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="El token no contiene un companyId válido",
            )

        current_user["rol"] = roles
        current_user["companyId"] = company_id
        return current_user
    return role_checker

get_current_encargado = _require_role("encargado")
get_current_cargador = _require_role("cliente")
get_current_sub = _require_role("subcontratado")

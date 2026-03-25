from __future__ import annotations

from typing import Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel

from ..dependencies.auth import get_current_user


router = APIRouter(prefix="/auth", tags=["auth"])


class AuthMeResponse(BaseModel):
	uid: str
	email: str | None = None
	email_verified: bool | None = None
	rol: list[str] | None = None
	provider: str | None = None


@router.get("/me", response_model=AuthMeResponse)
async def get_me(current_user: dict[str, Any] = Depends(get_current_user)):
	firebase_data = current_user.get("firebase", {})
	return AuthMeResponse(
		uid=current_user["uid"],
		email=current_user.get("email"),
		email_verified=current_user.get("email_verified"),
		rol=current_user.get("rol"),
		provider=firebase_data.get("sign_in_provider"),
	)


from fastapi import APIRouter, HTTPException
from ..schemas.users import UserSchema


router = APIRouter(prefix="/users", tags=["users"])

"""
@router.post("/")
async def create_user(user: UserSchema):
"""

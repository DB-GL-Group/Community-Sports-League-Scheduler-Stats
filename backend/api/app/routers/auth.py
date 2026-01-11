from fastapi import APIRouter, Depends, HTTPException

from ..dependencies.auth import get_current_user
from ..schemas.auth import LoginRequest, SignupRequest, TokenResponse, UserResponse
from ..services import auth as auth_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post("/signup", response_model=UserResponse)
async def signup(payload: SignupRequest):
    try:
        user = await auth_service.signup(
            payload.first_name,
            payload.last_name,
            payload.email,
            payload.phone,
            payload.password,
            payload.roles,
        )
        return user
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@router.post("/login", response_model=TokenResponse)
async def login(payload: LoginRequest):
    try:
        return await auth_service.login(payload.email, payload.password)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc))


@router.get("/me", response_model=UserResponse)
async def me(current_user: UserResponse = Depends(get_current_user)):
    return current_user

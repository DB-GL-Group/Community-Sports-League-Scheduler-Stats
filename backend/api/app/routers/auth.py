from fastapi import APIRouter, Depends, HTTPException

from ..dependencies.auth import get_current_user
from ..schemas.auth import LoginRequest, SignupRequest, TokenResponse, UserResponse, UserWithPersonResponse
from shared.persons import get_person
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


@router.get("/me", response_model=UserWithPersonResponse)
async def me(current_user: UserResponse = Depends(get_current_user)):
    person = None
    if current_user.get("person_id"):
        person = await get_person(current_user["person_id"])
    return {"user": current_user, "person": person or None}

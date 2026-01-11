from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer

from ..services import auth as auth_service

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/auth/login")


async def get_current_user(token: str = Depends(oauth2_scheme)):
    try:
        payload = auth_service.decode_access_token(token)
    except ValueError as exc:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(exc),
            headers={"WWW-Authenticate": "Bearer"},
        )
    user_id = payload.get("sub")
    if not user_id:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token payload",
            headers={"WWW-Authenticate": "Bearer"},
        )
    user = await auth_service.get_user_by_id(int(user_id))
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="User not found",
            headers={"WWW-Authenticate": "Bearer"},
        )
    if not user["is_active"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="User inactive",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return user


ROLE_HIERARCHY = {
    "PUBLIC": {"PUBLIC", "FAN", "MANAGER", "REFEREE", "ADMIN"},
    "FAN": {"FAN", "MANAGER", "REFEREE", "ADMIN"},
    "MANAGER": {"MANAGER", "ADMIN"},
    "REFEREE": {"REFEREE", "ADMIN"},
    "ADMIN": {"ADMIN"},
}


def require_role(role: str):
    async def _checker(current_user: dict = Depends(get_current_user)):
        allowed_roles = ROLE_HIERARCHY.get(role, {role})
        if not set(current_user.get("roles", [])).intersection(allowed_roles):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Role required",
            )
        return current_user

    return _checker

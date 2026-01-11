
import os
from datetime import datetime, timedelta, timezone

import jwt
from passlib.hash import argon2

from shared import users as repo

JWT_SECRET = os.getenv("JWT_SECRET", "dev-secret-change-me")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_EXPIRES_MINUTES = int(os.getenv("JWT_EXPIRES_MINUTES", "60"))


def _build_user_dict(raw):
    user_id, email, is_active, created_at, roles = raw
    return {
        "id": user_id,
        "email": email,
        "is_active": is_active,
        "created_at": created_at,
        "roles": roles or [],
    }


async def signup(email: str, password: str, roles: list[str]):
    if await repo.get_user_by_email(email):
        raise ValueError("Email already used")
    password_hash = argon2.hash(password)
    normalized = [r.upper() for r in roles]
    return await repo.create_user(email, password_hash, normalized)


def create_access_token(user: dict) -> str:
    expires = datetime.now(timezone.utc) + timedelta(minutes=JWT_EXPIRES_MINUTES)
    payload = {
        "sub": str(user["id"]),
        "email": user["email"],
        "roles": user.get("roles", []),
        "exp": expires,
    }
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def decode_access_token(token: str) -> dict:
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    except jwt.ExpiredSignatureError as exc:
        raise ValueError("Token expired") from exc
    except jwt.InvalidTokenError as exc:
        raise ValueError("Invalid token") from exc


async def login(email: str, password: str):
    user = await repo.get_user_with_credentials(email)
    if not user:
        raise ValueError("Invalid credentials")
    user_id, user_email, password_hash, is_active, created_at, roles = user
    if not is_active:
        raise ValueError("User is inactive")
    if not argon2.verify(password, password_hash):
        raise ValueError("Invalid credentials")

    user_dict = {
        "id": user_id,
        "email": user_email,
        "is_active": is_active,
        "created_at": created_at,
        "roles": roles or [],
    }
    token = create_access_token(user_dict)
    return {"access_token": token, "token_type": "bearer", "user": user_dict}


async def get_user_by_id(user_id: int):
    raw = await repo.get_user_by_id_with_roles(user_id)
    if not raw:
        return None
    return _build_user_dict(raw)

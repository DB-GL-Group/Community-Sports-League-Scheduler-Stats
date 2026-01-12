
import os
from datetime import datetime, timedelta, timezone

import jwt
from passlib.hash import argon2

from shared import users 

JWT_SECRET = os.getenv("JWT_SECRET", "dev-secret-change-me")
JWT_ALGORITHM = os.getenv("JWT_ALGORITHM", "HS256")
JWT_EXPIRES_MINUTES = int(os.getenv("JWT_EXPIRES_MINUTES", "60"))


def _build_user_dict(raw: dict) -> dict:
    return {
        "id": raw.get("id"),
        "email": raw.get("email"),
        "is_active": raw.get("is_active"),
        "created_at": raw.get("created_at"),
        "person_id": raw.get("person_id"),
        "roles": raw.get("roles", []),
    }


async def signup(
    first_name: str,
    last_name: str,
    email: str,
    password: str,
    roles: list[str],
    role_keys: dict[str, str] | None = None,
):
    if await users.get_user_by_email(email):
        raise ValueError("Email already used")
    password_hash = argon2.hash(password)
    normalized = [r.upper() for r in roles]

    if users.UserRoles.ADMIN.value in normalized:
        raise ValueError("Admin signups are not allowed")

    if not normalized:
        normalized = [users.UserRoles.FAN.value]

    role_keys = role_keys or {}

    needs_key = {users.UserRoles.MANAGER.value, users.UserRoles.REFEREE.value}
    for role in normalized:
        if role in needs_key:
            if role not in role_keys:
                raise ValueError(f"Missing role key for {role}")

    from shared.role_keys import is_role_key_available, mark_role_key_used

    for role in normalized:
        if role in needs_key:
            token = role_keys.get(role, "")
            if not await is_role_key_available(role, token):
                raise ValueError(f"Invalid or used role key for {role}")

    user = await users.create_user(first_name, last_name, email, password_hash, normalized)

    for role in normalized:
        if role in needs_key:
            token = role_keys.get(role, "")
            marked = await mark_role_key_used(role, token, user["id"])
            if not marked:
                raise ValueError(f"Role key already used for {role}")

    return user


def create_access_token(user: dict) -> str:
    expires = datetime.now(timezone.utc) + timedelta(minutes=JWT_EXPIRES_MINUTES)
    payload = {
        "sub": str(user["id"]),
        "email": user["email"],
        "person_id": user.get("person_id"),
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
    user = await users.get_user_with_credentials(email)
    if not user:
        raise ValueError("Invalid credentials")
    if not user.get("is_active"):
        raise ValueError("User is inactive")
    if not argon2.verify(password, user.get("password_hash", "")):
        raise ValueError("Invalid credentials")

    user_dict = {
        "id": user["id"],
        "email": user["email"],
        "is_active": user["is_active"],
        "created_at": user["created_at"],
        "person_id": user.get("person_id"),
        "roles": user.get("roles", []),
    }
    token = create_access_token(
        {
            "id": user["id"],
            "email": user["email"],
            "person_id": user.get("person_id"),
            "roles": user.get("roles", []),
        }
    )
    return {"access_token": token, "token_type": "bearer", "user": user_dict}


async def get_user_by_id(user_id: int):
    raw = await users.get_user_by_id_with_roles(user_id)
    if not raw:
        return None
    return _build_user_dict(raw)

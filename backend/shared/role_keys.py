import secrets
from datetime import datetime, timezone

from shared.db import get_async_pool


def _generate_token() -> str:
    return secrets.token_urlsafe(32)


async def create_role_key(role_name: str, created_by: int | None):
    token = _generate_token()
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO role_invite_keys (role_name, token, created_by)
            VALUES (%s, %s, %s)
            RETURNING id, role_name, token, created_at
            """,
            (role_name, token, created_by),
        )
        row = await cur.fetchone()
        await conn.commit()
        if not row:
            return {}
        return {
            "id": row[0],
            "role_name": row[1],
            "token": row[2],
            "created_at": row[3],
        }


async def mark_role_key_used(role_name: str, token: str, user_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            UPDATE role_invite_keys
            SET used_by = %s, used_at = %s
            WHERE role_name = %s AND token = %s AND used_at IS NULL
            RETURNING id
            """,
            (user_id, datetime.now(timezone.utc), role_name, token),
        )
        row = await cur.fetchone()
        await conn.commit()
        if not row:
            return {}
        return {"id": row[0]}


async def is_role_key_available(role_name: str, token: str) -> bool:
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT 1
            FROM role_invite_keys
            WHERE role_name = %s AND token = %s AND used_at IS NULL
            """,
            (role_name, token),
        )
        row = await cur.fetchone()
        return row is not None

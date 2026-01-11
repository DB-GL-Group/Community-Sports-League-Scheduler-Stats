from enum import Enum
from shared.managers import create_manager
from shared.referees import create_referee
from shared.admins import create_admin
from shared.db import get_async_pool
from shared.persons import create_person

class UserRoles(str, Enum):
    MANAGER = "MANAGER"
    FAN = "FAN"
    REFEREE = "REFEREE"
    ADMIN = "ADMIN"

async def get_user_by_email(email: str):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id, email, is_active, created_at, person_id
            FROM users
            WHERE email = %s
            """,
            (email,),
        )
        row = await cur.fetchone()
        if not row:
            return {}
        return {
            "id": row[0],
            "email": row[1],
            "is_active": row[2],
            "created_at": row[3],
            "person_id": row[4],
        }


async def get_user_by_id_with_roles(user_id: int):
    """Return user with aggregated roles (no password hash)."""
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT u.id, u.email, u.is_active, u.created_at, u.person_id,
                   COALESCE(array_agg(r.name ORDER BY r.name) FILTER (WHERE r.name IS NOT NULL), '{}') AS roles
            FROM users u
            LEFT JOIN user_roles ur ON ur.user_id = u.id
            LEFT JOIN roles r ON r.id = ur.role_id
            WHERE u.id = %s
            GROUP BY u.id, u.email
            """,
            (user_id,),
        )
        row = await cur.fetchone()
        if not row:
            return {}
        return {
            "id": row[0],
            "email": row[1],
            "is_active": row[2],
            "created_at": row[3],
            "person_id": row[4],
            "roles": row[5] or [],
        }


async def get_user_with_credentials(email: str):
    """Return user + password_hash + roles for authentication."""
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT u.id, u.email, u.password_hash, u.is_active, u.created_at, u.person_id,
                   COALESCE(array_agg(r.name ORDER BY r.name) FILTER (WHERE r.name IS NOT NULL), '{}') AS roles
            FROM users u
            LEFT JOIN user_roles ur ON ur.user_id = u.id
            LEFT JOIN roles r ON r.id = ur.role_id
            WHERE u.email = %s
            GROUP BY u.id
            """,
            (email,),
        )
        row = await cur.fetchone()
        if not row:
            return {}
        return {
            "id": row[0],
            "email": row[1],
            "password_hash": row[2],
            "is_active": row[3],
            "created_at": row[4],
            "person_id": row[5],
            "roles": row[6] or [],
        }


async def create_user(
    first_name: str,
    last_name: str,
    email: str,
    phone: str,
    password_hash: str,
    roles: list[str],
):
    person = await create_person(first_name, last_name, phone)
    match roles:
        case UserRoles.MANAGER.value:
            await create_manager(person["id"])
        case UserRoles.REFEREE.value:
            await create_referee(person["id"])
        case UserRoles.ADMIN.value:
            await create_admin(person["id"])
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO users (email, password_hash, person_id)
            VALUES (%s, %s, %s)
            RETURNING id, created_at, is_active, person_id
            """,
            (email, password_hash, person["id"]),
        )
        user = await cur.fetchone()
        await cur.execute("SELECT id, name FROM roles WHERE name = ANY(%s)", (roles,))
        role_rows = await cur.fetchall()
        role_ids = [r[0] for r in role_rows]
        if not role_ids:
            raise ValueError("No valid roles")
        await cur.executemany(
            "INSERT INTO user_roles (user_id, role_id) VALUES (%s, %s) ON CONFLICT DO NOTHING",
            [(user[0], rid) for rid in role_ids],
        )
        await conn.commit()
        return {
            "id": user[0],
            "email": email,
            "is_active": user[2],
            "created_at": user[1],
            "person_id": user[3],
            "roles": [r[1] for r in role_rows],
        }

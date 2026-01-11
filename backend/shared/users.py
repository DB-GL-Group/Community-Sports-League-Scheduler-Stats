from shared.db import get_async_pool


async def get_user_by_email(email: str):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute("SELECT id, email, is_active, created_at FROM users WHERE email=%s", (email,))
        return await cur.fetchone()


async def get_user_by_id_with_roles(user_id: int):
    """Return user with aggregated roles (no password hash)."""
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT u.id, u.email, u.is_active, u.created_at,
                   COALESCE(array_agg(r.name ORDER BY r.name) FILTER (WHERE r.name IS NOT NULL), '{}') AS roles
            FROM users u
            LEFT JOIN user_roles ur ON ur.user_id = u.id
            LEFT JOIN roles r ON r.id = ur.role_id
            WHERE u.id = %s
            GROUP BY u.id
            """,
            (user_id,),
        )
        return await cur.fetchone()


async def get_user_with_credentials(email: str):
    """Return user + password_hash + roles for authentication."""
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT u.id, u.email, u.password_hash, u.is_active, u.created_at,
                   COALESCE(array_agg(r.name ORDER BY r.name) FILTER (WHERE r.name IS NOT NULL), '{}') AS roles
            FROM users u
            LEFT JOIN user_roles ur ON ur.user_id = u.id
            LEFT JOIN roles r ON r.id = ur.role_id
            WHERE u.email = %s
            GROUP BY u.id
            """,
            (email,),
        )
        return await cur.fetchone()


async def create_user(email: str, password_hash: str, roles: list[str]):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            "INSERT INTO users (email, password_hash) VALUES (%s, %s) RETURNING id, created_at, is_active",
            (email, password_hash),
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
            "roles": [r[1] for r in role_rows],
        }

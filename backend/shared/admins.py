from shared.persons import create_person
from shared.db import get_async_pool


async def create_admin(person_id):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO admins (person_id)
            VALUES (%s)
            RETURNING person_id
            """,
            (person_id),
        )
        admin_id = await cur.fetchone()
        await conn.commit()
        if not admin_id:
            return {}
        return {"id": admin_id[0]}

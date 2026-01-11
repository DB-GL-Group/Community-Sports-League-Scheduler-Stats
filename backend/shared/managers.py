from shared.persons import create_person
from shared.db import get_async_pool


async def create_manager(first_name: str, last_name: str, email: str, phone: str):
    pool = get_async_pool()
    person_info = await create_person(first_name, last_name, email, phone)
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO managers (id)
            VALUES (%s)
            RETURNING id
            """,
            (person_info["id"],),
        )
        manager_id = await cur.fetchone()
        await conn.commit()
        return {"id": manager_id[0]}

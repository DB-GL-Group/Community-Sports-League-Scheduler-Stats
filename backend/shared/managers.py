from shared.persons import create_person
from shared.db import get_async_pool


async def create_manager(person_id):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO managers (person_id)
            VALUES (%s)
            RETURNING person_id
            """,
            (person_id,),
        )
        manager_id = await cur.fetchone()
        await conn.commit()
        if not manager_id:
            return {}
        return {"id": manager_id[0]}

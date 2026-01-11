from shared.persons import create_person
from shared.db import get_async_pool


async def create_player(first_name: str, last_name: str, phone: str):
    pool = get_async_pool()
    person_info = await create_person(first_name, last_name, phone)
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO players (person_id)
            VALUES (%s)
            RETURNING person_id
            """,
            (person_info["id"],),
        )
        player_id = await cur.fetchone()
        await conn.commit()
        if not player_id:
            return {}
        return {"id": player_id[0]}

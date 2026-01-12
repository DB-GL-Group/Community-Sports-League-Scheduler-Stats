from shared.persons import create_person
from shared.db import get_async_pool


async def create_player(first_name: str, last_name: str):
    pool = get_async_pool()
    person_info = await create_person(first_name, last_name)
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


async def delete_player_if_orphaned(player_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT 1
            FROM player_team
            WHERE player_id = %s
            LIMIT 1
            """,
            (player_id,),
        )
        still_linked = await cur.fetchone()
        if still_linked:
            return {"deleted": False}

        await cur.execute(
            """
            DELETE FROM players
            WHERE person_id = %s
            RETURNING person_id
            """,
            (player_id,),
        )
        player_row = await cur.fetchone()
        if not player_row:
            await conn.commit()
            return {"deleted": False}

        await cur.execute(
            """
            DELETE FROM persons
            WHERE id = %s
            RETURNING id
            """,
            (player_row[0],),
        )
        person_row = await cur.fetchone()
        await conn.commit()
        return {"deleted": person_row is not None}

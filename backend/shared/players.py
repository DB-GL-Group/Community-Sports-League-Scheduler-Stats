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


async def list_available_players(team_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT p.id, p.first_name, p.last_name
            FROM players pl
            JOIN persons p ON p.id = pl.person_id
            WHERE NOT EXISTS (
                SELECT 1
                FROM teams t
                JOIN player_team pt ON pt.team_id = t.id
                WHERE pt.player_id = pl.person_id
                  AND t.division = (SELECT division FROM teams WHERE id = %s)
            )
            ORDER BY p.last_name, p.first_name
            """,
            (team_id,),
        )
        rows = await cur.fetchall()
        return [
            {"id": row[0], "first_name": row[1], "last_name": row[2]}
            for row in rows
        ]


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

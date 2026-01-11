from shared.db import get_async_pool


async def create_team(division, name, manager_id, short_name, color_primary, color_secondary):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO teams (division, name, manager_id, short_name, color_primary, color_secondary)
            VALUES (%s, %s, %s, %s, %s, %s)
            RETURNING id, division, name, manager_id, short_name, color_primary, color_secondary
            """,
            (division, name, manager_id, short_name, color_primary, color_secondary),
        )
        team = await cur.fetchone()
        await conn.commit()
        return team


async def add_player(player_id, team_id):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO player_team (player_id, team_id)
            VALUES (%s, %s)
            RETURNING player_id, team_id, shirt_number, active
            """,
            (player_id, team_id),
        )
        player_team = await cur.fetchone()
        await conn.commit()
        return player_team

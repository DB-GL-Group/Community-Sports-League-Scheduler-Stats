from shared.db import get_async_pool

async def get_all_teams_id():
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id
            FROM teams
            """
        )
        allTeamsIDs = await cur.fetchall()
        return(allTeamsIDs)

async def get_team_by_manager_id(manager_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id, division, name, manager_id, short_name, color_primary, color_secondary
            FROM teams
            WHERE manager_id = %s
            """,
            (manager_id,),
        )
        return await cur.fetchone()


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
        return {"id" : team[0]}


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

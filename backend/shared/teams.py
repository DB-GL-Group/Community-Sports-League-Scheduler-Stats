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
        rows = await cur.fetchall()
        return [{"id": row[0]} for row in rows]

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
        row = await cur.fetchone()
        if not row:
            return {}
        return {
            "id": row[0],
            "division": row[1],
            "name": row[2],
            "manager_id": row[3],
            "short_name": row[4],
            "color_primary": row[5],
            "color_secondary": row[6],
        }


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
        if not team:
            return {}
        return {
            "id": team[0],
            "division": team[1],
            "name": team[2],
            "manager_id": team[3],
            "short_name": team[4],
            "color_primary": team[5],
            "color_secondary": team[6],
        }


async def add_player(player_id, team_id):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO player_team (player_id, team_id)
            VALUES (%s, %s)
            ON CONFLICT DO NOTHING
            RETURNING player_id, team_id, shirt_number, active
            """,
            (player_id, team_id),
        )
        player_team = await cur.fetchone()
        await conn.commit()
        if not player_team:
            return {}
        return {
            "player_id": player_team[0],
            "team_id": player_team[1],
            "shirt_number": player_team[2],
            "active": player_team[3],
        }


async def remove_player_from_team(player_id, team_id):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            DELETE FROM player_team
            WHERE player_id = %s AND team_id = %s
            RETURNING player_id, team_id
            """,
            (player_id, team_id),
        )
        row = await cur.fetchone()
        await conn.commit()
        if not row:
            return {}
        return {"player_id": row[0], "team_id": row[1]}

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

async def get_all_valid_teams(min_players: int = 11):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT t.id, t.division, t.name, t.manager_id, t.short_name, t.color_primary, t.color_secondary
            FROM teams t
            JOIN player_team pt ON pt.team_id = t.id
            GROUP BY t.id, t.division, t.name, t.manager_id, t.short_name, t.color_primary, t.color_secondary
            HAVING COUNT(pt.player_id) >= %s
            ORDER BY t.division, t.name
            """,
            (min_players,),
        )
        rows = await cur.fetchall()
        return [
            {
                "id": row[0],
                "division": row[1],
                "name": row[2],
                "manager_id": row[3],
                "short_name": row[4],
                "color_primary": row[5],
                "color_secondary": row[6],
            }
            for row in rows
        ]
    
async def get_team_details(team_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id, division, name, manager_id, short_name, color_primary, color_secondary
            FROM teams
            WHERE id = %s
            """,
            (team_id,),
        )
        row = await cur.fetchone()
        if not row: 
            return {}
        players = await list_team_players(team_id)
        return {
            "id": row[0],
            "division": row[1],
            "name": row[2],
            "manager_id": row[3],
            "short_name": row[4],
            "color_primary": row[5],
            "color_secondary": row[6],
            "players": players
        }


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
        players = await list_team_players(row[0])
        return {
            "id": row[0],
            "division": row[1],
            "name": row[2],
            "manager_id": row[3],
            "short_name": row[4],
            "color_primary": row[5],
            "color_secondary": row[6],
            "players": players,
        }
    
async def get_team_ID_by_name(team_name: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id
            FROM teams
            WHERE name = %s
            """,
            (team_name,),
        )
        row = await cur.fetchone()
        if not row:
            return {}
        return {"id": row[0]}

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


async def update_team(team_id, division, name, short_name, color_primary, color_secondary):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            UPDATE teams
            SET division = %s,
                name = %s,
                short_name = %s,
                color_primary = %s,
                color_secondary = %s
            WHERE id = %s
            RETURNING id, division, name, manager_id, short_name, color_primary, color_secondary
            """,
            (division, name, short_name, color_primary, color_secondary, team_id),
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


async def add_player(player_id, team_id, shirt_number):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO player_team (player_id, team_id, shirt_number)
            VALUES (%s, %s, %s)
            ON CONFLICT DO NOTHING
            RETURNING player_id, team_id, shirt_number
            """,
            (player_id, team_id, shirt_number),
        )
        player_team = await cur.fetchone()
        await conn.commit()
        if not player_team:
            return {}
        return {
            "player_id": player_team[0],
            "team_id": player_team[1],
            "shirt_number": player_team[2],
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


async def list_team_players(team_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT p.id, p.first_name, p.last_name, pt.shirt_number
            FROM player_team pt
            JOIN persons p ON p.id = pt.player_id
            WHERE pt.team_id = %s
            ORDER BY p.last_name, p.first_name
            """,
            (team_id,),
        )
        rows = await cur.fetchall()
        return [
            {
                "id": row[0],
                "first_name": row[1],
                "last_name": row[2],
                "number": row[3],
            }
            for row in rows
        ]



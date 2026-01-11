from shared.persons import create_person
from shared.db import get_async_pool


async def create_referee(first_name: str, last_name: str, email: str, phone: str):
    pool = get_async_pool()
    person_info = await create_person(first_name, last_name, email, phone)
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO referees (person_id)
            VALUES (%s)
            RETURNING person_id
            """,
            (person_info["id"],),
        )
        referee_id = await cur.fetchone()
        await conn.commit()
        if not referee_id:
            return {}
        return {"id": referee_id[0]}


async def get_referee_availability(referee_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT s.id, s.court_id, s.start_time, s.end_time
            FROM ref_dispos rd
            JOIN slots s ON s.id = rd.slot_id
            WHERE rd.referee_id = %s
            ORDER BY s.start_time
            """,
            (referee_id,),
        )
        rows = await cur.fetchall()
        return [
            {"slot_id": row[0], "court_id": row[1], "start_time": row[2], "end_time": row[3]}
            for row in rows
        ]


async def add_referee_availability(referee_id: int, slot_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO ref_dispos (referee_id, slot_id)
            VALUES (%s, %s)
            ON CONFLICT DO NOTHING
            RETURNING referee_id, slot_id
            """,
            (referee_id, slot_id),
        )
        row = await cur.fetchone()
        await conn.commit()
        if not row:
            return {}
        return {"id": row[0], "slot_id": row[1]}


async def remove_referee_availability(referee_id: int, slot_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            DELETE FROM ref_dispos
            WHERE referee_id = %s AND slot_id = %s
            RETURNING referee_id, slot_id
            """,
            (referee_id, slot_id),
        )
        row = await cur.fetchone()
        await conn.commit()
        if not row:
            return {}
        return {"id": row[0], "slot_id": row[1]}


async def replace_referee_availability(referee_id: int, slot_ids: list[int]):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute("DELETE FROM ref_dispos WHERE referee_id = %s", (referee_id,))
        if slot_ids:
            await cur.executemany(
                "INSERT INTO ref_dispos (referee_id, slot_id) VALUES (%s, %s) ON CONFLICT DO NOTHING",
                [(referee_id, slot_id) for slot_id in slot_ids],
            )
        await conn.commit()
        return {"id": referee_id, "count": len(slot_ids)}


async def get_referee_matches(referee_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT DISTINCT ON (m.id)
                   m.id,
                   m.division,
                   m.status,
                   ht.name AS home_team,
                   at.name AS away_team,
                   COALESCE(m.home_score, 0) AS home_score,
                   COALESCE(m.away_score, 0) AS away_score,
                   s.start_time
            FROM matches m
            JOIN teams ht ON ht.id = m.home_team_id
            JOIN teams at ON at.id = m.away_team_id
            JOIN slots s ON s.id = m.slot_id
            LEFT JOIN match_referees mr ON mr.match_id = m.id
            WHERE m.main_referee_id = %s OR mr.referee_id = %s
            ORDER BY m.id, s.start_time
            """,
            (referee_id, referee_id),
        )
        rows = await cur.fetchall()
        return [
            {
                "id": row[0],
                "division": row[1],
                "status": row[2],
                "home_team": row[3],
                "away_team": row[4],
                "home_score": row[5],
                "away_score": row[6],
                "start_time": row[7],
            }
            for row in rows
        ]

async def get_match_slots_without_referee():
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT s.id, s.court_id, s.start_time, s.end_time, m.id AS match_id
            FROM matches m
            JOIN slots s ON s.id = m.slot_id
            LEFT JOIN match_referees mr ON mr.match_id = m.id
            WHERE m.main_referee_id IS NULL
              AND mr.match_id IS NULL
            ORDER BY s.start_time
            """
        )
        rows = await cur.fetchall()
        return [
            {
                "slot_id": row[0],
                "court_id": row[1],
                "start_time": row[2],
                "end_time": row[3],
                "match_id": row[4],
            }
            for row in rows
        ]
        

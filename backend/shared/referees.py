from datetime import datetime, timedelta, timezone

from helper.redis import _get_queue
from shared.persons import create_person
from shared.db import get_async_pool
from worker.tasks.assign_referee import run_assign_referees_for_slots


async def create_referee(person_id):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO referees (person_id)
            VALUES (%s)
            RETURNING person_id
            """,
            (person_id,),
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
            SELECT s.id, v.name AS venue, s.start_time, s.end_time,
                   ht.name || ' vs ' || at.name AS match
            FROM ref_dispos rd
            JOIN slots s ON s.id = rd.slot_id
            JOIN courts c ON c.id = s.court_id
            JOIN venues v ON v.id = c.venue_id
            JOIN match_slot ms ON ms.slot_id = s.id
            JOIN matches m ON m.id = ms.match_id
            JOIN teams ht ON ht.id = m.home_team_id
            JOIN teams at ON at.id = m.away_team_id
            WHERE rd.referee_id = %s
            ORDER BY s.start_time
            """,
            (referee_id,),
        )
        rows = await cur.fetchall()
        return [
            {"id": row[0], "venue": row[1], "start_time": row[2], "end_time": row[3], "match": row[4]}
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
        queue = _get_queue()
        queue.enqueue(run_assign_referees_for_slots, [slot_id])
        return {"id": row[0], "slot_id": row[1]}


async def remove_referee_availability(referee_id: int, slot_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT start_time
            FROM slots
            WHERE id = %s
            """,
            (slot_id,),
        )
        slot_row = await cur.fetchone()
        if not slot_row:
            return {}
        start_time = slot_row[0]
        if start_time <= datetime.now(timezone.utc) + timedelta(hours=24):
            return {"locked": True, "start_time": start_time}

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
        queue = _get_queue()
        queue.enqueue(run_assign_referees_for_slots, [slot_id])
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
        queue = _get_queue()
        queue.enqueue(run_assign_referees_for_slots, None)
        return {"id": referee_id, "count": len(slot_ids)}


async def get_referee_matches(referee_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT m.id,
                   m.division,
                   ht.name AS home_team,
                   at.name AS away_team,
                   MIN(s.start_time) AS start_time,
                   MAX(s.end_time) AS end_time,
                   MIN(v.name) AS venue
            FROM match_referees mr
            JOIN matches m ON m.id = mr.match_id
            JOIN teams ht ON ht.id = m.home_team_id
            JOIN teams at ON at.id = m.away_team_id
            LEFT JOIN match_slot ms ON ms.match_id = m.id
            LEFT JOIN slots s ON s.id = ms.slot_id
            LEFT JOIN courts c ON c.id = s.court_id
            LEFT JOIN venues v ON v.id = c.venue_id
            WHERE mr.referee_id = %s
            GROUP BY m.id, m.division, ht.name, at.name
            ORDER BY MIN(s.start_time)
            """,
            (referee_id,),
        )
        rows = await cur.fetchall()
        return [
            {
                "id": row[0],
                "division": row[1],
                "status": "Accepted",
                "home_team": row[2],
                "away_team": row[3],
                "start_time": row[4],
                "end_time": row[5],
                "venue": row[6],
            }
            for row in rows
        ]


async def get_referee_history(referee_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT m.id,
                   m.division,
                   m.status,
                   ht.name AS home_team,
                   at.name AS away_team,
                   COALESCE(m.home_score, 0) AS home_score,
                   COALESCE(m.away_score, 0) AS away_score,
                   MIN(s.start_time) AS start_time,
                   MAX(s.end_time) AS end_time,
                   v.name AS venue
            FROM matches m
            JOIN teams ht ON ht.id = m.home_team_id
            JOIN teams at ON at.id = m.away_team_id
            JOIN match_referees mr ON mr.match_id = m.id
            LEFT JOIN match_slot ms ON ms.match_id = m.id
            LEFT JOIN slots s ON s.id = ms.slot_id
            LEFT JOIN courts c ON c.id = s.court_id
            LEFT JOIN venues v ON v.id = c.venue_id
            WHERE mr.referee_id = %s AND m.status = 'finished'
            GROUP BY m.id, m.division, m.status, ht.name, at.name, m.home_score, m.away_score, v.name
            ORDER BY start_time DESC
            """,
            (referee_id,),
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
                "end_time": row[8],
                "venue": row[9],
            }
            for row in rows
        ]

async def get_match_slots_without_referee(referee_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT s.id, v.name AS venue, s.start_time, s.end_time,
                   ht.name || ' vs ' || at.name AS match
            FROM matches m
            JOIN match_slot ms ON ms.match_id = m.id
            JOIN slots s ON s.id = ms.slot_id
            JOIN courts c ON c.id = s.court_id
            JOIN venues v ON v.id = c.venue_id
            JOIN teams ht ON m.home_team_id = ht.id
            JOIN teams at ON m.away_team_id = at.id
            LEFT JOIN ref_dispos rd ON rd.slot_id = s.id AND rd.referee_id = %s
            WHERE s.start_time > (NOW() + INTERVAL '24 hours')
               OR rd.referee_id IS NOT NULL
            ORDER BY s.start_time
            """,
            (referee_id,),
        )
        rows = await cur.fetchall()
        return [
            {
                "id": row[0],
                "venue": row[1],
                "start_time": row[2],
                "end_time": row[3],
                "match": row[4],
            }
            for row in rows
        ]
        

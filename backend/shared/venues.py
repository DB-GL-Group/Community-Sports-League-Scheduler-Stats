from shared.db import get_async_pool
from shared.matches import MatchStatus


async def add_venue(name, address):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO venues (name, address)
            VALUES (%s, %s)
            RETURNING id, name, address
            """,
            (name, address),
        )
        venue = await cur.fetchone()
        await conn.commit()
        if not venue:
            return {}
        return {"id": venue[0], "name": venue[1], "address": venue[2]}


async def list_venues():
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id, name, address
            FROM venues
            ORDER BY id DESC
            """
        )
        rows = await cur.fetchall()
        return [{"id": row[0], "name": row[1], "address": row[2]} for row in rows]


async def update_venue(venue_id: int, name: str, address: str | None):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            UPDATE venues
            SET name = %s,
                address = %s
            WHERE id = %s
            RETURNING id, name, address
            """,
            (name, address, venue_id),
        )
        row = await cur.fetchone()
        await conn.commit()
        if not row:
            return {}
        return {"id": row[0], "name": row[1], "address": row[2]}


async def delete_venue(venue_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT DISTINCT m.id,
                   ht.name AS home_team,
                   at.name AS away_team,
                   s.start_time
            FROM matches m
            JOIN match_slot ms ON ms.match_id = m.id
            JOIN slots s ON s.id = ms.slot_id
            JOIN courts c ON c.id = s.court_id
            JOIN venues v ON v.id = c.venue_id
            JOIN teams ht ON ht.id = m.home_team_id
            JOIN teams at ON at.id = m.away_team_id
            WHERE v.id = %s
            """,
            (venue_id,),
        )
        affected = await cur.fetchall()
        match_ids = [row[0] for row in affected]

        if match_ids:
            await cur.execute(
                """
                UPDATE matches
                SET status = %s,
                    scheduled_start_time = COALESCE(
                        matches.scheduled_start_time,
                        ms_start.start_time
                    )
                FROM (
                    SELECT ms.match_id, MIN(s.start_time) AS start_time
                    FROM match_slot ms
                    JOIN slots s ON s.id = ms.slot_id
                    WHERE ms.match_id = ANY(%s)
                    GROUP BY ms.match_id
                ) AS ms_start
                WHERE matches.id = ms_start.match_id
                """,
                (MatchStatus.CANCELED.value, match_ids),
            )
            await cur.execute(
                """
                DELETE FROM match_slot
                WHERE match_id = ANY(%s)
                """,
                (match_ids,),
            )

        await cur.execute(
            """
            DELETE FROM slots
            WHERE court_id IN (SELECT id FROM courts WHERE venue_id = %s)
            """,
            (venue_id,),
        )
        await cur.execute(
            """
            DELETE FROM courts
            WHERE venue_id = %s
            """,
            (venue_id,),
        )
        await cur.execute(
            """
            DELETE FROM venues
            WHERE id = %s
            RETURNING id
            """,
            (venue_id,),
        )
        row = await cur.fetchone()
        await conn.commit()
        if not row:
            return {}
        return {
            "id": row[0],
            "matches": [
                {
                    "id": m[0],
                    "home_team": m[1],
                    "away_team": m[2],
                    "start_time": m[3],
                }
                for m in affected
            ],
        }


async def list_venue_matches(venue_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT DISTINCT m.id,
                   ht.name AS home_team,
                   at.name AS away_team,
                   s.start_time
            FROM matches m
            JOIN match_slot ms ON ms.match_id = m.id
            JOIN slots s ON s.id = ms.slot_id
            JOIN courts c ON c.id = s.court_id
            JOIN venues v ON v.id = c.venue_id
            JOIN teams ht ON ht.id = m.home_team_id
            JOIN teams at ON at.id = m.away_team_id
            WHERE v.id = %s
            ORDER BY s.start_time
            """,
            (venue_id,),
        )
        rows = await cur.fetchall()
        return [
            {
                "id": row[0],
                "home_team": row[1],
                "away_team": row[2],
                "start_time": row[3],
            }
            for row in rows
        ]

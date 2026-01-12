from datetime import datetime, timedelta, timezone

from shared.db import get_async_pool


async def add_court(venue_id, name, surface):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO courts (venue_id, name, surface)
            VALUES (%s, %s, %s)
            RETURNING id, venue_id, name, surface
            """,
            (venue_id, name, surface),
        )
        court = await cur.fetchone()
        await conn.commit()
        if not court:
            return {}
        return {"id": court[0], "venue_id": court[1], "name": court[2], "surface": court[3]}

async def get_all_courts():
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id, venue_id, name, surface
            FROM courts
            """
        )
        row = await cur.fetchall()
        return {
            "id" : row[0],
            "venue_id" : row[1],
            "name" : row[2],
            "surface" : row[3]
        }

async def generate_slots(court_id, start_date, end_date, slots_per_day=6, slots_length=2):
    if slots_per_day <= 0:
        raise ValueError("slots_per_day must be positive")
    if slots_length <= 0:
        raise ValueError("slots_length must be positive")
    if slots_per_day * slots_length > 12:
        raise ValueError("total slots length cannot exceed 12 hours")

    start_day = start_date.date() if isinstance(start_date, datetime) else start_date
    end_day = end_date.date() if isinstance(end_date, datetime) else end_date
    if end_day < start_day:
        raise ValueError("end_date must be on or after start_date")

    slot_delta = timedelta(hours=slots_length)

    pool = get_async_pool()
    created = []
    async with pool.connection() as conn, conn.cursor() as cur:
        current_day = start_day
        while current_day <= end_day:
            current_start = datetime.combine(
                current_day, datetime.min.time(), tzinfo=timezone.utc
            ).replace(hour=8)
            for _ in range(slots_per_day):
                current_end = current_start + slot_delta
                await cur.execute(
                    """
                    INSERT INTO slots (court_id, start_time, end_time)
                    VALUES (%s, %s, %s)
                    RETURNING id, court_id, start_time, end_time
                    """,
                    (court_id, current_start, current_end),
                )
                row = await cur.fetchone()
                created.append(
                    {
                        "id": row[0],
                        "court_id": row[1],
                        "start_time": row[2],
                        "end_time": row[3],
                    }
                )
                current_start = current_end
            current_day += timedelta(days=1)
        await conn.commit()
    return created

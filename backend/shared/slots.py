from shared.db import get_async_pool


async def add_slot(court_id, start_time, end_time):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO slots (court_id, start_time, end_time)
            VALUES (%s, %s, %s)
            RETURNING id
            """,
            (court_id, start_time, end_time),
        )
        slot = await cur.fetchone()
        await conn.commit()
        return {"id": slot[0]}

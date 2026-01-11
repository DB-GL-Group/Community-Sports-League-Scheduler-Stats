from shared.db import get_async_pool


async def add_court(venue_id, name, surface):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO courts (venue_id, name, surface)
            VALUES (%s, %s, %s)
            RETURNING id
            """,
            (venue_id, name, surface),
        )
        court = await cur.fetchone()
        await conn.commit()
        return {"id": court[0]}

from shared.db import get_async_pool


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
        return {"id": venue[0]}

from shared.db import get_async_pool


async def create_person(first_name: str, last_name: str, email: str, phone: str):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO persons (first_name, last_name, email, phone)
            VALUES (%s, %s, %s, %s)
            RETURNING id
            """,
            (first_name, last_name, email, phone),
        )
        person_id = await cur.fetchone()
        await conn.commit()
        return {
            "id": person_id[0],
            "first_name": first_name,
            "last_name": last_name,
            "email": email,
            "phone": phone,
        }

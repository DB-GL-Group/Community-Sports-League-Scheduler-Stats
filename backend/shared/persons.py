from shared.db import get_async_pool


async def create_person(first_name: str, last_name: str, phone: str):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO persons (first_name, last_name, phone)
            VALUES (%s, %s, %s)
            RETURNING id
            """,
            (first_name, last_name, phone),
        )
        person_id = await cur.fetchone()
        await conn.commit()
        return {
            "id": person_id[0],
            "first_name": first_name,
            "last_name": last_name,
            "phone": phone,
        }
    
async def get_person(person_id):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id, first_name, last_name, phone
            FROM persons
            WHERE id = %s
            """,
            (person_id,),
        )
        row = await cur.fetchone()
        if not row:
            return {}
        return {
            "id": row[0],
            "first_name": row[1],
            "last_name": row[2],
            "phone": row[3],
        }

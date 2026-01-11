from shared.db import get_async_pool


async def get_all_matches():
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id, division, slot_id, home_team_id, away_team_id, main_referee_id,
                   status, home_score, away_score, notes
            FROM matches
            """
        )
        return await cur.fetchall()


async def add_match(
    division,
    slot_id,
    home_team_id,
    away_team_id,
    main_referee_id,
    status,
    home_score=0,
    away_score=0,
    notes="",
):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO matches (
                division, slot_id, home_team_id, away_team_id, main_referee_id,
                status, home_score, away_score, notes
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
            """,
            (
                division,
                slot_id,
                home_team_id,
                away_team_id,
                main_referee_id,
                status,
                home_score,
                away_score,
                notes,
            ),
        )
        match_row = await cur.fetchone()
        await conn.commit()
        return {"id": match_row[0]}

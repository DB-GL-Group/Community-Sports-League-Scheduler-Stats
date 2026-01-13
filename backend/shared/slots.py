from shared.db import get_async_pool
from shared.matches import get_home_and_away_teams_from_match_id


async def add_slot(court_id, start_time, end_time):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO slots (court_id, start_time, end_time)
            VALUES (%s, %s, %s)
            RETURNING id, court_id, start_time, end_time
            """,
            (court_id, start_time, end_time),
        )
        slot = await cur.fetchone()
        await conn.commit()
        if not slot:
            return {}
        return {"id": slot[0], "court_id": slot[1], "start_time": slot[2], "end_time": slot[3]}
    
    

async def get_all_slots():
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id, court_id, start_time, end_time
            FROM slots
            """
        )
        row = await cur.fetchall()
        if not row:
            return {}
        return [{
            "id" : row[0],
            "court_id" : row[1],
            "start_time" : row[2],
            "end_time" : row[3]
        }
        for row in row
        ]


async def get_next_slot(slot): # returns boolean if there is a next slot or not (meaning current slot's end_time == next slot's start_time)
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id
            FROM slots
            WHERE court_id = %s and start_time = %s
            """, (slot["court_id"], slot["end_time"])
        )
        row = await cur.fetchone()
        if not row:
            return False
        return True


async def is_next_slot_possible(current_slot, h_team_id, a_team_id): # return boolean is_next_slot_possible
    if (await get_next_slot(current_slot)):    
        pool = get_async_pool()
        async with pool.connection() as conn, conn.cursor() as cur:
            await cur.execute(
                """
                SELECT id
                FROM slots
                WHERE court_id = %s and start_time = %s
                """, (current_slot["court_id"], current_slot["end_time"])
            )
            row = await cur.fetchone() # This contains the id of the next_slot
            next_slot_match_id = await get_match_at_slot(row[0]) # checks if there is a match at next_slot
            if not next_slot_match_id: # if no match return final True.
                return True
            else: # checks whether or not any one of the teams in the current_slot are found in the next_slot that has a match sloted.
                print("SUIIIIIIIIIIII", next_slot_match_id, await get_match_at_slot(next_slot_match_id))
                next_teams_ids = await get_home_and_away_teams_from_match_id(await get_match_at_slot(next_slot_match_id))
                if h_team_id in next_teams_ids or a_team_id in next_teams_ids:
                    return False
                return True

    return False
    

async def get_match_at_slot(slot_id):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT match_id
            FROM match_slot
            WHERE slot_id = %s
            """, (slot_id,)
        )
        row = await cur.fetchone()
        if not row:
            return None
        return row[0]
    
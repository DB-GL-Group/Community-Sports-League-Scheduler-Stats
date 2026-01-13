from shared.db import get_async_pool
from shared.matches import get_home_and_away_teams_from_match_id
from shared.teams import list_team_players


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
            return []
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
async def get_previous_slot(slot): # returns boolean if there is a previous slot or not (meaning previous slot's end_time == current slot's start_time)
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id
            FROM slots
            WHERE court_id = %s and end_time = %s
            """, (slot["court_id"], slot["start_time"])
        )
        row = await cur.fetchone()
        if not row:
            return False
        return True

async def are_both_next_slots_possible(current_slot, h_team_id, a_team_id): # return boolean is_next_slot_possible
    result_next = False
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
                result_next = True
            else: # checks whether or not any one of the teams in the current_slot are found in the next_slot that has a match sloted.
                next_teams_ids = await get_home_and_away_teams_from_match_id(next_slot_match_id)
                if h_team_id in next_teams_ids or a_team_id in next_teams_ids:
                    result_next = False
                else:
                    result_next = True
    else:
        result_next = True
    
    result_previous = False
    if (await get_previous_slot(current_slot)):    
        pool = get_async_pool()
        async with pool.connection() as conn, conn.cursor() as cur:
            await cur.execute(
                """
                SELECT id
                FROM slots
                WHERE court_id = %s and end_time = %s
                """, (current_slot["court_id"], current_slot["start_time"])
            )
            row = await cur.fetchone() # This contains the id of the previous_slot
            previous_slot_match_id = await get_match_at_slot(row[0]) # checks if there is a match at previous_slot
            if not previous_slot_match_id: # if no match return final True.
                result_previous = True
            else: # checks whether or not any one of the teams in the current_slot are found in the previous_slot that has a match sloted.
                previous_teams_ids = await get_home_and_away_teams_from_match_id(previous_slot_match_id)
                if h_team_id in previous_teams_ids or a_team_id in previous_teams_ids:
                    result_previous = False
                else:
                    result_previous = True
    else:
        result_previous = True

    verdict = result_next and result_previous
    return verdict
    

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

async def get_matches_sloted_at_same_time(slot_id, start_time, end_time): # gets all parallel slots except the given one.
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT ms.match_id
            FROM slots s
            JOIN match_slot ms ON ms.slot_id = s.id
            WHERE s.id <> %s and s.start_time = %s and s.end_time = %s
            """, (slot_id, start_time, end_time)
        )
        rows = await cur.fetchall()
        return [{"match_id": row[0]} for row in rows]

async def are_parallel_matches_possible(slot, h_team_id, a_team_id):
    parallel_matches = await get_matches_sloted_at_same_time(slot["id"], slot["start_time"], slot["end_time"])
    if not parallel_matches:
        return True
    # See if our team is playing in any of the parallel matches or not.
    for parallel_match in parallel_matches:
        parallel_match_team_ids = await get_home_and_away_teams_from_match_id(parallel_match["match_id"])
        if h_team_id in parallel_match_team_ids or a_team_id in parallel_match_team_ids:
            return False

    # See if any players in our team are in the parallel matches or not.
    all_home_players_in_this_match = await list_team_players(h_team_id)
    all_away_players_in_this_match = await list_team_players(a_team_id)
    home_player_ids = {player["id"] for player in all_home_players_in_this_match if "id" in player}
    away_player_ids = {player["id"] for player in all_away_players_in_this_match if "id" in player}
    for p_match in parallel_matches:
        p_teams_ids = await get_home_and_away_teams_from_match_id(p_match["match_id"])
        all_home_players_in_that_match = await list_team_players(p_teams_ids[0])
        all_away_players_in_that_match = await list_team_players(p_teams_ids[1])
        parallel_home_ids = {player["id"] for player in all_home_players_in_that_match if "id" in player}
        parallel_away_ids = {player["id"] for player in all_away_players_in_that_match if "id" in player}
        if home_player_ids & (parallel_home_ids | parallel_away_ids):
            return False
        if away_player_ids & (parallel_home_ids | parallel_away_ids):
            return False
    
    return True

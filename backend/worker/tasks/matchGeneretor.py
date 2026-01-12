import asyncio
import logging
import time
from datetime import datetime, timedelta, timezone

from shared.courts import add_court
from shared.db import close_async_pool, open_async_pool
from shared.managers import create_manager
from shared.matches import addScore, add_match, get_all_matches, get_finalists
from shared.players import create_player
from shared.referees import create_referee
from shared.teams import add_player, create_team
from shared.venues import add_venue
from shared.courts import generate_slots



# //////////////////// JUST A TEMPLATE.. CODE DOESN'T ACTUALLY WORK ////////////////////




async def generate_matches(): # return us all of the matches
    await open_async_pool()
    try:
        # Teams are created and managed by managers
        home_team_id = (await create_team(division, "The flightless sharks", JohnDoeManager_id, "FLS", "Blue", "White"))["id"]
        away_team1_id = (await create_team(division, "The Thirsty Fish", JaneDoughManager_id, "TTF", "Purple", "Yellow"))["id"]
        away_team2_id = (await create_team(division, "The flexible rocks", JackDanielsManager_id, "TFR", "Grey", "LightGrey"))["id"]

        # Players are managed by managers
        player1 = await create_player("Mark", "Evans", "+41 890 890 90")
        player2 = await create_player("Axel", "Blaze", "+41 098 098 09")
        player3 = await create_player("Ubi", "Soft", "+41 685 752 65")
        await add_player(player1["id"], home_team_id)
        await add_player(player2["id"], away_team1_id)
        await add_player(player3["id"], away_team2_id)

        # Refs
        ref_id = (await create_referee("Reeses", "Puffs", "+12 456 456 45"))["id"]

        # Matches
        match1 = await add_match(division, court1_slots[current_court1_slot if current_court1_slot < total_available_court1_slots else Exception], home_team_id, away_team1_id, ref_id, "Active")
        match2 = await add_match(division, slot2, home_team_id, away_team2_id, ref_id, "Awaiting")
        match3 = await add_match(division, slot3, away_team1_id, away_team2_id, ref_id, "Awaiting")

        # print(await get_all_matches())


        # # Final
        # finalists = await get_finalists()
        # finalsMatch = await add_match(
        #     division, finals_slot, finalists[0], finalists[1], ref_id, "Awaiting"
        # )

        # await addScore(finalsMatch["id"], home_team_id, "home", player1["id"], time.time(), False)

        print("This is the end of ze match creation my friend.")
        return get_all_matches()
    finally:
        await close_async_pool()

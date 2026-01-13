import asyncio
import logging
import time
from datetime import datetime, timedelta, timezone

from shared.courts import add_court
from shared.db import close_async_pool, open_async_pool
from shared.managers import create_manager
from shared.matches import addScore, add_match, get_all_matches
from shared.players import create_player
from shared.referees import create_referee
from shared.teams import add_player, create_team
from shared.venues import add_venue
from shared.courts import generate_slots

logger = logging.getLogger(__name__)


def run_scheduler_job(job_id: str) -> None:
    asyncio.run(_run_scheduler_job(job_id))


async def _run_scheduler_job(job_id: str) -> None:
    await open_async_pool()
    option = "real" # "test"
    try:
        match option:
            case "real":
                allMatches = get_all_matches
                
                # Genereate season length based of all matches received
                

            
                #Implement scheduler logic
                # Venue setup
                venue_id = (await add_venue("Rocks The Lakes", "Rue de Saint-Pierre 12"))["id"]
                court1 = (await add_court(venue_id, "Court1", "IDK what surface is lmao"))["id"]
                court2 = (await add_court(venue_id, "Court2", "Surface is big"))["id"]
                division = 1

                # Schedule
                currentDate = datetime.date(timezone.utc)
                currentTime = datetime.now(timezone.utc)
                oneHour = timedelta(hours=1)

                # Format: [{id : x, court_id : x, start_time : x, end_time : x}, {...}]
                court1_slots = (await generate_slots(court1, currentDate, currentDate))
                total_available_court1_slots = len(court1_slots)
                current_court1_slot = 0
                court2_slots = (await generate_slots(court2, currentDate, currentDate))
                available_court2_slots = len(court2_slots)
                

                # slot1 = (await add_slot(court1, currentTime, currentTime + oneHour))["id"]
                # slot2 = (await add_slot(court1, currentTime + 4 * oneHour, currentTime + 5 * oneHour))["id"]
                # slot3 = (await add_slot(court1, currentTime + 8 * oneHour, currentTime + 9 * oneHour))["id"]
                # finals_slot = (await add_slot(court2, currentTime + 13 * oneHour, currentTime + 14 * oneHour))["id"]

                # Managers
                JohnDoeManager_id = (await create_manager("John", "Doe", "+41 123 123 12"))["id"]
                JaneDoughManager_id = (await create_manager("Jane", "Dough", "+41 321 321 32"))["id"]
                JackDanielsManager_id = (await create_manager("Jack", "Daniels", "+41 145 145 45"))["id"]
                
                # # Teams
                home_team_id = (await create_team(division, "The flightless sharks", JohnDoeManager_id, "FLS", "Blue", "White"))["id"]
                away_team1_id = (await create_team(division, "The Thirsty Fish", JaneDoughManager_id, "TTF", "Purple", "Yellow"))["id"]
                away_team2_id = (await create_team(division, "The flexible rocks", JackDanielsManager_id, "TFR", "Grey", "LightGrey"))["id"]

                # Players
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

                print(await get_all_matches())


                # Simulate
                await addScore(match1["id"], home_team_id, "home", player1["id"], time.time(), False)
                await addScore(match2["id"], home_team_id, "home", player1["id"], time.time(), False)
                await addScore(match2["id"], away_team2_id, "away", player3["id"], time.time(), False)
                await addScore(match3["id"], away_team2_id, "away", player3["id"], time.time(), False)


              

              

                print("This is the end of ze match day my friend.")
            case _:
                print("YOUUUUUU SKIPPED YOUR JOB (or just no job_id).. NO PAY FOR YOU MA MAN !!")
    finally:
        await close_async_pool()

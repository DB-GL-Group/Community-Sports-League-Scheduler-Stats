import asyncio
import logging

from shared.db import close_async_pool, get_async_cursor, open_async_pool
from shared.courts import add_court
from shared.managers import create_manager
from shared.matches import add_match, get_all_matches, addScore, get_finalists
from shared.persons import create_person
from shared.players import create_player
from shared.referees import create_referee
from shared.slots import add_slot
from shared.teams import create_team, add_player
from shared.users import create_user
from shared.venues import add_venue

from datetime import datetime, timezone, timedelta

logger = logging.getLogger(__name__)


def run_scheduler_job(job_id: str) -> None:
    asyncio.run(_run_scheduler_job(job_id))


async def _run_scheduler_job(job_id: str) -> None:
    await open_async_pool()
    try:
        #Implement scheduler logic
        # Venue setup
        venue_id = (await add_venue("Rocks The Lakes", "Rue de Saint-Pierre 12"))["id"]
        court1 = (await add_court(venue_id, "Court1", "IDK what surface is lmao"))["id"]
        court2 = (await add_court(venue_id, "Court2", "Surface is big"))["id"]
        division = 1

        # Schedule
        currentTime = datetime.now(timezone.utc)
        oneHour = timedelta(hours=1)
        slot1 = (await add_slot(court1, currentTime, currentTime+oneHour))["id"]
        slot2 = (await add_slot(court1, currentTime+4*oneHour, currentTime+oneHour))["id"]
        slot3 = (await add_slot(court1, currentTime+8*oneHour, currentTime+oneHour))["id"]
        finals_slot = (await add_slot(court2, currentTime+13*oneHour, currentTime+oneHour))["id"]

        # Managers
        JohnDoeManager_id = (await create_manager("John", "Doe", "johndoe@gmail.com", "+41 123 123 12"))["id"]
        JaneDoughManager_id = (await create_manager("Jane", "Dough", "janedouch@gmail.com", "+41 321 321 32"))["id"]
        JackDanielsManager_id = (await create_manager("Jack", "Daniels", "jackdaniels@gmail.com", "+41 145 145 45"))["id"]
        
        # # Teams
        home_team_id = (await create_team(division, "The flightless sharks", JohnDoeManager_id, "FLS", "Blue", "White"))["id"]
        away_team1_id = (await create_team(division, "The Thirsty Fish", JaneDoughManager_id, "TTF", "Purple", "Yellow"))["id"]
        away_team2_id = (await create_team(division, "The flexible rocks", JackDanielsManager_id, "TFR", "Grey", "LightGrey"))["id"]

        # # Players
        # player1 = await create_player("Mark", "Evans", "markevans@gmail.com", "+41 890 890 90")
        # player2 = await create_player("Axel", "Blaze", "axelblaze@gmail.com", "+41 098 098 09")
        # player3 = await create_player("Ubi", "Soft", "ubisoft@gmail.com", "+41 685 752 65")
        # await add_player(player1, home_team_id)
        # await add_player(player2, away_team1_id)
        # await add_player(player3, away_team2_id)

        # # Matches
        # ref_id = create_referee("Reeses", "Puffs", "reesespuffs@gmail.com", "+12 456 456 45")

        # match1 = await add_match(division, slot1, home_team_id, away_team1_id, ref_id, "Active")
        # match2 = await add_match(division, slot2, home_team_id, away_team2_id, ref_id, "Awating")
        # match3 = await add_match(division, slot3, away_team1_id, away_team2_id, ref_id, "Awating")

        # print(get_all_matches())


        # # Simulate
        # await addScore(match1, home_team_id, "home", player1, time.time(), False)
        # await addScore(match2, home_team_id, "home", player1, time.time(), False)
        # await addScore(match2, away_team2_id, "away", player3, time.time(), False)
        # await addScore(match3, away_team2_id, "away", player3, time.time(), False)


        # # Final
        # finalists = await get_finalists()
        # finalsMatch = await add_match(division, finals_slot, finalists[0], finalists[1], ref_id, "Awating")

        # await addScore(finalsMatch, home_team_id, "home", player1, time.time(), False)

        # print("This is the end of ze match day my friend.")
    
        # print("YOUUUUUU SKIPPED YOUR JOB (or just no job_id).. NO PAY FOR YOU MA MAN !!")
        # pass
    finally:
        await close_async_pool()

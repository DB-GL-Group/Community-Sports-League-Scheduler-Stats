import asyncio
import logging
import time
from datetime import datetime, timedelta, timezone

from shared.courts import add_court, generate_slots, get_all_courts
from shared.db import close_async_pool, open_async_pool
from shared.managers import create_manager
from shared.matches import addScore, add_match, get_all_matches, schedule_match, get_match_details
from shared.venues import add_venue
from tasks.matchGeneretor import generate_matches

logger = logging.getLogger(__name__)


def run_scheduler_job(job_id: str) -> None:
    asyncio.run(_run_scheduler_job(job_id))


async def _run_scheduler_job(job_id: str) -> None:
    await open_async_pool()
    try:
        #Implement scheduler logic
        all_matches = await generate_matches()
        nbr_of_matches = len(all_matches)

        # Schedule
        current_date = datetime.date(timezone.utc)

        # Venue setup
        venue_id = (await add_venue("Rocks The Lakes", "Rue de Saint-Pierre 12"))["id"]
        court1 = (await add_court(venue_id, "Court1", "Normal"))["id"]
        court2 = (await add_court(venue_id, "Court2", "Normal"))["id"]
        
        # Genereate season length based of all matches received (6 slots a day per venue)
        all_courts = await get_all_courts()
        nbr_of_courts = len(all_courts)

        # division = 1

        minimum_number_of_match_days = nbr_of_matches // 6 // nbr_of_courts
        season_start_date = current_date
        season_end_date = current_date + timedelta(days=minimum_number_of_match_days-1)

        for i in all_courts:
            await generate_slots(i["id"], season_start_date, season_end_date)

        # Schedule matches in slots
        nbr_matches_per_court = nbr_of_matches // nbr_of_courts
        unscheduled_matches = [] # matches that weren't scheduled, due to conflict with repeating teams playing. Only contains the match_id
        for i in range(nbr_of_courts):
            next_team_ban_IDs = [0, 0] # team id's so that the next slot isn't played by either team.
            for j in range(nbr_matches_per_court):
                match_offset = i*nbr_matches_per_court + j # offset for each court
                match_id = all_matches(match_offset)["match_id"]

                home_team_id = (await get_match_details(match_id))["home_team"]
                away_team_id = (await get_match_details(match_id))["away_team"] 

                if home_team_id not in next_team_ban_IDs and away_team_id not in next_team_ban_IDs:
                    proceed = (await schedule_match(match_id, all_courts[i]["id"]))
                    next_team_ban_IDs = [home_team_id, away_team_id]
                else:
                    unscheduled_matches.append(match_id)
        

        print("This is the end of ze schedluation my friend.")
    finally:
        await close_async_pool()

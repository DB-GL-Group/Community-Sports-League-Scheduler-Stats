import asyncio
import logging
import random
from datetime import datetime, timedelta, timezone, date

from shared.referees import create_referee
from shared.persons import create_person
from shared.players import create_player
from shared.managers import create_manager
from shared.matches import (
    addScore,
    add_match,
    clear_match_schedule,
    get_all_matches,
    schedule_match,
    get_match_details,
    get_home_and_away_teams_from_match_id,
)
from shared.courts import add_court, generate_slots, get_all_courts
from shared.venues import add_venue
from shared.teams import create_team, add_player
from shared.slots import get_all_slots, are_both_next_slots_possible, are_parallel_matches_possible
from shared.db import close_async_pool, open_async_pool
from worker.tasks.matchGeneretor import generate_matches

logger = logging.getLogger(__name__)


def run_scheduler_job() -> None:
    asyncio.run(_run_scheduler_job())


async def _run_scheduler_job() -> None:
    await open_async_pool()
    try:
        await clear_match_schedule()
        # Implement scheduler logic
        all_unscheduled_matches = await generate_matches()
        nbr_of_matches = len(all_unscheduled_matches)

        # Dates
        current_date = date.today()

        # Venue setup
        # It will be in the DB and just make a function that gets those venues.
        venue_id = (await add_venue("Rocks The Lakes", "Rue de Saint-Pierre 12"))["id"]
        court1_id = (await add_court(venue_id, "Court1", "Normal"))["id"]
        court2_id = (await add_court(venue_id, "Court2", "Normal"))["id"]
        
        # Genereate season length based of all matches received (6 slots a day per venue)
        all_courts = await get_all_courts()
        nbr_of_courts = len(all_courts)

        division = 1

        minimum_number_of_match_days = nbr_of_matches
        season_start_date = current_date
        season_end_date = current_date + timedelta(days=minimum_number_of_match_days)

        for court in all_courts:
            proceed = await generate_slots(court["id"], season_start_date, season_end_date)
        
        # Schedule
        # Going to change the system.
        # It's going to be scheduled day by day.
        # So here we receive valid matches. So no same player, two teams.
        # ////// Rules //////
        # 1. Once a team has played a match, they can't play in the immediate next one. => verif_1
        # 2. Teleportation is authorized. I player can play the very next match slot in another venue. => verif_2
        # 3. A team cannot play in two seperate matches at the same time. => verif_2
        
        for current_match in list(reversed(all_unscheduled_matches)): # Goes through all the matches from the end,
                                                            # so when we remove one, it doesn't do anything unexpected.
                                                            # It will only reiterate once a valid slot is found for the
                                                            # match is found.
            teams = await get_home_and_away_teams_from_match_id(current_match["id"])
            all_current_available_slots = await get_all_slots()
            random.shuffle(all_current_available_slots)
            if len(all_current_available_slots) == 0:
                raise Exception("NO MORE SLOTS AVAILABLE !!")                       # not good.
            # Slots are now in random order so can ditribute the matches out randomly.
            slots_iterator = 0
            while slots_iterator < len(all_current_available_slots):
                slot = all_current_available_slots[slots_iterator]                  # selects slot
                verif_1 = await are_both_next_slots_possible(slot, teams[0], teams[1]) # checks if next_slot and previous_slot don't contain either a match or a match, where one of the teams is playing
                verif_2 = await are_parallel_matches_possible(slot, teams[0], teams[1])  # checks if no parallel match is played by our team and checks if player none of the players are playing in a match that is at the same time.

                verdict = verif_1 and verif_2
                if verdict:
                    proceed = await schedule_match(current_match["id"], slot["id"]) # SCHEDULES MATCH
                    all_unscheduled_matches.pop(-1)
                    break
                slots_iterator += 1                                             # Here FAILED so moves on to the next available slot.



        if len(all_unscheduled_matches) != 0:
            raise Exception("SOME MATCHES WERE NOT SCHEDULED !!") # not good.

        print("This is the end of ze schedluation my friend.")
    finally:
        await close_async_pool()

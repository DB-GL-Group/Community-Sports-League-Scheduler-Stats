import asyncio
import logging
import random
from datetime import datetime, timedelta, timezone, date

from shared.referees import create_referee
from shared.persons import create_person
from shared.players import create_player
from shared.managers import create_manager
from shared.matches import addScore, add_match, get_all_matches, schedule_match, get_match_details
from shared.courts import add_court, generate_slots, get_all_courts
from shared.venues import add_venue
from shared.teams import create_team, get_home_and_away_teams_from_match_id, add_player
from shared.slots import get_all_slots, is_next_slot_possible
from shared.db import close_async_pool, open_async_pool
from worker.tasks.matchGeneretor import generate_matches

logger = logging.getLogger(__name__)


def run_scheduler_job() -> None:
    asyncio.run(_run_scheduler_job())


async def _run_scheduler_job() -> None:
    await open_async_pool()
    try:
        # TEST REMOVE AFTERWARDS AND USE LOGIC BELOW: "Implement scheduler logic ////////////////////////////////////////////////////////
        division = 1

        person1 = await create_person("John", "Doe")
        person2 = await create_person("Jane", "Dough")
        person3 = await create_person("Jack", "Daniels")
        person4 = await create_person("Ref", "Eree")

        player1 = await create_player("Mark", "Evans")
        player2 = await create_player("Axel", "Blaze")
        player3 = await create_player("Ubi", "Soft")

        JohnDoeManager_id = (await create_manager(person1["id"]))["id"]
        JaneDoughManager_id = (await create_manager(person2["id"]))["id"]
        JackDanielsManager_id = (await create_manager(person3["id"]))["id"]

        ref = await create_referee(person4["id"])

        home_team_id = (await create_team(division, "The flightless sharks", JohnDoeManager_id, "FLS", "Blue", "White"))["id"]
        away_team1_id = (await create_team(division, "The Thirsty Fish", JaneDoughManager_id, "TTF", "Purple", "Yellow"))["id"]
        away_team2_id = (await create_team(division, "The flexible rocks", JackDanielsManager_id, "TFR", "Grey", "LightGrey"))["id"]

        await add_player(player1["id"], home_team_id, 1)
        await add_player(player2["id"], away_team1_id, 2)
        await add_player(player3["id"], away_team2_id, 3)

        match1 = await add_match(division, home_team_id, away_team1_id, ref["id"], "Active")
        match2 = await add_match(division, home_team_id, away_team2_id, ref["id"], "Awaiting")
        match3 = await add_match(division, away_team1_id, away_team2_id, ref["id"], "Awaiting")

        all_unscheduled_matches = await get_all_matches()
        # # END OF TEST //////////////////////////////////////////////////////////////////////////////////////////////////////////////////


        # #Implement scheduler logic
        # all_unscheduled_matches = await generate_matches()
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
        # print("YAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")

        for i in all_courts:
            proceed = await generate_slots(court1_id, season_start_date, season_end_date)
        
        # Schedule
        # Going to change the system.
        # It's going to be scheduled day by day.
        # So here we receive valid matches. So no same player, two teams.
        # ////// Rules //////
        # 1. Teleportation is authorized. I player can play the very next match slot in another venue.
        # 2. Once a team has played a match, they can't play in the immediate next one.
        
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
                verif_1 = await is_next_slot_possible(slot, teams[0], teams[1])   # checks if next_slot doesn't contain either a match or a match, where one of the teams is playing
                verif_2 = True                                                      # TODO : check if player none of the players are playing in a match that is at the same time.

                verdict = verif_1 and verif_2
                if verdict:
                    proceed = await schedule_match(current_match["id"], slot["id"]) # SCHEDULES MATCH + TODO DONT FORGET TO MATCHES.ADD_MATCH_SLOT_ID !!!!
                    all_unscheduled_matches
                slots_iterator += 1                                             # Here FAILED so moves on to the next slot available.



        # if len(all_unscheduled_matches) != 0:
        #     raise Exception("SOME MATCHES WERE NOT SCHEDULED !!") # not good.



        # nbr_matches_per_court = nbr_of_matches // nbr_of_courts
        # for i in range(nbr_of_courts):
        #     next_team_ban_IDs = [-1, -1] # team id's so that the next slot isn't played by either team.
        #     for j in range(nbr_matches_per_court):
        #         match_offset = i*nbr_matches_per_court + j # offset for each court
        #         match_id = all_unscheduled_matches(match_offset)["match_id"]

        #         h_team_id, a_team_id = (await get_new_next_team_ban_IDs(match_id))

        #         if h_team_id not in next_team_ban_IDs and a_team_id not in next_team_ban_IDs:
        #             proceed = (await schedule_match(match_id, all_courts[i]["id"]))
        #             next_team_ban_IDs = [h_team_id, a_team_id]
        #             if check_no_matches_at_same_time()
        #         else:
        #             # unscheduled_matches.append(all_matches(match_offset))
        

        print("This is the end of ze schedluation my friend.")
    finally:
        await close_async_pool()

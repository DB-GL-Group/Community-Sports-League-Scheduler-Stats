import asyncio
import logging

from shared.db import close_async_pool, get_async_cursor, open_async_pool
from shared.courts import add_court
from shared.managers import create_manager
from shared.matches import add_match
from shared.matches import get_all_matches
from shared.persons import create_person
from shared.players import create_player
from shared.referees import create_referee
from shared.slots import add_slot
from shared.teams import create_team, add_player
from shared.users import create_user
from shared.venues import add_venue

import time

logger = logging.getLogger(__name__)


def run_scheduler_job(job_id: str) -> None:
    asyncio.run(_run_scheduler_job(job_id))


async def _run_scheduler_job(job_id: str) -> None:
    await open_async_pool()
    try:
        # TODO : Implement scheduler logic
        if job_id == 1:
            venue_id = add_venue("Rocks The Lakes", "Rue de Saint-Pierre 12")
            court1_id = add_court(venue_id, "Court1", "IDK what surface is lmao")
            slot_id = add_slot(court1_id, time.time(), time.time()+36000)

            JohnDoeManager_id = create_manager("John", "Doe", "johndoe@gmail.com", "+41 123 123 12")
            home_team_id = create_team("The flightless sharks", JohnDoeManager_id, "FLS", "Blue", "White")
            player1 = create_player("Mark", "Evans", "markevans@gmail.com", "+41 890 890 90")
            add_player(player1, home_team_id)

            JaneDoughManager_id = create_manager("Jane", "Dough", "janedouch@gmail.com", "+41 321 321 32")
            away_team_id = create_team("The Thirsty Fish", JaneDoughManager_id, "TTF", "Purple", "Yellow")
            player2 = create_player("Axel", "Blaze", "axelblaze@gmail.com", "+41 098 098 09")
            add_player(player2, away_team_id)

            ref_id = create_referee("Reeses", "Puffs", "reesespuffs@gmail.com", "+12 456 456 45")
            match1 = add_match(slot_id, home_team_id, away_team_id, ref_id, "Active")

            print(get_all_matches())
            print("This is the end of ze match my friend.")
        else:
            print("YOUUUUUU SKIPPED YOUR JOB.. NO PAY FOR YOU MA MAN !!")
        # pass
    finally:
        await close_async_pool()

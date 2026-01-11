import asyncio
import logging

from shared.db import close_async_pool, get_async_cursor, open_async_pool
from shared.courts import add_court
from shared.managers import create_manager
from shared.matches import add_match
from shared.persons import create_person
from shared.players import create_player
from shared.referees import create_referee
from shared.slots import add_slot
from shared.teams import create_team, add_player
from shared.users import create_user
from shared.venues import add_venue


logger = logging.getLogger(__name__)


def run_scheduler_job(job_id: str) -> None:
    asyncio.run(_run_scheduler_job(job_id))


async def _run_scheduler_job(job_id: str) -> None:
    await open_async_pool()
    try:
        # TODO : Implement scheduler logic
        pass
    finally:
        await close_async_pool()

import asyncio
import logging

from shared.db import close_async_pool, open_async_pool
from shared.managers import create_manager
from shared.referees import create_referee


# //////////////////// JUST A TEMPLATE.. CODE DOESN'T ACTUALLY WORK ////////////////////



async def create_managers_and_refs():
    await open_async_pool()
    try:
        # Managers
        JohnDoeManager_id = (await create_manager("John", "Doe", "+41 123 123 12"))["id"]
        JaneDoughManager_id = (await create_manager("Jane", "Dough", "+41 321 321 32"))["id"]
        JackDanielsManager_id = (await create_manager("Jack", "Daniels", "+41 145 145 45"))["id"]

        # Refs
        ref_id = (await create_referee("Reeses", "Puffs", "+12 456 456 45"))["id"]
    finally:
        await close_async_pool()

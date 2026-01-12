import asyncio
import random
from datetime import datetime

from shared.db import close_async_pool, open_async_pool
from shared.players import create_player


FIRST_NAMES = [
    "Alex",
    "Sam",
    "Jordan",
    "Taylor",
    "Chris",
    "Morgan",
    "Jamie",
    "Casey",
    "Riley",
    "Avery",
]

LAST_NAMES = [
    "Martin",
    "Bernard",
    "Thomas",
    "Petit",
    "Robert",
    "Richard",
    "Durand",
    "Dubois",
    "Moreau",
    "Laurent",
]


async def populate_players(count: int = 100) -> list[dict]:
    if count <= 0:
        return []

    await open_async_pool()
    created = []
    try:
        for i in range(count):
            first_name = random.choice(FIRST_NAMES)
            last_name = random.choice(LAST_NAMES)
            player = await create_player(first_name, last_name)
            created.append(player)
    finally:
        await close_async_pool()
    return created


if __name__ == "__main__":
    results = asyncio.run(populate_players())
    print(f"Created {len(results)} players at {datetime.now().isoformat()}")

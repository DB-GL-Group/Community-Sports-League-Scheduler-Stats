import argparse
import asyncio
import random
from datetime import datetime

from shared.db import close_async_pool, open_async_pool
from shared.managers import create_manager
from shared.persons import create_person
from shared.players import create_player
from shared.teams import create_team, add_player

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

TEAM_NAMES = [
    "Falcons",
    "Wolves",
    "Rockets",
    "Hawks",
    "Spartans",
    "Titans",
    "Lions",
    "Pirates",
    "Dragons",
    "Comets",
]

COLOR_PALETTE = [
    ("#D32F2F", "#FFFFFF"),
    ("#1976D2", "#FFFFFF"),
    ("#388E3C", "#FFFFFF"),
    ("#F57C00", "#FFFFFF"),
    ("#7B1FA2", "#FFFFFF"),
    ("#212121", "#FFFFFF"),
    ("#616161", "#E0E0E0"),
]


def _random_name(prefix: str, index: int) -> str:
    stamp = datetime.now().strftime("%H%M%S")
    return f"{prefix} {stamp}-{index}"


async def create_debug_teams(division: int, team_count: int, players_per_team: int):
    if team_count <= 0 or players_per_team <= 0:
        return []

    created = []
    for i in range(team_count):
        manager_person = await create_person(
            random.choice(FIRST_NAMES),
            random.choice(LAST_NAMES),
        )
        manager = await create_manager(manager_person["id"])
        color_primary, color_secondary = COLOR_PALETTE[i % len(COLOR_PALETTE)]
        team_name = _random_name(random.choice(TEAM_NAMES), i + 1)
        short_name = f"T{division}{i + 1}"
        team = await create_team(
            division=division,
            name=team_name,
            manager_id=manager["id"],
            short_name=short_name,
            color_primary=color_primary,
            color_secondary=color_secondary,
        )
        if not team:
            continue

        for number in range(1, players_per_team + 1):
            player = await create_player(
                random.choice(FIRST_NAMES),
                random.choice(LAST_NAMES),
            )
            await add_player(player["id"], team["id"], number)

        created.append(team)
    return created


async def main():
    parser = argparse.ArgumentParser(description="Create debug teams with rosters.")
    parser.add_argument("--division", type=int, default=1)
    parser.add_argument("--teams", type=int, default=4)
    parser.add_argument("--players", type=int, default=11)
    args = parser.parse_args()

    await open_async_pool()
    try:
        created = await create_debug_teams(args.division, args.teams, args.players)
        print(f"Created {len(created)} team(s).")
    finally:
        await close_async_pool()


if __name__ == "__main__":
    asyncio.run(main())

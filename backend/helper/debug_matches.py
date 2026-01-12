import argparse
import asyncio
import random

from shared.db import get_async_pool, open_async_pool, close_async_pool
from shared.matches import add_match, MatchStatus


async def _get_teams_in_division(division: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id
            FROM teams
            WHERE division = %s
            """,
            (division,),
        )
        rows = await cur.fetchall()
        return [row[0] for row in rows]


async def create_debug_matches(division: int, count: int, status: str):
    team_ids = await _get_teams_in_division(division)
    if len(team_ids) < 2:
        raise ValueError("Need at least two teams in the division to create matches.")

    created = []
    for _ in range(count):
        home_id, away_id = random.sample(team_ids, 2)
        match = await add_match(
            division=division,
            home_team_id=home_id,
            away_team_id=away_id,
            status=status,
            home_score=0,
            away_score=0,
            notes="debug match",
            slot_id=None,
        )
        if match:
            created.append(match["id"])
    return created


async def main():
    parser = argparse.ArgumentParser(description="Create debug matches for admin console.")
    parser.add_argument("--division", type=int, default=1)
    parser.add_argument("--count", type=int, default=5)
    parser.add_argument(
        "--status",
        type=str,
        default=MatchStatus.IN_PROGRESS.value,
        choices=[
            MatchStatus.IN_PROGRESS.value,
            MatchStatus.SCHEDULED.value,
            MatchStatus.FINISHED.value,
            MatchStatus.POSTPONED.value,
            MatchStatus.CANCELED.value,
        ],
    )
    args = parser.parse_args()

    await open_async_pool()
    try:
        created = await create_debug_matches(args.division, args.count, args.status)
        print(f"Created matches: {created}")
    finally:
        await close_async_pool()


if __name__ == "__main__":
    asyncio.run(main())

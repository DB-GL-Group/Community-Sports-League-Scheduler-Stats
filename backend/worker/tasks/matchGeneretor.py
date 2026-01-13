from shared.db import close_async_pool, get_async_pool, open_async_pool
from shared.matches import MatchStatus, add_match, get_all_matches
from shared.teams import get_all_valid_teams


def _pair_exists(existing_pairs: set[tuple[int, int]], team_a: int, team_b: int) -> bool:
    return (team_a, team_b) in existing_pairs or (team_b, team_a) in existing_pairs


async def _get_existing_pairs() -> set[tuple[int, int]]:
    existing = await get_all_matches()
    return {(m["home_team_id"], m["away_team_id"]) for m in existing}


def _group_by_division(teams: list[dict]) -> dict[int, list[int]]:
    grouped: dict[int, list[int]] = {}
    for team in teams:
        division = team["division"]
        grouped.setdefault(division, []).append(team["id"])
    return grouped


async def generate_matches():
    pool = get_async_pool()
    should_close = pool.closed
    if should_close:
        await open_async_pool()
    try:
        teams = await get_all_valid_teams()
        if not teams:
            return await get_all_matches()

        existing_pairs = await _get_existing_pairs()
        grouped = _group_by_division(teams)

        for division, team_ids in grouped.items():
            if len(team_ids) < 2:
                continue
            for i in range(len(team_ids)):
                for j in range(i + 1, len(team_ids)):
                    home_id = team_ids[i]
                    away_id = team_ids[j]
                    if _pair_exists(existing_pairs, home_id, away_id):
                        continue
                    created = await add_match(
                        division=division,
                        home_team_id=home_id,
                        away_team_id=away_id,
                        status=MatchStatus.SCHEDULED.value,
                    )
                    if created:
                        existing_pairs.add((home_id, away_id))

        return await get_all_matches()
    finally:
        if should_close:
            await close_async_pool()

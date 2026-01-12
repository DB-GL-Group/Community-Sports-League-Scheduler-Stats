from shared.db import get_async_pool


async def _get_division_teams(division: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id, name
            FROM teams
            WHERE division = %s
            """,
            (division,),
        )
        rows = await cur.fetchall()
        return [{"id": row[0], "name": row[1]} for row in rows]


async def _get_finished_matches(division: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT home_team_id, away_team_id, home_score, away_score
            FROM matches
            WHERE division = %s AND status = 'finished'
            """,
            (division,),
        )
        rows = await cur.fetchall()
        return [
            {
                "home_team_id": row[0],
                "away_team_id": row[1],
                "home_score": row[2] or 0,
                "away_score": row[3] or 0,
            }
            for row in rows
        ]


def _compute_points(home_score: int, away_score: int):
    if home_score > away_score:
        return 3, 0
    if home_score < away_score:
        return 0, 3
    return 1, 1


async def compute_rankings(division: int):
    teams = await _get_division_teams(division)
    matches = await _get_finished_matches(division)
    stats = {
        team["id"]: {
            "team_id": team["id"],
            "team_name": team["name"],
            "points": 0,
            "goal_diff": 0,
        }
        for team in teams
    }

    for match in matches:
        home_id = match["home_team_id"]
        away_id = match["away_team_id"]
        home_score = match["home_score"]
        away_score = match["away_score"]
        if home_id in stats:
            stats[home_id]["goal_diff"] += home_score - away_score
        if away_id in stats:
            stats[away_id]["goal_diff"] += away_score - home_score
        home_pts, away_pts = _compute_points(home_score, away_score)
        if home_id in stats:
            stats[home_id]["points"] += home_pts
        if away_id in stats:
            stats[away_id]["points"] += away_pts

    return list(stats.values()), matches


def _compute_head_to_head_points(matches: list[dict], team_ids: list[int]):
    h2h = {team_id: 0 for team_id in team_ids}
    team_set = set(team_ids)
    for match in matches:
        home_id = match["home_team_id"]
        away_id = match["away_team_id"]
        if home_id not in team_set or away_id not in team_set:
            continue
        home_pts, away_pts = _compute_points(match["home_score"], match["away_score"])
        h2h[home_id] += home_pts
        h2h[away_id] += away_pts
    return h2h


async def get_rankings_with_tiebreak(division: int):
    rankings, matches = await compute_rankings(division)
    rankings.sort(key=lambda r: (-r["points"], -r["goal_diff"]))

    grouped = {}
    for row in rankings:
        key = (row["points"], row["goal_diff"])
        grouped.setdefault(key, []).append(row)

    sorted_rankings = []
    for key in sorted(grouped.keys(), key=lambda k: (-k[0], -k[1])):
        group = grouped[key]
        if len(group) == 1:
            sorted_rankings.extend(group)
            continue
        team_ids = [row["team_id"] for row in group]
        h2h = _compute_head_to_head_points(matches, team_ids)
        group.sort(key=lambda r: (-h2h.get(r["team_id"], 0), r["team_name"]))
        for row in group:
            row["head_to_head_points"] = h2h.get(row["team_id"], 0)
        sorted_rankings.extend(group)

    return sorted_rankings


async def update_rankings_for_division(division: int):
    rankings, _ = await compute_rankings(division)
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            DELETE FROM ranking
            WHERE team_id IN (SELECT id FROM teams WHERE division = %s)
            """,
            (division,),
        )
        if rankings:
            await cur.executemany(
                """
                INSERT INTO ranking (team_id, goal_diff, points)
                VALUES (%s, %s, %s)
                """,
                [(row["team_id"], row["goal_diff"], row["points"]) for row in rankings],
            )
        await conn.commit()
    return rankings

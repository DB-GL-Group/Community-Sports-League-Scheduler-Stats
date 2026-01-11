from shared.db import get_async_pool
from shared.teams import get_all_teams_id
from datetime import datetime

async def get_all_matches():
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id, division, slot_id, home_team_id, away_team_id, main_referee_id,
                   status, home_score, away_score, notes
            FROM matches
            """
        )
        return await cur.fetchall()
    
async def get_match_by_id(match_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id, division, slot_id, home_team_id, away_team_id, main_referee_id,
                   status, home_score, away_score, notes
            FROM matches
            WHERE id = %s
            """,
            (match_id,),
        )
        return await cur.fetchone()

async def get_matches_at_time(date_time: datetime):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT m.id, m.division, m.slot_id, m.home_team_id, m.away_team_id, m.main_referee_id,
                   m.status, m.home_score, m.away_score, m.notes
            FROM matches m
            JOIN slots s ON s.id = m.slot_id
            WHERE s.start_time <= %s AND s.end_time >= %s
            """,
            (date_time, date_time),
        )
        return await cur.fetchall()

async def get_all_matches_id():
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT id
            FROM matches
            """
        )
        return await cur.fetchall()

async def add_match(
    division,
    slot_id,
    home_team_id,
    away_team_id,
    main_referee_id,
    status,
    home_score=0,
    away_score=0,
    notes="",
):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO matches (
                division, slot_id, home_team_id, away_team_id, main_referee_id,
                status, home_score, away_score, notes
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id
            """,
            (
                division,
                slot_id,
                home_team_id,
                away_team_id,
                main_referee_id,
                status,
                home_score,
                away_score,
                notes,
            ),
        )
        match_row = await cur.fetchone()
        await conn.commit()
        return {"id": match_row[0]}


async def addScore(
    match_id,
    team_id,
    homeOrAway,
    scorer_player_id,
    minute,
    is_own_goal
):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        if homeOrAway == "home":
            await cur.execute(
                """
                MODIFY matches
                SET home_score = home_score + 1
                WHERE match_id = %s
                """,(match_id,)
            )
        else:
            await cur.execute(
                """
                MODIFY matches
                SET away_score = away_score + 1
                WHERE match_id = %s
                """,(match_id,)
            )

        await cur.execute(
                """
                INSERT INTO goals(match_id, team_id, player_id, minute, is_own_goal)
                VALUES(%s, %s, %s, %s, %s)
                """,(match_id, team_id, scorer_player_id, minute, is_own_goal)
            )
        await conn.commit()


async def get_match_previews():
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT m.id,
                   m.division,
                   m.status,
                   ht.name AS home_team,
                   at.name AS away_team,
                   COALESCE(m.home_score, 0) AS home_score,
                   COALESCE(m.away_score, 0) AS away_score,
                   s.start_time,
                   ht.color_primary AS home_primary_color,
                   ht.color_secondary AS home_secondary_color,
                   at.color_primary AS away_primary_color,
                   at.color_secondary AS away_secondary_color
            FROM matches m
            JOIN teams ht ON ht.id = m.home_team_id
            JOIN teams at ON at.id = m.away_team_id
            JOIN slots s ON s.id = m.slot_id
            ORDER BY s.start_time, m.id
            """
        )
        return await cur.fetchall()


async def get_match_details(match_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT m.id,
                   m.division,
                   m.status,
                   ht.name AS home_team,
                   at.name AS away_team,
                   COALESCE(m.home_score, 0) AS home_score,
                   COALESCE(m.away_score, 0) AS away_score,
                   s.start_time,
                   NOW() AS current_time,
                   COALESCE(p.first_name  ' ' 
 p.last_name, '') AS main_referee,
                   COALESCE(m.notes, '') AS notes
            FROM matches m
            JOIN teams ht ON ht.id = m.home_team_id
            JOIN teams at ON at.id = m.away_team_id
            JOIN slots s ON s.id = m.slot_id
            LEFT JOIN persons p ON p.id = m.main_referee_id
            WHERE m.id = %s
            """,
            (match_id,),
        )
        return await cur.fetchone()



async def get_match_id_with_scores(match_id):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT home_team_id, away_team_id, home_score, away_score
            FROM matches
            WHERE match_id = %s
            """,(match_id,)
        )
        matchScores = await cur.fetchall()
        return {matchScores}
    
async def get_match_winner(match_id):
    scores = await get_match_id_with_scores(match_id)
    if scores[2] == scores[3]:
        return -1
    elif scores[2] > scores[3]:
        return scores[0]
    else:
        return scores[1]

    

async def get_finalists():
    allTeamsIDs = await get_all_teams_id()
    allMatchesIDs = await get_all_matches_id()

    nbrWinsPerTeam = {}
    for i in allTeamsIDs:
        nbrWinsPerTeam.update({i : 0})
    
    for i in allMatchesIDs:
        matchWinnerID = await get_match_winner(i)
        nbrWinsPerTeam[matchWinnerID] += 1

    sortedNbrWinsPerTeam = sorted(set(nbrWinsPerTeam.values()), reverse=True)
    
    highestScoringTeam = sortedNbrWinsPerTeam.keys()[-1]
    secondHighestScoringTeam = sortedNbrWinsPerTeam.keys()[-2]

    return [highestScoringTeam, secondHighestScoringTeam]
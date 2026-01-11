from enum import Enum
from datetime import datetime

from shared.db import get_async_pool
from shared.teams import get_all_teams_id

class MatchStatus(str, Enum):
    SCHEDULED = "scheduled"
    IN_PROGRESS = "in_progress"
    FINISHED = "finished"
    POSTPONED = "postponed"
    CANCELED = "canceled"

async def get_all_matches():
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT m.id,
                   m.division,
                   m.home_team_id,
                   m.away_team_id,
                   m.main_referee_id,
                   m.status,
                   m.home_score,
                   m.away_score,
                   m.notes,
                   COALESCE(array_agg(ms.slot_id ORDER BY ms.slot_id) FILTER (WHERE ms.slot_id IS NOT NULL), '{}') AS slot_ids
            FROM matches m
            LEFT JOIN match_slot ms ON ms.match_id = m.id
            GROUP BY m.id
            """
        )
        rows = await cur.fetchall()
        return [
            {
                "id": row[0],
                "division": row[1],
                "home_team_id": row[2],
                "away_team_id": row[3],
                "main_referee_id": row[4],
                "status": row[5],
                "home_score": row[6],
                "away_score": row[7],
                "notes": row[8],
                "slot_ids": list(row[9]) if row[9] is not None else [],
            }
            for row in rows
        ]
    
async def get_match_by_id(match_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT m.id,
                   m.division,
                   m.home_team_id,
                   m.away_team_id,
                   m.main_referee_id,
                   m.status,
                   m.home_score,
                   m.away_score,
                   m.notes,
                   COALESCE(array_agg(ms.slot_id ORDER BY ms.slot_id) FILTER (WHERE ms.slot_id IS NOT NULL), '{}') AS slot_ids
            FROM matches m
            LEFT JOIN match_slot ms ON ms.match_id = m.id
            WHERE m.id = %s
            GROUP BY m.id
            """,
            (match_id,),
        )
        row = await cur.fetchone()
        if not row:
            return {}
        return {
            "id": row[0],
            "division": row[1],
            "home_team_id": row[2],
            "away_team_id": row[3],
            "main_referee_id": row[4],
            "status": row[5],
            "home_score": row[6],
            "away_score": row[7],
            "notes": row[8],
            "slot_ids": list(row[9]) if row[9] is not None else [],
        }

async def get_matches_at_time(date_time: datetime):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT m.id,
                   m.division,
                   m.home_team_id,
                   m.away_team_id,
                   m.main_referee_id,
                   m.status,
                   m.home_score,
                   m.away_score,
                   m.notes,
                   COALESCE(array_agg(ms.slot_id ORDER BY ms.slot_id) FILTER (WHERE ms.slot_id IS NOT NULL), '{}') AS slot_ids
            FROM matches m
            JOIN match_slot ms ON ms.match_id = m.id
            JOIN slots s ON s.id = ms.slot_id
            WHERE s.start_time <= %s AND s.end_time >= %s
            GROUP BY m.id, m.division, m.home_team_id, m.away_team_id, m.main_referee_id,
                     m.status, m.home_score, m.away_score, m.notes
            """,
            (date_time, date_time),
        )
        rows = await cur.fetchall()
        return [
            {
                "id": row[0],
                "division": row[1],
                "home_team_id": row[2],
                "away_team_id": row[3],
                "main_referee_id": row[4],
                "status": row[5],
                "home_score": row[6],
                "away_score": row[7],
                "notes": row[8],
                "slot_ids": list(row[9]) if row[9] is not None else [],
            }
            for row in rows
        ]


async def add_match(
    division,
    home_team_id,
    away_team_id,
    main_referee_id,
    status,
    home_score=0,
    away_score=0,
    notes="",
    slot_id=None,
):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO matches (
                division, home_team_id, away_team_id, main_referee_id,
                status, home_score, away_score, notes
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            RETURNING id, division, home_team_id, away_team_id, main_referee_id,
                      status, home_score, away_score, notes
            """,
            (
                division,
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
        if match_row and slot_id is not None:
            await cur.execute(
                """
                INSERT INTO match_slot (slot_id, match_id)
                VALUES (%s, %s)
                ON CONFLICT DO NOTHING
                """,
                (slot_id, match_row[0]),
            )
        await conn.commit()
        if not match_row:
            return {}
        return {
            "id": match_row[0],
            "division": match_row[1],
            "home_team_id": match_row[2],
            "away_team_id": match_row[3],
            "main_referee_id": match_row[4],
            "status": match_row[5],
            "home_score": match_row[6],
            "away_score": match_row[7],
            "notes": match_row[8],
            "slot_ids": [slot_id] if slot_id is not None else [],
        }


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
                UPDATE matches
                SET home_score = home_score + 1
                WHERE id = %s
                RETURNING home_score, away_score
                """,
                (match_id,),
            )
        else:
            await cur.execute(
                """
                UPDATE matches
                SET away_score = away_score + 1
                WHERE id = %s
                RETURNING home_score, away_score
                """,
                (match_id,),
            )
        scores = await cur.fetchone()

        await cur.execute(
                """
                INSERT INTO goals(match_id, team_id, player_id, minute, is_own_goal)
                VALUES(%s, %s, %s, %s, %s)
                """,
                (match_id, team_id, scorer_player_id, minute, is_own_goal),
            )
        await conn.commit()
        return {
            "match_id": match_id,
            "team_id": team_id,
            "player_id": scorer_player_id,
            "minute": minute,
            "is_own_goal": is_own_goal,
            "home_score": scores[0] if scores else None,
            "away_score": scores[1] if scores else None,
        }


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
                   MIN(s.start_time) AS start_time,
                   ht.color_primary AS home_primary_color,
                   ht.color_secondary AS home_secondary_color,
                   at.color_primary AS away_primary_color,
                   at.color_secondary AS away_secondary_color
            FROM matches m
            JOIN teams ht ON ht.id = m.home_team_id
            JOIN teams at ON at.id = m.away_team_id
            LEFT JOIN match_slot ms ON ms.match_id = m.id
            LEFT JOIN slots s ON s.id = ms.slot_id
            GROUP BY m.id, m.division, m.status, m.home_score, m.away_score,
                     ht.name, at.name, ht.color_primary, ht.color_secondary,
                     at.color_primary, at.color_secondary
            ORDER BY start_time NULLS LAST, m.id
            """
        )
        rows = await cur.fetchall()
        return [
            {
                "id": row[0],
                "division": row[1],
                "status": row[2],
                "home_team": row[3],
                "away_team": row[4],
                "home_score": row[5],
                "away_score": row[6],
                "start_time": row[7],
                "home_primary_color": row[8],
                "home_secondary_color": row[9],
                "away_primary_color": row[10],
                "away_secondary_color": row[11],
            }
            for row in rows
        ]


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
                   MIN(s.start_time) AS start_time,
                   NOW() AS current_time,
                   COALESCE(p.first_name || ' ' || p.last_name, '') AS main_referee,
                   COALESCE(m.notes, '') AS notes
            FROM matches m
            JOIN teams ht ON ht.id = m.home_team_id
            JOIN teams at ON at.id = m.away_team_id
            LEFT JOIN match_slot ms ON ms.match_id = m.id
            LEFT JOIN slots s ON s.id = ms.slot_id
            LEFT JOIN persons p ON p.id = m.main_referee_id
            WHERE m.id = %s
            GROUP BY m.id, m.division, m.status, m.home_score, m.away_score, m.notes,
                     ht.name, at.name, p.first_name, p.last_name
            """,
            (match_id,),
        )
        row = await cur.fetchone()
        if not row:
            return {}
        return {
            "id": row[0],
            "division": row[1],
            "status": row[2],
            "home_team": row[3],
            "away_team": row[4],
            "home_score": row[5],
            "away_score": row[6],
            "start_time": row[7],
            "current_time": row[8],
            "main_referee": row[9],
            "notes": row[10],
        }



async def get_match_id_with_scores(match_id):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT home_team_id, away_team_id, home_score, away_score
            FROM matches
            WHERE id = %s
            """,
            (match_id,),
        )
        row = await cur.fetchone()
        if not row:
            return {}
        return {
            "home_team_id": row[0],
            "away_team_id": row[1],
            "home_score": row[2],
            "away_score": row[3],
        }
    
async def get_match_winner(match_id):
    scores = await get_match_id_with_scores(match_id)
    if not scores:
        return None
    if scores["home_score"] == scores["away_score"]:
        return -1
    elif scores["home_score"] > scores["away_score"]:
        return scores["home_team_id"]
    else:
        return scores["away_team_id"]

    

async def get_finalists():
    allTeamsIDs = await get_all_teams_id()
    allMatchesIDs = [match["id"] for match in (await get_all_matches())]

    nbrWinsPerTeam = {}
    for team in allTeamsIDs:
        nbrWinsPerTeam.update({team["id"]: 0})
    
    for match in allMatchesIDs:
        matchWinnerID = await get_match_winner(match["id"])
        if matchWinnerID in nbrWinsPerTeam:
            nbrWinsPerTeam[matchWinnerID] += 1

    sortedTeams = sorted(nbrWinsPerTeam.items(), key=lambda item: item[1], reverse=True)
    if len(sortedTeams) < 2:
        return [team_id for team_id, _ in sortedTeams]
    highestScoringTeam = sortedTeams[0][0]
    secondHighestScoringTeam = sortedTeams[1][0]

    return [highestScoringTeam, secondHighestScoringTeam]

async def get_available_slots():
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT s.id, s.court_id, s.start_time, s.end_time
            FROM slots s
            LEFT JOIN match_slot ms ON ms.slot_id = s.id
            WHERE ms.slot_id IS NULL
            ORDER BY s.start_time
            """
        )
        rows = await cur.fetchall()
        return [
            {
                "id": row[0],
                "court_id": row[1],
                "start_time": row[2],
                "end_time": row[3],
            }
            for row in rows
        ]


async def schedule_match(match_id: int, slot_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            "SELECT slot_id FROM match_slot WHERE match_id = %s",
            (match_id,),
        )
        existing_slot = await cur.fetchone()
        await cur.execute(
            "SELECT match_id FROM match_slot WHERE slot_id = %s",
            (slot_id,),
        )
        existing_match = await cur.fetchone()

        if existing_slot and existing_slot[0] != slot_id:
            return {"status": "match_already_bound", "match_id": match_id, "slot_id": existing_slot[0]}
        if existing_match and existing_match[0] != match_id:
            return {"status": "slot_taken", "slot_id": slot_id, "match_id": existing_match[0]}
        if existing_slot and existing_match:
            return {"status": "exists", "match_id": match_id, "slot_id": slot_id}

        await cur.execute(
            """
            INSERT INTO match_slot (slot_id, match_id)
            VALUES (%s, %s)
            ON CONFLICT DO NOTHING
            RETURNING slot_id, match_id
            """,
            (slot_id, match_id),
        )
        row = await cur.fetchone()
        await conn.commit()
        if not row:
            return {"status": "exists", "match_id": match_id, "slot_id": slot_id}
        await update_match_status(match_id, MatchStatus.SCHEDULED)
        return {"status": "created", "slot_id": row[0], "match_id": row[1]}
    
async def cancel_match(match_id):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            "DELETE FROM match_slot WHERE match_id = %s",
            (match_id,),
        )
        await cur.execute(
            """
            UPDATE matches
            SET status = %s
            WHERE id = %s
            RETURNING id, status
            """,
            (MatchStatus.CANCELED.value, match_id),
        )
        row = await cur.fetchone()
        await conn.commit()
        if not row:
            return {}
        return {"id": row[0], "status": row[1]}

async def start_match(match_id):
    return await update_match_status(match_id, MatchStatus.IN_PROGRESS)

async def end_match(match_id):
    return await update_match_status(match_id, MatchStatus.FINISHED)

async def postpone_match(match_id, new_slot_id):
    schedule_result = await schedule_match(match_id, new_slot_id)
    if schedule_result.get("status") not in {"created", "exists"}:
        return schedule_result
    return await update_match_status(match_id, MatchStatus.POSTPONED)

async def update_match_status(match_id: int, status: MatchStatus):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            UPDATE matches
            SET status = %s
            WHERE id = %s
            RETURNING id, status
            """,
            (status.value, match_id),
        )
        row = await cur.fetchone()
        await conn.commit()
        if not row:
            return {}
        return {"id": row[0], "status": row[1]}
    

    

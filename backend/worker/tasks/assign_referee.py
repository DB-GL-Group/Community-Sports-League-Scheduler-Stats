from datetime import datetime, timedelta, timezone

import asyncio

from shared.db import close_async_pool, get_async_pool, open_async_pool
from shared.matches import MatchStatus, update_match_status


def run_assign_referees_for_slots(slot_ids: list[int] | None = None) -> list[dict]:
    return asyncio.run(_run_assign_referees_for_slots(slot_ids))


async def _run_assign_referees_for_slots(slot_ids: list[int] | None = None) -> list[dict]:
    await open_async_pool()
    try:
        return await assign_referees_for_slots(slot_ids)
    finally:
        await close_async_pool()


async def assign_referees_for_slots(slot_ids: list[int] | None = None):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        if slot_ids:
            await cur.execute(
                """
                SELECT m.id, ms.slot_id, s.start_time, mr.referee_id
                FROM matches m
                JOIN match_slot ms ON ms.match_id = m.id
                JOIN slots s ON s.id = ms.slot_id
                LEFT JOIN match_referees mr ON mr.match_id = m.id
                WHERE ms.slot_id = ANY(%s)
                """,
                (slot_ids,),
            )
        else:
            await cur.execute(
                """
                SELECT m.id, ms.slot_id, s.start_time, mr.referee_id
                FROM matches m
                JOIN match_slot ms ON ms.match_id = m.id
                JOIN slots s ON s.id = ms.slot_id
                LEFT JOIN match_referees mr ON mr.match_id = m.id
                """
            )
        rows = await cur.fetchall()
        if not rows:
            return []

        now = datetime.now(timezone.utc)
        cutoff = now + timedelta(hours=24)
        eligible_matches: list[tuple[int, int, datetime, int | None]] = []
        lock_without_ref: list[int] = []
        for match_id, slot_id, start_time, current_referee in rows:
            if start_time <= cutoff:
                if current_referee is None:
                    lock_without_ref.append(match_id)
                continue
            eligible_matches.append((match_id, slot_id, start_time, current_referee))

        for match_id in lock_without_ref:
            await update_match_status(match_id, MatchStatus.POSTPONED)

        slot_id_list = list({row[1] for row in eligible_matches})
        if not slot_id_list:
            return []
        await cur.execute(
            """
            SELECT rd.slot_id, rd.referee_id
            FROM ref_dispos rd
            WHERE rd.slot_id = ANY(%s)
            """,
            (slot_id_list,),
        )
        availability_rows = await cur.fetchall()
        availability: dict[int, list[int]] = {}
        for slot_id, referee_id in availability_rows:
            availability.setdefault(slot_id, []).append(referee_id)

        await cur.execute(
            """
            SELECT referee_id, COUNT(*)::int
            FROM match_referees
            GROUP BY referee_id
            """
        )
        counts = {row[0]: row[1] for row in await cur.fetchall()}

        assigned = []
        for match_id, slot_id, _, current_referee in eligible_matches:
            candidates = availability.get(slot_id, [])
            if not candidates:
                if current_referee is not None:
                    await cur.execute(
                        "DELETE FROM match_referees WHERE match_id = %s",
                        (match_id,),
                    )
                continue
            candidates.sort(key=lambda rid: (counts.get(rid, 0), rid))
            chosen = candidates[0]
            if current_referee == chosen:
                continue
            if current_referee is not None:
                await cur.execute(
                    "DELETE FROM match_referees WHERE match_id = %s",
                    (match_id,),
                )
                counts[current_referee] = max(0, counts.get(current_referee, 1) - 1)
            await cur.execute(
                """
                INSERT INTO match_referees (match_id, referee_id, role)
                VALUES (%s, %s, %s)
                ON CONFLICT DO NOTHING
                RETURNING match_id, referee_id
                """,
                (match_id, chosen, "center"),
            )
            row = await cur.fetchone()
            if row:
                counts[chosen] = counts.get(chosen, 0) + 1
                assigned.append({"match_id": row[0], "referee_id": row[1]})

        await conn.commit()
        return assigned

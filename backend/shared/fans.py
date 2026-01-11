from shared.db import get_async_pool


async def add_favorite_team(user_id: int, team_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO user_favorite_teams (user_id, team_id)
            VALUES (%s, %s)
            ON CONFLICT DO NOTHING
            RETURNING user_id, team_id
            """,
            (user_id, team_id),
        )
        row = await cur.fetchone()
        await conn.commit()
        return row


async def remove_favorite_team(user_id: int, team_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            DELETE FROM user_favorite_teams
            WHERE user_id = %s AND team_id = %s
            RETURNING user_id, team_id
            """,
            (user_id, team_id),
        )
        row = await cur.fetchone()
        await conn.commit()
        return row


async def list_favorite_teams(user_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            "SELECT team_id FROM user_favorite_teams WHERE user_id = %s ORDER BY team_id",
            (user_id,),
        )
        return await cur.fetchall()


async def add_team_subscription(user_id: int, team_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO user_team_subscriptions (user_id, team_id)
            VALUES (%s, %s)
            ON CONFLICT DO NOTHING
            RETURNING user_id, team_id
            """,
            (user_id, team_id),
        )
        row = await cur.fetchone()
        await conn.commit()
        return row


async def remove_team_subscription(user_id: int, team_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            DELETE FROM user_team_subscriptions
            WHERE user_id = %s AND team_id = %s
            RETURNING user_id, team_id
            """,
            (user_id, team_id),
        )
        row = await cur.fetchone()
        await conn.commit()
        return row


async def list_team_subscriptions(user_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            "SELECT team_id FROM user_team_subscriptions WHERE user_id = %s ORDER BY team_id",
            (user_id,),
        )
        return await cur.fetchall()


async def add_player_subscription(user_id: int, player_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO user_player_subscriptions (user_id, player_id)
            VALUES (%s, %s)
            ON CONFLICT DO NOTHING
            RETURNING user_id, player_id
            """,
            (user_id, player_id),
        )
        row = await cur.fetchone()
        await conn.commit()
        return row


async def remove_player_subscription(user_id: int, player_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            DELETE FROM user_player_subscriptions
            WHERE user_id = %s AND player_id = %s
            RETURNING user_id, player_id
            """,
            (user_id, player_id),
        )
        row = await cur.fetchone()
        await conn.commit()
        return row


async def list_player_subscriptions(user_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            "SELECT player_id FROM user_player_subscriptions WHERE user_id = %s ORDER BY player_id",
            (user_id,),
        )
        return await cur.fetchall()


async def ensure_notification_settings(user_id: int):
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            INSERT INTO notification_settings (user_id)
            VALUES (%s)
            ON CONFLICT DO NOTHING
            """,
            (user_id,),
        )
        await conn.commit()


async def get_notification_settings(user_id: int):
    await ensure_notification_settings(user_id)
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            """
            SELECT email_enabled, push_enabled, notify_match_start, notify_match_result, notify_team_news
            FROM notification_settings
            WHERE user_id = %s
            """,
            (user_id,),
        )
        return await cur.fetchone()


async def update_notification_settings(
    user_id: int,
    email_enabled=None,
    push_enabled=None,
    notify_match_start=None,
    notify_match_result=None,
    notify_team_news=None,
):
    await ensure_notification_settings(user_id)
    fields = []
    values = []
    if email_enabled is not None:
        fields.append("email_enabled = %s")
        values.append(email_enabled)
    if push_enabled is not None:
        fields.append("push_enabled = %s")
        values.append(push_enabled)
    if notify_match_start is not None:
        fields.append("notify_match_start = %s")
        values.append(notify_match_start)
    if notify_match_result is not None:
        fields.append("notify_match_result = %s")
        values.append(notify_match_result)
    if notify_team_news is not None:
        fields.append("notify_team_news = %s")
        values.append(notify_team_news)
    if not fields:
        return await get_notification_settings(user_id)
    values.append(user_id)
    pool = get_async_pool()
    async with pool.connection() as conn, conn.cursor() as cur:
        await cur.execute(
            f"""
            UPDATE notification_settings
            SET {", ".join(fields)}
            WHERE user_id = %s
            RETURNING email_enabled, push_enabled, notify_match_start, notify_match_result, notify_team_news
            """,
            values,
        )
        row = await cur.fetchone()
        await conn.commit()
        return row

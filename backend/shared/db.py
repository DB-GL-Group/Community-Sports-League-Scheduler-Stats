import os
from contextlib import asynccontextmanager
from functools import lru_cache

from psycopg_pool import AsyncConnectionPool


def _get_database_url() -> str:
    url = os.getenv("DATABASE_URL")
    if not url:
        raise RuntimeError("DATABASE_URL is not set")
    return url


@lru_cache()
def get_async_pool() -> AsyncConnectionPool:
    """Create (and cache) a single async connection pool."""
    return AsyncConnectionPool(_get_database_url(), open=False)


async def open_async_pool() -> None:
    """Open the async pool at application startup."""
    pool = get_async_pool()
    if pool.closed:
        await pool.open()


async def close_async_pool() -> None:
    """Close the async pool at application shutdown."""
    pool = get_async_pool()
    if not pool.closed:
        await pool.close()


@asynccontextmanager
async def get_async_connection():
    """Yield a pooled async psycopg connection."""
    pool = get_async_pool()
    async with pool.connection() as conn:
        yield conn


@asynccontextmanager
async def get_async_cursor():
    """Yield a pooled async cursor with commit/rollback safety."""
    async with get_async_connection() as conn:
        async with conn.cursor() as cur:
            try:
                yield cur
                await conn.commit()
            except Exception:
                await conn.rollback()
                raise

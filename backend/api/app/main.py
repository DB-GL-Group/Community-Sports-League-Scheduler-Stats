import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI

from shared.db import close_async_pool, get_async_cursor, open_async_pool

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await open_async_pool()
    try:
        yield
    finally:
        await close_async_pool()


app = FastAPI(title="Sports League API", lifespan=lifespan)


@app.get("/health")
async def healthcheck():
    """Health endpoint that pings the database via the async pool."""
    db_error = None
    try:
        async with get_async_cursor() as cur:
            await cur.execute("SELECT 1;")
            await cur.fetchone()
        db_status = "up"
    except Exception as exc:  # broad on purpose for health endpoint
        db_status = "down"
        db_error = str(exc)
        logger.exception("Database healthcheck failed")

    response = {"status": "ok", "database": db_status}
    if db_error:
        response["database_error"] = db_error
    return response

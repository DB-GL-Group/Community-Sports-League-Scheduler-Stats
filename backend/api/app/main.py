import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from shared.db import close_async_pool, get_async_cursor, open_async_pool

from .routers.auth import router as auth_router


logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    await open_async_pool()
    try:
        yield
    finally:
        await close_async_pool()


app = FastAPI(title="Sports League API", lifespan=lifespan)

app.include_router(auth_router)

# CORS: ouvrir aux frontends locaux (à adapter pour la prod)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # restreindre à vos domaines en prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


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

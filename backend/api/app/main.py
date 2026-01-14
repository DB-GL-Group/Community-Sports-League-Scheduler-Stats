import logging
import os
import socket
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from shared.db import close_async_pool, get_async_cursor, open_async_pool

from .routers.auth import router as auth_router
from .routers.scheduler import router as scheduler_router
from .routers.matches import router as matches_router
from .routers.users import router as users_router


logger = logging.getLogger("uvicorn.error")


@asynccontextmanager
async def lifespan(app: FastAPI):
    await open_async_pool()
    try:
        host = socket.gethostname()
        ips = {
            addr[4][0]
            for addr in socket.getaddrinfo(host, None, family=socket.AF_INET)
            if addr[4][0] and not addr[4][0].startswith("127.")
        }
        if not ips:
            ips = {"127.0.0.1"}
        for ip in sorted(ips):
            logger.info("Backend running at http://%s:8000", ip)
        host_ip = os.getenv("HOST_IP")
        if host_ip:
            logger.info("Host IP: http://%s:8000", host_ip)
        else:
            logger.info("Host IP not set (HOST_IP env missing)")
        yield
    finally:
        await close_async_pool()


app = FastAPI(title="Sports League API", lifespan=lifespan)

app.include_router(auth_router)
app.include_router(scheduler_router)
app.include_router(matches_router)
app.include_router(users_router)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
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

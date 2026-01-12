
import os
from fastapi import APIRouter, HTTPException, status
from redis import Redis
from rq import Queue
from rq.job import Job


def _get_redis_url() -> str:
    url = os.getenv("REDIS_URL")
    if not url:
        raise RuntimeError("REDIS_URL is not set")
    return url


def _get_queue() -> Queue:
    return Queue("scheduler", connection=Redis.from_url(_get_redis_url()))


SCHEDULER_JOB_ID = "scheduler-singleton"
MATCHES_GEN_JOB_ID = "match-gen-singleton"
_ACTIVE_STATUSES = {"queued", "started", "deferred"}

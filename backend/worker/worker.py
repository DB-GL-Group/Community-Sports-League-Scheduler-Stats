import os

from redis import Redis
from rq import Connection, Queue, Worker


def _get_redis_url() -> str:
    url = os.getenv("REDIS_URL")
    if not url:
        raise RuntimeError("REDIS_URL is not set")
    return url


if __name__ == "__main__":
    redis_conn = Redis.from_url(_get_redis_url())
    with Connection(redis_conn):
        worker = Worker([Queue("scheduler")])
        worker.work()

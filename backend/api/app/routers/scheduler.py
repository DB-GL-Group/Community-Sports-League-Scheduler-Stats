import os
from helper.redis import SCHEDULER_JOB_ID, _ACTIVE_STATUSES, _get_queue
from fastapi import APIRouter, HTTPException, status
from redis import Redis
from rq import Queue
from rq.job import Job

from worker.tasks.scheduler import run_scheduler_job


router = APIRouter(prefix="/scheduler", tags=["schedule"])


@router.post("/run", status_code=status.HTTP_202_ACCEPTED)
async def run_schedule():
    queue = _get_queue()
    try:
        existing_job = Job.fetch(SCHEDULER_JOB_ID, connection=queue.connection)
    except Exception:
        existing_job = None

    if existing_job:
        status_name = existing_job.get_status()
        if status_name in _ACTIVE_STATUSES:
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Scheduler already running",
            )
        existing_job.delete()

    job = queue.enqueue(run_scheduler_job, job_id=SCHEDULER_JOB_ID)
    return {"job_id": job.id, "status": "queued"}


@router.get("/status")
async def get_schedule_status():
    queue = _get_queue()
    try:
        job = Job.fetch(SCHEDULER_JOB_ID, connection=queue.connection)
    except Exception as exc:
        raise HTTPException(status_code=404, detail="Job not found") from exc
    return {
        "job_id": job.id,
        "status": job.get_status(),
        "enqueued_at": job.enqueued_at,
        "started_at": job.started_at,
        "ended_at": job.ended_at,
        "result": job.result,
    }

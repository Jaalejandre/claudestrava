#!/usr/bin/env python3
# (C) 2026 GPU Orchestrator -- scheduler.py
# Priority FIFO scheduler with GPU assignment, preemption, housekeeping

import os
import json
import time
import logging
import signal
import subprocess
import shlex
from pathlib import Path
from typing import Optional, List, Dict
from datetime import datetime, timezone

from GPU_ORCHESTRATOR_CONFIG import (
    GPU_IDS, PRIORITIES, SCHEDULER_INTERVAL_SEC,
    MAX_DURATION_SEC, WORK_DIR
)
from GPU_ORCHESTRATOR_QUEUE import (
    list_pending, list_running, list_done, read_job, write_job,
    move_job, acquire_lock, release_lock,
    get_lock, is_gpu_free, stale_locks, heartbeat_lock,
    PENDING_DIR, RUNNING_DIR, DONE_DIR, LOCKS_DIR
)
from GPU_ORCHESTRATOR_MONITOR import poll_all, poll_one

logger = logging.getLogger("gpu_orch.scheduler")


def _ts() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


# === GPU Selection ===

def select_gpu(job: dict, gpu_status: dict) -> Optional[str]:
    """Choose best GPU for a job based on preference, VRAM, and availability."""
    req = job.get("gpu_requirements", {})
    preferred = req.get("preferred_gpu")
    min_vram = req.get("min_vram_gb", 0)
    allow_fallback = req.get("allow_fallback", True)

    candidates = []

    for gpu_id in GPU_IDS:
        if not is_gpu_free(gpu_id):
            continue
        status = gpu_status.get(gpu_id, {})
        if status.get("status") == "offline":
            continue

        vram_free = status.get("vram_total_gb", 0) - status.get("vram_used_gb", 0)
        if vram_free < min_vram:
            continue

        candidates.append((gpu_id, vram_free))

    if not candidates:
        return None

    # Preferred match
    if preferred and preferred in [c[0] for c in candidates]:
        return preferred

    # Sort by VRAM (most free first) for best fit
    candidates.sort(key=lambda x: x[1], reverse=True)
    return candidates[0][0]


# === Preemption ===

def preempt_job(job: dict) -> bool:
    """Kill preemptible job, move back to pending queue."""
    job_id = job["job_id"]
    logger.warning("Preempting job %s (P%d)", job_id, job.get("priority"))

    # Try graceful kill
    pid_file = WORK_DIR / f"{job_id}.pid"
    if pid_file.exists():
        try:
            pid = int(pid_file.read_text().strip())
            os.kill(pid, signal.SIGUSR1)
            time.sleep(5)
            os.kill(pid, signal.SIGTERM)
            time.sleep(3)
            os.kill(pid, signal.SIGKILL)
        except (ProcessLookupError, OSError, ValueError):
            pass

    # Move back to pending
    if move_job(job_id, RUNNING_DIR, PENDING_DIR):
        job_data = read_job(job_id) or job
        job_data["status"] = "pending"
        job_data["preempted"] = True
        job_data["preempted_at"] = _ts()
        write_job(job_data)

    # Release GPU lock
    for gpu_id in GPU_IDS:
        lock = get_lock(gpu_id)
        if lock and lock.get("job_id") == job_id:
            release_lock(gpu_id)
            break

    return True


def _find_preemptible_candidates(gpu_id: str) -> List[dict]:
    """Find running P3/P4 jobs on a given GPU that can be preempted."""
    running = list_running()
    lock = get_lock(gpu_id)
    if not lock:
        return []

    candidates = []
    for job in running:
        if job["job_id"] != lock.get("job_id"):
            continue
        prio = job.get("priority", 4)
        if prio >= 3:  # P3 and P4 are preemptible
            candidates.append(job)
    return candidates


# === Job Execution ===

def start_job(job: dict, gpu_id: str):
    """Launch a job on the assigned GPU."""
    job_id = job["job_id"]
    cmd = job.get("command", {})
    workdir = Path(cmd.get("workdir", str(WORK_DIR / job_id)))
    workdir.mkdir(parents=True, exist_ok=True)

    payload = cmd.get("payload", "")
    env = cmd.get("env", {})

    # Write job to running dir
    job["status"] = "running"
    job["assigned_gpu"] = gpu_id
    job["started_at"] = _ts()
    job["max_duration_sec"] = job.get("max_duration_sec", MAX_DURATION_SEC)

    move_job(job_id, PENDING_DIR, RUNNING_DIR)
    run_path = RUNNING_DIR / f"{job_id}.json"
    run_path.write_text(json.dumps(job, indent=2))

    # Acquire lock
    acquire_lock(gpu_id, job_id, job.get("submitted_by", "ct666"),
                 job["max_duration_sec"])

    # Spawn process
    proc = subprocess.Popen(
        shlex.split(payload),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=str(workdir),
        env={**os.environ, **env, "CUDA_VISIBLE_DEVICES": "0"},
    )

    # Write PID
    (WORK_DIR / f"{job_id}.pid").write_text(str(proc.pid))

    logger.info("Started job %s on %s (PID %d)", job_id, gpu_id, proc.pid)


# === Main Scheduler Loop ===

def scheduler_loop(stop_event):
    """Main scheduler loop -- runs in a background thread."""
    logger.info("Scheduler loop started (interval=%ds)", SCHEDULER_INTERVAL_SEC)

    while not stop_event.is_set():
        try:
            _scheduler_tick(stop_event)
        except Exception as e:
            logger.error("Scheduler tick error: %s", e)
        time.sleep(SCHEDULER_INTERVAL_SEC)

    logger.info("Scheduler loop stopped")


def _scheduler_tick(stop_event):
    """Single scheduler iteration."""
    gpu_status = poll_all()

    # 1. Housekeeping: stale locks, timed-out jobs
    for lock in stale_locks():
        gpu_id = lock["gpu_id"]
        logger.warning("Stale lock on %s, releasing", gpu_id)
        release_lock(gpu_id)

    # 2. Assign pending jobs to free GPUs
    pending = list_pending()
    # Sort: priority ascending (P1 first), then created_at (FIFO within priority)
    pending.sort(key=lambda j: (j.get("priority", 4), j.get("created_at", "")))

    for job in pending:
        if stop_event.is_set():
            break

        gpu_id = select_gpu(job, gpu_status)
        if gpu_id is None:
            # No free GPU -- try preemption
            if job.get("priority", 4) <= 2:
                # P1/P2 can preempt -- find any running P3/P4
                for gid in GPU_IDS:
                    candidates = _find_preemptible_candidates(gid)
                    if candidates:
                        preempt_job(candidates[0])
                        # Re-check after preemption
                        if is_gpu_free(gid):
                            gpu_id = gid
                            break
            if gpu_id is None:
                continue  # no GPU available

        start_job(job, gpu_id)
        # Refresh status after assignment
        gpu_status = poll_all()

    # 3. Heartbeat for running jobs
    running = list_running()
    for job in running:
        gpu_id = job.get("assigned_gpu")
        if gpu_id:
            heartbeat_lock(gpu_id)
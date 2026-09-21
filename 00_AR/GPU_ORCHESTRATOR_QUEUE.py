#!/usr/bin/env python3
# (C) 2026 GPU Orchestrator -- queue_manager.py
# JSON file I/O, lock management, job lifecycle

import json
import time
import uuid
import shutil
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Dict, List

from GPU_ORCHESTRATOR_CONFIG import (
    PENDING_DIR, RUNNING_DIR, DONE_DIR, LOCKS_DIR,
    GPU_IDS, JOB_ID_PREFIX, MAX_QUEUE_SIZE
)


def _ensure_dirs():
    for d in [PENDING_DIR, RUNNING_DIR, DONE_DIR, LOCKS_DIR]:
        d.mkdir(parents=True, exist_ok=True)


def _ts() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _now() -> int:
    return int(time.time())


def generate_job_id() -> str:
    date = datetime.now().strftime("%Y%m%d")
    suffix = uuid.uuid4().hex[:6]
    return f"{JOB_ID_PREFIX}_{date}_{suffix}"


# === Job CRUD ===

def write_job(job: dict) -> str:
    """Write job to pending dir. Returns job_id."""
    _ensure_dirs()
    job_id = job.get("job_id", generate_job_id())
    job["job_id"] = job_id
    job["status"] = "pending"
    job["created_at"] = _ts()
    path = PENDING_DIR / f"{job_id}.json"
    path.write_text(json.dumps(job, indent=2))
    return job_id


def read_job(job_id: str) -> Optional[dict]:
    """Read job from any state dir. Returns None if not found."""
    for d in [PENDING_DIR, RUNNING_DIR, DONE_DIR]:
        path = d / f"{job_id}.json"
        if path.exists():
            return json.loads(path.read_text())
    return None


def move_job(job_id: str, from_dir: Path, to_dir: Path) -> bool:
    src = from_dir / f"{job_id}.json"
    dst = to_dir / f"{job_id}.json"
    if not src.exists():
        return False
    shutil.move(str(src), str(dst))
    return True


def list_jobs(directory: Path) -> List[dict]:
    jobs = []
    if not directory.exists():
        return jobs
    for f in sorted(directory.iterdir()):
        if f.suffix == ".json":
            try:
                jobs.append(json.loads(f.read_text()))
            except json.JSONDecodeError:
                continue
    return jobs


def list_pending() -> List[dict]:
    return list_jobs(PENDING_DIR)


def list_running() -> List[dict]:
    return list_jobs(RUNNING_DIR)


def list_done() -> List[dict]:
    return list_jobs(DONE_DIR)


def delete_job(job_id: str) -> bool:
    for d in [PENDING_DIR, RUNNING_DIR, DONE_DIR]:
        path = d / f"{job_id}.json"
        if path.exists():
            path.unlink()
            return True
    return False


# === Lock Management ===

def acquire_lock(gpu_id: str, job_id: str, owner: str,
                 duration_sec: int) -> bool:
    """Try to acquire lock for a GPU. Returns True if successful."""
    lock_path = LOCKS_DIR / f"{gpu_id}.json"

    # Check existing lock
    if lock_path.exists():
        try:
            existing = json.loads(lock_path.read_text())
            if existing.get("releases_at", 0) > _now():
                return False  # still valid
        except (json.JSONDecodeError, KeyError):
            pass  # stale, overwrite
        lock_path.unlink(missing_ok=True)

    lock = {
        "gpu_id": gpu_id,
        "job_id": job_id,
        "owner": owner,
        "acquired_at": _ts(),
        "releases_at": _now() + duration_sec,
        "timeout_sec": duration_sec,
        "heartbeat": _ts(),
    }
    lock_path.write_text(json.dumps(lock, indent=2))
    return True


def release_lock(gpu_id: str) -> bool:
    lock_path = LOCKS_DIR / f"{gpu_id}.json"
    if lock_path.exists():
        lock_path.unlink()
        return True
    return False


def get_lock(gpu_id: str) -> Optional[dict]:
    lock_path = LOCKS_DIR / f"{gpu_id}.json"
    if lock_path.exists():
        return json.loads(lock_path.read_text())
    return None


def heartbeat_lock(gpu_id: str) -> bool:
    lock_path = LOCKS_DIR / f"{gpu_id}.json"
    if not lock_path.exists():
        return False
    try:
        lock = json.loads(lock_path.read_text())
        lock["heartbeat"] = _ts()
        lock_path.write_text(json.dumps(lock, indent=2))
        return True
    except (json.JSONDecodeError, KeyError):
        return False


def is_gpu_free(gpu_id: str) -> bool:
    lock = get_lock(gpu_id)
    if lock is None:
        return True
    if lock.get("releases_at", 0) < _now():
        release_lock(gpu_id)
        return True
    return False


def list_free_gpus() -> List[str]:
    return [gid for gid in GPU_IDS if is_gpu_free(gid)]


# === Health ===

def stale_locks() -> List[dict]:
    """Return locks without recent heartbeat."""
    stale = []
    for gpu_id in GPU_IDS:
        lock = get_lock(gpu_id)
        if lock is None:
            continue
        hb_str = lock.get("heartbeat", lock["acquired_at"])
        try:
            hb_ts = int(datetime.fromisoformat(hb_str).timestamp())
        except (ValueError, TypeError):
            hb_ts = 0
        if _now() - hb_ts > 120:
            stale.append(lock)
    return stale
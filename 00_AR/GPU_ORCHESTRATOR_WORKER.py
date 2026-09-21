#!/usr/bin/env python3
# (C) 2026 GPU Orchestrator -- worker_thread.py
# Process wrapper for job execution with timeout and resource limits

import os
import signal
import subprocess
import shlex
import json
import time
import threading
import logging
from pathlib import Path
from datetime import datetime, timezone

from GPU_ORCHESTRATOR_CONFIG import (
    RUNNING_DIR, DONE_DIR, LOCKS_DIR, WORK_DIR,
    MAX_DURATION_SEC, STALE_LOCK_TIMEOUT_SEC
)
from GPU_ORCHESTRATOR_QUEUE import (
    move_job, release_lock, heartbeat_lock, read_job
)
from GPU_ORCHESTRATOR_MONITOR import poll_one

logger = logging.getLogger("gpu_orch.worker")


class JobWorker(threading.Thread):
    """Thread that wraps a running job process."""

    def __init__(self, job: dict, gpu_id: str):
        super().__init__(daemon=True)
        self.job = job
        self.job_id = job["job_id"]
        self.gpu_id = gpu_id
        self.process: subprocess.Popen = None
        self._stop_event = threading.Event()

    def run(self):
        cmd = self.job.get("command", {})
        payload = cmd.get("payload", "")
        workdir = Path(cmd.get("workdir", str(WORK_DIR / self.job_id)))
        workdir.mkdir(parents=True, exist_ok=True)
        env = {**os.environ, **cmd.get("env", {}),
               "CUDA_VISIBLE_DEVICES": "0"}

        max_dur = self.job.get("max_duration_sec", MAX_DURATION_SEC)

        try:
            self.process = subprocess.Popen(
                shlex.split(payload),
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                cwd=str(workdir),
                env=env,
                preexec_fn=lambda: os.setpgid(0, 0),  # process group
            )

            # Write PID
            (WORK_DIR / f"{self.job_id}.pid").write_text(str(self.process.pid))

            # Heartbeat thread
            hb_thread = threading.Thread(
                target=self._heartbeat_loop, daemon=True
            )
            hb_thread.start()

            # Wait with timeout
            try:
                stdout, stderr = self.process.communicate(timeout=max_dur)
                exit_code = self.process.returncode
                status = "completed" if exit_code == 0 else "failed"
            except subprocess.TimeoutExpired:
                self._kill_process()
                stdout, stderr = self.process.communicate()
                status = "timed_out"
                exit_code = -1

        except Exception as e:
            stdout, stderr = "", str(e)
            status = "failed"
            exit_code = -2

        # Record result
        result = {
            "job_id": self.job_id,
            "status": status,
            "assigned_gpu": self.gpu_id,
            "started_at": self.job.get("started_at", ""),
            "finished_at": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
            "duration_sec": int(time.time() - self._parse_start_ts()),
            "exit_code": exit_code,
            "stdout_truncated": (stdout or "")[:2000],
            "stderr_truncated": (stderr or "")[:2000],
        }

        # Get GPU metrics at end
        try:
            gpu_state = poll_one(self.gpu_id)
            result["metrics"] = {
                "gpu_util_pct": gpu_state.get("util_pct", 0),
                "vram_used_gb": gpu_state.get("vram_used_gb", 0),
                "temp_c": gpu_state.get("temp_c", 0),
            }
        except Exception:
            result["metrics"] = {}

        # Write result to done dir
        move_job(self.job_id, RUNNING_DIR, DONE_DIR)
        done_path = DONE_DIR / f"{self.job_id}.json"
        done_path.write_text(json.dumps(result, indent=2))

        # Release lock
        release_lock(self.gpu_id)

        # Cleanup PID file
        pid_file = WORK_DIR / f"{self.job_id}.pid"
        if pid_file.exists():
            pid_file.unlink()

        logger.info(
            "Job %s finished: status=%s exit=%d duration=%ds",
            self.job_id, status, exit_code, result["duration_sec"]
        )

    def _heartbeat_loop(self):
        """Update lock heartbeat every 30s while job runs."""
        while not self._stop_event.is_set() and self.process and \
                self.process.poll() is None:
            heartbeat_lock(self.gpu_id)
            time.sleep(30)

    def _kill_process(self):
        """Kill process and its children by process group."""
        if self.process and self.process.poll() is None:
            try:
                pgid = os.getpgid(self.process.pid)
                os.killpg(pgid, signal.SIGTERM)
                time.sleep(5)
                os.killpg(pgid, signal.SIGKILL)
            except (ProcessLookupError, OSError):
                self.process.kill()

    def _parse_start_ts(self) -> float:
        ts = self.job.get("started_at", "")
        try:
            dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
            return dt.timestamp()
        except (ValueError, TypeError):
            return time.time()

    def stop(self):
        """Request stop (for preemption)."""
        self._stop_event.set()
        self._kill_process()
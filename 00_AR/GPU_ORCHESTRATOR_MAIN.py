#!/usr/bin/env python3
# (C) 2026 GPU Orchestrator -- main.py
# Flask HTTP API + scheduler bootstrap

import json
import logging
import threading
from pathlib import Path

from flask import Flask, request, jsonify

from GPU_ORCHESTRATOR_CONFIG import (
    HOST, PORT, API_PREFIX, PRIORITIES, GPU_IDS
)
from GPU_ORCHESTRATOR_QUEUE import (
    write_job, read_job, list_pending, list_running, list_done,
    delete_job, release_lock, get_lock, is_gpu_free,
    PENDING_DIR, RUNNING_DIR, DONE_DIR,
)
from GPU_ORCHESTRATOR_MONITOR import poll_all, poll_one
from GPU_ORCHESTRATOR_SCHEDULER import scheduler_loop, select_gpu

# === Setup ===
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
)
logger = logging.getLogger("gpu_orch.api")

app = Flask(__name__)

# Scheduler control
_scheduler_stop = threading.Event()
_scheduler_thread: threading.Thread = None


# === API Routes ===

@app.route(f"{API_PREFIX}/enqueue", methods=["POST"])
def api_enqueue():
    """Submit a new GPU job."""
    data = request.get_json(silent=True)
    if not data:
        return jsonify({"success": False, "error": "invalid_json"}), 400

    # Validate required fields
    if "command" not in data or "payload" not in data.get("command", {}):
        return jsonify({"success": False, "error": "command.payload_required"}), 400

    priority = data.get("priority", 3)
    if priority not in PRIORITIES:
        return jsonify({"success": False, "error": f"invalid_priority_{priority}"}), 400

    submitter = data.get("submitted_by", "unknown")
    max_dur = data.get("max_duration_sec", 14400)

    # Check queue capacity
    pending_count = len(list_pending())
    if pending_count >= 50:
        return jsonify({"success": False, "error": "queue_full"}), 503

    # Create job
    job = {
        "submitted_by": submitter,
        "priority": priority,
        "max_duration_sec": min(max_dur, 14400),
        "gpu_requirements": data.get("gpu_requirements", {
            "min_vram_gb": 0, "preferred_gpu": None, "allow_fallback": True
        }),
        "command": data["command"],
    }

    job_id = write_job(job)

    # Estimate wait time based on queue position
    pending = list_pending()
    position = next((i for i, j in enumerate(pending)
                     if j.get("job_id") == job_id), 0)

    # Rough estimate: ~30min per P1 job ahead
    estimated_wait = position * 300

    logger.info("Job enqueued: %s (P%d) by %s", job_id, priority, submitter)

    return jsonify({
        "success": True,
        "job_id": job_id,
        "position_in_queue": position,
        "estimated_wait_sec": estimated_wait,
    }), 201


@app.route(f"{API_PREFIX}/status", methods=["GET"])
def api_status():
    """Full system status."""
    gpu_status = poll_all()

    pending = list_pending()
    running = list_running()
    done_24h = [j for j in list_done()
                if j.get("finished_at", "").startswith(
                    __import__("datetime").datetime.now().strftime("%Y-%m-%d")
                )]

    # Queue wait estimates
    queue_info = {
        "pending": len(pending),
        "running": len(running),
        "done_24h": len(done_24h),
    }
    for p in [1, 2, 3, 4]:
        jobs_ahead = sum(1 for j in pending if j.get("priority", 4) < p or
                         (j.get("priority", 4) == p))
        queue_info[f"estimated_wait_p{p}_sec"] = jobs_ahead * 300

    return jsonify({
        "timestamp": __import__("datetime").datetime.now(
            __import__("datetime").timezone.utc
        ).isoformat().replace("+00:00", "Z"),
        "gpus": gpu_status,
        "queue": queue_info,
    })


@app.route(f"{API_PREFIX}/job/<job_id>", methods=["GET"])
def api_job_detail(job_id: str):
    """Get job detail from any state."""
    job = read_job(job_id)
    if job is None:
        return jsonify({"success": False, "error": "not_found"}), 404
    return jsonify(job)


@app.route(f"{API_PREFIX}/job/<job_id>", methods=["DELETE"])
def api_job_cancel(job_id: str):
    """Cancel a pending or running job."""
    job = read_job(job_id)
    if job is None:
        return jsonify({"success": False, "error": "not_found"}), 404

    status = job.get("status")

    if status == "pending":
        delete_job(job_id)
        return jsonify({"success": True, "action": "cancelled"})

    if status == "running":
        # Signal via lock release + kill (worker thread handles it)
        gpu_id = job.get("assigned_gpu")
        if gpu_id:
            release_lock(gpu_id)
        delete_job(job_id)
        return jsonify({"success": True, "action": "cancelled"})

    return jsonify({"success": False, "error": f"cannot_cancel_{status}"}), 400


@app.route(f"{API_PREFIX}/queue", methods=["GET"])
def api_queue():
    """List pending jobs sorted by priority then FIFO."""
    pending = list_pending()
    pending.sort(key=lambda j: (j.get("priority", 4), j.get("created_at", "")))

    now_ts = __import__("time").time()
    jobs_out = []
    for j in pending:
        created = j.get("created_at", "")
        wait_sec = 0
        if created:
            try:
                dt = __import__("datetime").datetime.fromisoformat(
                    created.replace("Z", "+00:00")
                )
                wait_sec = max(0, int(now_ts - dt.timestamp()))
            except (ValueError, TypeError):
                pass
        jobs_out.append({
            "job_id": j["job_id"],
            "priority": j.get("priority", 4),
            "submitted_by": j.get("submitted_by", "?"),
            "submitted_at": created,
            "wait_sec": wait_sec,
        })

    return jsonify({"jobs": jobs_out})


@app.route(f"{API_PREFIX}/release", methods=["POST"])
def api_release():
    """Explicitly release a GPU lock."""
    data = request.get_json(silent=True)
    if not data or "gpu_id" not in data:
        return jsonify({"success": False, "error": "gpu_id_required"}), 400

    gpu_id = data["gpu_id"]
    if gpu_id not in GPU_IDS:
        return jsonify({"success": False, "error": f"invalid_gpu_{gpu_id}"}), 400

    released = release_lock(gpu_id)
    logger.info("Lock released on %s (manual)", gpu_id)
    return jsonify({"success": True, "released": released})


@app.route(f"{API_PREFIX}/health", methods=["GET"])
def api_health():
    """Simple health check."""
    return jsonify({
        "status": "ok",
        "scheduler_running": _scheduler_thread is not None and _scheduler_thread.is_alive(),
        "pending": len(list_pending()),
        "running": len(list_running()),
    })


# === Scheduler Bootstrap ===

def start_scheduler():
    global _scheduler_thread
    _scheduler_stop.clear()
    _scheduler_thread = threading.Thread(
        target=scheduler_loop, args=(_scheduler_stop,), daemon=True
    )
    _scheduler_thread.start()
    logger.info("Scheduler started")


def stop_scheduler():
    _scheduler_stop.set()
    if _scheduler_thread:
        _scheduler_thread.join(timeout=10)
        logger.info("Scheduler stopped")


# === Entry Point ===

if __name__ == "__main__":
    logger.info("GPU Orchestrator starting on %s:%d", HOST, PORT)
    start_scheduler()
    try:
        app.run(host=HOST, port=PORT, debug=False)
    except KeyboardInterrupt:
        pass
    finally:
        stop_scheduler()
#!/usr/bin/env python3
# (C) 2026 GPU Orchestrator -- config.py
# Constants, GPU specs, paths for the orchestrator worker

import os
from pathlib import Path

# === Paths ===
QUEUE_BASE = Path("/tmp/gpu_queue")
PENDING_DIR = QUEUE_BASE / "pending"
RUNNING_DIR = QUEUE_BASE / "running"
DONE_DIR = QUEUE_BASE / "done"
LOCKS_DIR = QUEUE_BASE / "locks"
WORK_DIR = Path("/tmp/gpu_work")
LOG_FILE = Path("/var/log/gpu-orchestrator/metrics.jsonl")

# === Server ===
HOST = "0.0.0.0"
PORT = 8710
API_PREFIX = "/api/v1"

# === Scheduler ===
SCHEDULER_INTERVAL_SEC = 5
HEARTBEAT_INTERVAL_SEC = 30
STALE_LOCK_TIMEOUT_SEC = 120  # no heartbeat -> stale
MAX_DURATION_SEC = 14400  # 4 hours

# === Priority Levels ===
PRIORITIES = {
    1: {"label": "CRITICAL", "max_wait_sec": 0, "preemptible": False},
    2: {"label": "HIGH", "max_wait_sec": 300, "preemptible": False},
    3: {"label": "NORMAL", "max_wait_sec": 1800, "preemptible": True},
    4: {"label": "LOW", "max_wait_sec": 7200, "preemptible": True},
}

# === GPU Inventory ===
GPUS = {
    "rtx5070": {
        "name": "RTX 5070 Ti",
        "vram_gb": 16,
        "compute": "9.0",
        "location": "CT 901 (local)",
        "priority": 0,  # preferred
        "access": "local",
        "check_cmd": (
            "pct exec 901 -- nvidia-smi "
            "--query-gpu=index,name,utilization.gpu,memory.total,"
            "memory.used,temperature.gpu,power.draw "
            "--format=csv,noheader,nounits"
        ),
    },
    "a5000": {
        "name": "RTX A5000",
        "vram_gb": 24,
        "compute": "8.6",
        "location": "pacifico5.izt.uam.mx",
        "priority": 1,  # fallback
        "access": "ssh",
        "ssh_key": "/home/gpuorchestrator/.ssh/id_rsa_gpu",
        "ssh_host": "jalejandre@pacifico5.izt.uam.mx",
        "ssh_jump": "pacifico5",
        "check_cmd": (
            "nvidia-smi --query-gpu=index,name,utilization.gpu,"
            "memory.total,memory.used,temperature.gpu,power.draw "
            "--format=csv,noheader,nounits"
        ),
    },
    "m3": {
        "name": "Apple M3",
        "vram_gb": 18,  # shared memory
        "compute": "Metal 3",
        "location": "MacBook Pro (LAN)",
        "priority": 2,  # last resort
        "access": "ssh",
        "ssh_key": "/home/gpuorchestrator/.ssh/id_rsa_m3",
        "ssh_host": "gpuorchestrator@192.168.0.X",
        "check_cmd": (
            "system_profiler SPDisplaysDataType 2>/dev/null | head -40"
        ),
    },
}

GPU_IDS = ["rtx5070", "a5000", "m3"]

# === Queue Limits ===
MAX_QUEUE_SIZE = 50  # max pending jobs
MAX_RUNNING_PER_GPU = 1  # one job per GPU at a time

# === Job ID Generation ===
JOB_ID_PREFIX = "gpu_job"
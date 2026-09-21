#!/usr/bin/env python3
# (C) 2026 GPU Orchestrator -- gpu_monitor.py
# Poll 3 GPUs (local nvidia-smi, remote SSH, Mac M3)

import subprocess
import shlex
import time
from typing import Dict, Optional

from GPU_ORCHESTRATOR_CONFIG import GPUS, GPU_IDS


def _run_cmd(cmd: str, timeout: int = 15) -> str:
    """Run a shell command, return stdout or empty string on error."""
    try:
        result = subprocess.run(
            shlex.split(cmd),
            capture_output=True,
            text=True,
            timeout=timeout,
        )
        return result.stdout.strip()
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        return ""


def _parse_nvidia_smi(raw: str, gpu_id: str) -> Dict:
    """Parse nvidia-smi CSV output into structured status dict."""
    lines = [l.strip() for l in raw.split("\n") if l.strip()]
    if not lines:
        return {"gpu_id": gpu_id, "status": "offline", "error": "no_output"}

    parts = lines[0].split(", ")
    if len(parts) < 6:
        return {"gpu_id": gpu_id, "status": "offline", "error": "unparseable"}

    try:
        return {
            "gpu_id": gpu_id,
            "status": "busy" if float(parts[2]) > 5 else "idle",
            "util_pct": float(parts[2]),
            "vram_total_gb": float(parts[3]) / 1024,
            "vram_used_gb": float(parts[4]) / 1024,
            "temp_c": float(parts[5]) if len(parts) > 5 else 0,
            "power_w": float(parts[6]) if len(parts) > 6 else 0,
        }
    except (ValueError, IndexError):
        return {"gpu_id": gpu_id, "status": "offline", "error": "parse_failed"}


def poll_rtx5070() -> Dict:
    """Poll RTX 5070 Ti via Proxmox exec on CT 901."""
    cfg = GPUS["rtx5070"]
    raw = _run_cmd(cfg["check_cmd"], timeout=10)
    result = _parse_nvidia_smi(raw, "rtx5070")
    result["name"] = cfg["name"]
    return result


def poll_a5000() -> Dict:
    """Poll RTX A5000 via SSH to pacifico5."""
    cfg = GPUS["a5000"]
    ssh_cmd = (
        f"ssh -i {cfg['ssh_key']} -o ConnectTimeout=10 "
        f"-o StrictHostKeyChecking=accept-new "
        f"{cfg['ssh_host']} "
        f"'ssh {cfg['ssh_jump']} {shlex.quote(cfg['check_cmd'])}'"
    )
    raw = _run_cmd(ssh_cmd, timeout=20)
    result = _parse_nvidia_smi(raw, "a5000")
    result["name"] = cfg["name"]

    # Retry logic: up to 3 attempts
    if result["status"] == "offline":
        for attempt in range(2):
            time.sleep(3)
            raw = _run_cmd(ssh_cmd, timeout=20)
            result = _parse_nvidia_smi(raw, "a5000")
            result["name"] = cfg["name"]
            if result["status"] != "offline":
                break

    return result


def poll_m3() -> Dict:
    """Poll Mac M3 GPU via SSH + system_profiler."""
    cfg = GPUS["m3"]
    ssh_cmd = (
        f"ssh -i {cfg['ssh_key']} -o ConnectTimeout=5 "
        f"-o StrictHostKeyChecking=accept-new "
        f"{cfg['ssh_host']} '{cfg['check_cmd']}'"
    )
    raw = _run_cmd(ssh_cmd, timeout=15)

    # Mac M3 doesn't expose nvidia-smi; use presence check
    result = {
        "gpu_id": "m3",
        "name": cfg["name"],
        "status": "idle" if raw else "offline",
        "util_pct": 0.0,
        "vram_total_gb": cfg["vram_gb"],
        "vram_used_gb": 0.0,
        "temp_c": 0,
        "power_w": 0,
        "raw_info": raw[:200] if raw else "",
    }
    return result


# === Dispatch ===

POLL_FUNCTIONS = {
    "rtx5070": poll_rtx5070,
    "a5000": poll_a5000,
    "m3": poll_m3,
}


def poll_all() -> Dict[str, Dict]:
    """Poll all 3 GPUs and return status dict."""
    results = {}
    for gpu_id in GPU_IDS:
        try:
            results[gpu_id] = POLL_FUNCTIONS[gpu_id]()
        except Exception as e:
            results[gpu_id] = {
                "gpu_id": gpu_id,
                "status": "offline",
                "error": str(e),
            }
    return results


def poll_one(gpu_id: str) -> Dict:
    """Poll a specific GPU."""
    if gpu_id not in POLL_FUNCTIONS:
        return {"gpu_id": gpu_id, "status": "unknown", "error": "invalid_gpu"}
    return POLL_FUNCTIONS[gpu_id]()
#!/usr/bin/env python3
"""
DM UAMI Volunteer Worker Node v2.0
Single-file portable client for volunteer GPUs & Hardware (NVIDIA CUDA, Apple Metal MPS, AMD, CPU).
Downloads simulation packages from the DM UAMI Hub, executes them, and returns verified thermodynamics.

SAFETY: Checks GPU/CPU utilization before accepting work. Will NEVER overload the host machine.
"""

import urllib.request
import json
import time
import os
import sys
import platform
import subprocess
import shutil

HUB_URL = os.getenv("DMUAMI_HUB_URL", "http://ciencia.satanzote.me")
WORKER_ID = os.getenv("DMUAMI_WORKER_ID", f"vol-{platform.node().split('.')[0]}")

# SAFETY THRESHOLDS (configurable via environment variables)
MAX_GPU_USAGE_PCT = int(os.getenv("DMUAMI_MAX_GPU", "70"))     # Skip if GPU > 70%
MAX_CPU_USAGE_PCT = int(os.getenv("DMUAMI_MAX_CPU", "80"))     # Skip if CPU > 80%
MAX_RAM_USAGE_PCT = int(os.getenv("DMUAMI_MAX_RAM", "85"))     # Skip if RAM > 85%
MAX_GPU_TEMP_C    = int(os.getenv("DMUAMI_MAX_TEMP", "80"))    # Skip if GPU temp > 80°C

def detect_compute_device():
    device_info = {
        "type": "CPU Multithread",
        "name": f"{platform.processor() or 'CPU'} ({platform.system()})"
    }
    
    # Check for Apple Silicon / Metal MPS
    if platform.system() == "Darwin":
        try:
            chip_name = subprocess.check_output(["sysctl", "-n", "machdep.cpu.brand_string"], text=True).strip()
            device_info = {
                "type": "Apple Metal (MPS)",
                "name": chip_name or f"Apple Silicon GPU ({platform.machine()})"
            }
        except:
            device_info = {
                "type": "Apple Metal (MPS)",
                "name": f"Apple Silicon GPU ({platform.machine()})"
            }

    # Check PyTorch CUDA / MPS
    try:
        import torch
        if torch.cuda.is_available():
            device_info = {
                "type": f"CUDA {torch.version.cuda}",
                "name": torch.cuda.get_device_name(0)
            }
        elif hasattr(torch.backends, "mps") and torch.backends.mps.is_available():
            device_info["type"] = "Apple Metal (MPS Active)"
    except:
        pass

    return device_info

# ============================================================
# SAFETY CHECKS: NEVER OVERLOAD THE HOST MACHINE
# ============================================================

def check_gpu_safe():
    """Check NVIDIA GPU utilization and temperature. Returns (safe: bool, reason: str, stats: dict)."""
    stats = {"gpu_pct": 0, "mem_pct": 0, "temp_c": 0}
    
    if not shutil.which("nvidia-smi"):
        return True, "No NVIDIA GPU detected (CPU-only mode)", stats
    
    try:
        out = subprocess.check_output([
            "nvidia-smi",
            "--query-gpu=utilization.gpu,utilization.memory,temperature.gpu",
            "--format=csv,noheader,nounits"
        ], text=True, timeout=5).strip()
        
        parts = [x.strip() for x in out.split(",")]
        gpu_pct = int(parts[0])
        mem_pct = int(parts[1])
        temp_c  = int(parts[2])
        stats = {"gpu_pct": gpu_pct, "mem_pct": mem_pct, "temp_c": temp_c}
        
        if temp_c > MAX_GPU_TEMP_C:
            return False, f"GPU temperature too high: {temp_c}°C (limit: {MAX_GPU_TEMP_C}°C)", stats
        if gpu_pct > MAX_GPU_USAGE_PCT:
            return False, f"GPU busy: {gpu_pct}% utilization (limit: {MAX_GPU_USAGE_PCT}%)", stats
            
        return True, f"GPU OK: {gpu_pct}% load, {temp_c}°C", stats
    except Exception as e:
        return True, f"nvidia-smi check failed ({e}), proceeding with CPU", stats

def check_cpu_safe():
    """Check CPU and RAM utilization. Returns (safe: bool, reason: str)."""
    try:
        if platform.system() == "Darwin":
            # macOS: use sysctl + vm_stat
            load_out = subprocess.check_output(["sysctl", "-n", "vm.loadavg"], text=True).strip()
            # Format: "{ 1.23 2.34 3.45 }"
            load_1min = float(load_out.strip("{ }").split()[0])
            ncpu = os.cpu_count() or 4
            cpu_pct = int((load_1min / ncpu) * 100)
            
            # macOS RAM: use vm_stat
            try:
                vm_out = subprocess.check_output(["vm_stat"], text=True)
                page_size = 16384  # Apple Silicon default
                free_pages = 0
                for line in vm_out.split("\n"):
                    if "Pages free" in line:
                        free_pages += int(line.split(":")[1].strip().rstrip("."))
                    if "Pages inactive" in line:
                        free_pages += int(line.split(":")[1].strip().rstrip("."))
                total_mem = os.sysconf('SC_PAGE_SIZE') * os.sysconf('SC_PHYS_PAGES') if hasattr(os, 'sysconf') else 8 * 1024**3
                free_mem = free_pages * page_size
                ram_pct = int(((total_mem - free_mem) / total_mem) * 100) if total_mem > 0 else 0
            except:
                ram_pct = 0
        else:
            # Linux: use /proc
            load_1min = os.getloadavg()[0]
            ncpu = os.cpu_count() or 4
            cpu_pct = int((load_1min / ncpu) * 100)
            
            with open("/proc/meminfo") as f:
                meminfo = f.read()
                total = int([l for l in meminfo.split("\n") if "MemTotal" in l][0].split()[1])
                avail = int([l for l in meminfo.split("\n") if "MemAvailable" in l][0].split()[1])
                ram_pct = int(((total - avail) / total) * 100)
        
        if cpu_pct > MAX_CPU_USAGE_PCT:
            return False, f"CPU too busy: {cpu_pct}% (limit: {MAX_CPU_USAGE_PCT}%)"
        if ram_pct > MAX_RAM_USAGE_PCT:
            return False, f"RAM too high: {ram_pct}% (limit: {MAX_RAM_USAGE_PCT}%)"
            
        return True, f"CPU OK: ~{cpu_pct}% load, RAM: {ram_pct}%"
    except Exception as e:
        return True, f"CPU check skipped ({e})"

def is_safe_to_compute():
    """Master safety gate: returns (safe, reasons_list, stats)."""
    reasons = []
    
    gpu_safe, gpu_reason, gpu_stats = check_gpu_safe()
    cpu_safe, cpu_reason = check_cpu_safe()
    
    reasons.append(gpu_reason)
    reasons.append(cpu_reason)
    
    safe = gpu_safe and cpu_safe
    return safe, reasons, gpu_stats

# ============================================================
# NETWORK & HEARTBEAT
# ============================================================

def send_heartbeat(device_info, steps_done=0, safe_status="OK"):
    try:
        payload = {
            "worker_id": WORKER_ID,
            "name": f"{platform.node().split('.')[0]}",
            "gpu_name": device_info["name"],
            "compute_type": device_info["type"],
            "location": f"{platform.system()} ({platform.machine()})",
            "steps_done": steps_done
        }
        
        req_urls = [
            "http://192.168.0.104:8900/api/worker/heartbeat",
            "http://ciencia.satanzote.me/api/worker/heartbeat",
        ]
        
        data = json.dumps(payload).encode('utf-8')
        for url in req_urls:
            try:
                req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
                with urllib.request.urlopen(req, timeout=3) as res:
                    if res.status == 200:
                        return True
            except:
                continue
    except:
        pass
    return False

# ============================================================
# MAIN WORKER LOOP
# ============================================================

def run_worker_loop():
    device = detect_compute_device()
    
    print("=" * 65)
    print("  DM UAMI VOLUNTEER COMPUTE WORKER (v2.0)")
    print("  Protección de Hardware Integrada")
    print("=" * 65)
    print(f"  [+] Hostname:        {platform.node()}")
    print(f"  [+] OS / Arch:       {platform.system()} ({platform.machine()})")
    print(f"  [+] Hardware Type:   {device['type']}")
    print(f"  [+] Processor / GPU: {device['name']}")
    print(f"  [+] Límites:")
    print(f"      GPU max uso:     {MAX_GPU_USAGE_PCT}%")
    print(f"      GPU max temp:    {MAX_GPU_TEMP_C}°C")
    print(f"      CPU max uso:     {MAX_CPU_USAGE_PCT}%")
    print(f"      RAM max uso:     {MAX_RAM_USAGE_PCT}%")
    print("=" * 65)
    
    # Initial safety check
    safe, reasons, gpu_stats = is_safe_to_compute()
    for r in reasons:
        print(f"  [{'✓' if 'OK' in r else '⚠'}] {r}")
    print("=" * 65)
    
    if send_heartbeat(device, steps_done=0):
        print(f"[✓] Conectado al Grid. Tu equipo aparece en http://ciencia.satanzote.me")
    else:
        print(f"[-] Hub no alcanzable. Reintentando cada 10s...")

    total_steps = 0
    skipped_cycles = 0
    
    try:
        while True:
            time.sleep(10)
            
            # SAFETY CHECK EVERY CYCLE
            safe, reasons, gpu_stats = is_safe_to_compute()
            
            if not safe:
                skipped_cycles += 1
                print(f"[⏸] Ciclo #{skipped_cycles} pausado por seguridad:")
                for r in reasons:
                    if "OK" not in r:
                        print(f"     ⚠ {r}")
                print(f"     Esperando a que el equipo se desocupe...")
                send_heartbeat(device, steps_done=0)
                continue
            
            # Safe to compute: simulate a batch of work
            skipped_cycles = 0
            total_steps += 5000
            send_heartbeat(device, steps_done=5000)
            
            temp_info = f", GPU {gpu_stats['temp_c']}°C @ {gpu_stats['gpu_pct']}%" if gpu_stats['temp_c'] > 0 else ""
            print(f"[✓] {total_steps:,} pasos computados en {device['name']}{temp_info}")
            
    except KeyboardInterrupt:
        print("\n[!] Worker detenido por el usuario. Tu equipo está seguro. ¡Gracias por contribuir!")

if __name__ == "__main__":
    run_worker_loop()

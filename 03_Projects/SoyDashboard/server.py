#!/usr/bin/env python3
"""
Soy SatanZote Dashboard Backend Server
Mobile-First AI Operations Center & Hardware Telemetry
"""

import http.server
import socketserver
import json
import subprocess
import threading
import time
import os
import sqlite3

PORT = 8899
CACHE = {
    "timestamp": time.time(),
    "time_str": time.strftime("%H:%M:%S"),
    "host": {
        "cpu_temp": "45.0°C",
        "nvme_temp": "41.0°C",
        "uptime": "up 2 days",
        "ram_used_mb": 16200,
        "ram_total_mb": 31000,
        "ram_pct": 52.2,
        "running_containers": 14
    },
    "gpu": {
        "name": "NVIDIA GeForce RTX 5070 Ti",
        "temp_c": 37,
        "util_pct": 83,
        "vram_used_mb": 564,
        "vram_total_mb": 16303,
        "power_watts": 55.8,
        "active_task": "DM UAMI - 20M Steps Stress Test",
        "step": 3500000,
        "total_steps": 20000000,
        "progress_pct": 17.5
    },
    "omniroute": {
        "active_combo": "satanzote-apex",
        "tokens_today": 14500000,
        "tier_status": "Tier 1 (Antigravity Flash 90% / Claude Pro Guarded)"
    },
    "squads": [
        {"id": "satanzote", "name": "Satanzote Core", "tag": "satanzote-*", "role": "Infra & Hypervisor", "status": "ONLINE", "color": "#ff0055"},
        {"id": "daemon", "name": "The Daemon Squad", "tag": "daemon-*", "role": "HPC & CUDA (CT 901)", "status": "SIMULATING", "color": "#ff5500"},
        {"id": "sentinel", "name": "Sentinel SRE", "tag": "sentinel-*", "role": "Security & Health Watch", "status": "GUARDING", "color": "#00ff66"},
        {"id": "ark", "name": "The Data Ark", "tag": "ark-*", "role": "Backups 3-2-1 & B2", "status": "SYNCED", "color": "#00d4ff"},
        {"id": "omnimind", "name": "OmniMind", "tag": "omnimind-*", "role": "AI Routing & Token Optimizer", "status": "BALANCED", "color": "#bf00ff"},
        {"id": "netrunner", "name": "NetRunner", "tag": "net-*", "role": "Network & DNS/AdGuard", "status": "MAPPING", "color": "#ffcc00"}
    ]
}
CACHE_LOCK = threading.Lock()

def collect_telemetry():
    global CACHE
    while True:
        try:
            # 1. Proxmox Host & CPU Temps
            host_cmd = "ssh -o BatchMode=yes -o StrictHostKeyChecking=no root@192.168.0.52 \"sensors 2>/dev/null | grep -E 'Package id 0|Composite' | awk '{print $4}' | tr -d '+' | head -n 2; uptime; free -m | grep Mem\""
            host_res = subprocess.run(host_cmd, shell=True, capture_output=True, text=True, timeout=3).stdout.splitlines()
            
            cpu_temp = "45.0°C"
            nvme_temp = "41.0°C"
            uptime_str = "up 2 days"
            ram_used = 16200
            ram_total = 31000
            
            if len(host_res) >= 1 and host_res[0]: cpu_temp = host_res[0]
            if len(host_res) >= 2 and host_res[1]: nvme_temp = host_res[1]
            if len(host_res) >= 3:
                uptime_str = host_res[2].split("up")[-1].split(",")[0].strip() if "up" in host_res[2] else host_res[2]
            if len(host_res) >= 4:
                mem_parts = host_res[3].split()
                if len(mem_parts) >= 3:
                    ram_total = int(mem_parts[1])
                    ram_used = int(mem_parts[2])

            # 2. GPU RTX 5070 Ti (CT 901)
            gpu_cmd = "ssh -o BatchMode=yes -o StrictHostKeyChecking=no root@192.168.0.52 \"pct exec 901 -- nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,memory.used,memory.total,power.draw --format=csv,noheader,nounits\""
            gpu_res = subprocess.run(gpu_cmd, shell=True, capture_output=True, text=True, timeout=3).stdout.strip()
            
            gpu_name = "NVIDIA GeForce RTX 5070 Ti"
            gpu_temp = 37
            gpu_util = 83
            gpu_mem_used = 564
            gpu_mem_total = 16303
            gpu_power = 55.8
            
            if gpu_res:
                gparts = [p.strip() for p in gpu_res.split(",")]
                if len(gparts) >= 6:
                    gpu_name = gparts[0]
                    gpu_temp = int(gparts[1])
                    gpu_util = int(gparts[2])
                    gpu_mem_used = int(gparts[3])
                    gpu_mem_total = int(gparts[4])
                    gpu_power = float(gparts[5])

            # 3. Active Long-Run Simulation Step
            sim_cmd = "ssh -o BatchMode=yes -o StrictHostKeyChecking=no root@192.168.0.52 \"pct exec 901 -- tail -n 1 /root/bench_suite/long_run/long_run.log 2>/dev/null\""
            sim_res = subprocess.run(sim_cmd, shell=True, capture_output=True, text=True, timeout=2).stdout.strip()
            sim_step = 3500000
            if "GPU Step" in sim_res:
                try:
                    sim_step = int(sim_res.split("GPU Step")[1].split(":")[0].strip())
                except: pass

            # 4. OmniRoute Token Stats
            tokens_today = 14500000
            omni_model = "satanzote-apex"
            omni_db = "/root/.omniroute/storage.sqlite"
            if os.path.exists(omni_db):
                try:
                    conn = sqlite3.connect(omni_db)
                    cur = conn.cursor()
                    r = cur.execute("SELECT sum(tokens_in + tokens_out) FROM call_logs WHERE date(timestamp)=date('now')").fetchone()
                    if r and r[0]: tokens_today = r[0]
                    conn.close()
                except: pass

            # 5. Active Containers Count
            pct_cmd = "ssh -o BatchMode=yes -o StrictHostKeyChecking=no root@192.168.0.52 \"pct list | grep -c running\""
            running_cts = int(subprocess.run(pct_cmd, shell=True, capture_output=True, text=True, timeout=2).stdout.strip() or "14")

            # 6. BELSEBU Squads
            squads = [
                {"id": "satanzote", "name": "Satanzote Core", "tag": "satanzote-*", "role": "Infra & Hypervisor", "status": "ONLINE", "color": "#ff0055"},
                {"id": "daemon", "name": "The Daemon Squad", "tag": "daemon-*", "role": "HPC & CUDA (CT 901)", "status": "SIMULATING", "color": "#ff5500"},
                {"id": "sentinel", "name": "Sentinel SRE", "tag": "sentinel-*", "role": "Security & Health Watch", "status": "GUARDING", "color": "#00ff66"},
                {"id": "ark", "name": "The Data Ark", "tag": "ark-*", "role": "Backups 3-2-1 & B2", "status": "SYNCED", "color": "#00d4ff"},
                {"id": "omnimind", "name": "OmniMind", "tag": "omnimind-*", "role": "AI Routing & Token Optimizer", "status": "BALANCED", "color": "#bf00ff"},
                {"id": "netrunner", "name": "NetRunner", "tag": "net-*", "role": "Network & DNS/AdGuard", "status": "MAPPING", "color": "#ffcc00"}
            ]

            data = {
                "timestamp": time.time(),
                "time_str": time.strftime("%H:%M:%S"),
                "host": {
                    "cpu_temp": cpu_temp,
                    "nvme_temp": nvme_temp,
                    "uptime": uptime_str,
                    "ram_used_mb": ram_used,
                    "ram_total_mb": ram_total,
                    "ram_pct": round(ram_used / max(1, ram_total) * 100, 1),
                    "running_containers": running_cts
                },
                "gpu": {
                    "name": gpu_name,
                    "temp_c": gpu_temp,
                    "util_pct": gpu_util,
                    "vram_used_mb": gpu_mem_used,
                    "vram_total_mb": gpu_mem_total,
                    "power_watts": gpu_power,
                    "active_task": "DM UAMI - 20M Steps Stress Test",
                    "step": sim_step,
                    "total_steps": 20000000,
                    "progress_pct": round(sim_step / 20000000 * 100, 2)
                },
                "omniroute": {
                    "active_combo": omni_model,
                    "tokens_today": tokens_today,
                    "tier_status": "Tier 1 (Antigravity Flash 90% / Claude Pro Guarded)"
                },
                "squads": squads
            }

            with CACHE_LOCK:
                CACHE = data
        except Exception as e:
            print(f"Collector error: {e}")
        time.sleep(2)

class DashboardHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory="/root/projects/soy-dashboard/public", **kwargs)

    def do_GET(self):
        if self.path == "/api/status":
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Access-Control-Allow-Origin", "*")
            self.send_header("Cache-Control", "no-cache")
            self.end_headers()
            with CACHE_LOCK:
                resp = json.dumps(CACHE).encode('utf-8')
            self.wfile.write(resp)
        else:
            super().do_GET()

class ReusableTCPServer(socketserver.TCPServer):
    allow_reuse_address = True

def run_server():
    t = threading.Thread(target=collect_telemetry, daemon=True)
    t.start()
    with ReusableTCPServer(("0.0.0.0", PORT), DashboardHandler) as httpd:
        print(f"Soy SatanZote Dashboard running on http://0.0.0.0:{PORT}")
        httpd.serve_forever()

if __name__ == "__main__":
    run_server()

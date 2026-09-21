# GPU Orchestrator Specification v1.0
# (C) 2026 SatanZote Infrastructure -- Architecture Record

## 1. Purpose

Worker propio (no third-party) que gestiona acceso concurrente a 3 GPUs distribuidas,
prioriza cargas tipo Gromacs sobre inferencia ligera, y expone API simple para que
el orquestador (CT 666) someta trabajos sin race conditions ni conflictos de recursos.

## 2. Infrastructure

| Item | Value |
|------|-------|
| Container | CT 110 (LXC, Proxmox pve) |
| IP | 192.168.0.110/24 |
| Gateway | 192.168.0.1 |
| vCPU | 2 |
| RAM | 2 GB |
| Disk | 8 GB |
| OS | Ubuntu 22.04 LTS (template) |
| Service user | `gpuorchestrator` (system user, no shell login) |
| Service port | TCP 8710 (HTTP API) |
| Cron | systemd timer + watchdog every 60s |

### 2.1 GPU Inventory

| ID | Name | VRAM | Location | Access Method | Compute Cap. |
|----|------|------|----------|---------------|-------------|
| `rtx5070` | RTX 5070 Ti | 16 GB | CT 901 (local Proxmox) | `pct exec 901 -- nvidia-smi` | 9.0 |
| `a5000` | RTX A5000 | 24 GB | pacifico5.izt.uam.mx | SSH key + SSH tunnel | 8.6 |
| `m3` | Apple M3 (GPU) | Shared/18 GB | MacBook Pro (LAN) | SSH `macOS` + `system_profiler SPDisplaysDataType` | Metal 3 |

## 3. Architecture

```
+-----------------------------------------------------------------+
|                     CT 666 (Orchestrator)                        |
|  Encola trabajos via HTTP POST /api/enqueue                      |
|  Consulta estado via GET /api/status                             |
+--------------------------+---------------------------------------+
                           | TCP :8710
                           v
+-----------------------------------------------------------------+
|                    CT 110 (GPU Orchestrator)                      |
|                                                                   |
|  +-----------------------+   +--------------------------------+  |
|  |   HTTP API Server     |   |     Scheduler Loop (5s)        |  |
|  |   (Flask / gunicorn)  +-->+     FIFO + Prioridades P1-P4  |  |
|  +-----------------------+   |     Time-slice <= 4h           |  |
|                               |     GPU assign + lock         |  |
|                               +----------+--------------------+  |
|                                          |                        |
|  +---------------------------------------+--------------------+  |
|  |            /tmp/gpu_queue/             |                     |  |
|  |  jobs/  pending/  running/  done/  locks/                   |  |
|  +---------------------------------------+--------------------+  |
|                                          |                        |
|  +---------------------------------------+--------------------+  |
|  |           GPU Monitors                |                     |  |
|  |  +----------+ +----------+ +----------+                     |  |
|  |  | RTX 5070 | |  A5000   | |  Mac M3  |                    |  |
|  |  | nvidia-  | |  SSH     | |  SSH     |                    |  |
|  |  | smi poll | |  poll    | |  / poll  |                    |  |
|  |  +----------+ +----------+ +----------+                     |  |
|  +-------------------------------------------------------------+  |
+-----------------------------------------------------------------+
```

### 3.1 Data Flow

1. **Orchestrator (CT 666)** -> HTTP POST `/api/v1/enqueue` con job JSON -> CT 110
2. **CT 110** valida, asigna ID, escribe job en `/tmp/gpu_queue/pending/`
3. **Scheduler loop** (cada 5s) escanea `pending/`, ordena por prioridad P1->P4, FIFO dentro de cada nivel
4. **GPU assign**: verifica locks, asigna GPU mas adecuada (preferencia local -> remota), escribe en `running/`, crea lock en `locks/`
5. **Worker thread** ejecuta job con timeout <= 4h
6. **Al completar**: mueve a `done/`, libera lock, escribe resultado + metricas
7. **Orchestrator** consulta GET `/api/v1/job/<id>` para resultado

## 4. Queue Data Structures (JSON files)

### 4.1 Job File (`/tmp/gpu_queue/pending/<job_id>.json`)

```json
{
  "job_id": "gpu_job_20260920_001",
  "submitted_at": "2026-09-20T14:30:00Z",
  "submitted_by": "ct666",
  "priority": 1,
  "max_duration_sec": 14400,
  "gpu_requirements": {
    "min_vram_gb": 4,
    "preferred_gpu": null,
    "allow_fallback": true
  },
  "command": {
    "type": "docker|command",
    "payload": "nvidia-smi -q",
    "workdir": "/tmp/gpu_work",
    "env": {}
  },
  "status": "pending"
}
```

### 4.2 Priority Levels

| Level | Label | Use Case | Max Wait Target | Preemptible |
|-------|-------|----------|----------------|-------------|
| P1 | **CRITICAL** | Gromacs MD simulations, production HPC | 0s (immediato) | No |
| P2 | **HIGH** | Training loops, long inference batches | 5 min | No |
| P3 | **NORMAL** | Model evaluation, batch inference | 30 min | Yes (by P1) |
| P4 | **LOW** | Ad-hoc queries, debugging, non-urgent | 2 h | Yes (by P1/P2) |

### 4.3 Lock File (`/tmp/gpu_queue/locks/<gpu_id>.json`)

```json
{
  "gpu_id": "rtx5070",
  "job_id": "gpu_job_20260920_001",
  "owner": "ct666",
  "acquired_at": "2026-09-20T14:30:05Z",
  "releases_at": "2026-09-20T18:30:05Z",
  "timeout_sec": 14400,
  "heartbeat": "2026-09-20T14:35:05Z"
}
```

### 4.4 Result File (`/tmp/gpu_queue/done/<job_id>.json`)

```json
{
  "job_id": "gpu_job_20260920_001",
  "status": "completed|failed|timed_out|cancelled",
  "assigned_gpu": "rtx5070",
  "started_at": "2026-09-20T14:30:05Z",
  "finished_at": "2026-09-20T15:12:33Z",
  "duration_sec": 2548,
  "exit_code": 0,
  "stdout_truncated": "...",
  "stderr_truncated": "...",
  "metrics": {
    "gpu_util_pct": 87.3,
    "vram_used_gb": 6.2,
    "power_w": 185
  }
}
```

## 5. API Specification (HTTP)

Port **8710**, base path `/api/v1`. JSON in / JSON out.

### 5.1 `POST /api/v1/enqueue`

Submit new job.

**Request body:**
```json
{
  "submitted_by": "ct666",
  "priority": 1,
  "max_duration_sec": 14400,
  "gpu_requirements": {
    "min_vram_gb": 4,
    "preferred_gpu": null,
    "allow_fallback": true
  },
  "command": {
    "type": "command",
    "payload": "/usr/bin/gromacs-sim --input sim.tpr",
    "workdir": "/tmp/gpu_work/gromacs001",
    "env": {"OMP_NUM_THREADS": "4"}
  }
}
```

**Response (201):**
```json
{
  "success": true,
  "job_id": "gpu_job_20260920_001",
  "position_in_queue": 2,
  "estimated_wait_sec": 180
}
```

**Errors:** 400 (invalid schema), 401 (unknown submitter), 503 (all GPUs saturated + queue full).

### 5.2 `GET /api/v1/status`

Full system status.

**Response (200):**
```json
{
  "timestamp": "2026-09-20T14:30:00Z",
  "gpus": {
    "rtx5070": {
      "status": "idle|busy|offline",
      "current_job": null|"gpu_job_...",
      "util_pct": 0.0,
      "vram_total_gb": 16.0,
      "vram_used_gb": 0.4,
      "temperature_c": 42
    },
    "a5000": { "..." : "..." },
    "m3": { "..." : "..." }
  },
  "queue": {
    "pending": 5,
    "running": 2,
    "done_24h": 12,
    "estimated_wait_p1_sec": 0,
    "estimated_wait_p2_sec": 120,
    "estimated_wait_p3_sec": 900,
    "estimated_wait_p4_sec": 3600
  }
}
```

### 5.3 `GET /api/v1/job/<job_id>`

Job detail.

**Response (200):** Full job JSON as defined in section 4.4 (if done) or 4.1 (if pending/running).
**Error:** 404 (not found).

### 5.4 `DELETE /api/v1/job/<job_id>`

Cancel pending or running job (sigterm + sigkill for running).

**Response (200):** `{"success": true, "action": "cancelled"}`

### 5.5 `GET /api/v1/queue`

List pending jobs ordered by priority then FIFO.

**Response (200):**
```json
{
  "jobs": [
    {"job_id": "...", "priority": 1, "submitted_at": "...", "wait_sec": 0},
    {"job_id": "...", "priority": 2, "submitted_at": "...", "wait_sec": 45}
  ]
}
```

### 5.6 `POST /api/v1/release`

Explicitly release a GPU lock (for graceful shutdown).

**Request:** `{"gpu_id": "rtx5070"}`
**Response:** `{"success": true, "released": true}`

## 6. Scheduler Algorithm

### 6.1 Core Loop (pseudocode)

```
LOOP every 5 seconds:
  FOR each GPU in [rtx5070, a5000, m3]:
    status = poll_gpu(gpu)
    update_monitor(gpu, status)

    IF gpu is FREE:
      lock(gpu_id) exists AND get_lock(gpu_id).releases_at < now():
        remove_stale_lock(gpu_id)
      END

      best_job = find_best_job(gpu)
      IF best_job exists:
        assign_job_to_gpu(best_job, gpu)
        start_worker(best_job, gpu, max_duration)
      END
    END
  END

  # Housekeeping
  FOR each RUNNING job:
    IF job.duration > max_duration:
      kill_job(job, reason="timeout")
    END
    IF gpu_offline(job.assigned_gpu):
      kill_job(job, reason="gpu_lost")
      requeue(job, priority_boost=-1)
    END
  END
END
```

### 6.2 GPU Selection Logic

For a given job, select GPU by:

1. **Preferred GPU match** -- if `preferred_gpu` set and free, use it
2. **Min VRAM filter** -- exclude GPUs with < `min_vram_gb` free
3. **Priority tiebreaker** -- more free VRAM wins
4. **Proximity** -- local (rtx5070) > SSH (a5000) > Mac (m3)

### 6.3 Preemption

P3/P4 jobs running when a P1 job arrives:

1. Checkpoint? If job supports checkpoint signal (`SIGUSR1`), send it
2. Wait 30s grace period
3. Send `SIGTERM` -> wait 15s -> `SIGKILL`
4. Move job back to `pending/` with `preempted: true`
5. Assign P1 job to freed GPU

### 6.4 Heartbeat / Watchdog

Each running job thread sends heartbeat every 30s to its lock file.
Scheduler checks all locks every 60s. Stale lock (>120s without heartbeat) -> kill + requeue.

## 7. GPU Monitors

### 7.1 RTX 5070 Ti (Local via CT 901)

```bash
# Via Proxmox exec
pct exec 901 -- nvidia-smi --query-gpu=index,name,utilization.gpu,memory.total,memory.used,temperature.gpu,power.draw --format=csv,noheader,nounits
```

Poll interval: 5s (for status endpoint), 30s (for detailed metrics).

### 7.2 RTX A5000 (Remote via SSH)

```bash
ssh -i /home/gpuorchestrator/.ssh/id_rsa_gpu -o ConnectTimeout=10 jalejandre@pacifico5.izt.uam.mx \
  "ssh pacifico5 nvidia-smi --query-gpu=index,name,utilization.gpu,memory.total,memory.used,temperature.gpu,power.draw --format=csv,noheader,nounits"
```

SSH keypair pre-deployed. Connection retry: 3 attempts, 5s apart. Timeout status if unreachable.

### 7.3 Mac M3 (LAN via SSH)

```bash
ssh -i /home/gpuorchestrator/.ssh/id_rsa_m3 -o ConnectTimeout=5 gpuorchestrator@192.168.0.X \
  "system_profiler SPDisplaysDataType | head -40"
```

Fallback: `vm_stat` + `top -l 1 -n 0` for memory pressure when Metal GPU tools unavailable.

## 8. Deployment to CT 110

### 8.1 Create Container

```bash
# On Proxmox host (pve)
pct create 110 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname gpu-orch-ct110 \
  --cores 2 \
  --memory 2048 \
  --swap 512 \
  --rootfs local:8 \
  --net0 name=eth0,bridge=vmbr0,ip=192.168.0.110/24,gw=192.168.0.1 \
  --unprivileged 0 \
  --features nesting=1

pct start 110
pct exec 110 -- apt update && apt install -y python3 python3-pip python3-venv curl openssh-client
```

### 8.2 Service Setup

```bash
# Inside CT 110
useradd -r -s /bin/false gpuorchestrator
mkdir -p /opt/gpu-orchestrator /tmp/gpu_queue/{pending,running,done,locks}
mkdir -p /home/gpuorchestrator/.ssh

# Python deps
pip3 install flask gunicorn

# systemd service
cat > /etc/systemd/system/gpu-orchestrator.service << 'EOF'
[Unit]
Description=GPU Orchestrator Daemon
After=network.target

[Service]
User=gpuorchestrator
Group=gpuorchestrator
WorkingDirectory=/opt/gpu-orchestrator
ExecStart=/usr/bin/gunicorn -w 2 -b 0.0.0.0:8710 main:app
Restart=always
RestartSec=10
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now gpu-orchestrator
```

### 8.3 Provisioning From CT 666

```bash
# From orchestrator (CT 666)
scp /opt/gpu-orchestrator/main.py gpuorchestrator@192.168.0.110:/opt/gpu-orchestrator/
ssh gpuorchestrator@192.168.0.110 'sudo systemctl restart gpu-orchestrator'
```

## 9. Integration With Existing Systems

### 9.1 Compatibility With `gpu_multisite_reservation_system.py`

The existing system at `/root/.hermes/gpu_lock/gpu_multisite_reservation_system.py` manages
direct reservations via file locks. The GPU Orchestrator DOES NOT replace it -- instead:

- The orchestrator's lock files live in `/tmp/gpu_queue/locks/` (separate from `/tmp/gpu_lock/`)
- The orchestrator checks `/tmp/gpu_lock/*` as secondary source for GPU occupancy
- When the orchestrator is active, external scripts should use the orchestrator API instead of direct file locks
- A migration script `migrate_reservation.sh` can drain existing locks before transitioning

### 9.2 Client Library Snippet (for CT 666)

```python
#!/usr/bin/env python3
"""gpu_orchestrator_client.py -- Submit and monitor jobs from CT 666"""

import json, requests, time

ORCHESTRATOR_URL = "http://192.168.0.110:8710/api/v1"

def enqueue(priority=1, max_duration=14400, min_vram=4, command_str="",
            submitter="ct666", workdir="/tmp/gpu_work"):
    payload = {
        "submitted_by": submitter,
        "priority": priority,
        "max_duration_sec": max_duration,
        "gpu_requirements": {"min_vram_gb": min_vram, "allow_fallback": True},
        "command": {"type": "command", "payload": command_str, "workdir": workdir}
    }
    resp = requests.post(f"{ORCHESTRATOR_URL}/enqueue", json=payload, timeout=10)
    return resp.json()

def poll_until_done(job_id, interval=10):
    while True:
        resp = requests.get(f"{ORCHESTRATOR_URL}/job/{job_id}", timeout=10)
        data = resp.json()
        if data["status"] in ("completed", "failed", "timed_out", "cancelled"):
            return data
        time.sleep(interval)

def status():
    return requests.get(f"{ORCHESTRATOR_URL}/status", timeout=10).json()
```

## 10. Base Python Code Template

See companion files in the same directory:
- `GPU_ORCHESTRATOR_MAIN.py` -- Flask app + HTTP API handlers
- `GPU_ORCHESTRATOR_SCHEDULER.py` -- Priority scheduler logic
- `GPU_ORCHESTRATOR_MONITOR.py` -- 3 GPU monitor classes
- `GPU_ORCHESTRATOR_QUEUE.py` -- JSON file I/O, lock management
- `GPU_ORCHESTRATOR_WORKER.py` -- Job execution process wrapper

### 10.1 Target File Structure on CT 110

```
/opt/gpu-orchestrator/
|-- main.py              # Flask app + HTTP API handlers
|-- scheduler.py         # Priority scheduler logic
|-- gpu_monitor.py       # 3 GPU monitor classes
|-- queue_manager.py     # JSON file I/O, lock management
|-- worker_thread.py     # Job execution process wrapper
|-- config.py            # Constants, GPU specs, paths
```

## 11. Security

- API listens on CT 110 only (192.168.0.110:8710), not exposed to WAN
- No auth on API (internal Proxmox network only)
- SSH keys for remote GPUs are the only credentials stored
- Commands run as `gpuorchestrator` (unprivileged, restricted via systemd)
- Jobs run in cgroup with `MemoryMax=1.5G` and `CPUQuota=100%`
- Commands are logged but truncated at 4KB to prevent log injection

## 12. Monitoring & Alerting

### 12.1 Endpoint Health

```bash
# ntfy alert on crash (via systemd OnFailure)
systemctl add-wants gpu-orchestrator.service ntfy-onfailure@.service
```

### 12.2 Metrics Log (JSONL)

```
/var/log/gpu-orchestrator/metrics.jsonl
{"ts":"2026-09-20T14:30:00Z","event":"job_submit","job_id":"...","priority":1}
{"ts":"2026-09-20T14:30:05Z","event":"job_start","job_id":"...","gpu":"rtx5070"}
{"ts":"2026-09-20T15:12:33Z","event":"job_done","job_id":"...","duration":2548,"exit":0}
```

### 12.3 Prometheus / Grafana (Future)

Expose `/metrics` endpoint with:
- `gpu_orchestrator_jobs_submitted_total{priority="1"} 42`
- `gpu_orchestrator_jobs_running{} 2`
- `gpu_orchestrator_gpu_utilization{gpu="rtx5070"} 87.3`
- `gpu_orchestrator_queue_wait_seconds{priority="3"} 900`

## 13. Change Log

| Date | Version | Change |
|------|---------|--------|
| 2026-09-20 | 1.0 | Initial specification -- GPU Orchestrator worker |

## 14. References

- Existing: `/root/.hermes/gpu_lock/gpu_multisite_reservation_system.py`
- Existing: `/root/JarvisVault/00_AR/CURRENT_TOPOLOGY.md`
- GPU specs: RTX 5070 Ti 16GB GDDR7, RTX A5000 24GB GDDR6, Apple M3 (integrated)
- Proxmox API: `mcp__proxmox__*` tools
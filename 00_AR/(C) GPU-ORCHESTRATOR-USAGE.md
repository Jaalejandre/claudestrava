# (C) GPU Orchestrator — Usage Guide

**Source:** `00_AR/(C) GPU-ORCHESTRATOR-USAGE.md`
**Based on:** `00_AR/GPU_ORCHESTRATOR_*.py` + `00_AR/GPU_ORCHESTRATOR_SPEC.md`
**Last updated:** 2026-09-20

---

## 1. Overview

The GPU Orchestrator is a self-contained job scheduler for 3 distributed GPUs.
Corre en **CT 110** (192.168.0.110) y expone API HTTP en puerto **8710**.

**Agentes involucrados:** scheduler, worker, queue manager, monitor, API server.

---

## 2. Componentes

### `GPU_ORCHESTRATOR_CONFIG.py`
Constantes, rutas, specs de GPU, prioridades, tiempos de espera.

| Prioridad | Label | Max wait | Preemptible |
|-----------|-------|----------|-------------|
| 1 | CRITICAL | 0s | No |
| 2 | HIGH | 300s | No |
| 3 | NORMAL | 1800s | Sí |
| 4 | LOW | 7200s | Sí |

GPUs definidas: `rtx5070` (CT 901 local), `a5000` (pacifico5 SSH), `m3` (Mac Apple M3).

### `GPU_ORCHESTRATOR_QUEUE.py`
Manejo de cola basado en archivos JSON:

| Directorio | Estado |
|-----------|--------|
| `/tmp/gpu_queue/pending/` | Jobs esperando |
| `/tmp/gpu_queue/running/` | Jobs en ejecución |
| `/tmp/gpu_queue/done/` | Jobs completados |
| `/tmp/gpu_queue/locks/` | GPU locks |

Funciones: `write_job`, `read_job`, `list_pending/running/done`, `delete_job`,
`acquire_lock`, `release_lock`, `is_gpu_free`, `stale_locks`, `heartbeat_lock`.

### `GPU_ORCHESTRATOR_SCHEDULER.py`
Loop principal (cada 5s, configurable vía `SCHEDULER_INTERVAL_SEC`):
1. Lista jobs pendientes ordenados por prioridad
2. Consulta estado de GPUs via `poll_all()`
3. Selecciona GPU óptima para cada job (preferencia + VRAM + disponibilidad)
4. Mueve job a RUNNING_DIR, adquiere lock, lanza worker thread
5. Housekeeping: limpia locks stale, re-enqueue jobs fallidos

GPU selection logic (`select_gpu()`):
- Respeta `preferred_gpu` del job si está libre
- Fallback a otras GPUs si `allow_fallback=True`
- Verifica `min_vram_gb` antes de asignar

### `GPU_ORCHESTRATOR_WORKER.py`
Thread que ejecuta un job como subprocess:
- Setea `CUDA_VISIBLE_DEVICES=0`
- Timeout configurable (`max_duration_sec`, default 4h)
- Heartbeat cada 30s para detectar jobs colgados
- Captura stdout/stderr a archivo en `WORK_DIR/<job_id>/`
- Exit code, output y métricas se guardan en el JSON de resultado

### `GPU_ORCHESTRATOR_MONITOR.py`
Polling de GPUs:
- `poll_all()` → estado de las 3 GPUs
- `poll_one(gpu_id)` → GPU específica
- Usa `nvidia-smi` para GPUs NVIDIA, `system_profiler` para Mac M3
- Via `pct exec 901` para RTX 5070 Ti, `ssh` para A5000

### `GPU_ORCHESTRATOR_MAIN.py`
Entry point. Flask HTTP API:

| Endpoint | Method | Descripción |
|----------|--------|-------------|
| `/api/v1/enqueue` | POST | Someter job |
| `/api/v1/status` | GET | Estado de GPUs y cola |
| `/api/v1/status/<gpu_id>` | GET | Estado de GPU específica |
| `/api/v1/jobs/pending` | GET | Jobs pendientes |
| `/api/v1/jobs/running` | GET | Jobs en ejecución |
| `/api/v1/jobs/done` | GET | Jobs completados |
| `/api/v1/jobs/<job_id>` | GET | Detalle de job |
| `/api/v1/jobs/<job_id>` | DELETE | Cancelar job |
| `/api/v1/health` | GET | Health check |

Arranca scheduler thread al inicio + API server Flask.

---

## 3. Cómo lanzar un job

### Via API (recomendado)

```bash
# Someter job de Gromacs en RTX 5070 Ti (prioridad NORMAL)
curl -X POST http://192.168.0.110:8710/api/v1/enqueue \
  -H "Content-Type: application/json" \
  -d '{
    "command": {
      "payload": "cd /root/phase4_cuda_pinned && ./gromacs_sim --input ref_run/conf.gro --steps 1000000",
      "workdir": "/root/phase4_cuda_pinned",
      "env": {"OMP_NUM_THREADS": "4"}
    },
    "priority": 3,
    "max_duration_sec": 14400,
    "gpu_requirements": {
      "preferred_gpu": "rtx5070",
      "min_vram_gb": 8,
      "allow_fallback": true
    },
    "metadata": {
      "team": "cientificos",
      "task": "gromacs-npt-1M",
      "worker": "daemon"
    }
  }'
```

Response:
```json
{"success": true, "job_id": "GPU_20260920_a1b2c3", "position": 1}
```

### Ver estado
```bash
curl -s http://192.168.0.110:8710/api/v1/status | python3 -m json.tool
```

### Ver jobs pendientes
```bash
curl -s http://192.168.0.110:8710/api/v1/jobs/pending | python3 -m json.tool
```

### Cancelar job
```bash
curl -X DELETE http://192.168.0.110:8710/api/v1/jobs/GPU_20260920_a1b2c3
```

---

## 4. Cómo conectar al log central

El orchestrator escribe métricas a `/var/log/gpu-orchestrator/metrics.jsonl`.
Para integrar con el log central del vault:

### Opción A: Script de sync periódico (recomendado)

```bash
# Desde CT 109 o CT 666
ssh root@192.168.0.52 "pct exec 110 -- cat /var/log/gpu-orchestrator/metrics.jsonl" \
  >> /root/JarvisVault/00_System/logs/gpu-orch-$(date +%Y-%m-%d).jsonl
```

### Opción B: Webhook post-job (desde el worker)

Cada `GPU_ORCHESTRATOR_WORKER.py` puede hacer curl al vault al terminar un job.
Ejemplo de entry que escribe manualmente:

```bash
log='{"ts":"'$(date -Iseconds)'","team":"cientificos","task":"orch-job","worker_id":"orchestrator","status":"done","duration_s":3600,"gpu_used":"rtx5070","result":"GPU_20260920_a1b2c3 completado, energia -3.214e4 kJ/mol"}'
echo "$log" >> /root/JarvisVault/00_System/logs/$(date +%Y-%m-%d).jsonl
```

### Opción C: Notificación ntfy

```bash
curl -H "Title: GPU Job Complete" \
     -H "Priority: default" \
     -d "GPU_20260920_a1b2c3 terminado en rtx5070" \
     https://ntfy.sh/satanzote-alerts
```

---

## 5. Job JSON format

```json
{
  "job_id": "GPU_20260920_a1b2c3",
  "status": "pending|running|done|failed|cancelled",
  "command": {
    "payload": "comando a ejecutar",
    "workdir": "/path/opcional",
    "env": {"VAR": "value"}
  },
  "priority": 3,
  "max_duration_sec": 14400,
  "gpu_requirements": {
    "preferred_gpu": "rtx5070",
    "min_vram_gb": 8,
    "allow_fallback": true
  },
  "metadata": {
    "team": "cientificos",
    "task": "descripción",
    "worker": "daemon|e41|hermes"
  },
  "created_at": "2026-09-20T12:00:00Z",
  "started_at": null,
  "completed_at": null,
  "result": {
    "exit_code": 0,
    "stdout_path": "/tmp/gpu_work/GPU_20260920_a1b2c3/stdout.log",
    "stderr_path": "/tmp/gpu_work/GPU_20260920_a1b2c3/stderr.log",
    "output": "resumen corto",
    "gpu_metrics": {"util_pct": 95, "vram_used_gb": 12}
  }
}
```

---

## 6. Troubleshooting

| Problema | Causa | Solución |
|----------|-------|----------|
| Orchestrator no responde | CT 110 caído | `pct start 110` en Proxmox |
| Job queda en pending forever | GPU ocupada o sin GPUs libres | Verificar con `poll_all()`, liberar locks stale |
| `stale_locks` detectados | Worker murió sin cleanup | Scheduler los limpia automáticamente |
| GPU offline en status | SSH falla a pacifico5 | Verificar VPN UAM, timeout config |
| Job falla con exit_code != 0 | Error en payload | Revisar stdout/stderr en WORK_DIR |

---

## Referencias
- SPEC técnica: `00_AR/GPU_ORCHESTRATOR_SPEC.md`
- SWARM protocol: `00_AR/SWARM_PROTOCOL.md`
- GPU reservation: `00_Infra/(C) GPU-RESERVATION-PROTOCOL.md`
- SOUL equipo: `02_Teams/Cientificos-SOUL.md`
- Log central: `00_System/logs/`
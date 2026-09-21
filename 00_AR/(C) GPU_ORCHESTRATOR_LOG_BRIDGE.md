# (C) GPU Orchestrator → Log Central Bridge

> Documenta cómo conectar la salida del GPU Orchestrator (CT 110:8710)
> al log central de SatanZote (`/root/JarvisVault/00_System/logs/`).
> Creado: 2026-09-20

## Estado del Orchestrator

El GPU Orchestrator vive en **CT 110** (192.168.0.110), NO en CT 109 ni CT 666.
Puerto: **8710**, prefijo API: `/api/v1`.

**⚠️ Nota:** El orchestrator está definido en los archivos Python de `00_AR/` pero
su deploy real en CT 110 no está verificado. Verificar antes de usar:

```bash
curl -s http://192.168.0.110:8710/api/v1/health | jq .
```

## Endpoints de la API

| Endpoint | Método | Descripción |
|----------|--------|-------------|
| `/api/v1/health` | GET | Health check del servicio |
| `/api/v1/enqueue` | POST | Encolar un trabajo GPU |
| `/api/v1/status` | GET | Status general del sistema |
| `/api/v1/job/<job_id>` | GET | Estado de un trabajo específico |
| `/api/v1/job/<job_id>` | DELETE | Cancelar un trabajo |
| `/api/v1/queue` | GET | Lista de trabajos en cola |
| `/api/v1/release` | POST | Liberar GPU |

## Bridge: Conectar al Log Central

### Estrategia

Cada vez que el orchestrator completa, falla o encola un trabajo, el worker
(o el scheduler) debe escribir al log central.

### Formato de log esperado

```json
{
  "ts": "2026-09-20T19:00:00-06:00",
  "team": "ai-agentes",
  "task": "swarm-gpu",
  "worker_id": "gpu-orchestrator",
  "status": "done",
  "duration_s": 3600,
  "gpu_used": "rtx5070",
  "result": "Gromacs NPT sim 100ns completada. Energy drift: 0.03%"
}
```

### Script de bridge

Crear en CT 110 (o CT 666 como proxy):

```bash
#!/usr/bin/env bash
# (C) gpu-log-bridge.sh — Postea resultados del orchestrator al log central
# Uso: gpu-log-bridge.sh <job_id> <status> <duration_s> <gpu_id> <result_msg>

ORCHESTRATOR="http://192.168.0.110:8710/api/v1"
LOG_FILE="/root/JarvisVault/00_System/logs/$(date +%Y-%m-%d).jsonl"
JOB_ID="${1:-unknown}"
STATUS="${2:-done}"
DURATION="${3:-0}"
GPU="${4:-none}"
RESULT="${5:-no result}"

# Escapar comillas para JSON
RESULT_ESC=$(echo "$RESULT" | sed 's/"/\\"/g')

ENTRY=$(cat <<EOF
{"ts":"$(date -Iseconds)","team":"ai-agentes","task":"swarm-gpu","worker_id":"gpu-orchestrator","status":"$STATUS","duration_s":$DURATION,"gpu_used":"$GPU","result":"$RESULT_ESC"}
EOF
)

echo "$ENTRY" >> "$LOG_FILE"
echo "Logged: $ENTRY"
```

### Trigger desde el orchestrator

Opción A: **Post-job hook** en `GPU_ORCHESTRATOR_WORKER.py`:
```python
# Al final de run_job():
import subprocess, json
log_entry = {
    "ts": datetime.now().astimezone().isoformat(),
    "team": "ai-agentes",
    "task": "swarm-gpu",
    "worker_id": "gpu-orchestrator",
    "status": "done" if success else "failed",
    "duration_s": int(time.time() - start_time),
    "gpu_used": gpu_id,
    "result": result_summary
}
log_path = f"/root/JarvisVault/00_System/logs/{datetime.now():%Y-%m-%d}.jsonl"
with open(log_path, "a") as f:
    f.write(json.dumps(log_entry) + "\n")
```

Opción B: **Wrapper externo** (cron/systemd timer):
```bash
# Cada 5 min, consultar estado y loguear
curl -s http://192.168.0.110:8710/api/v1/status | python3 -c "
import json, sys
data = json.load(sys.stdin)
# Extraer trabajos en done
for job in data.get('jobs', []):
    if job['status'] == 'done' and not job.get('logged', False):
        print(json.dumps({
            'ts': job.get('completed_at', ''),
            'team': 'ai-agentes',
            'task': 'swarm-gpu',
            'worker_id': 'gpu-orchestrator',
            'status': 'done',
            'duration_s': job.get('duration_s', 0),
            'gpu_used': job.get('gpu_id', 'unknown'),
            'result': job.get('result', '')
        }))
" >> /root/JarvisVault/00_System/logs/$(date +%Y-%m-%d).jsonl
```

### Ejemplos curl

```bash
# Health check
curl -s http://192.168.0.110:8710/api/v1/health

# Encolar trabajo Gromacs
curl -s -X POST http://192.168.0.110:8710/api/v1/enqueue \
  -H "Content-Type: application/json" \
  -d '{"gpu":"rtx5070","cmd":"gmx_mpi mdrun -s topol.tpr -v","priority":2,"max_duration_s":14400}'

# Ver cola
curl -s http://192.168.0.110:8710/api/v1/queue | jq .

# Loggear resultado manual
curl -s http://192.168.0.110:8710/api/v1/job/<JOB_ID> | python3 -c "
import json,sys
j=json.load(sys.stdin)
e={'ts':j.get('completed_at'),'team':'ai-agentes','task':'swarm-gpu',
   'worker_id':'gpu-orchestrator','status':j.get('status'),
   'duration_s':j.get('duration_s',0),'gpu_used':j.get('gpu_id','none'),
   'result':j.get('result','')}
with open('/root/JarvisVault/00_System/logs/'+e['ts'][:10]+'.jsonl','a') as f:
    f.write(json.dumps(e)+'\n')
print('Logged:', e['ts'], e['status'])
"
```

## Integración con Swarm

Cuando un swarm GPU se ejecuta:

1. Swarm envía trabajos al orchestrator via `/api/v1/enqueue`
2. Orchestrator ejecuta en la GPU asignada
3. **Al completar**, worker escribe al log central (Opción A)
4. OmniMind puede consultar resultados via skill `log-query`

## Verificación

```bash
# 1. Orchestrator está vivo?
curl -s http://192.168.0.110:8710/api/v1/health

# 2. Logs de GPU existen?
grep '"gpu_used":"rtx5070"' /root/JarvisVault/00_System/logs/$(date +%Y-%m-%d).jsonl

# 3. Bridge funciona?
bash /root/JarvisVault/00_AR/scripts/gpu-log-bridge.sh "test-001" "done" 30 "rtx5070" "test OK"
tail -1 /root/JarvisVault/00_System/logs/$(date +%Y-%m-%d).jsonl | jq .
```
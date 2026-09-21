# (C) GPU Reservation Protocol
**Source:** `00_Infra/(C) GPU-RESERVATION-PROTOCOL.md`
**Derived from:** `gpu-reservation-protocol` skill (`/root/.hermes/skills/gpu-reservation-protocol/SKILL.md`)
**Last updated:** 2026-09-20

---

## 1. GPU Inventory

| ID | Name | VRAM | Location | Access |
|----|------|------|----------|--------|
| `rtx5070` | RTX 5070 Ti | 16 GB | CT 901 (192.168.0.230) | `pct exec 901 -- nvidia-smi` |
| `a5000` | RTX A5000 | 24 GB | pacifico5.izt.uam.mx | SSH key + tunnel |
| `m3` | Apple M3 (GPU) | Shared/18 GB | MacBook (LAN) | SSH macOS |

---

## 2. Verificar disponibilidad

### GPU local (RTX 5070 Ti, CT 901)
```bash
# Desde Proxmox host
pct exec 901 -- nvidia-smi --query-compute-apps=pid,name --format=csv

# Quién está usando el contenedor
pct exec 901 -- who
pct exec 901 -- ps aux | grep -E "(gromacs|mdrun|python.*sim)"

# Desde CT 109 (claude-dev) — proxy via Proxmox
ssh root@192.168.0.52 "pct exec 901 -- nvidia-smi --query-gpu=index,name,utilization.gpu,memory.total,memory.used,temperature.gpu --format=csv,noheader,nounits"
```

### GPU remota (RTX A5000, pacifico5)
```bash
ssh jalejandre@pacifico5.izt.uam.mx "nvidia-smi --query-compute-apps=pid,name --format=csv"
ssh jalejandre@pacifico5.izt.uam.mx "who"
```

### GPU Orchestrator status
```bash
# Si el orchestrator corre en CT 110
curl -s http://192.168.0.110:8710/api/v1/status | python3 -m json.tool

# O via Proxmox
ssh root@192.168.0.52 "pct exec 110 -- curl -s http://localhost:8710/api/v1/status"
```

---

## 3. Reservar GPU (Lock File Mechanism)

### Lock file structure (`/tmp/gpu_lock/`)
```
/tmp/gpu_lock/
├── OWNER         # SATANZOTE_<profile> | UAM-I
├── TIMESTAMP     # epoch seconds cuando se tomó
├── DURATION      # segundos estimados
└── RELEASE_TIME  # epoch seconds de liberación automática
```

### Adquirir lock
```bash
acquire_gpu_lock() {
    local profile=$1
    local duration=${2:-3600}  # default 1 hora
    local release=$(( $(date +%s) + duration ))
    
    mkdir -p /tmp/gpu_lock
    echo "SATANZOTE_$profile" > /tmp/gpu_lock/OWNER
    date +%s > /tmp/gpu_lock/TIMESTAMP
    echo "$duration" > /tmp/gpu_lock/DURATION
    echo "$release" > /tmp/gpu_lock/RELEASE_TIME
    
    echo "[GPU] Lock acquired for $profile (${duration}s)"
}
```

### Liberar lock
```bash
release_gpu_lock() {
    rm -f /tmp/gpu_lock/{OWNER,TIMESTAMP,DURATION,RELEASE_TIME}
    echo "[GPU] Lock released"
}
```

### Verificar si GPU está libre
```bash
check_gpu_free() {
    if [ -f /tmp/gpu_lock/OWNER ]; then
        owner=$(cat /tmp/gpu_lock/OWNER)
        release=$(cat /tmp/gpu_lock/RELEASE_TIME 2>/dev/null)
        now=$(date +%s)
        if [ "$now" -lt "${release:-0}" ]; then
            echo "GPU LOCKED by $owner until $(date -d @$release)"
            return 1
        fi
        # Lock expirado — cleanup
        release_gpu_lock
    fi
    echo "GPU FREE"
    return 0
}
```

### GPU lock wrapper (`/usr/local/bin/gpu-lock`)
```bash
# Usage: gpu-lock <cmd>
gpu-lock pct exec 901 -- ./gromacs_sim
```

---

## 4. Loggear uso de GPU al central

Cada vez que se usa GPU, escribir entry en `00_System/logs/<fecha>.jsonl`:

```json
{
  "ts": "2026-09-20T12:00:00-06:00",
  "team": "cientificos",
  "task": "gpu-reserve",
  "worker_id": "daemon|e41|hermes",
  "status": "started|done|failed",
  "duration_s": 3600,
  "gpu_used": "rtx5070|a5000",
  "gpu_vram_gb": 16,
  "result": "descripción breve"
}
```

Caso de uso:
```bash
log_entry='{"ts":"'"$(date -Iseconds)"'","team":"cientificos","task":"gromacs-sim","worker_id":"e41","status":"started","duration_s":86400,"gpu_used":"rtx5070","result":"NPT simulation de 10M pasos, referencia kwald"}'
echo "$log_entry" >> /root/JarvisVault/00_System/logs/$(date +%Y-%m-%d).jsonl
```

---

## 5. GPU Orchestrator Queue (CT 110)

Si el GPU Orchestrator corre, los jobs se someten vía API:

```bash
curl -X POST http://192.168.0.110:8710/api/v1/enqueue \
  -H "Content-Type: application/json" \
  -d '{
    "command": {"payload": "pct exec 901 -- ./gromacs_sim"},
    "priority": 3,
    "gpu_requirements": {"preferred_gpu": "rtx5070", "min_vram_gb": 8}
  }'
```

Ver estado:
```bash
curl -s http://192.168.0.110:8710/api/v1/status | python3 -m json.tool
```

---

## 6. Conflictos y resolución

| Síntoma | Causa probable | Acción |
|---------|---------------|--------|
| `nvidia-smi` muestra proceso PID desconocido | Lock stale | `release_gpu_lock` + matar proceso zombie |
| Lock expirado pero GPU ocupada | UAM-I usando directo | Coordinar vía ntfy/Slack, no matar procesos ajenos |
| Orchestrator no responde | CT 110 caído | `pct start 110` en Proxmox, verificar systemd timer |
| SSH a pacifico5 falla | VPN/red UAM caída | Esperar, usar RTX 5070 Ti como fallback |

---

## Referencias
- Skill: `gpu-reservation-protocol`
- Orchestrator: `00_AR/GPU_ORCHESTRATOR_*.py`
- Config: `00_AR/GPU_ORCHESTRATOR_CONFIG.py`
- Logs: `00_System/logs/`
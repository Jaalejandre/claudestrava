# TOPOLOGÍA FINAL DE INFRAESTRUCTURA DEDICADA ESTABLE
**Fecha:** 2026-09-20  
**Valida hasta:** Próximo cambio de hardware  
**SSOT:** Este documento. Cualquier discrepancia con configs anteriores — este gana.

---

## 1. RECURSOS DEL HOST (pve, 192.168.0.52)

| Recurso | Valor |
|---|---|
| CPU | Intel i5-14600K (6P+8E → 20 threads) |
| RAM | 31 GiB total, ~10-13 GiB usado base (sin builds) |
| GPU local | RTX 5070 Ti 16GB VRAM (compute 9.0) — única GPU CUDA real |
| LVM-thin (pve-data) | 794 GiB total, 514 GiB libre |
| NVMe rápido | 238 GiB en /mnt/nvme-fast (discos efímeros, colas) |
| Backups | 3.6 TB en /mnt/backups |
| Media | 3.6 TB en /mnt/media |
| Storage | 3.6 TB en /mnt/storage |

**Regla de oro:** RAM host 31GB, suma RAM asignada 64GB (2x overcommit). Las máquinas activas consumen ~10-13GB real. No añadir más RAM asignada sin eliminar primero.

---

## 2. TOPOLOGÍA DEFINITIVA — TABLA DE RECURSOS

### Núcleo (siempre activo, crítico)

| CT | Hostname | Rol | IP | vCPU | RAM | Disco | GPU | Swap | Notas |
|---|---|---|---|---|---|---|---|---|---|
| 666 | satanzote | **Orquestador Central + Hermes + OmniRoute** | .104 | 8 (de 16) | 16GB | 116GB | No* | 4GB | El cerebro. OmniRoute migrado aquí desde CT 109. |
| 110 | gpu-orch | **GPU Orchestrator** (NUEVO) | .110 | 2 | 2GB | 8GB | Sí (monitoreo) | 512MB | Ve las 3 GPUs, gestiona cola/reserva |
| 901 | ct901 | **GPU Compute Worker (Gromacs)** | .230 | 4 (de 12) | 4GB | 100GB | Sí (compute) | 2GB | Único que ejecuta CUDA compute pesado |
| 118 | bibliotecacentral | **SSOT Vault / Git** | .146 | 2 | 4GB | 16GB | No | 512MB | Vault central, documentación |

### Servicios de Red (siempre activos)

| CT | Hostname | Rol | IP | vCPU | RAM | Disco | Notas |
|---|---|---|---|---|---|---|---|
| 100 | nginxproxymanager | Reverse Proxy | .109 | 1 | 2GB | 8G | Público, TLS |
| 104 | adguard | DNS Ad-blocker | .10 | 1 | 512MB | 5G | Primario |
| 105 | unbound | DNS Resolver | .11 | 1 | 512MB | 2G | Recursivo |
| 108 | cloudflared | Cloudflare Tunnel | .12 | 1 | 512MB | 2G | Túneles Argo |
| 107 | docker | Docker host (legacy) | .61 | 2 | 2GB | 16G | Contenedores varios |
| 114 | vaultwarden | Password Manager | .30 | 2 | 2GB | 20G | Bitwarden self-hosted |

### Datos / Conocimiento

| CT | Hostname | Rol | IP | vCPU | RAM | Disco | Notas |
|---|---|---|---|---|---|---|---|
| 103 | openviking | **RAG / Memoria Larga** | .66 | 4 | 8GB | 32GB | OpenViking. Modelos CPU-only |
| 115 | debmediav2 | Media Server | .164 | 4 | 2GB | 60G | Contenido multimedia |

### Apps (bajo demanda)

| CT | Hostname | Rol | IP | vCPU | RAM | Disco |
|---|---|---|---|---|---|---|
| 111 | apps-prod | Producción | .20 | 4 | 4GB | 40G |
| 112 | app-dev | Desarrollo | .21 | 2 | 2GB | 20G |
| 117 | difybot | Dify / Chatbot | .14 | 2 | 4GB | 20G |

### Monitoreo

| CT | Hostname | Rol | IP | vCPU | RAM | Disco |
|---|---|---|---|---|---|---|
| 101 | hermesagent | Hermes secundario | DHCP | 2 | 4GB | 20G |
| 102 | uptimekuma | Uptime Monitor | DHCP | 1 | 1GB | 4G |

### Contenedor Legacy (programado para deprecar)

| CT | Hostname | Rol | Destino | vCPU | RAM | Disco | GPU |
|---|---|---|---|---|---|---|---|
| 109 | claude-dev | **DEPRECAR** | OmniRoute→666, prototipos→666 | 8 | 8GB | 60G | Sí (se retira) |

---

## 3. DESTINO DE CT 109 (claude-dev)

**Decisión: DEPRECAR — eliminar tras migrar.**

Servicios activos en CT 109 y su destino:

| Servicio | Puerto | Acción | Destino |
|---|---|---|---|
| OmniRoute | 20128 | Migrar a CT 666 | CT 666 (ya tiene Hermes, skills, cron) |
| proxmox-mcp | 8000 | Migrar a CT 666 o CT 110 | CT 666 para control infra |
| Prototipos web (uvicorn) | 8877 | Migrar a CT 666 | CT 666 como dev playground |
| Bifrost VPN | 8080 | Evaluar si es necesario | Si sí → CT 666 |
| Vault (JarvisVault) | — | Ya hay copia en CT 666 | Verificar sync |
| Gromacs dev artifacts | — | Archivar o migrar a 901 | No crítico |
| Evaluaciones de herramientas | — | Archivar o descartar | No crítico |

**Por qué eliminar y no reusar:**  
- Libera 8GB RAM + 8 vCPU + 60GB disco. El host está a 31GB RAM — 8GB es una fracción significativa.  
- No hay necesidad de otro contenedor: CT 666 + CT 110 cubren todos los roles.  
- Si en futuro se necesita un sandbox limpio, se clona desde plantilla.

---

## 4. GPU ORCHESTRATOR (CT 110 nuevo)

### 4.1 Recursos

| Recurso | Asignación | Justificación |
|---|---|---|
| vCPU | 2 (1 core físico) | Solo monitoreo y scheduling — sin compute |
| RAM | 2 GB | Suficiente para Python scheduler + SSH pool |
| Disco | 8 GB | Solo el script + logs |
| GPU | Bind-mount NVIDIA (solo nvidia-smi) | Para monitorear ocupación, temperatura, procesos |
| Swap | 512 MB | Prevención |
| IP | 192.168.0.110 | Estática |

### 4.2 Qué GPUs ve

| GPU | Tipo | Conexión | VRAM | Propósito |
|---|---|---|---|---|
| RTX 5070 Ti | CUDA (compute 9.0) | Bind-mount local en CT 110 | 16 GB | Compute principal (Gromacs) |
| RTX A5000 | CUDA (compute 8.6) | SSH → pacifico5 (UAM) | 24 GB | Overflow / modelos grandes |
| Mac M3 | Metal (NO CUDA) | SSH → MacBook Pro | 16-24 GB unif. | Inferencia local (llama.cpp/Ollama) |

### 4.3 Worker propio (zero dependencies externas)

Un solo script Python (`/opt/gpu-orch/gpu_orchestrator.py`) con:

**Componentes:**
1. **Monitor** — polling cada 5s a las 3 GPUs (nvidia-smi local + SSH remoto)
2. **Queue manager** — FIFO en disco (`/opt/gpu-orch/queue/`) con archivos JSON:
   - `job_NNNN.request` → solicitud
   - `job_NNNN.status` → pending|running|done|failed
   - `job_NNNN.result` → output
3. **Scheduler** — round-robin entre GPUs disponibles, con prioridad (Gromacs > inference)
4. **Lock** — archivo `/tmp/gpu_queues/local.lock` y `/tmp/gpu_queues/remote.lock`

**Protocolo de comunicación:**  
- Workers (CT 901, pacifico5, Mac) depositan `.request` via SSH SCP o NFS  
- Orchestrator lee, programa, y actualiza `.status`  
- Worker polling: cada 2s revisa su `.status`  
- Sin Redis, sin K8s, sin Slurm — archivos + SSH

### 4.4 Flujo

```
CT 666 (Hermes)
  │  solicita "correr Gromacs en GPU"
  ▼
CT 110 (GPU Orchestrator)
  │  chequea estado global de GPUs
  │  escribe job_001.request → /opt/gpu-orch/queue/
  │  asigna a GPU más libre (local > remoto)
  ▼
CT 901 (GPU Worker)
  │  detecta job_001.status = "assigned:901"
  │  adquiere lock local
  │  ejecuta Gromacs con GPU
  │  libera lock
  │  escribe job_001.status = "done"
  ▼
CT 110 (GPU Orchestrator)
  │  detecta "done"
  │  notifica a CT 666 (ntfy o archivo)
  ▼
CT 666 (Hermes) recibe resultado
```

---

## 5. MODELO DE SERVIDOR LOCAL ÓPTIMO

**Decisión: Ollama en CT 901 (GPU Worker)**

| Alternativa | Veredicto | Razón |
|---|---|---|
| **Ollama** | ✅ **GANADOR** | Binario único, GPU offloading nativo, multi-modelo, ya probado |
| vLLM | ❌ | Pensado para serving concurrente, no para cola compartida con Gromacs |
| llama.cpp server | ⚠️ Posible en Mac | Backend para Mac M3 (Metal), pero menos maduro como server |
| TGI (HuggingFace) | ❌ | Demasiado pesado, dependencias Python complejas |

### Estrategia de modelos

| Modelo | Tamaño (cuantizado) | GPU destino | Contexto de uso |
|---|---|---|---|
| qwen2.5-coder:14b | ~8-9 GB (Q4_K_M) | RTX 5070 Ti (16GB) | Asistente de código local |
| gemma3:12b | ~7-8 GB (Q4_K_M) | RTX 5070 Ti (16GB) | Razonamiento general |
| Ambos simultaneously | ❌ No caben | — | Se intercambian vía Ollama |
| Modelos >16GB | — | RTX A5000 (24GB) o CPU-offload | Overflow |

**Regla:** Como la VRAM es 16GB y se comparte con Gromacs, los modelos se cargan SOLO cuando la GPU está libre de compute. El GPU Orchestrator garantiza que Gromacs y Ollama no corran simultáneamente en la misma GPU.

**Caso Mac M3:** Ejecuta su propia instancia Ollama con backend Metal para inferencia ligera cuando la RTX 5070 Ti está ocupada.

---

## 6. PROTOCOLO DE COLA/RESERVA DE GPU

### 6.1 Filosofía

- **SWARM-FIRST**: si un trabajo puede paralelizarse en >1 GPU, se divide
- **GPU principal**: RTX 5070 Ti para compute (Gromacs) — prioridad 1
- **GPU secundaria**: RTX A5000 para modelos grandes — prioridad 2
- **GPU terciaria**: Mac M3 para inferencia ligera — prioridad 3
- **Sin monopolio**: time-slice máximo 4h por job, luego se re-evalúa

### 6.2 Estados de cada GPU

```
FREE → RESERVED → BUSY → RELEASING → FREE
```

### 6.3 Archivos de lock

```
/opt/gpu-orch/state/
├── local_gpu.state      # JSON: {owner, pid, since, estimated_end, job_id}
├── a5000_gpu.state      # mismo formato (vía SSH)
├── mac_gpu.state        # mismo formato (vía SSH)
├── queue/               # jobs pendientes
│   ├── next_id
│   ├── job_0001.req
│   └── job_0001.status
├── gpu_orchestrator.log
└── gpu_orchestrator.py   # el worker propio
```

### 6.4 Prioridades

| Prioridad | Tipo de trabajo | Tiempo máximo |
|---|---|---|
| P1 | Gromacs compute (GPU-bound) | 4h |
| P2 | Inferencia batch (evaluación) | 30min |
| P3 | Model training ligero | 2h |
| P4 | Inferencia interactiva (Chat) | 10min |

---

## 7. INTERCAMBIABILIDAD ENTRE GPUs

| Característica | RTX 5070 Ti (local) | RTX A5000 (pacifico5) | Mac M3 (local) |
|---|---|---|---|
| CUDA | ✅ Sí (compute 9.0) | ✅ Sí (compute 8.6) | ❌ NO (Metal) |
| VRAM | 16 GB | 24 GB | 16-24 GB unificada |
| Latencia | 0 (local) | ~2-5ms (LAN UAM) | 0 (local) |
| Velocidad relativa | 1.0x (base) | ~0.7x (generación anterior) | ~0.3x (inferencia) |
| Gromacs CUDA | ✅ | ✅ (con cross-compile) | ❌ Imposible |
| LLM inference | ✅ (Ollama) | ✅ (Ollama/vLLM) | ✅ (Ollama Metal) |
| Uso primario | Compute Gromacs | Overflow / modelos grandes | Fallback inference |

**NO son intercambiables 1:1.** Cada GPU tiene un rol distinto. El orquestador elige según:
1. ¿Es CUDA compute? → Solo RTX 5070 Ti o A5000
2. ¿Es inferencia? → Cualquiera, según disponibilidad
3. ¿Cabe en VRAM? → Si el modelo >16GB → forzar A5000

---

## 8. PLAN DE EJECUCIÓN

### Fase 1 — Hoy (preparación)
- [ ] Migrar OmniRoute de CT 109 a CT 666
- [ ] Verificar que CT 666 tiene JarvisVault completo (sync desde 109)
- [ ] Hacer backup de CT 109 (vzdump)
- [ ] Detener CT 109
- [ ] Validar que todo funciona sin CT 109

### Fase 2 — Crear CT 110 (GPU Orchestrator)
- [ ] `pct create 110` con 2GB RAM, 2 vCPU, 8GB disco
- [ ] Configurar bind-mount NVIDIA en CT 110 (solo monitoreo)
- [ ] IP estática .110
- [ ] Instalar Python3 + ssh client
- [ ] Desplegar `/opt/gpu-orch/gpu_orchestrator.py`

### Fase 3 — Migrar GPU control
- [ ] Añadir bind-mount NVIDIA también a CT 110 (no quitar de 901)
- [ ] Configurar SSH key CT 110 → CT 901 (sin contraseña)
- [ ] Configurar SSH key CT 110 → pacifico5
- [ ] Configurar SSH key CT 110 → Mac M3
- [ ] Test: CT 110 puede hacer nvidia-smi en los 3 targets

### Fase 4 — Activar protocolo de cola
- [ ] Arrancar `gpu_orchestrator.py` como servicio systemd en CT 110
- [ ] Crear script wrapper en CT 901 que consulta orquestador antes de usar GPU
- [ ] Modificar Gromacs build/lanzador para que pida permiso al orquestador
- [ ] Test: enviar trabajo desde CT 666 → orquestador (110) → worker (901) → resultado

### Fase 5 — Limpieza
- [ ] Eliminar CT 109 (después de 1 semana de validación)
- [ ] Actualizar skills: gpu-reservation-protocol, gpu-multisite-orchestration
- [ ] Registrar estado final en este documento

---

## 9. BALANCE FINAL DE RECURSOS (POST-MIGRACIÓN)

| Métrica | Antes (con 109) | Después (sin 109 + CT 110) | Diferencia |
|---|---|---|---|
| CTs activos | 18 | 18 (+1, -1) | Igual |
| RAM asignada total | ~64 GB | ~58 GB | **-6 GB** |
| RAM real usada (base) | ~13-17 GB | ~11-15 GB | **-2 GB** |
| vCPU asignados total | ~52 | ~46 | **-6 vCPU** |
| GPU passthrough | 2 CTs (109, 901, 666) | 3 CTs (110, 901, 666) | +monitoreo |
| Disco usado | ~480 GB | ~428 GB | **-52 GB** |
| Swap en uso | 5.4 GB | ~2-3 GB (estimado) | Mejora |

---

*Fin del documento. Para cambios, editar este archivo y actualizar fecha.*
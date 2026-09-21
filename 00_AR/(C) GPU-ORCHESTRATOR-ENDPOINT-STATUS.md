# (C) GPU Orchestrator — Estado Real de Endpoints

**Fecha:** 2026-09-20
**Verificado por:** Hermes (subagent)
**Host de origen:** CT 109 (192.168.0.64)

---

## Resumen

| Endpoint documentado | Puerto | Estado | Notas |
|---|---|---|---|
| 192.168.0.110:8710 | 8710 | 🔴 MUERTO | Connection refused. El proceso no está corriendo en CT 110. El código fuente (GPU_ORCHESTRATOR_MAIN.py) está configurado para este puerto con API prefix `/api/v1`, pero no hay proceso vivo. |
| 192.168.0.110:8900 | 8900 | 🟢 VIVO (v2.0.0) | Servidor HTTP Python (BaseHTTP) que expone API de solo lectura. Scheduler activo. 3 GPUs monitoreadas. |

## Endpoints Confirmados en 8900 (solo GET)

| Endpoint | HTTP | Descripción |
|---|---|---|
| `/health` | 200 ✅ | Status del servidor, uptime, versión, scheduler_running |
| `/status` | 200 ✅ | Estado de GPUs, queue length, running jobs, scheduler config |
| `/gpu-metrics` | 200 ✅ | Métricas detalladas de cada GPU (VRAM, temp, power, procesos) |
| `/queue` | 200 ✅ | Lista completa de jobs (histórico, con resultados) |
| `/tasks` | 200 ✅ | Lista de tasks (alias de queue) |
| `/tasks/<id>` | 200 ✅ | Detalle de job individual (ej: `/tasks/job_20260920_6ee0118c`) |
| `/scheduler` | 200 ✅ | Config del scheduler |
| `/sites` | 200 ✅ | Sitios/GPUs registrados |

**POST/PUT/DELETE a cualquier endpoint → 404.** La API actual es read-only.

## GPUs Monitoreadas

| GPU | Host | VRAM | Estado |
|---|---|---|---|
| `local_rtx5070` | 192.168.0.230 (CT 901) | 16 GB | IDLE, 0% uso, 38°C |
| `pacifico5_a5000` | pacifico5.izt.uam.mx | 24 GB | IDLE |
| `mac_m3pro` | 192.168.0.106 | 18 GB | IDLE |

## Jobs Históricos (todos completados con éxito)

- `job_20260920_6ee0118c`: `echo BINPACK_TEST_WITH_LOAD` → local_rtx5070
- `job_20260920_cf0e7271`: `echo FINAL_JOB_LOW` → local_rtx5070
- `job_20260920_941be74b`: `echo FINAL_JOB_NORMAL` → local_rtx5070
- `job_20260920_9485f810`: `echo FINAL_JOB_CRITICAL` → local_rtx5070
- `job_20260920_e38dfaba`: `echo LOCKED_GPU_TEST` → local_rtx5070

## Diagnóstico

1. **8710 muerto**: El proceso documentado (`GPU_ORCHESTRATOR_MAIN.py` con Puerto 8710, `/api/v1/enqueue`) no está corriendo en CT 110. Posibles causas: crash, no iniciado tras reboot, o reemplazado por la versión v2 en 8900.
2. **8900 vivo**: Es una versión v2.0.0 que no coincide con el código fuente del vault. No implementa enqueue por HTTP — solo monitoreo.
3. **Mecanismo de enqueue**: Los jobs previos (`binpack_real`, `final_test`) se inyectaron probablemente escribiendo archivos JSON directamente en `/tmp/gpu_queue/pending/` dentro de CT 110 (el mecanismo file-based que usa `GPU_ORCHESTRATOR_QUEUE.py`). Sin SSH, no es posible verificar o reproducir.
4. **Smoke test**: No se pudo completar porque no hay endpoint HTTP de enqueue funcional. Todos los GPUs están idle y libres.

## Recomendación

- Para integrar enqueue por HTTP, investigar si el servidor en 8900 es una versión legacy de solo monitoreo y si el verdadero API está en otro puerto/host.
- Alternativa: restaurar el servicio documentado (puerto 8710 con `/api/v1/enqueue`) usando el código fuente del vault en CT 110.
- Alinear el código fuente del vault con el servidor vivo (8900) o viceversa.
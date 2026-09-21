# Belcebú (RUDR9) — Team Manifest
**Canonical source:** `00_System/TEAM_MANIFEST.md`
**Last updated:** 2026-09-20

---

## 🔬 Científicos / Ingeniería
**Jefe:** Daemon (Squad 2)
**Sede:** CT 901 (gpu-orch, 192.168.0.230)
**GPU:** RTX 5070 Ti (local) + RTX A5000 (UAM, pacifico5)

| Proyecto | Encuentra en | Documentación |
|----------|-------------|---------------|
| GromacsMexicano (C++/CUDA) | `03_Projects/GromacsMexicano/` | `phase5_gpu_full_parallel/src/` |
| DM-UAMI (Fortran ref) | `Programa_DM/` (NO EDITAR) | Referencia congelada |
| DM-UAMI-AI (NN) | `01_Projects/DM-UAMI-AI/` | Redes surrogadas |
| DM-UAMI-GRID (grid) | `01_Projects/DM-UAMI-GRID/` | Cómputo grid |
| GPU Orchestrator | `00_AR/GPU_ORCHESTRATOR_*.py` | Scheduler + worker + queue |

**Skills:** `daemon-moldyn`, `gromacs-development`, `gromacs-cuda-compute-fix`, `gromacs-simulation-validation`, `physics-lock-swarm`, `gpu-multisite-orchestration`, `gpu-reservation-protocol`

**Logs:** `00_System/logs/` (tag: `cientificos`)

---

## 🖥️ Infraestructura
**Jefe:** Satanzote (Squad 1)
**Sede:** CT 666 (satanzote, 192.168.0.104)

| Proyecto | Encuentra en | Documentación |
|----------|-------------|---------------|
| Proxmox host | `pve` (192.168.0.52) | `00_Infra/` |
| Red / NetRunner | `02_Teams/NetRunner-Network-Squad.md` | Consolidado (NetRunner) |
| Backups (Ark) | `02_Teams/Ark-Backup-Resilience-Team.md` | Scripts: `/root/scripts/daily_backup.sh` en Proxmox |
| Monitoreo UPS (E23) | `Operations/E23_UPS_Monitoring/` | `cfe` skill |
| Monitoreo ntfy | `alert-monitoring-satanzote` skill | Topics: `sanzote-alerts`, `satanzote-infrastructure` |
| Logs / Chronos | `02_Teams/Chronos-LogVault-Squad.md` | Log central en vault |

**Infra map detallado:** `00_Infra/` y `SOUL.md` (sección infra)

**Skills:** `proxmox-control`, `infrastructure-audit-satanzote`, `alert-monitoring-satanzote`, `netkeeper`, `cfe`, `app-mapper`, `status-agent`, `b2-mcp`, `cloudflare-r2-storage`, `lxc-backup-restore-workflow`, `tailscale-lxc-setup`, `openviking-service-deploy`

**Logs:** `00_System/logs/` (tag: `infra`)

---

## 🤖 AI / Agentes
**Jefe:** OmniMind
**Sede:** CT 666 (satanzote, 192.168.0.104)

| Proyecto | Encuentra en | Documentación |
|----------|-------------|---------------|
| OmniRoute routing | `02_Teams/OmniMind-Routing-Squad.md` | Gateway en CT 666:20128 |
| OmniRoute maint | `02_Teams/OmniRoute-Maintenance-Squad.md` | Fusionado con OmniMind |
| OpenViking (RAG) | CT 118 (192.168.0.146:1933) | `openviking-USAGE.md` |
| Skills Hermes | `.hermes/skills/` (64 skills) | Docs en vault `05 Skills/` |
| E25 Research | `Operations/` | Monitoreo tech trends |

**Skills:** `omniroute-operations`, `omniroute-usage-optimizer`, `context-modularization`, `memoria-central`, `belcebu-orchestration`, `hermes-agent`, `hermes-auditor`, todas las skills OmniRoute

**Logs:** `00_System/logs/` (tag: `agentes`)

---

## 🌐 Web / UX
**Jefe:** E20 Dashboard Manager (Squad 3)
**Sede:** CT 109 (claude-dev, 192.168.0.64) + CT 901

| Proyecto | Encuentra en | Documentación |
|----------|-------------|---------------|
| Prototipos web | `03 Projects/Prototipos/` | Harness en CT 109:8877 |
| ~~Entrenador L'Étape~~ | ❌ **RETIRADO** (José pidió quitarlo — 5ª vez) | Dashboard CT 901:8003 — NO mantener, NO arreglar |
| ~~Claude Strava coach~~ | ❌ **RETIRADO** (depende de L'Étape/plan) | Weekly cron domingos — verificar si aplicar mismo retiro |
| SoyDashboard | `03_Projects/SoyDashboard/` | Dashboard personal |
| Laura Bernal web | `03 Projects/Laura-Bernal/` | ConfirmaCitas |
| Laura Strava/Garmin | `03 Projects/Laura-Strava-Garmin/` | Strava coach Laura |

**SOUL:** `02_Teams/WebUX-SOUL.md`
**Skills:** `prototipo-local`, `creative/*` (architecture-diagram, claude-design, p5js, etc.)
**Evaluación externa:** `01_Projects/WebUX/evaluacion-skills-emilkowalski-mcp-builder.md`

**Logs:** `00_System/logs/` (tag: `webux`)

---

## 📊 Datos / Investigación
**Jefe:** Chronos (LogVault Squad)
**Sede:** CT 666 (satanzote) + CT 118 (biblioteca)

| Proyecto | Encuentra en | Documentación |
|----------|-------------|---------------|
| Log Central | `00_System/logs/YYYY-MM-DD.jsonl` | Rotativo diario |
| OpenViking index | CT 118:1933 | Reindex diario 23:35 |
| Vault (JarvisVault) | `/root/JarvisVault/` | Git → GitHub |
| E24 Info Broker DNS | `Operations/` | Pub/sub DNS |
| E40 Memory Canonical | `Operations/EQUIPO-40-MEMORY-CANONICAL/` | Fuente de verdad |

**Skills:** `memoria-central`, `obsidian`, `search_files`, `web_extract`, `web_search`

**Logs:** `00_System/logs/` (tag: `datos`)

---

## 💼 Operaciones / RH
**Jefe:** Sofía CEO (E35) + Áine CoS (E36)
**Sede:** CT 666 (satanzote)

| Proyecto | Encuentra en | Documentación |
|----------|-------------|---------------|
| Token Budget (E33) | `Operations/` | Monitoreo OmniRoute |
| Revenue (E34) | `Operations/` | Ingresos |
| Auditor (E29) | `Operations/` | Auditorías |
| Eval Board (E27) | `Operations/` | Evaluaciones |
| Ejecutivo (E32) | `Operations/` | Dirección |

**Skills:** `rudr9-team-orchestration`, `belcebu-orchestration`, `omniroute-usage-optimizer`, `weekly-update`

**Logs:** `00_System/logs/` (tag: `ops`)

---

## Reglas de este manifiesto
1. **Un proyecto pertenece a UNA sola función.** Si hay duda, el jefe de función decide.
2. **Skills siguen al equipo**, no al revés. Si un skill no tiene equipo, se asigna por función.
3. **Logs son obligatorios** para toda ejecución de equipo (formato JSONL en `00_System/logs/`).
4. **Este manifiesto se actualiza** cada vez que se mueve un proyecto o cambia un jefe.
5. **📐 DIRECTIVA: Todo código → documentado + en biblioteca central.** Cualquier código que genere o modifique un equipo debe (a) tener documentación inline o README que explique qué hace, y (b) estar indexado en OpenViking (CT 118). Sin documentación no está terminado. Sin indexación no existe para los demás equipos. Ops + AI/Agentes mantienen esta política.

### Prioridad de recursos (quién gana en conflicto)
1. 🥇 **José** — siempre. Todo se pausa si él pide algo.
2. 🥈 **Científicos** (Gromacs, GPU) — ganan contra Infra, Web, AI, Ops.
3. 🥉 **Infra** (backups, red, salud) — gana contra Web, AI, Ops.
4. **AI/Agentes** (OmniRoute, skills) — gana contra Web, Ops.
5. **Web/UX** (dashboards) — gana contra Ops.
6. **Ops** (reportes, RH) — siempre último.

### Límites de recursos
| Recurso | Límite |
|---------|--------|
| GPU RTX 5070 Ti (local) | 1 job a la vez, máx 4h. Reservar vía gpu-reservation-protocol |
| GPU RTX A5000 (UAM) | 1 job a la vez, máx 8h. Prioridad menor que local |
| OmniRoute tokens | $2/día global. Si se excede → modo ahorro |
| Swarm workers | Máx 10 paralelos global, máx 6 por equipo |
| Log central | Sin límite (texto). Rotación diaria automática |

---

## Protocolo de comunicación entre equipos

### Canal 1 — Log Central (reporte estándar)
Cada equipo escribe al log al terminar cada tarea. Formato JSONL:
```json
{"ts":"ISO8601","team":"infra|cientificos|agentes|webux|datos|ops","task":"desc","worker_id":"...","status":"done|fail|running","duration_s":N,"gpu_used":"5070|A5000|none","result":"..."}
```
Cualquier equipo consulta con `grep 'team' 00_System/logs/YYYY-MM-DD.jsonl`.

### Canal 2 — Buzón de peticiones (cross-team requests)
Si un equipo necesita algo de otro:

```
00_System/requests/pendientes/  ← tickets activos
00_System/requests/resueltos/   ← tickets cerrados
```

**Formato del ticket:** archivo .md con frontmatter YAML:
```yaml
---
desde: webux
para: infra
asunto: Necesito subdominio para dashboard
fecha: 2026-09-20
prioridad: alta|media|baja
estado: pendiente
---
Descripción detallada de lo que se necesita y por qué.
```

**Flujo:**
1. Equipo A crea ticket en `pendientes/` y escribe al log ("solicitud a equipo X")
2. Equipo B revisa `pendientes/` al iniciar sus tareas
3. Equipo B resuelve, mueve ticket a `resueltos/`, escribe al log
4. Si urgente: equipo B usa ntfy (`sanzote-alerts`) para notificar

### Canal 3 — ntfy (urgencia cross-team)
- **Solo para:** servicio caído, backup fallido, GPU bloqueada >30 min, error crítico.
- **Topic:** `sanzote-alerts` (ya configurado en health_check.sh)
- No usar para reportes rutinarios — eso va al log central.

### Canal 4 — Status semanal
Cada viernes, cada equipo escribe un reporte en `00_System/weekly/`:
```
NOMBRE-EQUIPO-YYYY-MM-DD.md
```
Contenido:
- Qué se hizo esta semana
- Qué está bloqueado
- Qué necesita de otros equipos
- Próximos pasos

El jefe de cada equipo es responsable de que exista el weekly antes del viernes a las 18:00.
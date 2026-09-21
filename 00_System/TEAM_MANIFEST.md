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
**Jefe:** *(por asignar — propuesta: E20 Dashboard Manager)*
**Sede:** CT 109 (claude-dev, 192.168.0.64) + CT 901

| Proyecto | Encuentra en | Documentación |
|----------|-------------|---------------|
| Prototipos web | `03 Projects/Prototipos/` | Harness en CT 109:8877 |
| Entrenador L'Étape | `03 Projects/Plan_Entrenamiento/` | Dashboard CT 901:8003 |
| Claude Strava coach | `03 Projects/Claude Strava/` | Weekly cron domingos |
| SoyDashboard | `03_Projects/SoyDashboard/` | Dashboard personal |
| Laura Bernal web | `03 Projects/Laura-Bernal/` | ConfirmaCitas |
| Laura Strava/Garmin | `03 Projects/Laura-Strava-Garmin/` | Strava coach Laura |

**Skills:** `prototipo-local`, `creative/*` (architecture-diagram, claude-design, p5js, etc.)

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
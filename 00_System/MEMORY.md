GPU Multi-Sitio: RTX 5070 Ti (CT 901, 16GB) + RTX A5000 (UAM, 24GB). Mac GPU (Apple Silicon, 192.168.0.108) PENDIENTE — OFFLINE, falta autorizar SSH key servidor→Mac. Orchestrator en CT 110:8900 con cola+health. Skill: gpu-multisite-orchestration.
§
Belcebú (RUDR9) — Arquitectura de equipos (2026-09-20):
§
Framework: RUDR9 (Rapid Unified Development & Response, 9 perfiles). Call-sign operativo: "Belcebú". Plugin Hermes: rudr9-guard. Skill: rudr9-team-orchestration (existe). No renombrar — Belcebú = callsign de RUDR9.
§
Estructura:
- Swarm Workers (N paralelos, GPU-first). Preferir GPU (RTX 5070 Ti local + RTX A5000 UAM).
- Logger Agent (1 solo central, no 1 por worker). Escribe a vault/00_System/logs/YYYY-MM-DD.jsonl.
- Log Central: archivo JSONL rotativo diario en vault. Consultable por grep, jq, skill "belcebu-orchestration", u OpenViking (si se indexa).
§
Formato log entry:
{"ts":"ISO8601","team":"nombre","task":"desc","worker_id":"...","status":"done|fail|running","duration_s":N,"gpu_used":"5070|A5000|none","result":"..."}
§
GPU Orchestrator existente en 00_AR/GPU_ORCHESTRATOR_*.py (scheduler+worker+queue+monitor). Conectar a log central.
§
Execution Policy (2026-09-20): (1) SWARM-FIRST - delegar >30s. (2) GPU-FIRST (5070 Ti local, A5000 UAM). (3) Physics-lock mandatory. (4) Log mandatory al central.
§
OmniRoute routing (2026-09-17): Inst1 gratis (Gemini Flash+DeepSeek), Inst2 Claude Haiku fallback, Inst3 Sonnet/Fable crítico. ❌ Ollama unreliable. Budget $2/día. Alert >$0.05/hr, >$3/día. Monitor 15min.
§
Cloudflare tunnel (2026-09-17): CT 108 cloudflared ✅ + CT 100 nginx proxy ✅. 7 routes activas (satanzote.me + adguard.home). Operativo.
§
ntfy alerts (2026-09-17): Topics satanzote-infrastructure (CPU/RAM/disk), critical (down), omniroute (budget), gromacs, letape. Cron 15min. OmniRoute >75% spend o >$2/día → notifica.
§
Dashboard/UI preference: Lightweight (no heavy frameworks), animated abstractions (e.g., 'satansitos' as agent avatars), visual-first status (quick glance over text). Show active development projects only, not published/archived work. Iterate from prototype.
§
Communication stack (2026-09-17): ntfy for infrastructure alerts (CPU/RAM/disk/service down), Slack for inter-agent comms between profiles/projects, Telegram for urgent user messages. User lazy-approves configurations (accepts minor bugs if functional, focuses on 'does it work').
§
ACL/security: User willing to configure but prefers to 'think well' first—do not push security features that require upfront planning; flag when ready, let user decide timing.
§
test
§
Infraestructura: CT 109(hermes), CT 901(Gromacs), CT 103(Ollama), Proxmox 192.168.0.52. Preferencias: respuesta sin filler, mínimo código, priorizar GPU, optimizar costos. Proyectos activos: GromacsMexicano (C++ rewrite), Entrenador L'Étape, Claude Strava, Prototipos. Reglas operativas: no editar archivos, no modificar cron, usar memoria solo para consolidar. Usuario: José (developer, en busca de empleo AI).
§
Proyecto "Satanzote" (Sept 2026): Migración total de CT 109 (claude-dev) a un nuevo contenedor limpio llamado 'satanzote'. Objetivo: eliminar deuda técnica y parches acumulados, unificar identidad bajo el nombre 'Satanzote' y optimizar recursos (CPU/RAM/GPU). Protocolo: migración selectiva de activos (Vault, Skills, Perfiles, API Keys), purga de logs/basura y refactorización de archivos durante el traslado.
§
José prefiere nomenclatura/identidad cyberpunk en inglés para agentes/perfiles del sistema (SatanZote: Archon/Urbanist/Samurai/Sentinel/Scavenger/Proxy) y quiere usar Vaultwarden para centralizar llaves antes de migraciones.
§
User wants the new Hermes/agent ecosystem renamed to 'Satanzote' and prefers cyberpunk themed agent/profile names in English (e.g., SatanZote-Archon/Samurai/Sentinel) for identity consistency.
§
**Satanzote Infrastructure Migration (2026-09-19):** CT 666 (192.168.0.104) es el nuevo host limpio, sin parches históricos. CT 667 es restore del backup 2026-09-18 para validación. Telegram bot @satanzote667_bot (token 8927656628:AAEGAGvu_AmH-XZ80MCKWSMbv19fNFqrySU) activo pero en degraded mode. Git remote: git@github.com:Jaalejandre/claudestrava.git. Auto-backup timer: 23:30 CDMX.
§
Arquitectura de Cómputo Dividido: Mac (Apple Silicon ARM64, josealejandre) para interfaz/builds locales y alertas; CT 666 (SatanZote) como orquestador central y biblioteca; CT 901 (RTX 5070 Ti) para física CUDA. Enlazados vía AgentChat (@satanzote-archon) y MCP mac-control.
§
Tool Registry Preference (2026-09-20): Registro persistente en vault /root/JarvisVault/04 Tools Registry/. Propósito: proponer herramientas sin re-analizar. Estructura: Nombre, URL, Propósito, Decisión, Razón, Casos de Uso, Fecha. (OpenWRT🟡, PinchTab🟡, PKE❌, K3s❌ ya registradas, commit 1db9a66).
§
OmniRoute real status (2026-09-20): Gemini/Claude/CheaperInference FUNCIONALES. Solo 3 OAuth expirados: kimi-coding, github, amazon-q. Gasto real $3.93/día. ANTIGRAVITY revive 17 Sep, 27% tráfico gratis. GPU orchestrator v2 en CT 110:8900 con smart scheduling (bin-packing, monitoreo real).
§
User revealed new overarching vision: build a self-sustaining AI server + lab to learn AI (2026-09-20). This redefines scope from pure code optimization to autonomous infrastructure + AI experimentation platform.
§
Work style: define framework FIRST before acting. "Vamos hacer las cosas bien" — step back, establish architecture/source-of-truth/principles, then delegate execution. Prefers structured definition over rushing into implementation. Source of truth must be clear before building.
# ⚠️ Incidente — 14 sep 2026: Dashboard Entrenador L'Étape caído y código eliminado de CT 901

## Severidad: ALTA (proyecto sin artefacto desplegado)

## Síntomas (verificado)
- 3× `curl http://192.168.0.230:8003/` → **HTTP 000**, `time_total=0.0001s` (conexión rechazada/cerrada). Host 192.168.0.230 responde a ping (0% pérdida).
- Nada escuchando en `:8003` ni en `:8877` dentro de CT 901 (`ss -tlnp` vacío para ambos).
- Ningún proceso `plan_api`/`dashboard` vivo en CT 901.

## Causa raíz
- `/home/alejandre/EntrenadorLEtape/` — el árbol completo (dashboard.py, plan_api.py, plan_builder.py, plan_engine.py, zwift-recommender, 49 tests verdes, los 5 módulos) — **ya no existe en CT 901**.
- Búsqueda exhaustiva en CT 109, CT 901 y CT 103 (`find / -iname dashboard.py / plan_api.py`) → **no encontró el código** en ninguna parte.
- En CT 901 solo queda `/home/alejandre/dm-uami/` (trabajo de Fase 4). El directorio `EntrenadorLEtape` fue eliminado sin backup git (task kanban `t_338697aa` "Backup git" quedó en `ready`, sin ejecutar desde 2026-09-09).

## Impacto
- El dashboard (http://192.168.0.230:8003, dado como ✅ testeado en el CLAUDE.md del proyecto) está caído.
- Los 5 módulos que ya funcionaban (strava-ingest 22 tests, plan-engine 13, zwift-recommender 8, web-dashboard 6) no están desplegados ni respaldados.
- Los **km reales de Strava no se pierden** (14.8 km registrado en la revisión semanal del 14 sep) — esto solo afecta el proyecto de código del dashboard.

## Acciones inmediatas requeridas
1. Buscar el código en backups: snapshots Proxmox (host), MCP B2, copias locales/`~` antiguas.
2. **Prioridad**: restaurar y hacer el backup git (`t_338697aa`) para eliminar el punto único de falla.
3. Re-desplegar dashboard + plan_api una vez recuperado.
4. En paralelo sigue pendiente desbloquear Garmin (`t_5501aefe`, rate limit Cloudflare 429/403) para inyectar HRV/sueño al auto-ajuste.

## Lección
- El CLAUDE.md del proyecto indicaba el dashboard como ✅ sin que hubiera backup git. La falta de backup convirtió una limpieza de máquina en pérdida total del código del proyecto. Precedente: el backup git es obligatorio antes de declarar algo desplegado.
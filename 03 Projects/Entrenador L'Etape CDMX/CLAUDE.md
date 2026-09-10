# Entrenador L'Étape CDMX (Garmin + Strava + Zwift)

Agente que conecta **Garmin Connect** y **Strava** para construir una rutina de entrenamiento personalizada hacia la **L'Étape Ciudad de México 60 km** (15 nov 2026). Complementa a [[03 Projects/Claude Strava/CLAUDE.md|Claude Strava]] — el plan maestro sigue viviendo en el vault; este proyecto lo hace *ejecutable y auto-ajustable*.

## Claude's Role

Orquestas el desarrollo en **CT 901** usando **Ollama en CT 103** (modelos locales) para generar el código. Actúas como arquitecto: escribes los specs, revisas lo que genera el modelo, validas los gates, y aseguras la trazabilidad hacia este proyecto y el plan maestro.

Si una sesión se desvía sin acercar el producto terminado (dashboard con sesión de hoy, countdown, km acumulados, recomendación Zwift), redirígeme: "No estamos avanzando el dashboard — volvamos al spec del módulo en curso."

## Producto (definido en entrevista 2026-09-09)

Una **página web local** en CT 901 que muestre:
- Qué entrenamiento toca hoy (según el plan de Claude Strava)
- Cuántos días faltan para la competencia (15 nov 2026)
- Cuántos km llevo acumulados (desde Strava)
- El entrenamiento **se auto-modifica** según el progreso real (señales de Garmin: HRV, sueño, TSB)
- Qué workout/ruta **cargar en Zwift** (recomendación por sesión)

## Arquitectura aprobada (Capability Map 2026-09-09)

| Module id | Responsabilidad | Depende de |
|---|---|---|
| `strava-ingest` | API Strava V3 (OAuth), km, actividades | — |
| `garmin-ingest` | MCP Garmin (`taxuspt/garmin_mcp`), sueño/HRV/TSB/FTP/VO2max | — |
| `mcp-strava` | MCP oficial Strava para análisis agéntico (Claude) | — |
| `plan-engine` | "Qué toca hoy", countdown, km acumulados, auto-ajuste | strava+garmin |
| `zwift-recommender` | Sesión del día → workout/ruta exacta Zwift | plan-engine |
| `web-dashboard` | Página web local CT 901 | plan-engine, zwift |

Build order: `garmin-ingest` + `strava-ingest` (paralelo) → `plan-engine` → `zwift-recommender` → `web-dashboard`. `mcp-strava` corre en paralelo (capa agente, no bloquea web).

## Infraestructura

- **CT 901** (`ubuntu`, .52:901): desarrollo + web. Python 3.12, GPU RTX 5070 Ti libre, sin Docker (el MCP garmin corre con `uv run`, no docker).
- **CT 103** (`.99:11434`): Ollama — `qwen2.5-coder:14b` (default), `gpt-oss:latest`, `gemma3:latest` para generación.
- **Orquestación**: Claude Code en CT 901; el acceso desde este vault es contexto/specs/plans.

## Reglas

- **(C)** en archivos generados por IA.
- No editar el plan maestre de Claude Strava sin permiso — `plan-engine` *lee y propone ajustes*, Claude Strava aprueba.
- Nutrición (InBody/Mounjaro): fuera de este proyecto.
- Dashboard single-user (tú), local en CT 901.
- Los specs viven en `02 Specs/`; los planes en `03 Plan de Desarrollo/`.

## Estado actual

- [x] Entrevista completada (2026-09-09)
- [x] Capability Map aprobado
- [x] Spec garmin-ingest — cerrado (contraseña sin 2FA, 30/90 días)
- [x] Spec strava-ingest — cerrado (crear app, stravalib, km+horas+carga)
- [x] Spec plan-engine — cerrado (HRV rating Garmin, equipo casa, carga fórmula simple)
- [x] Spec zwift-recommender — cerrado (plan estándar)
- [x] Spec web-dashboard — cerrado (español, acceso local default)
- [x] **Fases 1-5 implementadas y testeando** (CT 901 `/home/alejandre/EntrenadorLEtape`, 49 tests verdes, 5 commits)

### Implementación (2026-09-09)

| Módulo | Estado | Detalle |
|---|---|---|
| `strava-ingest` | ✅ Testeado (22) | Auth OK, 3 actividades reales, km→horas→carga |
| `garmin-ingest` | ⛔ Bloqueado | **Rate limit 429/403 por IP pública (Cloudflare)** — credenciales OK (`.V@q3r0`), esperar enfriamiento o probar desde otra IP |
| `plan-engine` | ✅ Testeado (13) | `plan_builder.py` (MD→plan.json, FTP 148, 11 semanas) + `plan_engine.py` (ajustes HRV/sueño/TSB, no-mutación) + `plan_api.py` :8877 |
| `zwift-recommender` | ✅ Testeado (8) | Catálogo curado (7 workouts + 5 rutas), mapeo por tipo/zona/duración, `/zwift/today` |
| `web-dashboard` | ✅ Testeado (6) | `http://192.168.0.230:8003` — tarjeta "Hoy toca", countdown 67 días, barra km, recomendación Zwift, mobile-first en español |
| `mcp-strava` | ⬜ No iniciado | Capa agente, no bloquea web |

**Ejecutándose:** `plan_api.py` en `127.0.0.1:8877` (interno) + `dashboard.py` en `0.0.0.0:8003` (accesible en red local).

**Pendiente:** ① auth Garmin en vivo (esperar rate limit / otra IP) → inyectar HRV/sueño reales al auto-ajuste; ② `/adjust` (auditoría de ajustes); ③ visual check del dashboard en el navegador/teléfono.

**Nota proceso:** `start_api.sh` y `start_dashboard.sh` levantan los servicios (setsid, sobreviven al ssh). Todo el código se genera/edita en CT 901; el vault guarda specs y estado.
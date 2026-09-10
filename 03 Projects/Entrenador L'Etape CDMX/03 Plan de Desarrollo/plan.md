# Plan de Implementación — Entrenador L'Étape CDMX

> Fuente: specs aprobados en `/specs/` (2026-09-09). Este plan sigue el capability map aprobado y las reglas de planning-and-task-breakdown.

## Dependency Graph

```
garmin-ingest (MCP taxuspt) ──────┐
                                 ├── plan-engine (reglas heurísticas)
strava-ingest (API V3 + stravalib)┘          │
                                             ├── zwift-recommender (catálogo estático)
                                             └── web-dashboard (FastAPI + vanilla JS)

mcp-strava (capa agente, paralela a todo) ─── no bloquea, no depende de nada
```

**Orden:** ingest (paralelo) → plan-engine → zwift-recommender → web-dashboard. mcp-strava en paralelo cuando haya MCP de Strava configurado.

## Arquitectura de runtime (CT 901)

```
/home/alejandre/EntrenadorLEtape/
├── specs/            # specs aprobados (copia)
├── src/
│   ├── garmin_client.py     # wrapper del MCP garmin (lee tools del server MCP)
│   ├── strava_client.py     # stravalib + OAuth + cache
│   ├── plan_engine.py        # today_plan() + reglas heurísticas
│   ├── zwift_recommender.py  # recommend(session) + catálogo
│   ├── dashboard.py          # FastAPI app (sirve HTML + /api/*)
│   └── static/               # index.html, styles.css, app.js
├── data/             # plan.json, strava_cache.json, state.json, zwift_catalog.json
├── tasks/
│   ├── plan.md
│   └── todo.md
└── tests/            # unit tests con fixtures mock
```

**Dependencias Python** (requirements.txt): `stravalib`, `fastapi`, `uvicorn`, `python-dotenv`, `mcp>=1.28,<2`, `garminconnect==0.3.2`, `requests`, `pytest`, `pytest-asyncio`.

**Nota runtime MCP garmin:** el server MCP corre con `uv run garmin-mcp` (stdio). garmin_client.py lo invoca como subprocess o habla por stdio MCP. Alternativa: usar la librería `garminconnect` directamente (mismo motor del MCP) — DECISIÓN: usar **`garminconnect` directamente en v1** (más simple de testear, sin capa MCP stdio), el MCP queda disponible para la capa agente (Claude Code). ✅ elegido: directo via garminconnect.

## Fases y Tareas

### Fase 0 — Setup (pre-código)
- **T0.1** Crear app Strava Developers (humano: tú) — obtener client_id/client_secret
- **T0.2** Instalar deps Python en CT 901 (`uv venv` o virtualenv)
- **T0.3** Git init del repo local en CT 901 (+ `.gitignore` con secrets)

### Fase 1 — strava-ingest (paralelo con Fase 2)
- **T1.1** OAuth flow: obtener refresh token (script + browser)
- **T1.2** `strava_client.py`: activities(), stats(), ride_detail()
- **T1.3** `aggregate.py`: weekly_km(), hours_in_zone(), weekly_load()
- **T1.4** Cache JSON con TTL
- **T1.5** Tests unitarios (fixtures mock)

### Fase 2 — garmin-ingest (paralelo con Fase 1)
- **T2.1** Auth garminconnect (email/pass, sin 2FA) + tokens persistidos
- **T2.2** `garmin_client.py`: sleep(), hrv_status(), training_load(), ftp()
- **T2.3** Tests unitarios (fixtures mock)

### Fase 3 — plan-engine (dependency: Fase 1+2)
- **T3.1** Parser del plan MD del vault → `data/plan.json`
- **T3.2** `today_plan()`: calendario + sesión base + countdown
- **T3.3** Reglas de ajuste (HRV/sueño/TSB + progreso km)
- **T3.4** `progress()`: km/horas/carga integrando strava+garmin
- **T3.5** FastAPI `/plan/today`, `/plan/progress`, `/plan/week`
- **T3.6** Tests: hoy normal, hrv_low, sueño corto, tsb_bajo, días_to_event=67

### Fase 4 — zwift-recommender (dependency: plan-engine)
- **T4.1** Catálogo `zwift_catalog.json` (≥10 workouts, ≥5 rutas, curado)
- **T4.2** `recommend(session)` + tabla de mapeo
- **T4.3** Endpoint `/zwift/today`
- **T4.4** Tests de mapeo

### Fase 5 — web-dashboard (dependency: plan-engine + zwift)
- **T5.1** `index.html` mobile-first (dashboard básico)
- **T5.2** `/api/dashboard` (combinado plan+zwift) + JS render
- **T5.3** Vistas `/week` y `/adjust`
- **T5.4** `/healthz` + arranque uvicorn systemd
- **T5.5** Smoke: `GET /healthz` 200, `GET /api/dashboard` con datos reales

### Fase 6 — Integración end-to-end
- **T6.1** Ejecutar todo el stack, ver dashboard con datos reales
- **T6.2** Verificar el flujo: dashboard → abrir Zwift → hacer la sesión → se refleja en km al día siguiente

## Riesgos y mitigaciones

| Riesgo | Mitigación |
|---|---|
| Garmin cambia su scraping (garminconnect frágil) | wrappers aíslan cambios; fallback cadencia (sin Garmin solo se pierde ajuste, plan base sigue) |
| Strava OAuth refresh expira | script de refresh + alerta si falla 2 días seguidos |
| Plan maestro del vault cambia de formato | parser versionado; si rompe, reportar sin tocar el vault |
| Ollama genera código desviado del spec | gates por tarea: testeamos antes de avanzar, humano revisa |
| Zwift catálogo no veraz | solo incluir workouts/rutas reales verificables en la app |

## Gates por fase

- **Fase 0**: deps install, app Strava creada
- **Fase 1**: tests verdes + 1 llamada real a Strava devuelve datos
- **Fase 2**: auth garminconnect + 1 llamada real devuelve sleep/HRV
- **Fase 3**: today_plan() con fixtures + /plan/today 200
- **Fase 4**: recommend() mapea todos los tipos de sesión
- **Fase 5**: dashboard carga con datos reales (no hardcode) + smoke
- **Fase 6**: revisión humana del flujo completo

## Notas de implementación

- El código lo GENERA el modelo local (Ollama CT 103) con prompts desde Claude Code en CT 901
- Claude orquesta y revisa cada tarea contra su spec (gate)
- El humano (tú) ejecuta las tareas de setup que requieren login (Strava app, OAuth, Garmin auth) — son T0.1, T1.1 parcial y T2.1 parcial

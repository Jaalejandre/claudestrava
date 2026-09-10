# Spec: web-dashboard

## Objective

**Página web local** en CT 901 — el rostro visible del producto. Muestra: qué entrenamiento toca hoy, días para la competencia, km acumulados, horas en zona, carga semanal, y la recomendación Zwift del día. Lee de `plan-engine` (via su API interna) + `zwift-recommender`. Single-user, local, sin registro.

Historia de usuario:
> Como atleta, quiero abrir una página y VER de un vistazo qué me toca hoy, cuánto falta y cómo voy, para ejecutar el plan sin pensar.

## Entrada (depende de)

| Fuente | Qué muestra | Módulo |
|---|---|---|
| `plan-engine` | `/plan/today`, `/plan/progress`, `/plan/week` | API interna FastAPI |
| `zwift-recommender` | `/zwift/today` | su API |

## Tech Stack

| Componente | Detalle |
|---|---|
| Frontend | **HTML + CSS + JS vanilla** (sin framework) — página simple, servida por FastAPI o estática |
| Backend | FastAPI (Python 3.12) sirve HTML + proxies los endpoints internos |
| Port | **8003** en CT 901 (confirmado libre) |
| Estilo | Minimal, mobile-friendly (se ve en el teléfono junto al rodillo) |

## Vistas (v1)

### `/` — Dashboard
- **Tarjeta principal:** "Hoy toca: Rodada estructurada Z2 · 50 min" + celda de ajuste (si HRV bajo: "Recortada por HRV")
- **Countdown:** días para la competencia (grande, arriba)
- **Progreso semana:** km hechos vs meta (barra), horas en zona Z2/Z3/Z4, carga semanal
- **Recomendación Zwift:** nombre del workout/ruta + query de búsqueda (botón "buscar en Zwift")

### `/week` — Semana
- Las próximas 7 sesiones del plan en calendar layout simple
- Muestra cuáles ya se completaron (marcado por grooming manual o data de Strava)

### (opcional en v1 si da tiempo) `/adjust` — Historial de ajustes
- Lista de ajustes con razón (audit: "2026-09-09: recortada por HRV bajo")
- Lee del log de `plan-engine`

## API interna del dashboard

- `GET /` → HTML
- `GET /api/dashboard` → JSON combinado (plan + zwift) para render JS
- `GET /healthz` → 200 (healthcheck del compose/docker si aplica)

## Scope

**IN:**
- Página con las 3 vistas (dashboard, week, adjust)
- Estilos clean (mobile-first, no framework)
- Datos en vivo desde plan-engine/zwift (fetch con cache 15 min)
- Single-user sin auth (localhost-ish)

**OUT:**
- No auth/usuario (single-user)
- No PWA/offline en v1
- No backend de datos propio (todo viene de plan-engine + ingest)

## Success Criteria (testables)

- [ ] `GET /` abre y carga datos reales con fetch (no hardcodeados)
- [ ] Tarjeta "Hoy toca" muestra la sesión de `today_plan()` (incluyendo ajuste si aplica)
- [ ] Countdown correcto (67 días verificado hoy)
- [ ] Barra de progreso km semana vs meta
- [ ] Recomendación Zwift visible con botón de búsqueda
- [ ] `/healthz` 200
- [ ] Se ve bien en móvil (viewport) — revisión manual

## Boundaries

- **Always:** Mobile-first, single-user, render en el cliente (fetch). Sin framework frontend (YAGNI).
- **Ask first:** Agregar auth; agregar framework frontend; exponer el dashboard fuera de CT 901 (aún single-user pero via Cloudflare/NPM).
- **Never:** Meterse con el plan del vault; mostrar métricas de nutrición; hardcodear datos que puedan venir en vivo.

## Open Questions

1. ~~¿Acceso desde qué equipos?~~ → **Pendiente** — v1 asumo red local (`http://192.168.0.XX:8003`) desde compu/teléfono; confirma si necesitas acceso remoto ya.
2. ~~¿Idioma?~~ → **Asumido 2026-09-09: español** (coherente con vault/plan), salvo objeción.

## Decisiones cerradas (2026-09-09)

- Idioma: español
- Acceso: local en CT 901 (default), remoto pendiente de confirmar
- El dashboard muestra también el equipo en casa sugerido para sesiones no-Zwift (fuerza/descanso activo)

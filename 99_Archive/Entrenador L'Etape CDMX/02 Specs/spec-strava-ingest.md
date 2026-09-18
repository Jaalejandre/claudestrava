# Spec: strava-ingest

## Objective

Conectar la **API V3 oficial de Strava** (OAuth) en CT 901 para alimentar al `plan-engine` y `web-dashboard` con datos de actividades: km acumulados, rides recientes, métricas de rendimiento (potencia, FC, elevación). Complementa al MCP de Strava (capa agéntica) con un acceso **programático** para la web.

Historia de usuario:
> Como atleta, quiero ver en el dashboard cuántos km llevo acumulados y cómo van mis rides contra el plan, sin abrir Strava, para perseguir mi progreso del día a día.

## Tech Stack

| Componente | Versión / Detalle |
|---|---|
| API | Strava V3 (OAuth2) — `https://www.strava.com/api/v3` |
| App | Crear en `strava.com/settings/api` (client_id + client_secret) |
| Access | Refresh token (1era vez manual vía flujo OAuth en browser) |
| Librería | `stravalib` (Python, mantenida) o requests directos (decision: ver Open Questions) |
| Rate limits | 100 req/15min, 1000/día (suficiente: 1-2 llamadas por fetch) |

## Scope

**IN:**
- Crear app Strava en developers (requiere cuenta) y obtener `client_id`/`client_secret`
- Flujo OAuth: obtener refresh token del dueño de la cuenta (tú)
- `strava_client.py`: `activities(since, per_page)`, `stats()`, `ride_detail(activity_id)`
- Agregación: **km acumulados por semana** hacia el evento (para el dashboard)
- Persistencia mínima: cash JSON en `data/` (evita pegar a la API en cada vista)
- Smoke test real: una llamada devuelve tus rides

**OUT:**
- No escribir/borrar actividades (solo lectura)
- No exponer tokens en la web (el dashboard habla con `plan-engine`, no con Strava directo)
- MCP oficial de Strava queda **separado** (módulo `mcp-strava`) — este módulo es solo API REST

## Success Criteria (testables)

- [ ] App registrada + flujo OAuth completo → refresh token guardado en secret (0600)
- [ ] `strava_client.py` lista actividades y stats reales (tu cuenta: rides recientes, km)
- [ ] `weekly_km(since_date)` devuelve km por semana (espaciados al formato del plan)
- [ ] Cache en `data/strava_cache.json` con TTL (<15 min) — no se pega a la API en cada render
- [ ] Test unitario con fixture mock

## Boundaries

- **Always:** Cachear respuestas (respetar rate limits). Tokens en secret file `0600`. Nombrar la app "Entrenador LEtape" (uso personal).
- **Ask first:** Cambiar a `requests` directo (vs stravalib); agregar scope de escritura; usar webhooks.
- **Never:** Committear tokens; exponer client_secret en la web; escribir en la cuenta Strava (v1).

## Open Questions

1. ~~¿Ya tienes creada la app en Strava Developers?~~ → **Resuelto 2026-09-09: no existe, hay que crearla desde cero** (task 1 del PLAN — requiere cuenta strava.com/settings/api).
2. ~~¿Estás de acuerdo con `stravalib` como librería?~~ → **Resuelto 2026-09-09: sí, stravalib.**
3. ~~¿Solo km o también horas en zona/carga semanal?~~ → **Resuelto 2026-09-09: km acumulados + horas en zona + carga semanal en v1.**

## Decisiones cerradas (2026-09-09)

- Crear app Strava Developers desde cero (client_id + client_secret)
- Librería: `stravalib` (mantenida, typing)
- Dashboard v1: km acumulados + horas en zona (Z2/Z3/Z4) + carga semanal (estimación por sesión)
- Cache `data/strava_cache.json` con TTL <15 min
- Rate limits: 100 req/15 min — 1-2 llamadas por fetch, sin riesgo
# Spec: garmin-ingest

## Objective

Conectar el **MCP de Garmin** (`taxuspt/garmin_mcp`) en CT 901 para exponer datos de Garmin Connect al `plan-engine` y al `web-dashboard`. Único módulo de **entrada de datos fisiológicos**: sueño, HRV, TSB/CTL/ATL, FTP, VO2max, Body Battery, composición corporal.

Historia de usuario:
> Como atleta que entrena hacia L'Étape CDMX 60 km, quiero que mi entrenamiento se ajuste según mi recuperación real (sueño, HRV, estrés), para no sobreentrenar ni perder adaptación.

## Tech Stack

| Componente | Versión / Detalle |
|---|---|
| Servidor MCP | `taxuspt/garmin_mcp` v0.1.0 (repo clonado, `src/garmin_mcp`) |
| Motor | `garminconnect==0.3.2` (scraping Garmin Connect) |
| Runtime | `uv` (Python ≥3.10) — **sin Docker** en CT 901 |
| Transporte | MCP (stdio) — consumido por agentes MCP-compatibles y por nuestro wrapper HTTP |
| Auth | `garmin-mcp-auth` CLI (MFA + tokens OAuth persistidos en `/root/.garminconnect`) |

## Scope

**IN:**
- Instalar `garmin-mcp` en CT 901 vía `uv` (no Docker)
- Autenticar contra Garmin Connect (email/password + 2FA) y persistir tokens
- 110+ tools disponibles: actividades, sueño, HRV, estrés, respiración, TSB/CTL/ATL, FTP, VO2max, gear, workouts
- Wrapper Python (`garmin_client.py`) que encapsule las tool calls que el `plan-engine` necesita (5-8 específicas)
- Smoke test: una llamada real a Garmin devuelve datos reales

**OUT:**
- No editar actividades Garmin (solo lectura) — al menos en v1
- No exponer el MCP a la red (solo localhost)
- No guardar password en texto plano — usar secret file/`GARMIN_EMAIL`/`GARMIN_PASSWORD` con permiso `0600`

## Success Criteria (testables)

- [ ] `garmin-mcp-auth` completa auth con MFA y deja tokens funcionales
- [ ] `uv run garmin-mcp` arranca como MCP server sin error
- [ ] Un cliente MCP (ej. `mcp` CLI o Claude Code) lista las tool calls y llama `get_sleep_data` → datos reales JSON
- [ ] `garmin_client.py` expone: `sleep(days)`, `hrv(days)`, `tsb_trend()`, `ftp()`, `vo2max()`, `body_composition()` — cada una devuelve dict/JSON validado
- [ ] Test unitario con fixture mock (no depende de Garmin vivo)

## Boundaries

- **Always:** Leer las metricas solo con las tools de lectura del MCP. Persistir tokens en `/root/.garminconnect` con permisos `0600`. Loggear sanitizado (nunca tokens/passwords en logs).
- **Ask first:** Cambiar a otra librería Garmin; agregar tools de escritura (editar actividades); mover el MCP a otro CT.
- **Never:** Committear credenciales Garmin; exponer el MCP fuera de CT 901; ejecutar llamadas de escritura hacia Garmin.

## Open Questions

1. ~~¿Tu Garmin Connect usa email/password normal o también 2FA?~~ → **Resuelto 2026-09-09: solo contraseña, sin 2FA.** El auth CLI no requiere MFA interactiva.
2. ~~¿Cuántos días de historial quieres backfill en v1?~~ → **Resuelto 2026-09-09: 30 días sueño/HRV, 90 días actividades (para TSB).**

## Decisiones cerradas (2026-09-09)

- Auth: solo email + password (sin TOTP/2FA)
- Backfill v1: 30 días de sueño/HRV, 90 días de actividades
- Runtime: `uv run` (sin Docker en CT 901)
- El MCP se consume localhost-only; `garmin_client.py` encapsula las 6 tools base para el plan-engine
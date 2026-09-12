---
tipo: plan-infraestructura
proyecto: infraestructura
estado: ACTIVO
creado: 2026-09-12
actualizado: 2026-09-12
metodologia: Este plan es el contexto compartido de todos los agentes (Claudian, Claude Code CT 109/901, Hermes). Se ejecuta CONTRA el plan. Al completarse, se borra este archivo y el estado final queda documentado en el mapa del servidor.
---

# PLAN — Infraestructura LLM: OmniRoute como router único (cimientos primero)

## 0. Orden correcto (aprendido 2026-09-12)

**PRIMERO los cimientos, después la migración de apps.**

1. **Fase A — OmniRoute bien armado** (router + Hermes director + Ollama local gratis)
2. **Fase B — Consumidores repuntados** (todo el acceso a LLM pasa por OmniRoute)
3. **Fase C — Migración de apps CT 109 → CT 112** (cosmético, solo al final)

> ❌ Error corregido: se intentó empezar por la Fase C (mover airbnb-admin). El usuario marcó el orden correcto. La migración de apps NO construye nada si los cimientos del router no están.

## 0b. ARQUITECTURA CONFIRMADA POR EL USUARIO (2026-09-12)

**Hermes = orquestador. SatanZote (modelo más fuerte, esta sesión) = cerebro de razonamiento.**

- Hermes recibe/observa → para tareas SIMPLES usa local (Ollama CT 103) o gratis (Gemini).
- Para lo PESADO (razonar, planear, revisar, decidir) → llama al modelo más fuerte disponible (Claude sonnet/opus vía OmniRoute, apodado "satanzote").
- TODO headless (optimizar recursos, cero UI).
- La API key de Anthropic (sk-ant, propia, vence 2026-10-10) es el futuro reemplazo de la suscripción Pro: API es más barato por token y sin límite de sesión.
- El crédito de la API key es limitado por ahora; la suscripción Pro sigue como principal hasta que se optimice el consumo. A medida que el sistema madure → API-first.

## 1. Visión

**OmniRoute es el router central de LLM** (`192.168.0.64:20128`). Decide qué modelo/proveedor/tokens usa cada tarea:

- **Tareas de programación y tokens caros** → Claude (suscripción) vía router, **dirigidas por Hermes**
- **Todo lo demás (gratis)** → modelos locales **Ollama (CT 103)** u otros providers gratuitos vía router
- **Hermes = el director**: recibe la petición, decide dónde corre, delega, y reporta
- **Ningún consumidor pega directo** a Anthropic/Google/OpenAI por su cuenta

Regla de oro: **lo que se pueda hacer local, se hace local (Ollama). Lo caro, solo cuando Hermes lo justifique.**

## 2. Arquitectura objetivo

```
                    ┌─────────────────────────────┐
                    │       HERMES (director)      │
                    │  decide qué tarea → dónde    │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │   OMNIROUTE (router único)  │  :20128
                    │  auth · prioridad · fallback │
                    └──┬────────┬────────┬────────┘
                       │        │        │
              ┌────────▼──┐ ┌───▼────┐ ┌─▼──────────┐
              │ Claude    │ │ Ollama │ │ Gratis     │
              │ (suscrip- │ │ CT 103 │ │ nvidia/    │
              │  ción,    │ │ LOCAL  │ │ gemini/    │
              │  caro)    │ │ FREE   │ │ deepseek…  │
              └───────────┘ └────────┘ └────────────┘

Consumidores → OmniRoute: CT 901, CT 109, Hermes, Claudian, apps (si usan LLM)
```

## 3. Estado actual verificado (2026-09-12)

### OmniRoute (CT 109 :20128)
- Corriendo. Providers activos: `claude` (OAuth suscripción), `nvidia`, `gemini`, `deepseek`, `ollama-cloud`, `cloudflare-ai`.
- ⚠️ Hallazgo del 11-09: modelo correcto para la suscripción = **`claude/claude-sonnet-5`** (namespace `cc/` NO existe).
- ⚠️ Pendiente: verificar integración con **Ollama CT 103 como provider local gratis** (¿está conectado como `ollama`/`ollama-cloud`?).

> **ACTUALIZADO 2026-09-12 (verificado en vivo):**
> - **API key de Anthropic agregada** como conexión `satanzote-api` (provider `anthropic`, api-key). Key del usuario, vence 2026-10-10. Probado: `anthropic/claude-sonnet-4-6` ✅ y `anthropic/claude-opus-4-6` ✅ responden "pong".
> - **Gemini reconectado** con la `GOOGLE_API_KEY` real de Hermes (via `providers rotate --from-env`). Modelos vivos: `gemini-3.1-flash-lite`, `gemini-3.6-flash` (los `2.5-*` dan 404, retirados por Google).
> - **Ruta Hermes completa verificada**: Hermes → OmniRoute → {anthropic sonnet 4.6 ✅, gemini 3.1 ✅, ollama-local qwen2.5-coder ✅ (con `--reasoning none`)}.
> - **ollama-cloud**: NO tiene key real (la de Hermes era dummy `ollama`). Necesita key nueva de cloud.ollama.com para activarse.
> - **Pirámide de routing (decisión 2026-09-12, "satan" decide):** razonar/planear → sonnet 4.6 (API); máxima potencia puntual → opus 4.6 (API); intermedio → gemini; simple/local → qwen2.5-coder (Ollama CT 103).
> - **CORRECCIÓN del usuario (2026-09-12):** el orquestador NO necesita sonnet. Hermes = trabajo ligero (clasificar/despachar) → **haiku**. Se crearon 3 combos con prioridad exacta dentro de cada nivel (verificados con request real el 12-sep):
>   - `orquestador` (default de Hermes): `claude/claude-haiku-4-5-20251001` (Pro, gratis) → `anthropic/claude-haiku-4-5-20251001` (API, centavos) → `gemini/gemini-3.1-flash-lite` (free) → `ollama-local/qwen2.5-coder:14b` (local).
>   - `satanzote` (razonamiento pesado, invocado explícitamente cuando la tarea lo amerita): `anthropic/claude-sonnet-4-6` (API) → `claude/claude-sonnet-5` (Pro) → `gemini` → local.
>   - `local-first` (tareas de código simple): `ollama-local/qwen2.5-coder:14b` (LOCAL primero, $0) → `claude/claude-haiku-4-5-20251001` (Pro) → `anthropic/claude-sonnet-4-6` (API). Verificado: responde con modelo `qwen2.5-coder:14b`, fingerprint `fp_ollama`.
>   - Opus 4.6 disponible puntual vía API (no en combo, evitar gasto default).
> - **Prioridad general del usuario:** local → suscripción → API (cambiará eventualmente a API-only). OmniRoute = decide el tráfico; Hermes = decide el nivel del combo.

### Hermes (CT 109)
- `hermes-gateway.service` corriendo.
- Conectado a OmniRoute (Pasos 1-6 del plan anterior ✅).
- Tiene credenciales limpias (Gemini/Ollama-cloud muertas removidas; Whisper/OpenAI intactos).

### Ollama (CT 103)
- Modelos: `qwen2.5-coder:14b` + `gpt-oss:latest` (GPU, nvme-fast).
- Rol: **modelo local gratis** para lo que no necesita tokens caros.

### Consumidores

| Consumidor | Ruta actual | Estado |
|---|---|---|
| Claude Code CT 901 (programador) | OmniRoute `claude/claude-sonnet-5` | ✅ |
| Hermes | OmniRoute | ✅ |
| Claude Code CT 109 (admin) | directo a Anthropic (sin base_url) | ❌ repuntar |
| Claudian (Mac) | directo / OmniRoute local | ❓ verificar |
| Apps | ¿alguna usa LLM? | ❓ verificar (Fase C) |

## 4. Fase A — Cimientos: OmniRoute bien armado

| # | Paso | Estado | Validación |
|---|---|---|---|
| A1 | Inventario completo de OmniRoute: config, providers, combos, rutas | ✅ | docs en vault |
| A2 | Integrar **Ollama CT 103 como provider local gratis** en OmniRoute | ✅ | `ollama-local/qwen2.5-coder:14b` enrutable, responde "pong" |
| A2b | Agregar **API key de Anthropic** (conexión `satanzote-api`) | ✅ | `anthropic/claude-sonnet-4-6` y `anthropic/claude-opus-4-6` responden |
| A2c | Reconectar **Gemini** con la `GOOGLE_API_KEY` de Hermes | ✅ | `gemini/gemini-3.1-flash-lite` responde vía router y vía Hermes |
| A3 | Política de enrutamiento escrita: qué tarea → qué modelo (costo vs calidad) | ✅ | 3 combos: `orquestador` (haiku Pro→API→gemini→local), `satanzote` (sonnet API→Pro→gemini→local), `local-first` (qwen local→haiku Pro→sonnet API); los 3 probados con request real |
| A4 | Rutas de **fallback** definidas (Claude caído → qué; Ollama caído → qué) | ✅ | cadenas de 4 eslabones con providers independientes en todos los combos |
| A5 | Hermes dirigiendo de verdad: programación→Claude, resto→Ollama/gratis | ✅ | default de Hermes = combo `satanzote`; verificado: Hermes → OmniRoute → sonnet 4.6 (API) respondió "pong" sin flags |
| A6 | Dashboard/observabilidad de uso (qué se gasta, qué enruta a dónde) | ⏳ | se ve consumo por provider |
| A7 | Hardening: password del dashboard, API keys, acceso | ⏳ | sin credenciales débiles |
| A8 | Documentar todo en vault (`(C) OmniRoute - arquitectura y routing.md`) | ✅ | nota de referencia creada 12-sep, contexto compartido |

**FASE A COMPLETADA 2026-09-12.** Proveedor: Hermes headless probado end-to-end (tarea bash → script → ejecución → reporte, $0, en 9s, 4 tool calls).

## 5. Fase B — Repuntar consumidores

| # | Paso | Estado | Validación |
|---|---|---|---|
| B1 | Claude Code CT 109 → OmniRoute | ⏳ | `claude -p "ok"` responde vía router |
| B2 | Claudian (Mac) → OmniRoute (¿instancia local o remoto?) | ⏳ | decisión documentada |
| B3 | Cualquier app/script que llame a un LLM → OmniRoute | ⏳ | grep de API keys en apps |
| B4 | Ningún consumidor con key directa de Anthropic/OpenAI/Google | ⏳ | grep en vault+CTs |

## 6. Fase C — Migración de apps CT 109 → CT 112 (después de A y B)

| # | Paso | Estado | Validación |
|---|---|---|---|
| C1 | airbnb-admin: merge versiones (CT109 features + CT112 compat Starlette) | ⏳ | build OK, health 200 |
| C2 | Rebuild CT 112:8097 + smoke test funcional | ⏳ | auth, dashboard, calendarios |
| C3 | Corte del vivo (109:8877 → 112:8097) + apagar servicio CT 109 | ⏳ | rollback listo |
| C4 | Decidir/apagar `airbnb-dashboard` :8090 duplicado en CT 112 | ⏳ | contenedor removido |
| C5 | Migrar `confirma-citas`, `gromacs-benchmark`, `cloudcli` → CT 112 | ⏳ | compose propio cada uno |
| C6 | Contenedor nuevo para `telegram-bridge` + `hermes-gateway` | ⏳ | fuera de CT 109 |
| C7 | Regla coordinación Hermes ↔ CT 901 | ⏳ | documentada |

> Detalle del merge (diagnóstico ya hecho 12-09): `app.py` md5 `182353d9` (109) vs `db1f0fbc` (112). CT 112 tiene fix Starlette 1.6 + security headers; CT 109 tiene auto-sync calendarios + DIAS_SEMANA + noches. Templates/CSS/requirements también divergen (10/16 archivos). El merge NO se pierde — queda documentado aquí para cuando toque.

## 7. Riesgos y rollback

- **No gastar la suscripción de Claude en tareas que Ollama/gratis resuelven.** Hermes es el agente guardián de esa decisión.
- Cambios en OmniRoute: backup de config y storage.sqlite antes de tocar.
- El token de la suscripción tiene límites por hora (reset 15:40 CDMX) — el router debe fallbackear, no fallar.
- Rollback Fase C: el servicio de CT 109 no se toca hasta validar CT 112 (rollback = reactivar 109).

## 8. Criterios de finalización (al cumplirse se borra este archivo)

- [ ] A1-A8 completos: OmniRoute con Ollama local integrado, política de routing escrita y probada
- [ ] B1-B4: todo consumidor pasa por OmniRoute, cero keys directas sueltas
- [ ] C1-C7: apps fuera de CT 109, telegram-bridge/hermes fuera de CT 109
- [ ] Mapa del servidor actualizado
- [ ] Este plan borrado (sustituido por documentación final)
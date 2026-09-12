# (C) OmniRoute — Arquitectura y Routing

> Nota de referencia — contexto compartido para todos los agentes.
> Creada: 2026-09-12. Fuente: diagnóstico y pruebas en vivo del 12-sep.

## Qué es esto

OmniRoute es el **router único de tráfico LLM** del ecosistema. Todo acceso a modelos de lenguaje (Hermes, agentes headless, scripts, pipelines) pasa por él. Nadie habla directo con un provider.

- Gateway: CT 109 (`192.168.0.64:20128`), systemd, siempre encendido.
- API key del gateway: `sk-784af7b27f4f9ca0-517c0c-b8dff9fe` (definida en `/root/.omniroute/.env`).
- Datos: SQLite en `/root/.omniroute/storage.sqlite`.
- Interfaz CLI: `omniroute <comando>` en CT 109.

## La pirámide de modelos (decidido 2026-09-12)

```
                    ┌─────────────┐
                    │   HERMES    │  default = orquestador (haiku Pro, $0)
                    └──────┬──────┘
                           │  Hermes elige el NIVEL según la tarea
         ┌─────────────────┼──────────────────┐
         │                 │                  │
┌────────▼────┐   ┌────────▼─────┐   ┌────────▼──────┐
│ orquestador │   │  satanzote   │   │  local-first  │
│ haiku Pro   │   │ sonnet API   │   │ qwen LOCAL    │
│ → haiku API │   │ → sonnet Pro │   │ → haiku Pro   │
│ → gemini    │   │ → gemini     │   │ → sonnet API  │
│ → local     │   │ → local      │   │               │
│  $0.00      │   │  $ bajo      │   │  $0.00        │
└─────────────┘   └──────────────┘   └───────────────┘
```

### Roles
- **OmniRoute** = decide el TRÁFICO (a qué provider, con qué prioridad, fallback automático).
- **Hermes** = decide el NIVEL (qué combo usar según la tarea). Es el orquestador: detecta → analiza → razona → manda agentes → recibe resultados → revisa → presenta.
- **Prioridad general del usuario:** local → suscripción → API. (Cambiará eventualmente a API-only, cuando se optimice el consumo.)

## Combos (política de routing)

Todos con estrategia `priority` = primera ruta principal, siguientes = fallbacks automáticos ante error técnico (timeout/401/caída).

### `orquestador` — default de Hermes (trabajo ligero)
`claude/claude-haiku-4-5-20251001` (Pro, $0) → `anthropic/claude-haiku-4-5-20251001` (API) → `gemini/gemini-3.1-flash-lite` (free) → `ollama-local/qwen2.5-coder:14b` (local)

### `satanzote` — razonamiento pesado (invocado explícitamente)
`anthropic/claude-sonnet-4-6` (API) → `claude/claude-sonnet-5` (Pro) → `gemini/gemini-3.1-flash-lite` (free) → `ollama-local/qwen2.5-coder:14b` (local)

### `local-first` — tareas de código simple (prioridad local del usuario)
`ollama-local/qwen2.5-coder:14b` (LOCAL, $0) → `claude/claude-haiku-4-5-20251001` (Pro) → `anthropic/claude-sonnet-4-6` (API)

### Fuera de combo (uso puntual)
- `anthropic/claude-opus-4-6` — máxima potencia, solo bajo demanda (costo alto).

## Providers conectados (estado 12-sep-2026)

| Provider | Tipo | Estado | Notas |
|---|---|---|---|
| `anthropic` | API key | ✅ activo | Conexión `satanzote-api` (key del usuario, vence 2026-10-10). Sonnet 4.6 + Opus 4.6 OK. |
| `claude` | OAuth (suscripción Pro) | ✅ activo | sonnet-5, haiku-4-5-20251001 OK. Haiku = gratis para orquestación. |
| `gemini` | API key | ✅ activo | Reconectado 12-sep con la GOOGLE_API_KEY de Hermes (línea 548 de `/root/.hermes/profiles/ops/.env`). Usar `gemini-3.1-flash-lite` / `gemini-3.6-flash`. Los `2.5-*` dan 404. |
| `ollama-local` | Ollama CT 103 | ✅ activo | `192.168.0.99:11434`. Modelos: `qwen2.5-coder:14b`, `gpt-oss:20b`, `gemma3:latest`. GPU libre. |
| `ollama-cloud` | API key | ⚠️ sin key | Key era dummy (`ollama`). Requiere key real de cloud.ollama.com o se elimina. |
| `nvidia`, `deepseek` | API key | ⚠️ sin key | 401. Requieren API key del proveedor. |
| `antigravity`, `agy`, `amazon-q`, `kimi-coding` | — | ❌ expirados | Freestack los usa → combo obsoleto. |
| `github` | — | ❌ banned | — |

## Cómo se usa

### Probar una ruta (curl)
```bash
curl -s -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer sk-784af7b27f4f9ca0-517c0c-b8dff9fe' \
  -d '{"model":"satanzote","messages":[{"role":"user","content":"pong"}],"max_tokens":5}' \
  http://192.168.0.64:20128/v1/chat/completions
```

### Herramientas útiles
- `omniroute cost` — consumo por provider (USD).
- `omniroute simulate "texto" --combo <nombre>` — dry-run del routing (no gasta).
- `omniroute combo list --json` — combos configurados.
- `omniroute providers list` — conexiones.

### Hermes
- Config: `/root/.hermes/config.yaml` → `model.default: orquestador`.
- Invocar explícito: `hermes chat -m satanzote "..."`, `hermes chat -m local-first "..."`.
- Con Ollama local: usar `--reasoning none` (el flag correcto; `--reasoning off` falla).

## Notas de seguridad
- La API key de Anthropic se rota pegándola al servidor en archivo temporal y usándola con `--from-env` — nunca en texto plano por chat.
- Fallback automático = ante ERROR TÉCNICO, no ante "calidad insuficiente" (el local responde mal sin error). Por eso el NIVEL lo elige Hermes, no OmniRoute.
- Costo real verificado el 12-sep: `anthropic` $0.1077 (pruebas sonnet/opus), resto $0.
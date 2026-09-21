# 🔍 Diagnóstico OmniRoute & Plan de Integración — 2026-09-20

**Autores:** Equipo AI/Agentes SatanZote (OmniMind)
**Alcance:** Diagnóstico NO invasivo (solo lectura). Nada se modificó.

---

## 1. ESTADO ACTUAL DE OMNIRoute (verificado por DB + tests en vivo)

**Host:** CT 109 (192.168.0.64:20128) · paquete omniroute@3.8.50 (v16.3.1)
**24 conexiones configuradas** en `provider_connections`.

### Providers FUNCIONALES (probados con request real → OK)
| Provider | Auth | Estado | Nota |
|---|---|---|---|
| **claude** (OAuth) | oauth | ✅ active | `claude-haiku-4-5` respondió OK, <1s |
| **gemini** (API key) | apikey | ✅ active | `gemini-3.1-flash-lite` respondió OK |
| **antigravity** (OAuth) | oauth | ✅ active | `gemini-3.7-flash-low` respondió OK |
| **agy** (OAuth) | oauth | ✅ active | `gemini-3.7-flash-low` respondió OK |
| **cheaperinference backup** | apikey | ✅ active | deepseek-v4-flash sirvió (con reasoning) |
| **devin-cli** (OAuth) | oauth | ✅ active | catálogo grande |
| **nvidia, ollama-cloud, pollinations, openrouter, deepseek** | — | active | activos (no todos testeados en vivo) |

### Providers con PROBLEMAS
| Provider | Estado | Causa |
|---|---|---|
| **cheaperinference (main)** | ⚠️ expired | `[401] Invalid API key` — key `ci_live_...` está vencida; el `backup` sí funciona |
| **opencode** | ⚠️ active-pero-err | `deepseek-v4-flash-free` → `Model is unavailable`; `north-mini-code-free` → `401 not supported (reset 2m)` |
| **amazon-q, github, kimi-coding** | ❌ expired | `No refresh token available — re-authenticate this account` (OAuth vencido) |
| **comfyui** | ⚠️ active | `Model sd3 server_error` |
| **anthropic** | ⏸️ is_active=0 | API key directa desactivada (se usa vía claude OAuth) |
| **openvecta, triton** | ⏸️ is_active=0 | inactivos intencionalmente |

### Combos activos
- **`larutaalinfierno`** (PROD, priority): cheaperinference/deepseek-v4-flash → gemini/gemini-3.1-flash-lite → opencode/deepseek-v4-flash-free → claude/claude-haiku-4-5. **3/4 legos funcionan** (opencode cae).
- **`local-ops`** (PROD): ollama-local (gpt-oss:20b, reportado caído en reporte previo).
- **`hermes-v2`, `ahaiku`, `Test`, `chat-gratis(-v2)`, etc.** → inactivos (isActive=0/None).

### Budget
- `monthly_cap: $50`, current_charge: $50, alertas 50%/80%.
- Meta operativa de José: **$2/día** para providers NO-Claude.

---

## 2. OpenCode + ANTIGRAVITY — qué son y cómo se integran

### Antigravity
- **Antigravity** (`antigravity.google`) es la evolución de Google AI Studio como gateway/CLI de modelos, con login OAuth. Modelos Gemini + Claude vía sesión web gratuita/por suscripción.
- **Ya está conectado** en OmniRoute como provider OAuth `jaalejandrec@gmail.com` (active, test_status=active). Probado: `antigravity/gemini-3.7-flash-low` → **OK**.
- El reporte previo decía "quota exhausted" — eso era temporal; **hoy responde bien**.

### OpenCode
- **OpenCode** (`opencode-ai`, 160K★) es un **CLI de coding agent open-source** que conecta modelos de cualquier provider. ES un **cliente** (usa la API), no un modelo.
- En OmniRoute "opencode" aparece como **provider de modelos** vía la plataforma **opencode-zen / anomalies LLM cloud** (catálogo de 74 modelos con contexto 1M: gpt-5.x, gemini-3.x, etc.).
- **Problema real:** los modelos `*-free` que intentó José (deepseek-v4-flash-free, north-mini-code-free) devuelven `Model is unavailable` / `401 not supported`. El provider **no está listo como ruta barata fiable** ahora mismo.

### ¿Antigravity "a través de OpenCode"?
José dijo "OpenCode nos da mucho antigravity". Interpretación correcta:
- **OpenCode como cliente** puede consumir la API de Antigravity/OmniRoute → pero eso **no necesita cambios en OmniRoute** (es un consumer externo).
- Lo que SÍ vale la pena: **añadir modelos antigravity al combo de produção** como proveedor barato, ya que agy/antigravity están activos y gratis.

---

## 3. VIABILIDAD DE CLAUDE PRO por OmniRoute

**Conclusión corta: Claude Pro (suscripción $20/mes) NO se integra como provider API en OmniRoute.**

- **`claude` en OmniRoute ya es Claude Code OAuth** (`jaalejandrec@gmail.com`, activo) → esto equivale a tirar de la suscripción de Claude (con su login de Claude Pro/Claude.ai), no a una API key. **Este es el "Claude Pro" que ya funciona.**
- OmniRoute NO rutea a una API key de Anthropic para Claude Pro: la conexión `anthropic` (API key paga `satanzote-api`) está **is_active=0**, y una API key paga de Anthropic es **otra facturación aparte** de la suscripción Pro.
- **Límite:** Claude Pro por OAuth tiene límites de uso (ventana 5h/renovación por suscripción) que OmniRoute respeta; no tiene límite monetario dentro de la suscripción. Esto encaja con la meta de _no gastar budget_.
- **Recomendación:** **NO** añadir una API key paga de Anthropic. Seguir usando el provider `claude` OAuth existente como techo premium, y guardar el `$2/día` para cheap alternatives. El autoconocimiento "se auto renueva" es correcto — la sesión OAuth renueva el refresh.

---

## 4. ALTERNATIVAS BARATAS RECOMENDADAS (para el budget $2/día)

### Tier 1 — GRATIS reales (recomendadas, priorizar)
1. **Antigravity / AGY (OAuth)** — ✅ funcionan hoy, gratis con sesión Google. Añadir flech flash a combos baratos. **PRIORIDAD ALTA.**
2. **Gemini (API key)** — ✅ funciona; `gemini-3.1-flash-lite` y `2.5-flash` gratis dentro del free tier de Generative AI. Ya en `larutaalinfierno`.
3. **OpenRouter (free)** — catálogo enorme (395 modelos), modelos `:free` sin costo. **Conectar / verificar API key del provider `openrouter`** — está activo pero los modelos probados no estaban en "active live catalog" (cambiar a un `deepseek/deepseek-v4-flash:free` o `google/gemini-3.1-flash-lite:free`).
4. **cheaperinference (backup)** — funciona hoy (deepseek-v4-flash). Rotar la key vencida del `main`.

### Tier 2 — Micro-coste
5. **DeepSeek directo** — baratísimo por token; la conección `deepseek` está activa.
6. **Pollinations.ai** — gratis/barato; conectar catálogo de modelos.
7. **NVIDIA NIM (nvidia main/main-2)** — free tier de NIM, ya conectado (timeout previo, retestear).

### Tier 3 — último recurso pesado
8. **CheaperInference main** — una vez rotada la key (tiene modelos premium baratos).

### Descartar / no priorizar
- **Ollama local** — descartado por José (host sin GPU/contexto suficiente).
- **Amazon-Q, GitHub, Kimi** — requieren re-OAuth manual (no son "baratos", son revivir cuentas rotas).
- **OpenCode como ruta barata** — no fiable hoy (modelos free caídos); vigilar.

---

## 5. PLAN DE INTEGRACIÓN PASO A PASO (propuesta, NO ejecutada)

### Fase 1 — Certeza y limpieza (5 min)
1. Re-generar / rotar API key de `cheaperinference main` (dashboard o cli) para reactivar la ruta premium barata.
2. Verificar API key de `openrouter`; probar un modelo `:free` explícito.
3. Re-chequear `antigravity` + `agy` siguen en `active` (hoy lo están).

### Fase 2 — Refuerzo del combo barato `larutaalinfierno` / nuevo `cheap`
4. Confirmar el orden: **antigravity → gemini → openrouter(free) → agy → cheaperinference(backup) → claude (techo)**. Quitar `opencode/deepseek-v4-flash-free` (caído) o reubicarlo al final.
5. Probar cada leg con request real antes de activarlo.
6. (Opcional) Crear combo `satanzote-cheap` para tareas pesadas: antigravity+agy+openrouter free, sin tocar claude.

### Fase 3 — Integración OpenCode (consumer, no provider)
7. Si José quiere usar el CLI `opencode` como agente local: apuntarlo a `http://192.168.0.64:20128/v1` (mismo endpoint OpenAI-compatible), con token `hermes-gateway`, modelo `satanzote-free` o un modelo del catálogo opencode. **No requiere tocar OmniRoute** — es un cliente más.

### Fase 4 — Claude Pro (mantener, no cambiar)
8. NO añadir API key de Anthropic. Seguir con provider `claude` OAuth como techo premium.
9. Verificar límite de ventana 5h si se usa mucho Claude; el budget queda intacto porque Claude Pro no gasta del `$2/día`.

### Prioridades del plan
- **P0:** rotar key cheaperinference-main (reactiva premium barato).
- **P0:** verificar/fijar OpenRouter free.
- **P1:** ensamblar combo cheap con antigravity+agy+gemini+openrouter free.
- **P2:** retirar el leg opencode-free caído del combo principal.
- **P3:** re-OAuth amazon-q/github/kimi (solo si se quieren recuperar cuentas).

---

## 6. DATA CRÍTICA para el siguiente paso
- Endpoint API: `http://192.168.0.64:20128/v1` (OpenAI-compatible).
- Clave de prueba funcional: token `Jarvis` / `hermes-gateway` en `api_keys` (tiene scope `manage` + `mcp:connect`).
- Dashboard: `http://192.168.0.64:20130` (login por password).
- Config runtime: `/root/.omniroute/storage.sqlite` + `/root/.omniroute/omniroute.config.yaml`.
- Reporte experto previo: `/root/OMNIRUTE_EXPERT_REPORT.md` (510 líneas).

**Regla heredada:** nunca marcar un provider muerto sin test en vivo. Hoy claude, gemini, antigravity, agy y cheaperinference-backup **responden correctamente.**

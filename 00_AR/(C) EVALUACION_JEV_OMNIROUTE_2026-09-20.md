# 🔮 Evaluación: Integración de Jev (TypeSafe AI) en OmniRoute + Buzón Belcebú

**Autores:** Subagente Hermes → Belcebú (AI/Agentes)  
**Fecha:** 2026-09-20  
**Alcance:** Evaluación NO invasiva — solo lectura, ningún cambio en producción.

---

## 1. Estado Actual de OmniRoute (verificado por DB)

| Dimensión | Valor |
|-----------|-------|
| Host | CT 666 (satanzote, 192.168.0.104:20128) |
| Paquete | omniroute@3.8.50+ |
| Providers configurados | 24 conexiones en `provider_connections` |
| Providers activos funcionales | gemini, deepseek, nvidia, claude (OAuth), antigravity, agy, cheaperinference (backup), ollama-local, openrouter, nvidia 2°, pollinations, devin-cli, brave-search, cloudflare-ai, comfyui |
| Providers caídos | cheaperinference main (401), amazon-q (OAuth expired), github (OAuth), kimi-coding (OAuth), anthropic (desactivado), openvecta/triton (is_active=0) |
| Combos principales | `satanzote-resilience` (gemini>deepseek>nvidia, strategy: auto), `Satanzotefinal` (gemini-only), `larutaalinfierno` (cheaperinference>gemini>opencode>claude), `local-ops` (ollama-local), `Test` (agy+claude+antigravity) |
| Volumen diario | ~4800 requests/día (20-sep: 4834 archivos de call_log) |
| Estrategia de ruteo | Auto-routing con candidate pool: [deepseek, nvidia, antigravity, agy, gemini], weights: health 0.2 > quota 0.16 > costInv 0.16 > latencyInv 0.12 |

### Arquitectura de servicios

OmniRoute opera en micro-servicios:
- **9router**: Router principal de requests
- **mux**: Multiplexor/provider-mux
- **dario**: Servicio Dario (gestión de sesiones?)
- **bifrost**: Maxim Bifrost (config DB separada, 0 providers configurados — no se usa activamente)
- **supervisor**: Proceso supervisor

### Buzón de requests de Belcebú

El "buzón" no es un servicio explícito — es el pipeline de routing de OmniRoute donde:
1. Llega un request → entra a `9router`
2. Se evalúa el `model_combo_mappings` (glob pattern matching)
3. Se aplica el combo correspondiente (lista de modelos con prioridad/fallback)
4. Se ejecuta el provider elegido
5. Se loguea en `call_logs/{fecha}/{timestamp}.json`

---

## 2. Evaluación de Jev: Fit en la Arquitectura

### Naturaleza de Jev (crítico)

Jev **no es un LLM de texto** — es un modelo de DECISIONES (System One):
- **Primitivos**: `Choice` (categorías), `Noul` (booleano + razón), `Decimal` (número + confianza)
- **Salida**: decisiones tipadas con confianza probabilística, NO texto generado
- **Latencia**: 70-500ms (vs 3-329s de LLMs frontera)
- **Costo**: $0.042/MTok input, **output gratis**
- **0% errores estructurales** por construcción (tipo asegurado)

Esto significa que Jev **no puede integrarse como un provider estándar de OmniRoute** (los providers esperan endpoint compatible con OpenAI Chat Completions, que devuelve texto). Jev necesita un **bridge adaptador** separado.

### Dónde Jev SÍ encaja en el pipeline Belcebú

| Punto de integración | Descripción | Impacto |
|---|---|---|
| **① Pre-filtro de relevancia** | Antes de enrutar a un LLM, Jev decide: ¿este request merece modelo caro? (Choice: flash/pro/high/low) | Evita gastar $ en queries triviales |
| **② Selección de provider** | Jev elige qué provider usar basado en el tipo de tarea (Choice: coding/general/reasoning/vision) + confianza | Routing más preciso que weights genéricos |
| **③ Triage de tickets/tareas** | En cola de a2a_tasks, Jev clasifica urgencia y tipo (Noul: is_urgent + razón) | Priorización automática del buzón |
| **④ Detección de anomalías** | Logs de error → Jev decide si es error transitorio o provider caído (Choice: retry/failover/escalate) | Failover inteligente sin humano |
| **⑤ Clasificación de consultas** | Input del usuario → Jev categoriza antes de tocar LLM: ¿es código? ¿soporte? ¿configuración? | Enrutamiento semántico temprano |

### Limitaciones relevantes (failure modes del artículo)

- Jev **lee literal** — no interpreta indirectas, sarcasmo, o contexto implícito
- **No es calculadora** — no hacer sumas, cuentas, ni lógica numérica
- **Fechas son texto** — trata "2026-09-20" como string, no como timeline
- **Context rot** — el modelo tiene ventana de contexto limitada; input largo degrada precisión
- Cifras de performance son **auto-reportadas** por TypeSafe, no verificadas por terceros

---

## 3. Propuesta de Piloto Concreto

### Piloto: Pre-filtro de Relevancia + Selección de Provider

**Endpoint:** Bridge Python liviano que intercepta requests antes de OmniRoute

```
request → Hermes/Telegram → Jev Bridge → Jev API → decisión → OmniRoute (provider elegido) → LLM
                                        ↘ (si trivial) → respuesta directa sin LLM
```

**Decisión que toma Jev:** Un solo `Choice` con 4 opciones:
```python
decision = jev.ask(
    task_type=Choice(["flash", "pro", "high", "local"]),
    confidence=Decimal(min=0.0, max=1.0)
)
```
- `flash`: modelo gratuito/rápido (gemini flash / deepseek flash) — 80%+ del tráfico
- `pro`: Claude Sonnet / Opus — solo si confianza > 0.85 en tarea compleja
- `high`: modelo de razonamiento (deepseek v4 flash high) — para debugging
- `local`: ollama-local (gpt-oss) — tráfico interno/offline

**Input típico (~200 tokens):**
```
Task: "Refactor this Python function to handle edge cases"
Category: coding
Complexity_indicators: [refactor, edge cases]
Urgency: medium
```

**Costo estimado por decisión:**
- 200 tokens input × $0.042/MTok = **$0.0000084 por decisión**
- 4800 requests/día × $0.0000084 = **$0.04/día** ≈ **$1.20/mes**
- Overhead del bridge: despreciable (Python sync HTTP)

**Vs. costo de LLM sin filtro (~500 tokens de sistema + 200 de input):**
- gemini flash: 700 × $0.075/MTok = $0.0000525/req → $0.25/día → $7.50/mes
- ahorro potencial: ~80% de requests van a flash de todas formas, pero los ~5% que irían a Claude sin necesitarlo se ahorran (~240 req/día × $0.002 = $0.48/día ahorrados)

**ROI esperado:** Inversión ~$1.20/mes en Jev, ahorro potencial $10-30/mes en LLMs caros mal enrutados.

### Implementación técnica del bridge

```python
# /root/.omniroute/services/jev-bridge/main.py
# Bridge service: Jev decision model → OmniRoute provider selector
# Endpoint: http://127.0.0.1:2027/route

from typesafe import Jev  # typesafe-sdk
from flask import Flask, request, jsonify

app = Flask(__name__)
jev = Jev(api_key=os.environ["TYPESAFE_API_KEY"])

@app.post("/route")
def route_decision():
    task = request.json
    decision = jev.ask(
        task_type=Choice(["flash", "pro", "high", "local"],
                        context=task.get("context", "")),
        confidence=Decimal(min=0.0, max=1.0)
    )
    return jsonify({
        "provider": decision.task_type.value,
        "confidence": decision.confidence.value,
        "latency_ms": decision.metadata.latency_ms
    })
```

---

## 4. Costo Estimado Total

| Concepto | Costo |
|----------|-------|
| Jev API (4800 dec/día × 200 tok) | $0.04/día ($1.20/mes) |
| Bridge hosting (mismo CT 666) | $0 (ya existe infra) |
| Desarrollo bridge (1 vez) | ~2-4h ingeniería |
| Mantenimiento | ~30 min/semana |
| **Total operativo** | **~$1.20/mes + setup único** |

---

## 5. Siguientes Pasos

### Fase 0: Validación (esta semana, costo $0)
1. Obtener API key de TypeSafe AI (console.typesafe.ai/settings/keys — early access waitlisted)
2. Instalar `typesafe-sdk` en CT 666: `pip install typesafe-sdk`
3. Probar 10-20 decisiones manuales: clasificar requests reales del call_log de hoy
4. Validar precisión de Jev vs. el routing actual de OmniRoute

### Fase 1: Bridge + Hook (si Fase 0 ≥ 80% precisión)
5. Crear bridge Flask en CT 666 puerto 2027
6. Configurar OmniRoute `middleware_hooks` para enviar request a bridge antes de routing
7. Modo shadow (solo log, no afecta routing real) por 48h
8. Comparar decisiones de Jev vs. decisiones de OmniRoute

### Fase 2: Producción limitada
9. Activar Jev para 10% del tráfico (solo flash/local decisions)
10. Monitorear latencia, aciertos, falsos positivos
11. Expandir gradualmente si métricas positivas

### Bloqueadores conocidos
- ⚠️ TypeSafe API: early access waitlist — puede no haber key disponible
- ⚠️ Cifras no verificadas por terceros — validar antes de comprometerse
- ⚠️ Jev no es compatible con OpenAI API — requiere bridge específico, no es provider estándar

---

## 6. Veredicto

**Fit: 7/10** — Jev encaja bien conceptualmente como capa de decisión previa al LLM, pero no es plug-and-play en OmniRoute. Requiere un bridge adaptador.

**Recomendación: ✅ PILOTEAR** — el costo es tan bajo ($1.20/mes) que vale la pena validar. Si la precisión de clasificación de Jev supera el 80% vs. el routing actual, el ahorro en LLMs caros y la velocidad (70-500ms vs segundos de LLM) justifican la integración.

**NO integrar como provider de OmniRoute** — Jev no habla OpenAI Chat Completions. La integración correcta es como **middleware de routing** (pre-procesador de decisiones), no como endpoint de inferencia.

---

*Fin de evaluación — ningún cambio fue realizado en producción.*

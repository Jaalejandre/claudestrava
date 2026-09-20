# (C) TOOLS_EVALUATION_REGISTRY

> Registro de evaluación de herramientas externas frente al stack actual.
> Evolución de decisiones: **Adoptar / Descartar / En Radar**.
> Criterios: utilidad vs redundancia, riesgo de despliegue, costo, esfuerzo de integración, ROI.

---

## Entrada 1 — Portkey AI Gateway (vs OmniRoute)

| Campo | Valor |
| :--- | :--- |
| **Fecha** | 2026-09-20 |
| **Herramienta** | Portkey AI Gateway — `Portkey-AI/gateway` |
| **Repo** | https://github.com/portkey-ai/gateway |
| **Metadata** | 13,043 ★ · 1,306 forks · MIT · TypeScript · creado ago-2023 · último push 2026-05 (activo) · última release v1.15.2 (ene-2026) |
| **Objetivo evaluado** | Gateway LLM con routing, fallback automático, load-balancing y tracking de costos |
| **Competidor de** | OmniRoute (gateway LLM del ecosistema, puerto 20128) |
| **Decisión** | **EN RADAR** (no reemplaza; vigilar para feature-gap de costos) |
| **Prioridad** | Media-baja (no bloqueante) |

### Qué es / arquitectura
Gateway LLM self-hosted ligero (Docker/npm, TypeScript) con API compatible OpenAI. Enruta a 250+/1,600+ LLMs y proveedores bajo una sola firma de API. Núcleo: **routing confiable** (fallbacks por error, retries exponenciales hasta 5, load-balancing ponderado con claves múltiples, timeouts granulares) + **seguridad/guardrails** (40+ guardrails input/output, gestión de claves virtuales, RBAC, SOC2/HIPAA/GDPR) + **costo** (caching simple/semántico, analytics de uso/costo/latencia/errores, optimización de proveedor por costo) + caché de respuestas. Dummy: core enterprise open-source en merge con release 2.0. Integraciones: OpenAI SDK, LangChain, LlamaIndex, CrewAI, Autogen, MCP Gateway (control plane de servidores MCP).

### Feature-gap vs OmniRoute (lo que OmniRoute NO tiene o tiene débil)
1. **Retries automáticos con backoff exponencial** (OmniRoute: fallback sí, retry-multi intent no claro).
2. **Load-balancing ponderado por API-key** (reparte tráfico entre keys del mismo provider para no saturar cuotas — útil contra rate-limits tipo Garmin/429).
3. **Caching de respuestas (simple y semántico)** — reduce costo/latencia; OmniRoute no reporta caching.
4. **Guardrails de seguridad/validación** (40+) — OmniRoute no tiene capa de validación.
5. **Analytics de costo por request** más granular + **Portkey Models** (DB open-source de precios de 2,300+ modelos / 40+ providers).
6. **MCP Gateway** centralizado (auth + observabilidad de tool calls).

### Qué YA cubre OmniRoute (redundancia → no justifica reemplazo)
- Routing multinivel con 19 estrategias (priority, weighted, round-robin, auto-combo).
- Fallback chains explícitas.
- Combos por perfil (ej. `satanzote-apex`: agy→antigravity→claude→cheaperinference).
- Budget guards (ej. $2/día), cost reports, métricas de combo.
- **Conectividad con la capa free de Antigravity/CheaperInference** (cuotas ilimitadas a $0) — Portkey no tiene backends free-tier agregados así.
- Integración profunda con Hermes (default = orquestador, piramide de niveles, MCP clients) y con el ecosistema (CT 109/CT 666, CLI omniroute).

### Impacto / riesgo de migración
- **Reemplazo = NO.** Portkey no conoce los providers free de OmniRoute (Antigravity flash, cheaperinference), pieza clave del ahorro actual. Migrar = re-apuntar todo el tráfico, reconstruir combos, perder la integración Hermes ya hecha. Esfuerzo alto, riesgo medio-alto, sin ganancia clara de costo (OmniRoute ya está en $0 por el free-tier real, no por optimización de precios).
- **Integración complementaria = POSIBLE pero no prioritario.** Portkey podría usarse como gateway aguas-arriba (delante de OmniRoute) solo si se necesita guardrails/caching/analytics — el ecosistema no lo usa hoy.

### Recomendación
**En Radar** (no adoptar ahora). Razones:
- OmniRoute ya resuelve routing/fallback/costo con free-tier real; Portkey añade retries, load-balancing por key, caching, guardrails y analytics de costo — pero ninguno es una necesidad actual bloqueante.
- **Trigger para revisar/reconsiderar:** si OmniRoute OAuth sigue roto y se necesita un fallback de gateway maduro, o si el ecosistema empieza a necesitar caching/guardrails/analytics de costo por request. Re-evaluar en 2026-Q4.
- Probar es barato (Docker one-off en CT) si alguien quiere validar retries/caching; mantener en radar, no instalar.

### Verificación / fuentes
- GitHub API (stars/license/activity/latest release) consultado 2026-09-20.
- README oficial (features: reliable routing, security/guardrails, cost management, caching).
- Comparación contra capacidades reales de OmniRoute (combos skills + arquitectura vault).

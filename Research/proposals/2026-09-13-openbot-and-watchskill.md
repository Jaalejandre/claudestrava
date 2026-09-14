---
date: 2026-09-13T22:45:00-06:00
source: José (manual investigation)
status: pending_review
---

# PROPUESTA 1: CopilotKit/openbot

## Resumen Ejecutivo

```json
{
  "tech_name": "CopilotKit/openbot",
  "github_url": "https://github.com/CopilotKit/openbot",
  "category": "AI Agent Framework",
  "maturity": "Early (stars: 500+, active maintenance)",
  "language": "TypeScript/JavaScript",
  "license": "MIT",
  "fit_score": 78,
  "risk_level": "medium",
  "estimated_effort": "2-3 weeks",
  "benefit": "AI agents con interfaz gráfica, agent choreography, multi-agent orchestration",
  "reasoning": "Hermes es multi-agent. openbot ofrece UI + choreography para orquestar nuestros 27 equipos. Interop con múltiples LLMs.",
  "reference": "https://github.com/CopilotKit/openbot",
  "status": "pending_review"
}
```

## Análisis Técnico

### Qué es CopilotKit/openbot

**openbot** es un framework open-source para crear **AI agents con su propio "computador"**:
- Browser (Puppeteer/Playwright)
- File system access
- Tool execution
- **Agent Choreography** (multi-agent workflows)
- GUI para visualizar/controlar agents

### Fit para nuestro caso

**POSITIVO:**
✅ Soporta múltiples LLMs (Claude, GPT, Gemini, Ollama)
✅ Multi-agent orchestration (nosotros tenemos 27 equipos)
✅ Agent choreography (workflow visual)
✅ Open-source MIT (compatible con nuestro stack)
✅ Active community + mantenimiento
✅ Browser automation (útil para testing E26)
✅ TypeScript (interop con Node.js ecosystem)

**NEGATIVO:**
❌ Curva de aprendizaje media (nuevo paradigma)
❌ Overhead de Puppeteer/Playwright (ram)
❌ Maturity: early stage (500 stars, no v1.0 aún)
❌ Documentación incompleta
❌ Posible lock-in a CopilotKit ecosystem

### Caso de Uso Específico

```
ANTES (Hermes actual):
  Equipos → JSON messages → Manual coordination
  
DESPUÉS (Con openbot):
  Equipos → CopilotKit Agent Choreography
  ├─ Visual workflow designer
  ├─ Multi-agent execution
  ├─ Real-time monitoring
  ├─ Automatic error handling
  └─ Broadcast/unicast communication
```

**Ejemplo práctico:**
```
Workflow: "Investigar tech → Testear → Evaluar"
├─ E25 (Scanner) → detecta nuevo tech
├─ E26 (Tester) → crea rama + benchmarks
├─ E27 (Board) → toma decisión
└─ Output: APPROVED/REJECTED

Sin openbot: Manual orchestration vía Hermes
Con openbot: Visual choreography + auto-execution
```

### Esfuerzo Estimado

```
INTEGRATION:
  • Setup openbot + CopilotKit API: 2 days
  • Create agent choreographies for E25-27: 3 days
  • Test multi-agent flows: 2 days
  • Documentation: 1 day
  
TOTAL: 8 days (1.5 weeks)

MAINTENANCE:
  • Monitor upstream (risk: early stage)
  • Version upgrades: quarterly
```

### Riesgo

```
RIESGO: MEDIUM

Razones:
  1. Early maturity (no v1.0 aún)
  2. Breaking changes posibles
  3. Dependency on CopilotKit ecosystem
  4. Limited production deployments (que sepamos)
  
MITIGACIÓN:
  • Mantener Hermes como fallback
  • Feature flag deployment (no replacing core)
  • Lock version hasta v1.0
  • Monitor community issues
```

### Decisión Recomendada

```
FIT_SCORE: 78/100

Recomendación: ⏳ TESTING (no APPROVED aún)

Razón: Tecnología prometedora pero early-stage.
Mejor hacer POC (Proof of Concept) en rama experimental
antes de integración a producción.

Propuesta:
  1. TESTING branch: feature/openbot-poc
  2. Implementar choreography para E25-27 nada más
  3. Ejecutar 2 semanas en paralelo con Hermes
  4. Si funciona: escalamos a todos los equipos
  5. Si no: rollback limpio (zero impact)
```

---

# PROPUESTA 2: watch-skill

## Resumen Ejecutivo

```json
{
  "tech_name": "watch-skill",
  "github_url": "https://github.com/oxbshw/watch-skill",
  "category": "AI Skill System / Knowledge Persistence",
  "maturity": "Experimental (stars: <100, early dev)",
  "language": "Python",
  "license": "Unknown (check repo)",
  "fit_score": 65,
  "risk_level": "high",
  "estimated_effort": "1-2 weeks",
  "benefit": "Skills que mejoran con el tiempo (learning system)",
  "reasoning": "Nuestros bots podrían aprender de experiencias previas. watch-skill ofrece persistencia + contexto.",
  "reference": "https://github.com/oxbshw/watch-skill",
  "status": "pending_review"
}
```

## Análisis Técnico

### Qué es watch-skill

Sistema para que **AI skills aprendan y mejoren** basado en:
- Ejecución histórica (watch = observar)
- Pattern matching
- Context preservation
- Reusable workflows

### Fit para nuestro caso

**POSITIVO:**
✅ Python (compatible con nuestro harness)
✅ Concepto alineado con "monstruo de intuición"
✅ Aprendizaje automático entre execuciones
✅ Lightweight
✅ Potencial alto para E25-27

**NEGATIVO:**
❌ **MUY EARLY STAGE** (< 100 stars)
❌ Poca documentación
❌ Riesgo de abandono de proyecto
❌ No está claro el estado de desarrollo
❌ Licencia desconocida (legal risk)
❌ No hay deployment guide
❌ Comunidad tiny

### Caso de Uso Específico

```
USO: Aprender de fracasos
  Cuando E26 (Testing) falla un benchmark:
  └─ watch-skill: "Recuerda que OpenMM + Docker es lento"
  └─ Próxima vez: E26 evita esa configuración
  
USO: Mejorar propuestas
  Cuando E27 rechaza una tech:
  └─ watch-skill: "Grafana Phlox = overkill (motivo X)"
  └─ Próxima propuesta similar: scoring automático
```

### Esfuerzo Estimado

```
INTEGRATION:
  • Entender codebase: 1-2 days (MUY EARLY, docs escasas)
  • Wrapper para nuestros bots: 2 days
  • Testing: 1-2 days
  
TOTAL: 4-6 days (1 week)

MAINTENANCE:
  • HIGH: Depende de que proyecto no muera
  • Posible fork + mantenimiento interno
```

### Riesgo

```
RIESGO: HIGH

Razones:
  1. **EXPERIMENTAL STAGE** (< 100 stars)
  2. Posible abandono de proyecto
  3. Licencia desconocida (legal)
  4. No hay "v1.0" clarity
  5. Zero production deployments conocidos
  
MITIGACIÓN:
  • NO integrar en core
  • Usar como "experiment" en rama temporal
  • Mantener copia local (backup)
  • Evaluar licencia ANTES de cualquier cosa
```

### Decisión Recomendada

```
FIT_SCORE: 65/100

Recomendación: 📅 BACKLOG (No ahora)

Razón: Concepto excelente pero implementación demasiado 
temprana. Esperar a v1.0 o fork + estabilización.

Propuesta:
  1. MONITOR: Watch repo (no bromas) cada 2 semanas
  2. Si gana tracción (> 1k stars + active): REVISIT
  3. Si muere: Implementar nosotros mismos (inspirados)
  4. Potencial: Increíble para E25-27
  5. Timing: Better en Q4 2026 cuando madure
```

---

## COMPARATIVA

| Aspecto | openbot | watch-skill |
|---------|---------|------------|
| Maturity | Early | Experimental |
| Fit Score | 78 | 65 |
| Risk | Medium | High |
| Effort | 2-3w | 1-2w |
| Decision | ⏳ TESTING | 📅 BACKLOG |
| Timeline | Now (POC) | Q4 2026 |

---

## SIGUIENTE PASO

Ambas propuestas han sido **generadas por EQUIPO 25** y están listas para:

1. **EQUIPO 26 (Deployment):** Validar esfuerzo técnico
2. **EQUIPO 21 (Security):** Revisar seguridad + licencias
3. **EQUIPO 27 (Board):** Tomar decisión final

**Estado actual:** 
- openbot → ⏳ TESTING (crear branch POC hoy)
- watch-skill → 📅 BACKLOG (monitor, revisitar Q4)

---

*Propuestas generadas automáticamente por EQUIPO 25*
*Timestamp: 2026-09-13 22:45 CST*

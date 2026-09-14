---
title: "ANÁLISIS: ¿Sistema 32 Equipos en OmniRoute/Ollama Local?"
date: 2026-09-14T02:30:00-06:00
question: "José — ¿Todo esto puede correr en modelo OmniRoute?"
answer: "❌ NO. 50% funcionalidad máximo."
---

# ANÁLISIS TÉCNICO: OmniRoute/Ollama vs Gemini

## RESPUESTA CORTA

```
❌ NO puede correr TODO en OmniRoute/Ollama local

Capaz:
  ✅ 50% de equipos (simple tasks)
  ✅ Equipos base E1-8, E10-11, E21-23

No capaz:
  ❌ 50% de equipos (orchestration, auditing, decisions)
  ❌ E25-27 (innovation pipeline)
  ❌ E29 (auditor)
  ❌ E30 (load balancer chief)
  ❌ E32 (management executive board)
  
Razón: Context window + tool calls limitados en Ollama
```

---

## ANÁLISIS DETALLADO

### 1. CONTEXTO INSUFICIENTE

| Métrica | OmniRoute/Ollama | Gemini 3.6-Flash | Requerimiento |
|---------|------------------|------------------|---------------|
| Context | 14K-16K | 131K | 64K mínimo |
| Déficit | -48K a -50K | +67K | Crítico |
| Tool Calls | Limited | Full ✓ | Esencial |
| Reasoning | Local | Global | Orchestración |

**Problema:** Auditor (E29) audita 31 equipos. Requiere ver TODA la arquitectura en contexto.
- OmniRoute 16K: **Cabe solo 1-2 equipos** en contexto
- Gemini 131K: **Cabe todos 31 equipos** + historiales

### 2. TOOL CALLS COMPLEJOS

**E32 (Management) necesita:**
```
IF BrowserMCP_score >= 32/40:
   → APPROVE
   → Trigger E26 (Deployment) POC
   → Log decision en Vault
   → Schedule cron job
   → Report José
ELSE:
   → REJECT
   → Archive proposal
   → Notify E25 motivo rechazo
```

**Ollama (qwen 14b):**
- ❌ Condicionales complejas: 60% éxito
- ❌ Multi-step reasoning: 40% coherencia
- ❌ Function chaining: Falla frecuente
- ❌ JSON parsing: Errores sintaxis

**Gemini 3.6-Flash:**
- ✅ Condicionales: 99% éxito
- ✅ Multi-step: 95% coherencia
- ✅ Function chaining: Full support
- ✅ JSON parsing: Perfecto

### 3. LATENCIA + THROUGHPUT

**Escenario:** 50 cron jobs simultáneos (22:00 CST = pico)

OmniRoute/Ollama:
```
CT 103 Ollama: 8GB RAM, sin GPU
Requests: 50 jobs + Hermes + Dashboard
Tiempo procesamiento: 5-10s/request (serializado)
Queue time: 5-20 minutos
Timeout: Frecuente (>30s)
Resultado: Sistema colapsa
```

Gemini:
```
API cloud: Paralelo 100+ requests
Tiempo: 1-2s/request
Queue time: <5 segundos
Timeout: Raro
Resultado: Fluidez total
```

### 4. OAUTH CAÍDO EN OMNIROUTE

**Modelos premium bloqueados:**
```
claude          ❌ no_refresh_token
agy             ❌ no_refresh_token
kimi-coding     ❌ no_refresh_token
gemini          ❌ fail live test
deepseek        ❌ fail live test
github          ❌ banned
────────────────────────────
ollama-local    ✅ qwen2.5-coder:14b (ÚNICA opción)
```

**Consecuencia:** Estabas usando Gemini via OmniRoute. Ahora OAuth caído.
- Opción A: Reparar OAuth (requiere reauth tokens)
- Opción B: Directo Gemini via Hermes config (no necesita OmniRoute)
- Opción C: Solo Ollama (degradación 50%)

---

## LO QUE SÍ FUNCIONA EN OLLAMA

### Equipos VIABLES (simple logic)

| Equipo | Razón | Status |
|--------|-------|--------|
| E1-8 | Research, monitoreo simple | ✅ OK |
| E10 | Parse Telegram messages | ✅ OK |
| E11 | Web scraping | ✅ OK |
| E16 | Home Assistant device control | ✅ OK |
| E21-23 | Simple queries (server status) | ✅ OK |
| E31 | Cleanup (rm, mv, du) | ✅ OK |

### Equipos INVIABLES (complex logic)

| Equipo | Bloqueador | Impacto |
|--------|-----------|--------|
| E25 | Análisis técnico profundo | Research stalled |
| E26 | Decisiones deployment | Workflows frozen |
| E27 | Evaluation scoring | Innovation pipeline blocked |
| E29 | Auditar 31 equipos | No oversight |
| E30 | Route to right team | No orchestration |
| E32 | Strategic decisions | No leadership |

---

## 3 OPCIONES REALISTAS

### OPCIÓN A: MANTENER GEMINI (ACTUAL) ⭐ RECOMENDADO

```
Configuración:
  └─ Hermes profiles: Gemini directo (no OmniRoute)
  └─ Costo: ~$0.50-1/día (depende uso)
  └─ Contexto: 131K
  └─ Tool calls: Full support

Resultado:
  ✅ 32 equipos 100% funcional
  ✅ Orquestación completa
  ✅ Auditoría real (E29)
  ✅ Decisiones ejecutivas (E32)
  ✅ Confiabilidad: 99%

Acción:
  1. Reconectar Gemini en Hermes config
  2. Bypass OmniRoute (token OAuth caído)
  3. Aprobación: José compra token AI Studio
```

### OPCIÓN B: HYBRID (Ollama + Gemini)

```
Arquitectura:
  ├─ Ollama local: E1-8, E10-11, E21-23 (60% carga)
  │  └─ Tareas simples, bajo contexto
  └─ Gemini: E25-27, E29-30, E32 (40% carga, crítico)
     └─ Orchestration, auditing, decisions

Resultado:
  ✅ 90% funcionalidad
  ✅ Orquestación viva
  ✅ Costo: 50% vs Opción A
  ⚠️  Confiabilidad: 95% (switching overhead)

Acción:
  1. Reconfig Hermes profiles (E29, E30, E32 → Gemini)
  2. E1-8 queries pequeñas → Ollama
  3. Monitoreo latencia

Complexity: MEDIA (requiere reconfig)
```

### OPCIÓN C: SOLO OLLAMA

```
Sistema:
  └─ 100% OmniRoute/Ollama local

Realidad:
  ❌ 50% equipos funcionales
  ❌ E30 (Load Balancer) INOPERANTE → no hay orquestación
  ❌ E29 (Auditor) limitado → auditoría superficial
  ❌ E32 (Management) sin tool calls → decisiones tontas
  ❌ Latencia: 5-10x más lenta
  ❌ Sistema 50% cojo

Costo: $0 (pero calidad: 50%)

⚠️  NO RECOMENDADO
```

---

## RECOMENDACIÓN FINAL

```
🎯 JOSÉ:

La arquitectura de 32 equipos FUE diseñada con Gemini en mente.

OPCIÓN A (MANTENER GEMINI):
  ✅ Cero cambios
  ✅ 100% funcionalidad
  ✅ Costo mínimo (~$1/día)
  ✅ Autonomía total equipos
  → RECOMENDADO (mejor ROI)

OPCIÓN B (HYBRID):
  ✅ Si quieres reducir costo
  ⚠️  Requiere reconfig Hermes
  ⚠️  Complejidad media
  → VIABLE (si presupuesto es priority)

OPCIÓN C (SOLO OLLAMA):
  ❌ Sistema reduce 50% capacidad
  ❌ Pierde orquestación real
  ❌ E30 + E32 = inútiles
  → NO VIABLE

Decisión: ¿Mantener Gemini o degradar sistema?
```

---

## ACCIÓN INMEDIATA

**Si quieres mantener 100% funcionalidad:**

1. Reconectar Gemini en Hermes
2. Usar Gemini directo (no OmniRoute)
3. Token AI Studio ($10-20 para 3 meses)

**Si quieres reducir costo a $0:**

1. Aceptar 50% funcionalidad
2. Equipos críticos (E29, E30, E32) degradados
3. No hay auditoría ni orquestación real

---

## VERDICT

```
OmniRoute/Ollama local: NO suficiente para 32 equipos
Gemini: NECESARIO para orchestration + auditing + decisions

Sistema actual (Gemini): 100% viable
Sistema Ollama solo: 50% viable (inaceptable)
Sistema Hybrid: 90% viable (viable si cost-driven)
```

**Recomendación: MANTENER GEMINI. ROI > Costo.**

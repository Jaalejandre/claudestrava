---
title: "EQUIPO 34: ZEROS-VENDEDOR (Marketing & Revenue)"
date: 2026-09-14T04:00:00-06:00
phase: 65
status: "🚀 LISTO PARA ACTIVAR"
directive: "Buscar proyectos autónomos para mantener servidor ($100-500/mes)"
---

# EQUIPO 34: ZEROS-VENDEDOR (Marketing & Revenue)

## MISIÓN

Identificar + lanzar **proyectos autónomos** que generen ingresos.
Objetivo: **Mantener infraestructura ($100-500/mes mínimo).**
Coordinar con E33 (Zeros-Contador) presupuesto tokens.

---

## 5 BOTS ESPECIALIZADOS

### 1. 🔍 OPPORTUNITY-SCOUT
**Responsabilidad:** Identificar mercados + demanda

```
Busca constantemente:
  ├─ Tendencias tech (GitHub, HN, Reddit, Twitter)
  ├─ Problemas sin solución (comunidades, foros)
  ├─ Competencia saturada vs nicho sin explotar
  ├─ Precios de mercado (SaaS, consultoría, APIs)
  └─ Demanda latente (búsquedas Google, Discord)

Fuentes:
  • Product Hunt (nuevas ideas)
  • Indie Hackers (que funciona)
  • Twitter tech (tendencias)
  • GitHub trending (frameworks)
  • Y Combinator (validación)

Genera: Matriz de oportunidades
  ┌────────────────┬─────────┬─────────┬──────────┐
  │ Idea           │ Demanda │ Esfuerzo│ Margen   │
  ├────────────────┼─────────┼─────────┼──────────┤
  │ ChatGPT wrapper│ ALTA    │ BAJO    │ 40-60%   │
  │ API monitoring │ MEDIA   │ MEDIO   │ 30-50%   │
  │ Data scraper   │ ALTA    │ BAJO    │ 50-70%   │
  │ ML benchmarking│ MEDIA   │ ALTO    │ 20-40%   │
  └────────────────┴─────────┴─────────┴──────────┘

Reporte: Semanal (Lunes 09:00 CST)
```

### 2. 💡 PRODUCT-DESIGNER
**Responsabilidad:** Diseñar MVP mínimo viable

```
Toma oportunidades de Scout → diseña producto

Criterios MVP:
  ✅ <2 semanas desarrollo (Zeros-Explorador)
  ✅ <$50 presupuesto tokens (Zeros-Contador)
  ✅ >$100/mes potencial revenue
  ✅ Automatable (sin mantenimiento manual)
  ✅ Standalone (no necesita José)

Ejemplos viables:

1. ChatGPT Wrapper (Gemini Flash API)
   ├─ Tiempo: 3 días
   ├─ Costo: $10
   ├─ Revenue: $200-500/mes (10-50 usuarios @ $10-20/mes)
   ├─ Automático: SÍ (cron job)
   └─ Skill: E25 research + E26 deploy

2. API Monitor (uptime alerts)
   ├─ Tiempo: 5 días
   ├─ Costo: $15
   ├─ Revenue: $150-300/mes (5-15 usuarios @ $10-20/mes)
   ├─ Automático: SÍ (webhook monitoring)
   └─ Skill: E30 (distribuidor) orquesta

3. Data Scraper (web automation)
   ├─ Tiempo: 7 días
   ├─ Costo: $25
   ├─ Revenue: $300-1000/mes (BrowserMCP si aprobado)
   ├─ Automático: SÍ (scheduled tasks)
   └─ Skill: E25 research + BrowserMCP

4. LLM Benchmarking (Gemini vs Claude vs Ollama)
   ├─ Tiempo: 10 días
   ├─ Costo: $50
   ├─ Revenue: $500-2000/mes (SaaS pricing)
   ├─ Automático: PARCIAL (weekly runs)
   └─ Skill: E33 (presupuesto) + E25 (análisis)

Genera: Spec 1-pager por MVP
  ├─ Descripción
  ├─ Timeline
  ├─ Presupuesto tokens
  ├─ Revenue proyectado
  └─ Equipo requerido

Reporte: Bi-semanal (propuestas)
```

### 3. 🎯 MARKET-VALIDATOR
**Responsabilidad:** Validar demanda ANTES de build

```
Toma MVP Designer → valida que realmente hay clientes

Métodos:
  • Landing page + link sharing (Twitter, Reddit, HN)
  • Survey SurveyMonkey (10 preguntas)
  • Cold email (50 prospects potenciales)
  • Discord communities (pitch directo)
  • Pre-sales (¿cuántos comprarían?)

Criterio GO:
  ✅ >10 interested responses
  ✅ >5 committed to pagar
  ✅ >3 "quiero ahora mismo"
  → BUILD MVP

Criterio NO-GO:
  ❌ <3 interested
  ❌ 0 dispuestos pagar
  ❌ "Interesting pero..." (nunca compran)
  → PIVOT idea, no buildear

Reporte: Validation matrix
  ┌──────────┬──────────┬─────────┐
  │ Idea     │ Interesse│ Ready2P │ Verdict
  ├──────────┼──────────┼─────────┼─────────┤
  │ ChatGPT  │ 28/50    │ 12/28   │ ✅ GO   │
  │ Monitor  │ 15/50    │ 3/15    │ ❌ NO-GO│
  │ Scraper  │ 35/50    │ 18/35   │ ✅ GO   │
  └──────────┴──────────┴─────────┴─────────┘

Reporte: Mensual (validaciones completadas)
```

### 4. 💰 REVENUE-ANALYST
**Responsabilidad:** Calcular viabilidad financiera + pricing

```
Toma validaciones → define pricing + proyecciones

Análisis:
  • TAM (Total Addressable Market)
    - ChatGPT wrapper: 10M+ usuarios LLM
    - API monitor: 50K+ API builders
    - Data scraper: 100K+ data teams
  
  • SAM (Serviceable Available Market)
    - Alcance realista: 1-10% TAM
  
  • SOM (Serviceable Obtainable Market)
    - Año 1: 0.1-1% SAM
  
  • Pricing tiers:
    - Starter: $10/mes (100 users)
    - Pro: $30/mes (30 users)
    - Enterprise: $100/mes (5 users)
    → Proyectado mes 1: $3,200
    → Proyectado mes 12: $8,500 (growth)

Calcula:
  ├─ Break-even point
  ├─ Presupuesto tokens vs revenue (ROI)
  ├─ Escalabilidad (¿crece sin José?)
  └─ Riesgo (¿si falla?)

Reporte: Financial model (Excel proyectado 12 meses)
```

### 5. 🚀 GROWTH-EXECUTOR
**Responsabilidad:** Lanzar + mantener productos activos

```
Toma MVP + lanza al mercado

Workflow:
  1. Código: E25 (Explorador) + E26 (Deploy)
  2. Landing page: Zeros-Vendedor (Growth-Executor)
  3. Hosting: Infraestructura SatanZote
  4. Payments: Stripe/Paddle (auto-billing)
  5. Support: Chatbot automático (E28 Mensajero)
  6. Monitoring: E31 (Conserje) + E33 (Contador)

Métricas tracking:
  ├─ Signups (diarios)
  ├─ Conversión (signup → pagados)
  ├─ Churn (cancelaciones/mes)
  ├─ ARR (Annual Recurring Revenue)
  ├─ LTV (Customer Lifetime Value)
  └─ CAC (Customer Acquisition Cost)

Optimization:
  • SEO (keywords LLM, data)
  • Content (blog posts, tutorials)
  • Referrals (affiliate program)
  • Community (Discord, Slack)
  • Email (nurture sequences)

Reporte: Dashboard real-time (usuarios, ingresos, churn)
```

---

## COORDINACIÓN CON OTROS EQUIPOS

```
Zeros-Vendedor ↔ Zeros-Explorador (E25)
  "Necesito MVP ChatGPT wrapper en 3 días"
  ← "Cuánto presupuesto tokens?"
  → "Máximo $15, target $200/mes revenue"
  ← "OK, lo armamos"

Zeros-Vendedor ↔ Zeros-Contador (E33)
  "Lanzamos producto, $50 tokens/mes"
  ← "¿Revenue esperado?"
  → "$300/mes" 
  ← "ROI 6x, APROBADO"

Zeros-Vendedor ↔ Zeros-Conserje (E31)
  "Producto tiene 500 usuarios, servidor slow"
  ← "Monitoreando, detectado spike"
  → "Escala automático"

Zeros-Vendedor ↔ Zeros-Mensajero (E28)
  "50 support tickets diarios"
  ← "Chatbot respondiendo 80%, escalado 20% José"
  → "Perfecto"
```

---

## PRODUCTOS CANDIDATOS (PRIORIDAD)

### TIER 1: Inmediato (2 semanas)

```
1. ChatGPT Wrapper (Gemini Flash)
   Problema: Usuarios quieren GUI simple Gemini (no prompt engeneering)
   Solución: Landing + chat interface simple
   Precio: $10/mes (limitado 10K tokens/mes)
   Revenue: $300/mes (30 usuarios)
   Effort: 3 días (E25 + E26)
   Status: LISTO PARA VALIDAR
   
2. LLM Response Timer
   Problema: Devs quieren benchmark latencia LLM sin code
   Solución: Dashboard upload prompt → test vs Gemini/Claude/Ollama
   Precio: $20/mes (1000 tests/mes)
   Revenue: $500/mes (25 usuarios)
   Effort: 5 días
   Status: VALIDANDO
```

### TIER 2: Próximas 4 semanas

```
3. API Uptime Monitor
   Problema: Startups necesitan uptime monitoring barato
   Solución: Simple webhook checker (send alert si API down)
   Precio: $15/mes (25 endpoints)
   Revenue: $300/mes (20 usuarios)
   Effort: 7 días
   Status: DISEÑO

4. Data Scraper SaaS
   Problema: Non-technical users quieren scrape datos sin código
   Solución: UI para crear scrapers, scheduled execution
   Precio: $50/mes (1000 pages/mes)
   Revenue: $800/mes (BrowserMCP si GO)
   Effort: 10 días + BrowserMCP aprobación
   Status: ESPERANDO E25+E32 decision BrowserMCP
```

### TIER 3: Futuro (mes 2+)

```
5. LLM Benchmarking SaaS
   Problema: LLM researchers necesitan benchmarks bajo demanda
   Solución: UI parametrizado, runner distribuido, resultados dashboard
   Precio: $100/mes (unlimited benchmarks)
   Revenue: $2000/mes (20 usuarios académicos/enterprise)
   Effort: 14 días
   Status: CONCEPT
```

---

## MÉTRICAS DE ÉXITO

```
META MES 1 (Octubre 2026):
  ✅ 1-2 productos en validación
  ✅ >20 usuarios pagados totales
  ✅ $300-500/mes ingresos

META MES 3 (Diciembre 2026):
  ✅ 3-4 productos activos
  ✅ >100 usuarios pagados
  ✅ $1500-2000/mes ingresos (cubrir servidor)

META MES 6 (Marzo 2027):
  ✅ 5+ productos, escalando
  ✅ >300 usuarios
  ✅ $3000-5000/mes (margen después tokens)
```

---

## PRESUPUESTO TOKENS ASIGNADO

```
Zeros-Vendedor (E34) presupuesto:
  • Investigación: $5/semana (Opportunity Scout)
  • Validación: $10/semana (surveys, emails)
  • Análisis: $3/semana (financiero)
  • Total: $18/mes (dentro E33 budget)

Productos en launch:
  • ChatGPT wrapper: $20 (3 días)
  • API monitor: $30 (5 días)
  • Data scraper: $50 (10 días)
  Total: $100 (presupuestado en E33)

TOTAL DEPARTAMENTO: $118/mes
  → Objetivo revenue: >$1000/mes (ROI 8x)
```

---

## AUTONOMÍA + ESCALACIÓN

```
Zeros-Vendedor DECIDE:
  ✅ Qué productos validar
  ✅ Pricing
  ✅ Go/no-go después validación
  ✅ Optimizaciones growth
  ✅ Partnerships (affiliates, etc)

ESCALA A JOSÉ si:
  ❌ Presupuesto tokens exceed $150/mes
  ❌ Equipo adicional requerido (hiring)
  ❌ Productivo conflict con GromacsMexicano
  ❌ Viralidad exponencial (scaling infra)
```

---

## DIRECTIVA FINAL (José)

```
ORDEN: "Buscar proyectos autónomos mantener servidor"

E34 (Zeros-Vendedor) OBJETIVO:
  
  Mes 1: Validar 2-3 ideas, launch 1 MVP
  Mes 3: 3-4 productos activos, $1500+/mes
  
  Requisito:
    • Autónomos (sin mantenimiento José)
    • Predecibles (recurring revenue, no viral)
    • Escalables (crecen sin recursos)
    • ROI positivo (tokens < revenue)
  
  Restricción:
    • No interfiere GromacsMexicano
    • Presupuesto tokens $100-150/mes
    • Servidores SatanZote únicamente
    • Equipo existente (no hiring)

TIMELINE:
  2026-09-21: Validación 2-3 ideas completada
  2026-10-05: MVP ChatGPT wrapper live
  2026-10-31: 3 productos activos, $300+/mes
  2026-12-31: $1500+/mes run rate

STATUS: 🚀 LISTO ACTIVAR
```

---

## NOTAS

- E34 propone, E32 (Consejero) aprueba gasto
- E33 (Contador) monitorea ROI presupuesto tokens
- E31 (Conserje) mantiene infraestructura estable
- Si producto falla → pivot, no abandono
- Éxito = "servidor se mantiene solo" (goal final)

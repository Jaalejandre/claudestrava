---
title: "EQUIPO 37: NETWORK TRAFFIC OPTIMIZER — Rate Limiting & Traffic Control"
date: 2026-09-14T18:30:00-06:00
version: "1.0"
status: "🚀 LISTO CREAR"
priority: "🔴 CRÍTICA"
owner: "Sofía (E35)"
---

# EQUIPO 37: NETWORK TRAFFIC OPTIMIZER 🚦

**Misión:** Prevenir saturación de backend (como el 503 de hoy) mediante rate-limiting, circuit-breaker, y traffic shaping.

**Objective:** Evitar que Hermes + OmniRoute se saturen → mantener 99.9% uptime

**Timeline:** Activar inmediatamente (2026-09-14)
**Supervisor:** Sofía (E35 Daemon-Director)

---

## 🎯 PROBLEMA QUE RESUELVE

**Síntoma (hoy 16:30):**
```
HTTP 503: Chat admission capacity is temporarily unavailable
Causa: OmniRoute recibió demasiadas requests simultáneas
Impacto: Hermes bloqueado (3 reintentos fallidos)
Consecuencia: Equipos esperando, tareas atrasadas
```

**Root Cause:**
- Sin límite de rate (rate-limit)
- Sin circuit-breaker (para fallos temporales)
- Sin token bucket (para controlar flujo)
- Sin retry exponential backoff
- Sin fallback a ollama-local

---

## 👥 EQUIPO (4 BOTS ESPECIALIZADOS)

### Bot 1: Rate Limiter Controller
**Responsabilidad:** Controlar flujo de requests a OmniRoute
**SLA:** <100ms latencia en decision

**Funciones:**
- Token Bucket algorithm (requests/segundo)
- Per-IP rate limiting
- Per-model rate limiting (gemini vs deepseek vs ollama)
- Adaptive rate (reduce under load, increase when stable)

**Configuración:**
```yaml
Rate Limits:
  Global: 50 requests/sec
  Per-IP: 10 requests/sec
  Per-Model:
    gemini-3.6-flash: 20 req/sec (premium, limited)
    deepseek-v4-flash: 30 req/sec (cheaper, higher limit)
    ollama-local: unlimited (local resource)
  
Burst allowance: 5 extra requests (for spikes)
```

### Bot 2: Circuit Breaker Manager
**Responsabilidad:** Detectar fallos y "abrir circuito" automáticamente
**SLA:** Detección en <1 segundo

**Funciones:**
- Monitor backend health (HTTP 5xx, timeouts)
- Open circuit → redirect to fallback
- Half-open state (test recovery)
- Exponential backoff (wait 5s, 10s, 30s)

**Estados:**
```
CLOSED (healthy)
  ↓ (5 consecutive failures)
OPEN (fail-fast, reject new requests)
  ↓ (wait 30s)
HALF-OPEN (test 1 request)
  ↓ (if success) CLOSED
  ↓ (if fail) OPEN
```

### Bot 3: Fallback Orchestrator
**Responsabilidad:** Redirigir requests a modelos alternativos cuando backend falla
**SLA:** Fallback en <2 segundos

**Decisión árbol:**
```
Request → gemini-3.6-flash
  ├─ Is backend healthy? YES → use gemini
  └─ Is backend healthy? NO → fallback cascade:
     ├─ Try deepseek-v4-flash (Cheaper Inference)
     ├─ If deepseek fails → try ollama-local
     └─ If all fail → queue + retry in 30s
```

**Modelo Fallback Priority:**
1. gemini-3.6-flash (premium, preferred)
2. deepseek-v4-flash (fast, cost-efficient)
3. ollama-local:qwen2.5-coder:14b (local, unlimited)

### Bot 4: Metrics & Alert Manager
**Responsabilidad:** Monitorear y alertar sobre degradación
**SLA:** Alert en <30 segundos

**Métricas:**
- Request queue depth
- Backend response time (p50, p95, p99)
- Error rate (4xx, 5xx)
- Circuit breaker state changes
- Fallback activation count

**Alertas (a José vía Telegram):**
- 🔴 CRITICAL: Circuit open (backend down)
- 🟠 WARNING: Error rate > 5%
- 🟡 INFO: Fallback activated (N times in 10 min)

---

## 🔧 ARQUITECTURA

```
┌─────────────────────────────────────────────────────┐
│  HERMES AGENTS (producing requests)                 │
└────────────────────┬────────────────────────────────┘
                     │
        ┌────────────▼────────────┐
        │  EQUIPO 37 MIDDLEWARE   │ ← NEW
        │                         │
        ├─ Rate Limiter          │
        ├─ Circuit Breaker       │
        ├─ Fallback Router       │
        └──────────┬─────────────┘
                   │
        ┌──────────▼──────────┐
        │  OMNIROUTE GATEWAY  │
        │ (http://192.168.0.64:20128/v1)
        └──────────┬──────────┘
                   │
        ┌──────────▼──────────────────────┐
        │  BACKEND PROVIDERS              │
        ├─ Gemini API (premium)           │
        ├─ Cheaper Inference (deepseek)   │
        ├─ Ollama local (fallback)        │
        └─────────────────────────────────┘
```

**Deployment Location:** CT 109 (colocated con OmniRoute)

---

## 📊 CONFIG INICIAL

```yaml
EQUIPO_37_CONFIG:
  name: "Network Traffic Optimizer"
  namespace: "infrastructure"
  
  rate_limiting:
    enabled: true
    global_qps: 50
    per_ip_qps: 10
    per_model:
      gemini: 20
      deepseek: 30
      ollama: unlimited
    burst_size: 5
    
  circuit_breaker:
    enabled: true
    failure_threshold: 5  # failures before open
    success_threshold: 2  # successes to close
    timeout: 30  # seconds in open state
    
  fallback:
    enabled: true
    priority_order:
      - "gemini-3.6-flash"
      - "deepseek-v4-flash"
      - "ollama-local:qwen2.5-coder:14b"
    retry_delay_ms: 5000  # wait 5s before retry
    
  monitoring:
    enabled: true
    metrics_interval_sec: 10
    alert_threshold_errors: 0.05  # 5% error rate
    alert_channels:
      - telegram  # José
      - logs      # system logs

  persistence:
    state_file: "/root/.hermes/equipo37/state.json"
    metrics_db: "/root/.hermes/equipo37/metrics.sqlite"
```

---

## ⚙️ OPERACIÓN DIARIA

### Start (Manual)
```bash
# Activar EQUIPO 37
hermes-cli teams activate EQUIPO-37

# Verificar estado inicial
hermes-cli teams status EQUIPO-37
  → Rate Limiter: ONLINE
  → Circuit Breaker: ONLINE (CLOSED)
  → Fallback Router: ONLINE
  → Metrics Manager: ONLINE
```

### Monitoring (Continuous)
```bash
# Ver métricas en tiempo real
hermes-cli metrics EQUIPO-37 --watch
  Global QPS: 22 / 50 (44% utilized)
  Circuit Breaker: CLOSED ✓
  Error Rate (10m): 0.3%
  Fallback Activations: 0
  Backend Latency (p95): 342ms
```

### Response to 503 (Automatic)
```
16:30:46 → HTTP 503 detected (gemini backend)
16:30:47 → Circuit Breaker opens
16:30:48 → Fallback Router: redirect to deepseek-v4-flash
16:30:49 → User request succeeds (via deepseek)
16:31:00 → Circuit Breaker: HALF-OPEN (test recovery)
16:31:05 → Gemini responds ✓ → Circuit CLOSED
```

---

## 📈 SUCCESS METRICS

| Metric | Target | Measurement |
|--------|--------|-------------|
| Availability | 99.9% | Uptime per week |
| Fallback Activation | <5 times/week | Count of backend failures |
| Response Time | <500ms p95 | Latency with fallback included |
| Error Rate | <1% | HTTP 4xx+5xx / total |
| Circuit Recovery Time | <60s | Time from OPEN to CLOSED |
| Rate Limit Compliance | 100% | No overages recorded |

---

## 🚀 DEPLOYMENT STEPS

**1. Code Deploy (2 hours)**
- Write rate-limiter module (Python)
- Write circuit-breaker module (Python)
- Write fallback router (Python)
- Write metrics collector (Python)
- Integrate with Hermes gateway

**2. Testing (1 hour)**
- Unit tests (rate limiter logic)
- Integration tests (with OmniRoute)
- Load test (simulate 100 requests/sec)
- Chaos test (kill backend, verify fallback)

**3. Activation (30 min)**
- Enable in production (monitoring ON)
- Set alerts
- Document for ops team

**4. Monitoring (Continuous)**
- Hermes logs → check for circuit changes
- Metrics → dashboard
- Alerts → Telegram to José

---

## 📞 ESCALATION

| Issue | Action | SLA |
|-------|--------|-----|
| Circuit open (5+ failures) | Auto-fallback, alert José | <2s |
| Persistent backend down (>5 min) | Page on-call, consider restart | <5m |
| Rate limit exceeded (client) | Reject with 429, log request | Real-time |
| Metrics unavailable | Alert ops team | 15m |

---

## 🎯 NEXT PHASES

### Phase 2: Adaptive Rate Limiting
- ML model learns peak hours → adjust limits dynamically
- Timeline: 2026-09-20

### Phase 3: Regional Failover
- Route to backup OmniRoute instance (if deployed)
- Timeline: 2026-10-01

### Phase 4: Cost Optimization
- Auto-switch to cheaper model (deepseek) during off-peak
- Timeline: 2026-09-30

---

## ✅ SIGN-OFF

**Status:** 🚀 READY TO CREATE
**Owner:** Sofía (E35)
**Approved by:** José (CEO)
**Activation Date:** 2026-09-14 (TODAY)

**Next action:** Create EQUIPO 37 and activate immediately.

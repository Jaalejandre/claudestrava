---
title: "DELEGACIÓN: Diseñar Conexión SatanZote ↔ Infraestructura (SSOT)"
date: 2026-09-14T03:00:00-06:00
issued_by: "José"
to: "E29 (AUDITOR) + E32 (MANAGEMENT)"
priority: "🔴 CRÍTICA — Infraestructura"
task: "Diseñar + proponer solución"
---

# DELEGACIÓN: Conexión SatanZote ← → Infraestructura REAL

## PROBLEMA

SatanZote está desactualizado. Tiene información vieja del proyecto.
Necesita estar SIEMPRE conectado a estado real del sistema.

**Sin esto:** Pregunta cosas que ya sabe, propone soluciones obsoletas, no usa infraestructura armada.

---

## SOLUCIONES PROPUESTAS (elegir + mejorar)

### OPCIÓN A: ENDPOINT API (E30 Load Balancer)

**Concepto:**
```
E30 (Load Balancer Chief) expone endpoint:
  GET http://localhost:20128/api/system/status
  
Retorna JSON:
{
  "timestamp": "2026-09-14T03:00:00Z",
  "models": {
    "primary": "gemini-3.6-flash (131k context)",
    "fallback": ["ollama-local:qwen2.5-coder:14b"],
    "status": "operational"
  },
  "hermes": {
    "profiles_active": 69,
    "default_profile": "default",
    "contexts": {
      "e29_auditor": "gemini-3.6-flash",
      "e30_loadbalancer": "gemini-3.6-flash",
      "e32_management": "gemini-3.6-flash"
    }
  },
  "capacity": {
    "ct_109_ram": "10GB, using 2.9GB (70% free)",
    "ct_901_ram": "12GB, using 31MB (95% free)",
    "gpu_vram": "16GB (available)"
  },
  "cron_jobs": 50,
  "teams": 32,
  "bots": 120
}

SatanZote:
  1. Lee endpoint al inicio de cada sesión
  2. Valida: modelos, contexto, capacidad
  3. Usa información REAL para decisiones
```

**Ventaja:** Centralizado, autoridad única (E30), siempre fresco
**Esfuerzo:** Medio (E30 desarrolla endpoint)
**Latencia:** <100ms

---

### OPCIÓN B: ARCHIVO VAULT (E29 actualiza)

**Concepto:**
```
E29 (AUDITOR) mantiene archivo en Vault:
  /root/JarvisVault/SYSTEM-STATE-LIVE.json
  
Actualizado cada:
  • 06:00 CST (audit diario)
  • On-demand si cambio crítico

Contenido:
{
  "last_audit": "2026-09-14T06:00:00Z",
  "audit_cycle": "daily",
  "models": {...},
  "hermes_profiles": {...},
  "capacity": {...},
  "status": "operational|degraded|critical"
}

SatanZote:
  1. Lee SYSTEM-STATE-LIVE.json al inicio
  2. Usa para todas las decisiones
  3. Si > 24h sin actualizar → usa cached + alerta
```

**Ventaja:** E29 autoridad única, integra con Vault
**Esfuerzo:** Bajo (E29 agrega a cron audit)
**Latencia:** <1ms (archivo local)

---

### OPCIÓN C: HERMES MCP (Directo)

**Concepto:**
```
E30/E29 exponen MCP server local:
  
SatanZote:
  1. Conéctate a MCP server (puerto TBD)
  2. Call: infrastructure:get-status()
  3. Recibe estado real en tiempo real
  
Respuesta:
{
  "models": [...],
  "profiles": [...],
  "capacity": [...],
  "status": "ready|degraded"
}
```

**Ventaja:** Integración nativa Hermes, actualización en tiempo real
**Esfuerzo:** Alto (MCP server + handlers)
**Latencia:** <50ms

---

### OPCIÓN D: DASHBOARD API (E20 actualiza)

**Concepto:**
```
E20 (Dashboard Manager) expone:
  GET http://localhost:3000/api/system/status
  
SatanZote:
  1. Lee dashboard API
  2. Extrae: modelos, profiles, capacidad, estado
  3. Usa para decisiones
```

**Ventaja:** Visual + API, E20 ya mantiene
**Esfuerzo:** Bajo (E20 agrega endpoint)
**Latencia:** <200ms

---

## DECISIÓN REQUERIDA (E32)

### Evaluar por:
1. **Facilidad implementación** (tiempo E29/E30/E20)
2. **Actualización** (¿qué tan fresco?)
3. **Confiabilidad** (¿siempre disponible?)
4. **Integración** (¿funciona con Hermes actual?)
5. **Mantenimiento** (¿quién lo cuida?)

### Criterios aceptación:
- ✅ SatanZote lee ANTES de cada pregunta/decisión
- ✅ Información < 1 hora vieja (máximo)
- ✅ 99% uptime
- ✅ Retorna: modelos, profiles, capacity, status

---

## IMPLEMENTACIÓN

**E32 elige opción + mejoras:**
```
OPCIÓN ELEGIDA: [A/B/C/D o HÍBRIDA]

IMPLEMENTACIÓN:
  1. E29/E30/E20: Desarrolla endpoint/archivo/MCP
  2. Testing: Valida formato + datos
  3. SatanZote: Integra lectura
  4. Cron: Mantiene actualizado

TIMELINE: [TBD por E32]

OWNER: [E29/E30/E20 según opción]
```

---

## CONEXIÓN DESPUÉS

Una vez implementado:

```
SatanZote (inicio sesión):
  1. curl/read SYSTEM-STATE
  2. Parse modelos, profiles, capacity
  3. Valida: "¿tengo Gemini? ¿32 equipos caben?"
  4. SABE respuesta sin preguntar

Resultado:
  • Decisiones basadas en hechos reales
  • Propuestas relevantes (no obsoletas)
  • USA infraestructura armada (E29, E30, E20)
  • No pregunta lo mismo 2 veces
```

---

## AUTORIDAD

**E32 (Management):** Elige opción + timeline
**E29/E30/E20:** Implementan
**SatanZote:** Integra + usa

No vuelvo a trabajar con información vieja.

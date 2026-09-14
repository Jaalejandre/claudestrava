---
title: "DECISIONES AUTOMÁTICAS — Framework de Gobernanza"
date: 2026-09-13T23:25:00-06:00
phase: 59
status: "🚀 NUEVO FRAMEWORK"
---

# DECISIONES AUTOMÁTICAS POR EQUIPO

## Principio

**NO preguntar a José. El equipo correcto DECIDE y EJECUTA automáticamente.**

```
Viejo workflow:
  Agent → Pregunta "¿Hago esto?" → José responde → Ejecuta
  ❌ Lento, interrumpe a José, no es escalable

Nuevo workflow:
  Evento → Equipo analiza → Equipo DECIDE → Equipo EJECUTA
  ✅ Automático, rápido, sin interrupciones
```

---

## MATRIZ DE DECISIONES POR EQUIPO

### EQUIPO 19 (VAULT MASTER) — Decisiones de Datos

```yaml
Trigger: Vault crece > 80% capacidad
Decisión: Archivar logs antiguos
Acción: Ejecutar automáticamente
SLA: Dentro de 1 hora
Notificación: A José (solo resumen)

Trigger: Integridad vault comprometida
Decisión: Restaurar desde backup
Acción: Ejecutar automáticamente (con log detallado)
SLA: Inmediato
Notificación: A José (CRÍTICA)
```

### EQUIPO 20 (DASHBOARD) — Decisiones de Visualización

```yaml
Trigger: Dashboard lag > 1 segundo
Decisión: Reducir polling rate, optimizar queries
Acción: Ejecutar automáticamente
SLA: < 5 minutos
Notificación: A José (log en vault)

Trigger: Métrica crítica no llega
Decisión: Cambiar fuente de datos, fallback
Acción: Ejecutar automáticamente
SLA: Inmediato
Notificación: A José (debug info)
```

### EQUIPO 27 (EVALUATION BOARD) — Decisiones Estratégicas ⭐

```yaml
Trigger: Tecnología nueva evaluada (scores completos)
Decisión: APPROVE / REJECT / MONITOR
Criterios:
  • Score técnico: > 70 → más peso
  • ROI: > 3:1 → APPROVE
  • Riesgo: > 40% → REJECT
  • Madurez: < 0.5 → MONITOR

Acción si APPROVE:
  1. Crear rama git feature/tech-XXXX
  2. Notificar a EQUIPO 26 (Testing)
  3. Scheduling automático en próximo ciclo
  4. Loguear decisión en vault

Acción si REJECT:
  1. Guardar justificación
  2. Marcar para revisión (6 meses)
  3. Notificar a EQUIPO 25 (Research)
  4. Loguear en vault

Notificación a José:
  • Resumen: "OpenMM APPROVED (score 85.9, ROI 4.2:1)"
  • Link a decisión en vault
  • No pedir confirmación
```

### EQUIPO 8 (DM UAMI) — Decisiones Científicas

```yaml
Trigger: Benchmarks completos (Phase 5 GPU kernels)
Decisión: KERNEL OPTIMIZED / NEEDS TUNING

Criterios:
  • Throughput ≥ 1200 st/s → OPTIMIZED
  • Memory bandwidth util ≥ 80% → OPTIMIZED
  • Numerical errors < 0.1% → OPTIMIZED

Acción si OPTIMIZED:
  1. Commit código a main branch
  2. Crear release tag v1.X.X
  3. Documentar en Phase5 wiki
  4. Loguear en vault

Acción si NEEDS TUNING:
  1. Analizar bottleneck
  2. Crear issue (blockers detallados)
  3. Asignar a EQUIPO 8B (MD Expert)
  4. Schedule siguiente benchmark

Notificación a José:
  • "Phase 5 Kernel LISTA: ✅ OPTIMIZED (1247 st/s)"
  • Gráficos de benchmark
  • Tiempo estimado para siguiente kernel
```

### EQUIPO 6 (AI CARRILLO) — Decisiones de Infraestructura

```yaml
Trigger: CT 109 RAM > 85%
Decisión: INCREASE RESOURCES automáticamente

Criterios de Escalada:
  • RAM > 90% → Aumentar +4 GB (automático)
  • RAM > 95% → Aumentar +8 GB (automático, alert crítica)
  • Cores > 80% → Aumentar +2 cores

Acción:
  1. Validar espacio en host Proxmox
  2. Ejecutar: pct set 109 -memory 12288
  3. Reiniciar CT (schedule en ventana)
  4. Verificar servicios post-reboot
  5. Loguear en vault

Notificación a José:
  • "CT 109 escalado: 6 GB → 10 GB (E28 requería +3.9 GB)"
  • Downtime: < 2 minutos
  • Services OK: Hermes ✓ OmniRoute ✓ Dashboard ✓
  • Próxima revisión: en 1 semana
```

### EQUIPO 28 (TRAVEL AGENCY) — Decisiones de Búsqueda

```yaml
Trigger: Laura envía mensaje con detalles de viaje
Decisión: INICIAR búsqueda automáticamente

Flujo:
  1. flight-searcher: Activa 5 búsquedas en paralelo
  2. hotel-finder: Activa 5 búsquedas en paralelo
  3. price-monitor: Activa alertas cada 6h
  4. Compilar resultados
  5. Enviar recomendación a Laura

Acción si precio baja > 10%:
  1. Notificar a Laura INMEDIATAMENTE
  2. Recomendar comprar (si < 24h)
  3. Tracking continuo
  
Notificación a José:
  • Resumen diario (consolidado)
  • Status: "Laura viaje a Paris: ✅ boletos encontrados"
  • No interrupciones innecesarias
```

---

## PLANTILLA PARA NUEVOS EQUIPOS

Cada equipo debe tener definidas:

```yaml
equipment_name: "EQUIPO XX"
automation_level: "HIGH"  # HIGH/MEDIUM/LOW

decisions:
  - trigger: "Condición X"
    owner: "Bot Y en EQUIPO XX"
    options: ["APPROVE", "REJECT", "MONITOR", "ESCALATE"]
    criteria: 
      - "Métrica A > threshold"
      - "Métrica B < threshold"
    action_if_approved: "Ejecutar comando X"
    action_if_rejected: "Notificar a EQUIPO Z"
    notification_to_josé: "Resumen (no ask)"
    sla_minutes: 30
    escalation_path: "Si no se puede decidir → EQUIPO 27 (Board)"
```

---

## MATRIZ RÁPIDA: ¿QUIÉN DECIDE QUÉ?

| Decisión | Equipo | Automático | Notif a José |
|----------|--------|-----------|--------------|
| Aumentar RAM CT 109 | E6 (Carrillo) | ✅ | Resumen |
| Adoptar tech nueva | E27 (Board) | ✅ | Resumen |
| Optimizar kernel GPU | E8 (DM) | ✅ | Resumen |
| Escaldar datos vault | E19 (Master) | ✅ | Si crítico |
| Iniciar búsqueda viaje | E28 (Travel) | ✅ | Resumen |
| Crear nuevo EQUIPO | E27 (Board) | ⏳ | Para aprobar |
| Cambiar directiva | José | - | (él decide) |
| Budget > $10k | José | - | (él decide) |

---

## IMPLEMENTACIÓN HOY

```
✅ EQUIPO 27 (EVALUATION BOARD)
   └─ Ya decide sobre tecnologías automáticamente
   └─ LISTO para adoptar este framework

✅ EQUIPO 8 (DM UAMI)
   └─ Ya ejecuta benchmarks
   └─ Próxima: decidir automáticamente si kernel está "ready"

✅ EQUIPO 6 (AI CARRILLO)
   └─ Próxima: implementar auto-scaling CT 109

⏳ TODOS LOS EQUIPOS
   └─ Auditar decisiones manuales
   └─ Automatizarlas según matriz

📋 VAULT DOCUMENTATION
   └─ Todas las decisiones logged automáticamente
   └─ José puede revisar, pero NO autoriza cada una
```

---

## NOTIFICACIONES A JOSÉ (Nuevo Estándar)

```
VIEJO:
  "¿Debo aumentar CT 109?"
  
NUEVO:
  "CT 109 escalado a 10 GB (E6 decidió, criterio: RAM > 85%)
   Downtime: 2 min. Services OK. Ver detalle: [link vault]"

CRÍTICO SOLO:
  "⚠️ VAULT INTEGRITY FAILED - Restaurando backup
     ETA: 5 min. Details: [log]"
```

---

## Regla Oro

**Automatiza TODO lo que puedas.
Notifica a José DESPUÉS.
Escala a EQUIPO 27 si hay conflicto.**

```
Agent: "¿Ejecuto aumento de recursos?"
José: "Eso lo decide el equipo. Hazlo automático."
Agent: "Entendido. ✅ EQUIPO 6 decide. Ejecutar."
```

---

*Framework de gobernanza autónoma — Equipos deciden, no José*
*Timestamp: 2026-09-13 23:25 CST*

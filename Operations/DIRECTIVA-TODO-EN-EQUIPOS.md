---
title: "DIRECTIVA OFICIAL: TODO EN EQUIPOS + VAULT MASTER"
date: 2026-09-13T21:05:00-06:00
priority: "🔴 CRÍTICA"
status: "✅ APROBADA"
applies_to: "TODOS LOS EQUIPOS (1-20)"
---

# 🔴 DIRECTIVA OFICIAL: TODO SE HACE EN EQUIPOS

**Efectiva desde:** 2026-09-13  
**Aprobada por:** José  
**Scope:** 100% de operaciones SatanZote

---

## REGLA #1: NO HAY TRABAJO INDIVIDUAL

❌ PROHIBIDO:
```
• Editar archivos directamente
• Cambios sin equipo responsable
• Acciones sin documentación
• Modificaciones sin trazabilidad
```

✅ OBLIGATORIO:
```
• TODO trabajo → asignado a un equipo
• TODO cambio → solicitado via VAULT MASTER
• TODO archivo → custodiado por alguien
• TODO proceso → tiene dueño y respaldo
```

---

## REGLA #2: VAULT MASTER ES LA AUTORIDAD CENTRAL

**Equipo 19: VAULT MASTER ⭐** es la **fuente única de verdad (SSOT).**

```
Ningún equipo edita archivos directamente.

Protocolo:
  1. Equipo X necesita cambio
  2. Solicita a VAULT MASTER
  3. VAULT MASTER valida
  4. VAULT MASTER aplica cambio
  5. VAULT MASTER registra en auditoría
  6. VAULT MASTER responde OK/DENIED
```

**Archivos bajo custodia de VAULT MASTER:**
- `/root/JarvisVault/` (completo)
- `~/.hermes/` (configuración crítica)
- `~/.omniroute/` (puertas LLM)

---

## REGLA #3: TODO PASA POR UN EQUIPO

**Mapeo de responsabilidades:**

| Área | Equipo Responsable |
|------|-------------------|
| **Visión/Datos** | Equipo 19 (VAULT MASTER) |
| **Visualización** | Equipo 20 (DASHBOARD MANAGER) |
| **Hermes Config** | Equipo 1 (Bot Mode) |
| **Seguridad** | Equipo 11 (Security Team) |
| **Gobernanza** | Equipo 12 (Governance) |
| **Auditoria** | Equipo 2 (Audit) |
| **GPU/Proxmox** | Equipo 4 (Proxmox Optimization) |
| **UAMI (Fases)** | Equipo 8 (DM UAMI Coord) |
| **Entrenamiento** | Equipo 15 (L'Étape) |
| **Ideas** | Equipo 18 (Strategic Ideas) |
| **Home Assistant** | Equipo 16 (HA Control) |
| **Simulador Papá** | Equipo 17 (UAMI Simulator) |

**Si necesitas algo y no está en esta tabla → propón crear un nuevo equipo.**

---

## REGLA #4: TRAZABILIDAD 100%

**Cada cambio registra:**
- Quién: Equipo X
- Qué: descripción de cambio
- Cuándo: timestamp exacto
- Dónde: archivo/path
- Por qué: motivo/justificación
- Commit git: hash para rollback

**Audit log:** `~/.hermes/vault-master/audit.log`

---

## REGLA #5: PERMISOS POR ÁREA

**VAULT MASTER** tiene matriz de permisos:

```
LECTURA: Todos los equipos pueden leer TODO

ESCRITURA:
  • Equipo 2 (Audit): 01 Daily Reviews/
  • Equipo 15 (L'Étape): 02 Plan Entrenamiento/
  • Equipos 8, 14: 03 Projects/GromacsMexicano/
  • Equipo 18: 03 Projects/Prototipos/
  • Equipos 12, 19: Operations/
  • Equipo 2: 01 Daily Reviews/
  • Equipos 8, 14: Phase5/

ADMIN (solo Equipo 19):
  • Crear nuevas carpetas
  • Cambiar permisos de escritura
  • Hacer rollback de commits
  • Banear acceso a equipos
```

---

## REGLA #6: FLUJO DE CAMBIOS

```
PASO 1: Necesidad
   "Equipo X necesita cambiar archivo Y"

PASO 2: Solicitud a VAULT MASTER
   → protocolo JSON
   → Quién, Qué, Por qué

PASO 3: Validación
   ✓ ¿Tiene permiso?
   ✓ ¿Archivo es válido?
   ✓ ¿Respeta esquema?

PASO 4: Ejecución (si OK)
   ✓ Editar archivo
   ✓ Commit git
   ✓ Registrar en audit log
   ✓ Push a GitHub

PASO 5: Respuesta
   → OK + commit hash
   → O DENIED + razón
```

---

## REGLA #7: CONTROL + VISIBILIDAD

**Dashboard (Equipo 20) muestra:**
- Estado de cada equipo (✅ online, ❌ offline)
- Última actividad de cada equipo
- Cambios recientes en VAULT
- Auditoría de cambios
- Métricas de sistema (CPU, RAM, Disk)

---

## REGLA #8: RESPUESTA A CONFLICTOS

**Si dos equipos piden cambios conflictivos:**
1. VAULT MASTER rechaza ambos
2. Envía a **Equipo 12 (Governance)** para resolver
3. Governance decide prioridad
4. VAULT MASTER aplica decisión
5. Ambos equipos notificados

---

## REGLA #9: BACKUPS + SINCRONIZACIÓN

**VAULT MASTER garantiza:**
- ✅ Git push automático cada 1 hora
- ✅ Backup a GitHub (remoto)
- ✅ Rollback posible a cualquier commit
- ✅ Sincronización con CT 901, VM 106 (si aplica)

---

## REGLA #10: SERIALIDAD (NO PARRELO)

**Directiva de José:** Cambios se aplican **serial, no paralelo**

```
Cambio 1: Editar archivo A
   ↓ (esperar OK)
Cambio 2: Editar archivo B
   ↓ (esperar OK)
Cambio 3: Editar archivo C
```

**Razón:** Evitar estados corruptos, facilitar rollback.

---

## MIGRACIÓN INMEDIATA

**A partir de HOY (2026-09-13):**

```
PASO 1: Crear VAULT MASTER (Equipo 19) ✅
PASO 2: Crear DASHBOARD MANAGER (Equipo 20) ✅
PASO 3: Todos los equipos actualizados en Hermes
PASO 4: Auditar accesos directos (audit log)
PASO 5: Migrar procedimientos a "via VAULT MASTER"
```

---

## VERIFICACIÓN DE CUMPLIMIENTO

**Cada día:**
- Equipo 2 (Audit) revisa audit log
- Si hay cambios directos → ⚠️ ALERTA
- Governance decide castigo (si procede)

**Cada semana:**
- Reporte de trazabilidad
- Matriz de permisos revisada
- Nuevos equipos registrados (si aplica)

---

## PREGUNTAS FRECUENTES

**P: ¿Puedo editar JarvisVault directamente?**  
A: ❌ NO. SIEMPRE via VAULT MASTER.

**P: ¿Y si VAULT MASTER está caído?**  
A: Contacta a Equipo 19. Tienen backup de emergencia. Sin workarounds.

**P: ¿Puedo crear un equipo nuevo?**  
A: Propón a Equipo 12 (Governance). Ellos validan + aprueban.

**P: ¿Cuánto tarda un cambio?**  
A: < 2 minutos (VAULT MASTER garantiza).

**P: ¿Se puede rollback?**  
A: Sí. VAULT MASTER lo hace en 30 segundos.

---

## BENEFICIOS

```
✅ Trazabilidad 100% (auditoría completa)
✅ Prevención de conflictos (permisos claros)
✅ Fácil rollback (todo en git)
✅ Escalable (nuevos equipos sin fricciones)
✅ Seguridad (solo VAULT MASTER accede críticos)
✅ Cien porciento (estado consistente siempre)
```

---

**FIRMADO:** José (2026-09-13)  
**STATUS:** 🔴 VIGENTE - TODO EQUIPO DEBE CUMPLIR  
**PRÓXIMO REVIEW:** 2026-09-20

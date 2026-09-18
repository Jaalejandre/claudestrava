# 🎯 PLAN DE ATAQUE — Paralelización GPU+CPU (BORRADOR)

**Fecha:** 2026-09-12 12:00 CDMX  
**Estado:** ESPERANDO ANÁLISIS DEL AGENTE  
**Estrategia:** Mínimos cambios, máxima seguridad

---

## ESTRUCTURA DEL PLAN (A SER REFINADA)

### FASE 1: ANÁLISIS ⏳ (En progreso)
- [ ] Agente escanea 108 archivos fuente
- [ ] Identifica loops paralelizables exactos
- [ ] Mapea dependencias de datos
- [ ] Lista riesgos conocidos
- [ ] Propone orden de ataque

**Entregable esperado:** `analysis_openmp_cuda.json`

---

### FASE 2: DISEÑO DEL PLAN (Pendiente)
**Una vez tengo análisis:**
1. **Identificar TOP 3 loops** con mejor relación speedup/riesgo
2. **Seleccionar estrategia OpenMP** para cada:
   - `parallel do` simple (independent iterations)
   - `parallel do reduction()` (acumuladores)
   - `parallel sections` (tareas disjuntas)
3. **GPU sync strategy:**
   - ¿Kernels síncronos o asíncronos?
   - ¿Host-device memory transfers timing?
4. **Validación post-cambio:**
   - Compilación sin errores
   - 1 run quick test (no seg fault)
   - 3 full validations (reproducibilidad)

---

### FASE 3: IMPLEMENTACIÓN (Delegada a agente)
**Agente 2 ejecuta:**
1. Ediciones quirúrgicas de main.f + subrutinas (usar Edit tool, no sed)
2. Recompilación paso a paso (capturar cada error)
3. Validación de compilación
4. Si compila: 1 quick run (timeout 30s)

**Checkpoint:** Si hay seg fault, parar y reportar

---

### FASE 4: VALIDACIÓN (Agente 3)
**3 corridas de 1000 pasos cada una:**
- Comparar energías vs baseline
- Medir wall time (comparar vs sin OpenMP)
- Verificar reproducibilidad (Δ energía < 0.1%)
- Generar reporte de aceleración

---

## RIESGOS CONOCIDOS (A ACTUALIZAR CON ANÁLISIS)

| Riesgo | Probabilidad | Mitigación |
|--------|--------------|-----------|
| Race condition en `fx, fy, fz` | ALTA | No paralelizar acumulación sin `reduction()` |
| Seg fault por pragma incorrecto | MEDIA | Usar Edit tool (preciso) vs sed (destructivo) |
| GPU no activo con OpenMP | BAJA | Verificar compilación con `-fopenmp` |
| Overhead OpenMP > ganancia | MEDIA | Enfocarse en loops largos (>1000 iter) |

---

## TIMELINE

- ⏳ **Análisis:** 10-15 min (agente trabajando)
- 📋 **Revisión de plan:** 5 min (coordinador = yo)
- 🔨 **Implementación:** 30-45 min (agente + iteraciones)
- ✅ **Validación:** 10-15 min (agente 3 valida)

**Total estimado:** 60-90 minutos (vs 4 horas de intento manual)

---

## CRITERIOS DE ÉXITO

✅ Ejecutable compila sin errores  
✅ No hay segmentation faults  
✅ 3 validaciones completadas exitosamente  
✅ Energías reproducibles (diff < 0.1% vs baseline)  
✅ Wall time < baseline (o justificado si aumenta)  

---

## CRITERIOS DE ABORTO

❌ Seg fault persiste tras 2 iteraciones  
❌ Energías divergen > 1% vs baseline  
❌ No compila tras 3 intentos  

→ Rollback a main.f.pre_openmp + documentar lección

---

**Próximo paso:** Esperar análisis del agente.

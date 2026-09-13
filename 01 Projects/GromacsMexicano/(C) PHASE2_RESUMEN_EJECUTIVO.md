# 📊 PHASE 2 — RESUMEN EJECUTIVO

**Status:** Plan específico completado y guardado en vault

---

## 🎯 QUÉ ES PHASE 2

**Objetivo:** Paralelizar bonded forces (pairwise, bonds, angles, dihedrals, 1-4 pairs)

**Speedup esperado:** 1.5-2× adicional (cumulative: 4-6× total desde Fortran baseline)

**Riesgo:** MEDIUM (race conditions, pero soluciones documentadas)

---

## 6 LOOPS IDENTIFICADOS

| Loop | Archivo | Estrategia | Risk | Speedup |
|------|---------|-----------|------|---------|
| Pairwise forces | forces.cpp | Force buffering | HIGH | 2-4× |
| Neighbor list | neighbor.cpp | Per-thread merge | MEDIUM | 2-3× |
| Bond stretching | forces.cpp | Atomic | MEDIUM | 1.5-2× |
| Angle bending | forces.cpp | Atomic | LOW | 1.5-2× |
| Dihedrals | forces.cpp | Atomic | LOW | 1.5-2× |
| 1-4 pairs | forces.cpp | Atomic | LOW | 1.5-2× |

---

## 📋 ORDEN DE IMPLEMENTACIÓN (RECOMENDADO)

1. **Bonds + Angles + Dihedrals + 1-4 pairs** (4 loops, atomic)
   - Bajo riesgo, simple pattern
   - 1.5-2× cada uno
   - ~2 días implementación

2. **Pairwise forces** (1 loop, force buffering)
   - Alto riesgo, máximo payoff (2-4×)
   - Hacer después que tengas confianza en atomics
   - ~2 días implementación

3. **Neighbor list** (1 loop, per-thread merge)
   - Medium riesgo
   - Hacer al final
   - ~1 día implementación

**Total Phase 2:** ~5 días (Si quieres 3 loops rápido: ~2 días)

---

## 🚀 CÓMO PROCEDER

1. **Lees** `PHASE2_IMPLEMENTATION_PLAN.md` (en vault)
2. **Confirms** si haces los 6 loops o solo bonds/angles/dihedrals primero
3. **Delegas** con el plan específico (igual que Phase 1)
4. **Validar** reproducibilidad + timing
5. **Benchmark** Phase 1 vs Phase 2 vs baseline

---

## ⚠️ CONSIDERACIONES CRÍTICAS

**Force buffering (pairwise):**
- Cada thread necesita su propia copia de `fx[]`, `fy[]`, `fz[]`
- Después: sequential reduction con `#pragma omp critical`
- Cuidado: overhead memoria (multiple copies), overhead critical section

**Atomic operations (bonds, angles, etc.):**
- Simple: `#pragma omp atomic buf.fx[i] += fbond_x;`
- Más lento que buffers (contención), pero no requiere memoria extra
- Mejor para loops pequeños

**Neighbor list:**
- Per-thread local vectors
- Merge con critical (secuencial, rápido)

---

## 📁 ARCHIVOS GUARDADOS EN VAULT

```
(C) PHASE2_IMPLEMENTATION_PLAN.md
   └─ Plan completo (6 loops, pragmas específicos, línea-por-línea)
```

---

## ✅ CHECKLIST ANTES DE DELEGAR PHASE 2

- [ ] Leíste PHASE2_IMPLEMENTATION_PLAN.md
- [ ] Decidiste: ¿6 loops o solo bonds/angles/dihedrals?
- [ ] Entiendes diferencia entre force buffering y atomic
- [ ] Confirmaste que quieres proceder
- [ ] Listo para delegar

---

**¿Procedemos con Phase 2?** 

Opciones:
1. **Haz los 6 loops completo** (5 días, máximo speedup 4-6×)
2. **Haz solo bonded forces (loops 3-6 con atomic)** (2 días, speedup 3-4× cumulative)
3. **Haz solo pairwise primero** (2 días, speedup 4-6× pero más arriesgado)

¿Cuál prefieres?

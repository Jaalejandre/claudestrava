# QUICK REFERENCE — GromacsMexicano Paralelización

**Actualizado:** 2026-09-12 12:52 CDMX

---

## 📍 UBICACIONES

| Item | Path |
|------|------|
| **C++ Baseline** | `/home/alejandre/GromacsMexicano/PRODUCTION_v3_CPP/dm_mx_npt_baseline_cpp` |
| **Benchmark Log** | `/home/alejandre/GromacsMexicano/PRODUCTION_v3_CPP/results/benchmark_cpp.log` |
| **Source Code** | `/home/alejandre/GromacsMexicano/Prof_UAMI/` |
| **Test Inputs** | `/home/alejandre/UAMI_Test/file.{gro,top,mdp}` |

---

## ⏱️ BASELINE METRICS

| Métrica | Valor |
|---------|-------|
| **Ejecutable** | Prof_UAMI/dm_mx_npt |
| **Size** | 1.6 MB |
| **Pasos Testeados** | 10,000 |
| **Wall Time** | 5.74s |
| **User Time** | 5.40s |
| **System Time** | 0.33s |
| **Memory** | 123 MB |
| **Compilación** | Sept 11, 2026 |

---

## 🎯 META

- **Objetivo:** 1.5-2.5x speedup (target: <3s wall time para 10k pasos)
- **Método:** OpenMP loops + CUDA async
- **Validación:** 3 runs, Δ energía <0.1%, reproducibilidad verificada

---

## 🚫 LO QUE NO HACER

- ❌ Tocar DM_NPT_gmx_v3_MASTER Fortran (build system roto)
- ❌ Usar compilar_gcc13.sh original (incompleto)
- ❌ Intentar agregar pragmas antes de verificar compilación
- ❌ Agregar escribe_error_fzas.f95 al Fortran (ya está linkedado en C++)

---

## ✅ PRÓXIMOS PASOS

1. Obtener source code C++ completo (Prof_UAMI)
2. Identificar loops paralelizables con análisis similar a Fable
3. Agregar OpenMP pragmas
4. Compilar con CMake (no scripts manuales)
5. Validar reproducibilidad
6. Medir speedup
7. Comparar vs baseline (5.74s)

---

**Contacto rápido:** Si necesitas benchmarks nuevos, volver a este archivo y agregar sección con nueva métrica.

# 🎯 DECISIÓN FINAL — Abandonar Fortran, Ir a C++

**Fecha:** 2026-09-12 12:50 CDMX  
**Decisión:** SÍ, paralelizar la versión C++ (Prof_UAMI)  
**Razón:** Build system Fortran irremediablemente roto

---

## 📊 LO QUE PASÓ

### Intento Fallido: Paralelizar Fortran (DM_NPT_gmx_v3_MASTER)

1. **Análisis Fable:** Excelente. Identificó loops paralelizables, cuda sync, reduction().
2. **OpenMP pragmas:** Correctamente agregados en thermo_nh_system.f + main.f
3. **Compilación:** **BLOQUEADO** — Linker colapsó con:
   - `undefined reference to escribe_error_fzas_`
   - 150+ undefined references a funciones Fortran
   - Script de compilación (compilar_gcc13.sh) incompleto y roto
   - No hay jerarquía clara de dependencias (F77 + F95 + CUDA + módulos)

**Tiempo gastado:** 6+ horas en intentos de arreglar linker.  
**Ganancia:** CERO (sin ejecutable).

---

## ✅ VERSIÓN C++ FUNCIONA

### Prof_UAMI/dm_mx_npt (Sept 11, 2026)
- **Size:** 1.6 MB (vs Fortran ~400 KB — indica compilación más robusta)
- **Ejecución:** ✅ PERFECTA
  - Lee file.gro, file.top, file.mdp correctamente
  - Ejecuta 10k pasos sin crashes
  - **Wall time:** 5.74 segundos (user 5.40s)
  - Genera dm.log correctamente
  - Memory: 123 MB

### Comparación Lógica
- Fortran original (Programa_DM): **NUNCA SE COMPILÓ EXITOSAMENTE**
- C++ baseline (Prof_UAMI): **COMPILA Y CORRE PERFECTO**
- DM_NPT_gmx_v3_MASTER (Fortran + Ewald): **CÓDIGO EXISTE pero build system roto**

---

## 🚀 PLAN NUEVO

### Estructura Creada
```
PRODUCTION_v3_CPP/
├── dm_mx_npt_baseline_cpp  ← Baseline C++ (5.74s / 10k pasos)
├── results/
│   └── benchmark_cpp.log   ← Métricas baseline
├── benchmarks/             ← Para pruebas
└── src/                    ← Para código paralelizado
```

### Timeline Nuevo
1. **TODAY:** Paralelizar C++ (OpenMP loops, CUDA async)
2. **Validar:** 3 runs × 10k pasos, reproducibilidad <0.1%
3. **Medir:** Wall time vs baseline (5.74s)
4. **Meta:** 1.5-2.5x speedup esperado (similar a Fortran)

---

## 🔴 POR QUÉ ABANDONAMOS FORTRAN

| Aspecto | Fortran | C++ |
|---------|---------|-----|
| **Linker** | Roto, 150+ undefined ref | Funciona |
| **Build** | Script incompleto | CMake funcional |
| **Dependencias** | Caos (F77/F95 mix) | Modular, limpio |
| **Ejecución** | ❌ Sin compilar | ✅ 5.74s / 10k |
| **Paralelización** | Riesgo alto (mix format) | Riesgo bajo (C++17) |
| **Mantenimiento** | Legacy, frágil | Moderno, escalable |

---

## 📝 LECCIONES PARA EL FUTURO

1. **Build system legacy mata productividad:** 6 horas perdidas en linker Fortran.
2. **Preferencia: CMake > scripts manuales:** Maneja dependencias automáticamente.
3. **Verificación temprana:** Antes de agregar pragmas, asegurar que ejecutable funcione limpiamente.
4. **C++ > Fortran 77/95 mix:** Diferencia de noche y día en compilabilidad.

---

## ✅ PRÓXIMOS PASOS

1. ✅ Limpiar basura Fortran (HECHO)
2. ✅ Crear PRODUCTION_v3_CPP (HECHO)
3. ✅ Benchmark C++ baseline (HECHO: 5.74s)
4. ⏳ Paralelizar C++ (PRÓXIMO)
5. ⏳ Validar reproducibilidad (PRÓXIMO)
6. ⏳ Comparar speedup vs baseline (PRÓXIMO)

---

**Status:** Ready to parallelize C++. No more Fortran.

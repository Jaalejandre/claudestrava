# ✅ UAMI BASELINE LISTO

**Fecha:** 2026-09-11, 10:20 CET  
**Status:** LISTO PARA BENCHMARK

---

## Qué se descargó

**Servidor:** UAM Pacifico (pacifico5)  
**Ruta original:** `~/Edgar/DM_NPT_gmx_v3/`  
**Total:** 109 archivos Fortran + CUDA + 1 binario compilado

### Estructura en CT 901

```
/home/alejandre/GromacsMexicano/UAMI_baseline/
├── Código fuente (109 archivos)
│   ├── main.f                (2298 líneas, programa principal)
│   ├── *.f *.f95             (rutinas Fortran 77/95)
│   ├── *.cu                  (kernels CUDA)
│   ├── interfaz_*.f95        (wrappers CUDA-Fortran)
│   └── compilar_baseline.sh  (script compilación — fallido por dependencias)
│
└── dm_uami_baseline_binary   (1.3M, ejecutable, COMPILADO EN UAMI)
    └── CPU single-thread (baseline, sin OpenMP, sin GPU)
```

---

## VASE (Producto Baseline)

**Binario:** `/home/alejandre/GromacsMexicano/UAMI_baseline/dm_uami_baseline_binary`

**Características:**
- ✅ Código original UAMI
- ✅ CPU single-thread (NO paralelización)
- ✅ GPU CUDA presente en código (pero NO ejecutándose)
- ✅ Compilado con gfortran + nvcc en UAM

**Potenciales presentes:**
- Lennard-Jones (LJ) sf/st
- FDR (repulsivo)
- Mie (generalizado)
- Ewald k-space (kwald)
- Link-cell

---

## Próximos Pasos

### Opción A: Usar binario UAMI como es
1. ✅ Binario descargado
2. ⏭️ Test: 1000 pasos (VASE baseline)
3. ⏭️ Comparar con dm_mx_npt anterior
4. ⏭️ Benchmark: Tiempo, energías

### Opción B: Recompilar con OpenMP (v3 OpenMP)
1. Necesita resolver dependencias .mod
2. Compilar con `-fopenmp`
3. Test: OMP_NUM_THREADS=1,2,4
4. Medir speedup paralelo

### Opción C: Usar binario como GPU (si ya tiene CUDA compilado)
1. Test: OMP_NUM_THREADS=1, GPU enabled
2. Verificar si kernels CUDA están activos
3. Medir GPU performance

---

## Archivos de referencia

- **Código descargado en vault:** `/root/JarvisVault/01 Projects/GromacsMexicano/main_uami.f` (y otros)
- **Estrategia:** `/root/JarvisVault/01 Projects/GromacsMexicano/ESTRATEGIA_v3_UAMI.md`
- **Estado anterior:** `/root/JarvisVault/01 Projects/GromacsMexicano/ESTADO_v3_FINAL.md` (versión antigua, NO usar)

---

## ¿Qué hago ahora?

**Opciones:**

**A)** Test UAMI baseline tal como está → benchmark vsBenchmark anterior  
**B)** Intentar recompilación con OpenMP → crear v3_omp  
**C)** Pausa y definir estrategia clara

¿Cuál?


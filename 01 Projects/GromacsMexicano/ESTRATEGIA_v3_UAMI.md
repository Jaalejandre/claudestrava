# Estrategia v3 UAMI — Línea Base vs GPU+Paralelo

**Fecha:** 2026-09-11  
**Cambio de Dirección:** UAMI es el producto BASE (VASE)

---

## Decisión Estratégica

**Antes:** Estábamos usando `dm_mx_npt` (variante diferente)  
**Ahora:** Usar `dm_uami` (UAMI base científica) como referencia

**Por qué:** 
- UAMI tiene datos distintos
- UAMI es el código original de los científicos
- Necesitamos comparar UAMI (baseline) vs v3 (GPU+paralelo derivado de UAMI)

---

## Código Fuente UAMI

**Origen:** Servidor UAM Pacifico  
- Ruta: `~/Edgar/DM_NPT_gmx_v3/main.f`
- Tamaño: 67K (2298 líneas)
- Compilador: gfortran + CUDA (kernels .cu presentes)
- Status: ✅ Descargado a vault

**Archivo local:**
```
/root/JarvisVault/01 Projects/GromacsMexicano/main_uami.f
```

---

## Estructura Descubierta en UAMI

```
Edgar/DM_NPT_gmx_v3/
├── main.f                           (67K, 2298 líneas)  ← DESCARGADO
├── Rutinas Fortran (.f)
│   ├── mdp.f, top_gmx.f95
│   ├── fzas_*.f (LJ, FDR, ángulos, dihedros)
│   ├── kwald_o.f, lista.f
│   └── etc (~70 rutinas)
├── Kernels CUDA (.cu)
│   ├── fzas_lj_sf_cuda.cu
│   ├── fzas_fdr_sf_cuda.cu
│   ├── kwald_cuda.cu
│   ├── lista_linkcell_cuda.cu
│   └── etc (interfaces CUDA)
├── Binario compilado
│   └── dm_mx_npt (1.3M, CUDA linkado)
└── Datos
    └── file.mdp (parametrizaciones)
```

**Potenciales presentes:**
- ✅ Lennard-Jones (LJ) + short-field (sf) y switched (st)
- ✅ FDR (repulsivo adicional)
- ✅ Mie (generalizado)
- ✅ Ewald k-space (kwald_cuda)
- ✅ Link-cell CUDA (aceleración de vecinos)

---

## Plan v3 UAMI (GPU + OpenMP)

### Fase 1: Baseline UAMI (SIN modificaciones)
1. Copiar `main_uami.f` + rutinas a directorio limpio
2. Compilar con gfortran (single-thread, CPU-only)
3. Test: 1000 pasos
4. Benchmark: Tiempo base, energías

### Fase 2: Agregar OpenMP (Paralelo CPU)
1. Insertar `!$OMP PARALLEL DO` en loops críticos
2. Recompilar con `-fopenmp`
3. Test: OMP_NUM_THREADS=1,2,4
4. Benchmark: Medir speedup paralelo

### Fase 3: GPU (Ya presente en code)
1. Verificar kernels CUDA presentes
2. Compilar con nvcc + gfortran
3. Ambiente CUDA 13.0 (CT 901)
4. Test: GPU enabled
5. Benchmark: CPU single vs CPU paralelo vs GPU

### Fase 4: Comparación Final
```
| Versión | Config | Tiempo (10k pasos) | Speedup | Status |
|---------|--------|-------------------|---------|--------|
| UAMI (baseline) | CPU 1-thread | T_base | 1.0× | TODO |
| UAMI + OpenMP | CPU 4-threads | T_omp | ? | TODO |
| v3 UAMI | GPU + OMP | T_gpu | ? | TODO |
```

---

## Diferencia con Previous dm_mx_npt

**Lo que teníamos antes:**
- `Programa_DM/dm_mx_npt` — versión compilada (948K)
- Datos: `agua_nacl_5m_Ewald`
- Status: Estable pero NOT UAMI base

**Lo nuevo:**
- `main_uami.f` — código fuente UAMI (2298 líneas)
- Datos: (a determinar en UAMI)
- Status: CÓDIGO ORIGINAL DE CIENTÍFICOS

---

## Siguientes Pasos

**INMEDIATO (hoy):**
1. ✅ Descargar main_uami.f
2. ⏭️ Descargar todas las rutinas .f de UAMI
3. ⏭️ Crear directorio `/home/alejandre/GromacsMexicano/UAMI_baseline/`
4. ⏭️ Compilar UAMI sin modificaciones (baseline)
5. ⏭️ Test 1000 pasos, verificar energías

**DESPUÉS:**
- Agregar OpenMP
- Compilar GPU
- Benchmark final

---

## Comandos de Referencia

**Descargar todo de UAMI:**
```bash
sshpass -p 'JaQUImica-uaMIzt26' ssh jalejandre@pacifico.izt.uam.mx \
  "ssh pacifico5 'cd ~/Edgar/DM_NPT_gmx_v3 && tar czf - .' " > uami.tar.gz
```

**Compilar UAMI baseline (gfortran single-thread):**
```bash
cd /home/alejandre/GromacsMexicano/UAMI_baseline
gfortran-13 -O3 -ffree-form main.f *.f -o dm_uami
```

**Compilar UAMI + OpenMP:**
```bash
gfortran-13 -O3 -ffree-form -fopenmp main.f *.f -o dm_uami_omp
```

---

**Producto VASE:** UAMI baseline (código original)  
**Producto v3:** UAMI + GPU + OpenMP (derivado optimizado)

**Objetivo:** Cuantificar speedup real de paralelización.

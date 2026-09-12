# (C) Benchmark UAMI_baseline — 2026-09-11

## Con qué se hizo el benchmark

- **Caso de prueba:** `Prueba/` (el oficial del dashboard) — H₂O SPC/E + NaCl, 2544 átomos, 10 000 pasos, NPT, Ewald real + termostato/barostato Nosé-Hoover (MTTK), `dt=0.0002`, `rcut=1.2nm`, caja 2.9613³ nm³. Copiado a `/home/alejandre/GromacsMexicano/Bench_UAMI_baseline/` (aislado, no se tocó `Prueba/`).
- **Binario:** `dm_mx_npt` recompilado en CT901 desde `/home/alejandre/UAMI_Source/` (código de UAM Pacífico, distinto del Fortran de este proyecto), flags de producción `-O3 -march=native`.
- **Hardware:** CT901, RTX 5070 Ti (`sm_120`, compute capability 12.0), CUDA 13.0, gfortran 13.3. Verificado libre (`who` + `ps aux` + `nvidia-smi`) antes de medir — se encontró y detuvo una corrida de 500k pasos (`/tmp/bench_v3`, con loop de auto-relanzamiento en una sesión bash desde el 9 de sept) que estaba ocupando CPU+GPU al 99%.
- **Metodología:** 3 corridas limpias, `time ./dm_mx_npt`, mismas condiciones que las filas "Fortran sin Ewald/Optimizado" ya en el dashboard.

## Bug real encontrado (no de config)

Al correr el caso de 2544 átomos (el de 102 átomos de ayer nunca lo activó): **`SIGFPE` dentro del kernel CUDA `fzas_lj_st_cuda.cu`**, exclusivamente con sistemas grandes (1.5M pares en la lista de vecinos) — el sistema chico de ayer (150 pares) no lo disparaba.

- Diagnóstico: agregué `fprintf` de depuración + `compute-sanitizer --tool memcheck` (0 errores de memoria) para descartar accesos fuera de rango. Probé con y sin `-ffpe-trap` — seguía crasheando sin ese flag, lo que descarta que fuera una trampa de punto flotante y apunta a una excepción real a nivel de hardware/driver.
- **Causa real:** los kernels CUDA se compilaban con `nvcc -arch=sm_86` (Ampere), pero la GPU real es `sm_120` (Blackwell, `nvidia-smi --query-gpu=compute_cap` → `12.0`). El JIT del driver tolera el desajuste en kernels chicos pero falla en kernels con miles de bloques.
- **Fix:** recompilar los 9 archivos `.cu` con `-arch=sm_120` (`nvcc --list-gpu-arch` confirma que está soportado). Con eso el binario corrió limpio.

## Resultado

```
Corrida 1: 182.184s
Corrida 2: 182.175s
Corrida 3: 182.046s
Promedio:  182.14s
```

**Validación física** (no solo "corrió"):
- Exit code 0 en las 3 corridas.
- `energy.dat`: 1000 filas de datos (header + 1 fila cada 10 pasos × 10 000 pasos), 0 NaN, 0 Inf.
- Temperatura promedio: **298.42 K** (objetivo 298.15 K).
- Presión promedio: **1.95 bar** (objetivo ~1 bar, dentro de fluctuación NPT normal).
- ΔE (deriva de energía): **0.00030 kJ/mol** — muy buena conservación.

## Comparación con el dashboard

| Versión | Tiempo | vs Original |
|---|---|---|
| Fortran sin Ewald (-O0) | 151.4s | base |
| Fortran sin Ewald Optimizado (-O3, sm_120) | 98.0s | −35.3% |
| **UAMI_baseline (-O3, sm_120)** | **182.1s** | **+20.3%** |

**UAMI_baseline es más lento** que ambas versiones de "Fortran sin Ewald" — esperado, y no por más pasos (las tres corridas usan los mismos 10 000): el Fortran de este proyecto tiene el bug `NATQ` documentado (`main.f:1641`, ver `CLAUDE.md` del proyecto) que deja el **Ewald recíproco inactivo** — calcula menos física por paso, por eso sale más rápido. UAMI_baseline sí corre el Ewald recíproco completo, y tampoco pasó por la ronda de optimización de kernels (−45.7% wall time, cerrada 2026-09-04) que se aplicó al Fortran de GromacsMexicano.

## Dónde quedó

- Dashboard vivo actualizado: `http://192.168.0.64:8851` (fila `UAMI_baseline` en tarjetas/gráfica/tabla, aviso arriba explicando histórico de Fortran sin Ewald/Optimizado).
- Binario de producción: `/home/alejandre/UAMI_Source/dm_mx_npt` (recompilado `sm_120`, sin flags de debug).
- Corridas: `/home/alejandre/GromacsMexicano/Bench_UAMI_baseline/` (`run_final1.log`, `run_final2.log`, `run_final3.log`, `energy.dat`).

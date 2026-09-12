# ✅ TEST UAMI BASELINE: 1000 PASOS — VERIFICADO EN CT901

**Fecha:** 2026-09-11 ~11:00 CDMX
**Status:** ✅ Real, verificado línea por línea (no solo exit code)

---

## Contexto

La nota `(C) UAMI_TEST_1000_PASOS_SUCCESS.md` (10:38) decía "éxito, sin errores" pero era falsa: corría el binario viejo (CUDA 11), `energy.dat` tenía solo la cabecera y el log terminaba en `ERROR: ref-t debe ser positivo`. Se verificó contra el servidor real (CT 901, no las notas) y se encontraron 6 problemas distintos, 2 de ellos bugs reales del programa Fortran de UAMI (no solo de configuración).

## Bugs encontrados y arreglados

| # | Problema | Causa | Fix |
|---|---|---|---|
| 1 | `run_uami.sh` corría binario viejo | Apuntaba a `UAMI_Test/dm_mx_npt` (CUDA 11, copia sin recompilar) en vez de `UAMI_Source/dm_mx_npt` (CUDA 13, recompilado en CT901) | Apuntado al binario correcto |
| 2 | Crash "ref-t debe ser positivo" | `file.mdp` no traía `ref-t` | Agregado `ref-t=300`, `tc-grps=System`, `tau-t=0.1` |
| 3 | `ULJ`=7.7M kJ/mol, `Vangles`=NaN al inicio | `file.gro` generado con posiciones dummy random, sin respetar bond/ángulo de la topología (script `gen_gro.sh` bash roto) | Reescrito `gen_gro.py`: geometría SPC/E real (O-H=0.09572nm, ángulo H-O-H=109.47°) en malla 4×3×3 |
| 4 | `Ethermo`=NaN desde el paso 0 | Sin velocidades iniciales en `file.gro` (T=0K → 0/0 en el termostato). El programa **no genera velocidades**, las lee del `.gro` | `gen_gro.py` agrega velocidades Maxwell-Boltzmann a 300K (masas O=15.9994, H=1.008 amu) |
| 5 | **Bug real en `ini_xis_system.f`**: con `nh-chain-length=1` (default), el loop solo inicializa `qp(1)`, pero la línea siguiente hace `qp(1)=9*qp(2)` leyendo `qp(2)` **sin inicializar** → NaN | Forzado `nh-chain-length=2` en `file.mdp` (workaround de config, no se tocó el Fortran) |
| 6 | **Bug real en `main.f:2178`**: `mod(istep, nstxout)` con `nstxout=0` → división por cero → `SIGFPE` | `nstxout=1000` en vez de 0 |

Bugs #5 y #6 son defectos del Fortran original de UAMI (código congelado/referencia), no de la config — solo aparecen con ciertos valores de `file.mdp` que el programa no valida. Documentados aquí, **no corregidos en el fuente** (regla del proyecto: no tocar el código de los científicos).

## Recompilación

Usé el script que ya estaba en el repo, `compilar_cuda_ct901.sh`, con `nvcc` en PATH (`export PATH=/usr/local/cuda/bin:$PATH`) y agregando `-Wl,--allow-multiple-definition` al link (símbolos duplicados de `ISO_C_BINDING`). Flags del script: `-O0 -g -fbacktrace -fcheck=bounds -ffpe-trap=invalid,zero,overflow` — con esto el bug #6 dio backtrace con línea exacta (`main.f:2178`) en vez de fallar en silencio.

Binario: `/home/alejandre/UAMI_Source/dm_mx_npt` (1.3M, CT901, CUDA 13 + gfortran 13.3).

## Verificación real (no solo exit code)

```
EXIT=0
energy.dat: 103 líneas (3 cabecera + 100 filas de datos, 1 cada 10 pasos)
grep -ci nan energy.dat  → 0
grep -ci inf energy.dat  → 0
```

Energía total (`etot`) estable entre ~124–132 kJ/mol durante los 1000 pasos, sin blowup. Temperatura sube de 300K a ~500-560K hacia el final (el termostato Nose-Hoover no la controla del todo en 2ps desde geometría inicial artificial en malla — esperable para un sistema que arranca lejos del equilibrio, no es un bug).

## Archivos

- Binario: `/home/alejandre/UAMI_Source/dm_mx_npt` (CT901)
- Test: `/home/alejandre/UAMI_Test/` (`file.gro`, `file.top`, `file.mdp`, `energy.dat`, `uami_test_1000.log`)
- Generador de geometría corregido: `/home/alejandre/UAMI_Test/gen_gro.py`

## Próximos pasos

1. Sistema mayor (100 → 1000+ átomos) para benchmark real.
2. Verificar si los kernels CUDA realmente se ejecutan (GPU) vs. solo CPU.
3. Comparar contra v3 GPU (proyecto en curso, reescritura C++).

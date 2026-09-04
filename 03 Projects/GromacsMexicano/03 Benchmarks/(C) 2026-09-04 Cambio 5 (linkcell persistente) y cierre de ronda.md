# Benchmark 2026-09-04 — Cambio #5 (buffers persistentes en linkcell) y cierre de la ronda de optimización GPU

## Cambio #5 — Buffers persistentes en `lista_linkcell_cuda`

**Dónde:** `lista_linkcell_cuda.cu` — se llama ~cada 7 pasos (73 veces en el perfilado de 500 pasos, 12.7% del tiempo GPU en esas llamadas).

**Qué cambia:** cada llamada hacía `cudaMalloc`+`cudaMemcpy`+`cudaFree` completo de todos sus buffers, incluido `cell_atoms` (`maxnat × ncells` enteros, el más grande). `ncells = ncx·ncy·ncz` depende de `floor(box/rlist)`; bajo NPT la caja fluctúa cada paso, pero `ncells` (un entero) casi nunca cambia en la práctica. Se volvieron persistentes los buffers de tamaño fijo, con reasignación solo si `maxnat`/`maxlist`/`ncells` cambian — mismo patrón *reinit-on-change* que ya usa `kwald_init_cuda` para Ewald. La geometría (`cellx`/`celly`/`cellz`) se sigue recalculando cada llamada porque sí depende del valor exacto de la caja.

**Wall time** (10 000 pasos, CT 901 verificado libre con `who`/`ps aux` antes de cada corrida):

| Corrida | Tiempo |
|---|---|
| 1 | 1:37.72 |
| 2 | 1:37.74 |
| 3 | 1:37.85 |
| **Promedio** | **1:37.77** |

Varianza: 0.13s. Vs. referencia cambio #2c (1:39.98): **−2.2%**. Cero crashes.

**Física** (Total, kJ/mol, referencia −89.05846 ± 0.01195): −89.05723 / −89.05691 / −89.05630 — dentro de 1σ en las 3.

## Cierre de la ronda: #7 (OpenMP) y "bonos a GPU" — evaluados y descartados

Antes de cerrar se evaluaron las dos opciones que quedaban en la cola.

**Medición:** se necesitaba saber cuánto tiempo de CPU (no GPU) consumen las rutinas por-paso. `perf` no se pudo instalar (requiere `sudo`, sin contraseña disponible — no se le pide al usuario que la comparta por chat). Se usó `gprof` en su lugar: recompilación aparte con `-pg` (sin tocar el binario release validado), corrida corta (500 pasos externos × 20 sub-pasos, `file.mdp` con `nsteps=500`), `gprof dm_mx_npt gmon.out`.

**Resultado:**

| Rutina | % CPU muestreado | Llamadas | Tiempo/llamada |
|---|---|---|---|
| `MAIN__` (loops de integración) | 29.6% | 1 | — |
| `fzas_angulo_` | 20.4% | 10001 | 20 µs |
| `fzas_de_` | 15.3% | 10001 | 15 µs |
| `check_` | 14.3% | 10000 | 14 µs |
| `intra_` | 6.1% | 501 | 120 µs |

Extrapolado, ~19% del tiempo de pared es cómputo puro de CPU — más de lo esperado dado que el profiling GPU anterior mostraba la CPU mayormente esperando (`cudaDeviceSynchronize` 41.9%).

**Por qué se descartaron ambas rutas igual:**

- `fzas_angulo`/`fzas_de`/`check` se llaman ~200 000 veces en una corrida completa, cada una con solo 14-20µs de trabajo.
- El sistema tiene muy pocos elementos para paralelizar: 800 moléculas de agua → **1600 enlaces, 800 ángulos** (confirmado en `spce.itp`). Comparado con `nk≈2900` en Ewald o decenas de miles de pares en LJ, es un problema 10-30x más chico.
- El overhead de abrir una región OpenMP (fork-join) o lanzar un kernel CUDA standalone (malloc/memcpy/kernel/memcpy/free, launch + sync) es típicamente de 15-30µs — del mismo orden o mayor que el trabajo que se quiere paralelizar. Es el mismo modo de falla que hizo fallar el cambio #3 (overhead > ganancia).
- La única vía que evitaría ese overhead sería fusionar estos cálculos dentro del lanzamiento de kernel LJ que ya ocurre cada paso (reusar posiciones ya residentes en GPU, un solo round-trip CPU↔GPU). Pero eso es una reestructura de arquitectura que toca `main.f`, la interfaz Fortran↔CUDA y cómo se combinan las contribuciones de fuerza — riesgo real de condición de carrera silenciosa en `fx/fy/fz` (el tipo de bug que pasa el chequeo de 1σ por suerte y falla después), por un techo de solo ~7% adicional en el mejor caso.

**Decisión (2026-09-04, con el usuario):** cerrar la ronda de optimización GPU en el estado actual. La relación esfuerzo/riesgo/beneficio de seguir es peor que la de cualquiera de los 5 cambios ya capturados.

## Total acumulado de la ronda

Debug original (3:00.14) → **1:37.77 promedio** = **−45.7% wall time**, física validada dentro de 1σ en cada uno de los 5 cambios, cero crashes en el estado final (`ca9ef61`).

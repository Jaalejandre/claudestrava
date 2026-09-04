# Benchmark 2026-09-04 — Debug baseline vs Release (-O3)

**Cambio:** #1 del plan (`02 Optimizacion`) — build de release (`-O3 -march=native -funroll-loops`) en vez de debug (`-O0 -g -fcheck=bounds -ffpe-trap=...`). Script nuevo: `compilar_release.sh` (el original `compilar_cuda.sh` no se tocó).

**Caso de prueba:** agua SPC/E (800 mol) + 72 Na + 72 Cl = 2544 átomos, `nbfunc=4`, 10 000 pasos, `dt=0.2 fs`.

## Tiempo de pared

| Build | Wall time | User time | % ganancia |
|---|---|---|---|
| Debug (`-O0`, referencia original) | 3:00.14 | 174.24s | — |
| Release (`-O3 -march=native`) | **2:10.10** | 124.37s | **+27.7%** |

## Física (release vs. referencia, ver `01 Analisis`)

| Cantidad | Referencia | Release | Δ dentro de 1σ |
|---|---|---|---|
| Potential | −98.874 ± 0.214 | −98.844 ± 0.200 | ✅ |
| Kinetic | 10.002 ± 0.167 | 10.026 ± 0.157 | ✅ |
| Total | −89.058 ± 0.012 | −89.060 ± 0.012 | ✅ |
| ΔE | 0.00013 ± 0.00009 | 0.00013 ± 0.00010 | ✅ |
| Density | 1162.96 ± 7.34 | 1161.62 ± 7.82 | ✅ |
| Temperature | 297.60 ± 4.96 | 298.29 ± 4.68 | ✅ |
| Pressure | 2.20 ± 791.9 | 1.67 ± 810.2 | ✅ |

Todas las cantidades dentro de 1σ. Cambio validado.

## Lectura

Solo el flag de compilación dio +27.7%, pero el análisis de código (§5A en `01 Analisis`) ya predecía que el grueso del tiempo NO es cómputo Fortran sino el `cudaMalloc`/`cudaMemcpy`/`cudaFree` repetido en cada paso de DM dentro de los kernels CUDA. Esto confirma que el próximo cambio (#2: buffers GPU persistentes) es donde está la ganancia grande, no aquí.

**Nota importante sobre "sweet spot de cores":** el código hoy **no tiene ningún paralelismo de CPU** (ni OpenMP ni vectorización explícita) — el bucle de DM completo corre en 1 solo core (confirmado: 99% CPU de 1 hilo en ambas corridas). No tiene sentido medir "cores óptimos" todavía porque no hay nada que escale con más cores — eso es el cambio #5 del plan (OpenMP en los bucles `do i=1,nat`). El benchmark de sweet-spot se hace **después** de meter OpenMP, no antes.

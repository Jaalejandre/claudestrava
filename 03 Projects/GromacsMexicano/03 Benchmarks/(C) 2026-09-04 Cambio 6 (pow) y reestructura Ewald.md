# Benchmark 2026-09-04 — Cambio #6 (`pow`→multiplicación) y reestructura Ewald (cambio #2c)

Dos cambios validados en la misma sesión, en secuencia, sobre la base `6c8db7d` (buffers constantes persistentes, ya validada).

## Cambio #6 — `pow(sigmaij/rij, 6.0)` → multiplicaciones directas

**Dónde:** `kernel_fzas_lj_st` (`fzas_lj_st_cuda.cu`), el kernel LJ+Coulomb — 47.3% del tiempo GPU según el profiling de `nsys`.

**Qué cambia:** `pow(x, 6.0)` con exponente real es mucho más caro que `x²·x²·x² = x⁶` con multiplicaciones directas. Mismo resultado matemático, riesgo mínimo.

Trabajo iniciado por José directamente en CT 901; se encontró el benchmark ya corrido y limpio, se verificó y se commiteó (`90b2995`).

**Wall time** (10 000 pasos, entorno verificado libre de otra actividad):

| Corrida | Tiempo |
|---|---|
| 1 | 1:56.98 |
| 2 | 1:57.22 |
| 3 | 1:56.87 |
| **Promedio** | **1:57.02** |

Varianza: 0.35s. Vs. referencia `6c8db7d` (2:04.79): **−6.2%**.

**Física** (Total, kJ/mol, referencia −89.05846 ± 0.01195): −89.06062 / −89.05818 / −89.05792 — dentro de 1σ en las 3.

## Cambio #2c — Reestructura de kernels Ewald por ocupación de GPU

**Dónde:** `build_structure_factors_from_trig_kernel` y `force_kwald_from_trig_kernel` (`kwald_cuda.cu`) — 23.7% + 7.1% del tiempo GPU.

**Corrección de una hipótesis previa:** el status del proyecto asumía que estos kernels "ya estaban bien optimizados" porque no usan `atomicAdd`. Cierto que no lo usan, pero **el paralelismo era insuficiente de todos modos**: con el caso de prueba real (`kmaxx=kmaxy=kmaxz=11` → `nk≈2900` k-vectors), la versión anterior lanzaba:

- `build_structure_factors_from_trig_kernel`: 1 hilo por k-vector (`ik`), cada uno con un loop serial sobre los 2544 átomos → solo `nk/128 ≈ 23` bloques activos.
- `force_kwald_from_trig_kernel`: 1 hilo por átomo, loop serial sobre los ~2900 k-vectors → solo `nat/128 ≈ 20` bloques activos.

Con una GPU de decenas de SMs, ~20 bloques la deja mayormente vacía.

**Qué cambia:** mismo patrón ya validado en `kernel_fzas_lj_st` (cambio #2b) pero aplicado para *subir el número de bloques* en vez de para *bajar atomics*: ahora 1 bloque por `ik` (o por átomo), 128 hilos reparten el loop interno con stride, y se reduce en árbol en memoria compartida. La suma es la misma cantidad, solo reordenada (no asociatividad de punto flotante da diferencias esperadas en el último bit).

**Wall time** (10 000 pasos, `who`/`ps aux`/`nvidia-smi` verificados limpios antes de cada corrida):

| Corrida | Tiempo |
|---|---|
| 1 | 1:39.93 |
| 2 | 1:40.00 |
| 3 | 1:40.01 |
| **Promedio** | **1:39.98** |

Varianza: 0.08s — muy ajustada. Vs. referencia cambio #6 (1:57.02): **−14.6%**. Cero crashes en las 3 corridas.

**Física** (Total, kJ/mol, referencia −89.05846 ± 0.01195): −89.05947 / −89.05748 / −89.05536 — dentro de 1σ en las 3.

## Incidente durante la validación (contexto, no afecta el resultado final)

La primera corrida de este cambio se hizo mientras un proceso ajeno (`ABtest3`, un reintento manual de "buffers persistentes" por José) corría en paralelo en CT 901 — eso contaminó una medición (2:15.76 en vez de ~2:00) y luego una corrida completa fue matada externamente (`SIGKILL`, exit 137) a mitad de camino, probablemente por la sesión interactiva de José en el mismo contenedor. Los 3 números reportados arriba son de una segunda ronda, corrida **después** de confirmar `who` y `ps aux` limpios. Ver nota de protocolo actualizada en `CLAUDE.md` (verificar concurrencia antes de medir).

## Total acumulado

Debug original (3:00.14) → **1:39.98 promedio** = **−44.5% wall time**, física validada en cada paso, cero crashes en el estado actual (`2110700`).

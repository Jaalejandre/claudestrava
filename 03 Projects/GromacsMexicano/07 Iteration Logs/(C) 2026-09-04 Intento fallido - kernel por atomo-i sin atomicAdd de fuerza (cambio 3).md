# 2026-09-04 (noche) — Intento fallido: kernel de fuerzas LJ por átomo-i sin `atomicAdd` de fuerza (Cambio #3)

## Qué se intentó

Reescribir `kernel_fzas_lj_st` en `fzas_lj_st_cuda.cu` de "1 hilo por PAR (i,j) con `atomicAdd(&fx[i],...)`/`atomicAdd(&fx[j],...)`" a "1 hilo por ÁTOMO i, sin atomicAdd de fuerza" — patrón estándar en MD-GPU.

`nblist1`/`nblist2` (construidos en `lista_linkcell_cuda.cu`) solo guardan **la mitad** de cada par (convención `i<j`, filtro `j<=i -> continue`). Un kernel por-átomo necesita ver TODOS los vecinos de cada átomo, no solo la mitad. Para no tocar `lista_linkcell_cuda.cu` ni la interfaz Fortran (y así acotar el radio de riesgo, aprendiendo del incidente de buffers persistentes anterior), se construyó la lista de adyacencia simétrica **dentro del mismo `.cu`**, en cada llamada:

1. `count_degree_kernel` — cuenta vecinos por átomo (atomicAdd sobre enteros, no sobre fuerzas).
2. `exclusive_scan_kernel` — scan exclusivo de grados → offsets (kernel de 1 solo hilo, nat=2544 es pequeño).
3. `fill_neighbors_kernel` — segunda pasada sobre los pares, llena la lista CSR simétrica.
4. `kernel_fzas_lj_st_atom` — 1 hilo por átomo, recorre su lista completa de vecinos, acumula fuerza en registro local, escribe `fx[i]/fy[i]/fz[i]` UNA vez (cero atomicAdd de fuerza). Energía/virial se cuentan una sola vez por par usando la condición `vecino > átomo_propio` (evita doble conteo, ya que cada par ahora aparece en las listas de AMBOS átomos).

Se agregó `cudaGetLastError()` después de cada etapa (malloc, memset, cada kernel launch+sync, free).

## Resultado

- **Compiló limpio** (`-O3 -march=native -funroll-loops`, solo warnings preexistentes).
- **Física correcta**: corrida completa de 10 000 pasos, Total −89.05648 ± 0.01240 (referencia −89.058 ± 0.012), ΔE 0.00012 ± 0.00009 (referencia 0.00013 ± 0.00009), Density 1159.98 ± 8.60 (referencia 1162.96 ± 7.34), Temperature 298.55 ± 4.89 (referencia 297.60 ± 4.96) — todo dentro de 1σ. El algoritmo es correcto.
- **Rendimiento: catastrófico.** Tiempo de pared: **8m32.766s**, contra 2:04.79 de referencia (`6c8db7d`) — **≈4.1× MÁS LENTO**, no una mejora. Se abortó después de esta primera corrida (no se hicieron las 4 restantes) porque el resultado es inequívoco y repetirlo no cambiaría la conclusión.

## Por qué salió tan mal (análisis honesto de causa raíz)

El objetivo era eliminar la contención de `atomicAdd` en `fx/fy/fz` (6 atomics por par). Se logró — cero atomics de fuerza en el kernel final. Pero el costo se movió a otro lado y resultó mucho peor:

1. **Trabajo por-par duplicado.** El kernel original evalúa la física completa (LJ + Coulomb erfc/exp, ambas funciones trascendentales caras) **una vez por par** (`npares` evaluaciones). El kernel nuevo, al tener lista simétrica completa, evalúa esa misma física **una vez por cada extremo del par** (`2×npares` evaluaciones) — el hilo `i` y el hilo `j` cada uno recorre el par independientemente y recalcula `erfc`, `exp`, `pow`, `sqrt` desde cero. Solo se evita duplicar la *acumulación* de energía/virial (con el filtro `j>i`), pero el cómputo de fuerza en sí se duplica sin remedio en este diseño.
2. **Dos pasadas extra sobre la lista de pares, en CADA llamada.** `count_degree_kernel` y `fill_neighbors_kernel` recorren los `npares` pares completos cada vez que se llama `fzas_lj_st_cuda` (~20 000 veces en 10 000 pasos, ya que se llama ~2×/paso). Como el cambio se hizo autocontenido en este archivo (para no tocar `lista_linkcell_cuda.cu` ni la interfaz Fortran), esta reconstrucción CSR se paga en **cada** llamada, no solo cuando la lista de vecinos se reconstruye de verdad (~cada 7 pasos, según el profiling de `construir_pares`).
3. **Combinado:** el trabajo total de "pasadas sobre pares" pasó de `1×npares` (kernel original) a aproximadamente `4×npares` (`count_degree` + `fill_neighbors` + `2×` en el kernel de fuerzas por la duplicación de #1). Eso encaja casi exactamente con el factor ~4.1× de slowdown observado — no es ruido, es la aritmética del cambio.

**Conclusión:** la premisa "atomicAdd de fuerza es el cuello de botella dominante" no se sostiene aquí frente al costo real: la contención de `atomicAdd` sobre 6 doubles por par resultó ser MENOS cara que duplicar el cómputo de `erfc`/`exp`/`pow` por par, más pagar la reconstrucción de la lista de adyacencia en cada llamada. El patrón "1 hilo por átomo, full neighbor list" SÍ es estándar y gana en muchos códigos MD-GPU, pero típicamente:
   - construyendo el full-list en el kernel de construcción de vecinos (no en el de fuerzas, y no en cada llamada de fuerzas sino solo cuando la lista se reconstruye), y
   - a menudo cacheando o compartiendo el cómputo par a par entre bloques (shared memory tiling), no recalculándolo por separado en cada extremo.
   Implementar eso bien requeriría tocar `lista_linkcell_cuda.cu` y la interfaz Fortran para persistir la lista CSR entre llamadas de fuerza (solo reconstruirla cuando `construir_pares` se ejecuta) — una reestructuración bastante más grande, con su propio riesgo, que no se justifica dado que el cambio #2 (reducción por bloque, ya aplicado) capturó la ganancia fácil de los atomics de energía/virial, y el atomicAdd de fuerza por sí solo no domina lo suficiente como para justificar duplicar el trabajo aritmético.

## Qué se hizo

- Se revirtió `fzas_lj_st_cuda.cu` a su estado exacto en `6c8db7d` (`git checkout --`).
- Se recompiló el binario limpio con `compilar_release.sh` — confirmado que vuelve a ser el kernel validado (pair-based, con atomicAdd de fuerza, reducción por bloque para energía/virial).
- No se commiteó nada de este intento.
- Se limpiaron los directorios de prueba (`run_c3_1`..`run_c3_5`).

## Recomendación para el futuro (si se retoma)

Si en una sesión futura se quiere de verdad eliminar el atomicAdd de fuerza sin duplicar el cómputo por-par:
1. Construir la lista CSR simétrica **una sola vez**, dentro de `lista_linkcell_cuda.cu`, junto con (o en vez de) `nblist1`/`nblist2`, y persistirla en buffers GPU hasta la siguiente reconstrucción de lista (esto sí requiere tocar la interfaz Fortran — pasar `offsets`/`neighbors` a través de la cadena de llamadas, o hacerlos globales persistentes en el `.cu` con una bandera "lista cambió").
2. Mantener el cómputo de la física **una vez por par** (no una vez por extremo): por ejemplo, procesar pares en bloques donde un bloque de hilos calcula la fuerza de un conjunto de pares una sola vez y la deposita con `atomicAdd` en memoria compartida por bloque antes de un único `atomicAdd` a memoria global por átomo tocado en ese bloque (reduce el número de atomics globales sin duplicar el cómputo transcendental).
3. Alternativamente, no perseguir este cambio — el cambio #2 ya capturó la fracción fácil, y #6 (`pow()`→multiplicación) es una ganancia garantizada de bajo riesgo sin ninguna de estas complicaciones.

Se descarta el cambio #3 para esta sesión. Se sigue con el cambio #5 (revisar `construir_pares`) y el cambio #6 (`pow()`→multiplicación, aplicado sobre el kernel actual validado, no sobre el experimento fallido).

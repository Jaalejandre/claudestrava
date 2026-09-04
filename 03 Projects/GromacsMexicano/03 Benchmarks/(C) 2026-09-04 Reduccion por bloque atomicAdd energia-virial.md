# Benchmark 2026-09-04 — Reducción por bloque (atomicAdd energía/virial)

**Cambio:** #2 del plan re-priorizado (`01 Analisis/(C) 2026-09-04 Profiling real...`) — reducción por memoria compartida dentro de cada bloque CUDA para los 8 acumuladores globales (`ulj`, `ucoul`, `wxx`, `wxy`, `wxz`, `wyy`, `wyz`, `wzz`) en `kernel_fzas_lj_st`. Antes: cada hilo activo hacía `atomicAdd` directo a las 8 direcciones globales. Ahora: reducción en árbol dentro del bloque (256 hilos), solo el hilo 0 hace los 8 `atomicAdd` finales por bloque.

**No se tocó:** los `atomicAdd` de fuerzas (`fx[i],fy[i],fz[i],fx[j],fy[j],fz[j]`) — eso es el cambio #3, más riesgoso (requiere reformatear la lista de vecinos a formato por-átomo). Tampoco se tocó la gestión de memoria (malloc/free por llamada, igual que el release validado). Un cambio a la vez.

Se agregó `cudaGetLastError()` después de cada etapa (malloc, memcpy H2D, kernel, memcpy D2H, free) para diagnóstico — lección del intento fallido anterior donde un bug produjo un segfault silencioso.

## Metodología (reforzada tras el intento fallido anterior)

Dado que el cambio anterior (buffers persistentes) pareció funcionar en una corrida y crasheó en la siguiente, esta vez se corrió el caso de prueba completo (10 000 pasos) **tres veces seguidas** antes de aceptar el resultado.

## Tiempo de pared

| Build | Wall time | Δ vs. release |
|---|---|---|
| Release (`c698cc7`, referencia) | 2:10.10 | — |
| Reducción por bloque, corrida 1 | 2:06.40 | −3.7s |
| Reducción por bloque, corrida 2 | 2:06.21 | −3.9s |
| Reducción por bloque, corrida 3 | 2:06.02 | −4.1s |
| **Promedio** | **2:06.21** | **−3.9s (≈3.0%)** |

Varianza entre corridas: 0.38s — mucho más ajustada que el ruido visto en el intento anterior (~8s), lo cual da confianza en que la mejora es real, no ruido de medición. **Cero crashes en las 3 corridas.**

## Física (las 3 corridas vs. referencia)

| Cantidad | Referencia | Corrida 1 | Corrida 2 | Corrida 3 | Dentro de 1σ |
|---|---|---|---|---|---|
| Potential | −98.874 ± 0.214 | −98.840 | −98.719 | −98.866 | ✅ (las 3) |
| Kinetic | 10.002 ± 0.167 | 10.004 | 10.032 | 10.002 | ✅ |
| Total | −89.058 ± 0.012 | −89.060 | −89.060 | −89.060 | ✅ (muy consistente) |
| ΔE | 0.00013 ± 0.00009 | 0.00014 | 0.00014 | 0.00014 | ✅ |
| Density | 1162.96 ± 7.34 | 1161.41 | — | — | ✅ |
| Temperature | 297.60 ± 4.96 | 297.65 | — | — | ✅ |
| Pressure | 2.20 ± 791.9 | 1.45 | — | — | ✅ |

## Lectura

Ganancia modesta (~3%) pero real, estable y verificada — coherente con lo esperado: solo se atacó **una fracción** de la contención de `atomicAdd` en un kernel que representa 47.3% del tiempo GPU (los `atomicAdd` de fuerzas, que no se tocaron, siguen ahí). El cambio #3 (kernel por átomo-i sin atomicAdd de fuerza) debería dar más, pero requiere reformatear la lista de vecinos — mayor riesgo, se hace como iteración separada.

**Total acumulado hasta ahora:** 3:00.14 (debug original) → 2:06.21 (release + reducción) = **−29.7% wall time**, física validada en cada paso.

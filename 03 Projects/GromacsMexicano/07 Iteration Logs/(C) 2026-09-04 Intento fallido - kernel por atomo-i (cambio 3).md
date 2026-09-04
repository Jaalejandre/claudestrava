# 2026-09-04 — Intento fallido: kernel LJ por átomo-i sin atomicAdd de fuerzas (cambio #3)

## Qué se intentó

Reestructurar `kernel_fzas_lj_st` de "1 hilo por PAR (i,j)" (con `atomicAdd` en `fx[i]`/`fx[j]` para acumular fuerzas — colisión de escritura entre hilos que comparten átomo) a "1 hilo por ÁTOMO i" que recorre todos sus vecinos y escribe `fx[i]` una sola vez, sin atomics de fuerza.

**Enfoque:** dado que `nblist1`/`nblist2` (de `lista_linkcell_cuda.cu`) solo guardan cada par una vez (`i<j`), se agregó — dentro del mismo archivo, sin tocar la lista de vecinos original — la construcción de una lista de adyacencia simétrica en formato CSR (offsets + vecinos concatenados) en 3 pasos: contar grado por átomo (`atomicAdd` sobre enteros), scan exclusivo (1 hilo, barato), y llenar la lista. Esto se repetía en **cada llamada** (no solo cuando se reconstruye la lista de pares real).

## Resultado

- **Física correcta:** Total −89.05648 (referencia −89.058±0.012, dentro de 1σ). El algoritmo era correcto.
- **Rendimiento: 8 min 49s — 4.3× MÁS LENTO** que el estado actual (2:04.79). Regresión severa, no ganancia.

## Por qué (lectura, sin haber debuggeado a fondo — se revirtió por tiempo, no se investigó exhaustivamente)

Dos costos nuevos que superaron con creces el ahorro de eliminar los atomics de fuerza:

1. **Reconstruir el CSR en cada llamada** (no solo cuando la lista de pares real se reconstruye) añade trabajo O(npares) extra en cada una de las ~20 000 llamadas de la corrida completa.
2. **Duplicación de la matemática cara:** en el kernel original, cada par calculaba UNA vez `erfc`/`exp`/`sqrt`/`pow` (las operaciones más caras del kernel, ver profiling) y aplicaba la fuerza a ambos átomos vía `atomicAdd`. En el kernel por-átomo, cada átomo recorre su lista de vecinos simétrica y **recalcula la misma matemática cara para ambas direcciones del par** (una vez cuando lo visita el átomo i, otra vez cuando lo visita el átomo j) — duplica el trabajo más costoso del kernel para ahorrar en atomics, que según el profiling no eran el costo dominante.

## Lección para una futura iteración (si se retoma)

Este patrón SÍ funciona bien en muchos códigos de MD-GPU (es el que ya usa `kwald_cuda.cu` para las fuerzas de Ewald, con éxito), pero ahí cada átomo recorre una lista de **vectores-k** (no depende de un cálculo pareja-a-pareja caro por vecino) — el caso de LJ+Coulomb es distinto porque el costo por-vecino SÍ es caro (erfc/exp/sqrt).

Para que este enfoque funcione en LJ habría que:
1. Construir el CSR **solo cuando se reconstruye la lista de pares real** (no en cada llamada) — cachearlo igual que se hizo con los buffers constantes.
2. Evitar la duplicación de matemática: computar la física una vez por par y escribir el resultado en un buffer intermedio (por ejemplo, fuerza escalar + dx/dy/dz por par, ya calculados), y que el kernel por-átomo solo sume esos valores ya calculados (sin recalcular erfc/exp/sqrt) — esto es más complejo de implementar correctamente y no se intentó por tiempo.

**No se recomienda retomar esto sin resolver ambos puntos primero** — de lo contrario se repite la misma regresión.

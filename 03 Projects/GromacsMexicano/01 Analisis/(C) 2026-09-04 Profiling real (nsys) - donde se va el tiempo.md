# Profiling real con `nsys` — 2026-09-04

> Corrida de perfilado: caso de prueba estándar (agua+NaCl, 2544 átomos) con `nsteps=500` (recortado de 10 000 solo para que el trazado no tarde demasiado), binario release (`c698cc7`, `-O3 -march=native`). Comando: `nsys profile --stats=true -o dm_profile ../Programa_DM/dm_mx_npt`, análisis con `nsys stats --report cuda_api_sum,cuda_gpu_kern_sum,cuda_gpu_mem_time_sum`.

## Por qué se hizo esto

El análisis inicial (`(C) Analisis del programa dm_mx_npt.md`, §5A) hipotetizaba, **sin perfilar**, que el `cudaMalloc`/`cudaMemcpy`/`cudaFree` repetido por paso era "probablemente el 80% del problema". Se intentó arreglar eso (buffers persistentes) — no dio mejora medible y además introdujo un crash no determinista (ver `07 Iteration Logs/(C) 2026-09-04 Intento fallido...`). Este documento reemplaza esa hipótesis con datos reales.

## 1. CUDA API Summary — dónde espera la CPU

| Llamada | % tiempo | Total (500 pasos) | # llamadas | Lectura |
|---|---|---|---|---|
| `cudaMemcpy` | 48.2% | 2.543 s | 27 623 (~55/paso) | Dominante. Muchas transferencias pequeñas y repetidas — varias suben datos que **no cambian entre pasos** (`iitipo`, `carga`, `sigma`, `eps`) |
| `cudaDeviceSynchronize` | 41.9% | 2.211 s | 1 074 | Es la CPU esperando a que el kernel termine — refleja el costo real de cómputo GPU |
| `cudaMalloc` | 4.9% | 256 ms | 20 773 | Menor de lo esperado |
| `cudaFree` | 4.3% | 228 ms | 20 750 | Menor de lo esperado |
| `cudaMemset` | 0.5% | 29 ms | 11 230 | — |
| `cudaLaunchKernel` | 0.2% | 13 ms | 3 151 | — |

**malloc + free combinados = 9.2%**, no ~80%. La optimización intentada (cambio #2) atacaba el problema equivocado.

## 2. CUDA GPU Kernel Summary — dónde se va el cómputo real

| Kernel | % tiempo GPU | Instancias | Avg/llamada | Lectura |
|---|---|---|---|---|
| `kernel_fzas_lj_st` | **47.3%** | 1001 | 1.72 ms | El kernel de fuerzas LJ+Coulomb real. 1.72ms es lento para 2544 átomos en una RTX 5070 Ti — coincide con los puntos C/D/E del análisis original: `atomicAdd` sobre 8 escalares globales (energía, tensor de presión) serializa hilos; `atomicAdd` por-par en `fx[i],fx[j]` colisiona; `pow(sigmaij/rij, 6.0)` en vez de multiplicaciones |
| `force_kwald_from_trig_kernel` | 23.7% | 501 | 1.72 ms | Ewald recíproco — mismo orden de magnitud que LJ, probable mismo patrón de atomicAdd ineficiente |
| `construir_pares` (lista de vecinos) | 12.7% | 73 | **6.35 ms** | Se llama poco (lista se reconstruye ~cada 7 pasos) pero cada llamada es carísima — vale la pena revisar el algoritmo del kernel de construcción de pares |
| `build_trig_table_kernel` (Ewald) | 9.0% | 501 | 0.66 ms | — |
| `build_structure_factors_from_trig_kernel` (Ewald) | 7.1% | 501 | 0.52 ms | — |
| `energy_virial_kwald_kernel` | ~0% | 501 | 2.6 µs | Trivial |
| `asignar_celdas` (link-cell) | ~0% | 73 | 3.0 µs | Trivial |

**Lectura combinada:** LJ (47%) + Ewald completo (40%) + lista de vecinos (13%) = prácticamente el 100% del tiempo GPU. Esto es esperado (son las 3 partes caras identificadas desde el análisis inicial) — lo nuevo es saber que **dentro de cada una, el kernel mismo es ineficiente**, no solo la gestión de memoria alrededor.

## 3. CUDA GPU MemOps Summary

| Operación | % tiempo | Total | # |
|---|---|---|---|
| Host→Device | 86.5% | 680 ms | 11 310 |
| Device→Host | 12.9% | 101 ms | 16 313 |
| Memset | 0.6% | 4.6 ms | 11 230 |

El tiempo de transferencia GPU real (780ms) es menor que el tiempo de API de `cudaMemcpy` medido en CPU (2.54s) — la diferencia es *overhead de la llamada síncrona en sí* (setup, no ancho de banda). Confirma que **reducir el número de llamadas** (no solo su tamaño) importa: subir `iitipo`/`carga`/`sigma`/`eps` una sola vez en vez de cada paso eliminaría una fracción real de las 27 623 llamadas.

## 4. Plan de optimización re-priorizado (reemplaza el orden original)

| # | Cambio | Basado en | Ganancia esperada |
|---|---|---|---|
| 1 | ~~Buffers GPU persistentes (malloc/free)~~ | Intentado, revertido — solo 9.2% del problema y con bug | ~~alta~~ → **baja, no vale el riesgo solo** |
| **2** | **Reducción por bloque para `atomicAdd` de energía/virial en `kernel_fzas_lj_st` y kernels de Ewald** | 47%+40% del tiempo GPU está en estos kernels; atomicAdd sobre 8 escalares globales serializa | **alta** |
| **3** | **Kernel de fuerzas por átomo-i (sin atomicAdd de fuerza por par)** | Mismo kernel, colisión de escritura en `fx[i],fx[j]` | **alta**, requiere reformatear la lista de vecinos |
| **4** | **Subir `iitipo`/`carga`/`sigma`/`eps` una sola vez (son constantes durante toda la corrida), no cada llamada** | 48.2% del tiempo de API es `cudaMemcpy`, con miles de llamadas redundantes | **media**, bajo riesgo (dato no cambia, fácil de razonar) |
| 5 | Revisar el kernel `construir_pares` — 6.35ms/llamada es alto para link-cell | 12.7% del tiempo GPU en solo 73 llamadas | media |
| 6 | Matemática del kernel: `pow()` → multiplicación directa | Parte del 47% de `kernel_fzas_lj_st` | baja-media, fácil y de bajo riesgo |
| 7 | OpenMP en bucles CPU | El bucle de DM sigue en 1 solo core (fuera del alcance de este profiling, que midió solo GPU) | media, pendiente |

## 5. Nota metodológica para la próxima iteración

Cualquier cambio a estos kernels debe:
1. Agregar `cudaGetLastError()` después de cada `cudaMalloc`/kernel launch/memcpy — el crash anterior fue un segfault silencioso sin diagnóstico.
2. Correr el caso de prueba **completo** (10 000 pasos, no el recorte de 500 usado aquí solo para perfilar) al menos 2-3 veces antes de concluir que hay ganancia real — ya se vio comportamiento no determinista en una corrida.
3. Verificar física dentro de 1σ en cada cambio, sin excepción.

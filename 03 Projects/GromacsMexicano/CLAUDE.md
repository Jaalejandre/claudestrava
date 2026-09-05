# GromacsMexicano

Adaptación de un código de dinámica molecular (DM) tipo GROMACS, desarrollada por un grupo de científicos, que incorpora ecuaciones/potenciales propios (LJ, Mie, FDR, Ewald con termostato y barostato Nosé-Hoover, ensamble NPT) y busca ser fácil de usar para gente que **no sabe línea de comandos**. La meta a largo plazo: un programa instalable en muchos dispositivos, que corra en paralelo (CPU multinúcleo + GPU), y adaptable para público general.

El código base es Fortran (f77/f95) con kernels CUDA, compilado con `compilar_cuda.sh`. Los científicos entregan un programa que **corre bien** y sirve como punto de partida para analizar, optimizar y eventualmente reescribir en otros lenguajes.

## Claude's Role

Analizar el código de DM existente y optimizarlo para que corra en paralelo aprovechando la GPU. En concreto:

- Leer y mapear el programa (`Programa_DM/`): flujo de ejecución, qué hace cada rutina, dónde está el costo computacional real (fuerzas no enlazadas, listas de vecinos/link-cell, Ewald).
- Identificar cuellos de botella y oportunidades de paralelización (GPU CUDA, OpenMP en CPU, vectorización).
- Proponer y aplicar optimizaciones con **benchmarks antes/después** usando el caso de prueba (`Prueba/`, agua + NaCl) — nunca "optimizar a ciegas".
- Verificar que los resultados físicos no cambien: energías, temperatura, presión, densidad y RDF deben coincidir dentro del error estadístico con la corrida de referencia (`dm.log`).
- Cuando aplique, preparar el terreno para reescritura a otro lenguaje o para empaquetado multiplataforma.

**Prime directive:** Si una sesión se desvía sin acercarse a *código de DM más rápido y verificado corriendo en paralelo con GPU*, regrésame al foco: "¿Esto hace que la simulación corra más rápido sin cambiar la física? Si no, ¿por qué lo estamos haciendo?"

## Arquitectura de trabajo (IMPORTANTE — difiere de la skill New Dev Project)

El código y la GPU **NO** viven en `claude-dev`. Viven en otro contenedor:

| Dato | Valor |
|---|---|
| Contenedor | CT **901** `ubuntu` en Proxmox (`192.168.0.52`) |
| IP (DHCP) | `192.168.0.230` — verificar con `ssh root@192.168.0.52 "pct exec 901 -- hostname -I"` |
| Usuario del código | `alejandre` (home `/home/alejandre/`) |
| GPU | NVIDIA RTX 5070 Ti (Blackwell, `sm_120`), CUDA disponible en el PATH de `alejandre` |
| CPU / RAM | 12 vCPU / 24 GB |
| Código original | `/home/alejandre/Programa_DM/` (Fortran + CUDA) |
| Caso de prueba | `/home/alejandre/Prueba/` — correr con `correr_dm.sh`, genera `dm.log` / `dm.lis` |
| Otras versiones | `/home/alejandre/DM_NPT_gmx_v2/`, `/home/alejandre/DM_NVE/` (ver README de Prueba) |
| GROMACS de referencia | `gromacs-2025.2`, `gromacs-2025.3` compilados en el home |

- **El vault (`03 Projects/GromacsMexicano/`) es para contexto, análisis, planes y benchmarks documentados.** El trabajo real de código ocurre por SSH en CT 901.
- Una **copia de trabajo con git** del código vive en `/home/alejandre/GromacsMexicano/` (o `Programa_DM` bajo git) para versionar cambios sin tocar el original de los científicos hasta validar.
- El original de los científicos en `/home/alejandre/Programa_DM/` es **read-only conceptualmente**: no se modifica sin permiso; se trabaja sobre la copia.

## Process

1. **Ingesta** — Copiar `Programa_DM/` + `Prueba/` a una copia de trabajo con git. Compilar tal cual con `compilar_cuda.sh` y correr el caso de prueba para tener la **línea base** (tiempo de pared + `dm.log` de referencia).
2. **Análisis** — Mapear el código en `01 Analisis/`: diagrama de llamadas, coste por rutina (profiling con `gprof`/`nsys`/`ncu`), estado actual de la paralelización (qué ya está en CUDA, qué en CPU serial).
3. **Plan de optimización** — En `02 Optimizacion/`: lista priorizada de cambios (flags de compilación `-O3`/arch reales — hoy compila en `-O0 -g`; OpenMP; mover/optimizar kernels CUDA; memoria pinned; overlap CPU/GPU). Un cambio por iteración.
4. **Aplicar + medir** — Implementar el cambio en la copia de trabajo, recompilar, correr el caso de prueba, comparar resultados físicos vs. referencia y tiempo vs. línea base. Registrar en `03 Benchmarks/`.
5. **Verificar física** — Energías / T / P / densidad / RDF dentro del error. Si cambia la física, el cambio se revierte o se investiga.
6. **Iterar** — Repetir 3–5. Documentar aprendizajes en `07 Iteration Logs/`.
7. **(Futuro)** Reescritura a otro lenguaje / empaquetado multiplataforma / interfaz sin CLI.

## Key People

- **Yo (José)** — desarrollo, optimización, paralelización.
- **Científicos (grupo de DM)** — autores de las ecuaciones y del código base. Entregan el programa funcionando; son la autoridad sobre la física y los potenciales. Ante cualquier duda sobre el significado físico de una rutina o parámetro, se les pregunta.

## Folder Structure

- `00 Codigo Fuente Original/` — copia de referencia / notas del código tal como lo entregaron los científicos (el código vivo está en CT 901, aquí solo van copias puntuales y notas).
- `01 Analisis/` — mapeo del código, diagramas de llamadas, resultados de profiling, dónde está el costo.
- `02 Optimizacion/` — planes de optimización priorizados, notas de diseño de cada cambio.
- `03 Benchmarks/` — mediciones antes/después: tiempo de pared, comparación de resultados físicos vs. referencia.
- `04 System/` — scripts de compilación/corrida/benchmark reutilizables, config.
- `05 Skills/` — procesos reutilizables como markdown (NO skills de Claude Code).
- `06 Attachments/` — imágenes, gráficas, PDFs (papers, diagramas).
- `07 Iteration Logs/` — qué se probó, qué funcionó, qué no, qué mejorar.

## Rules & Conventions

- **`(C)` prefix** — Archivos creados por Claude llevan prefijo `(C)`.
- **Editar** — Antes de editar cualquier archivo sin prefijo `(C)`, pedir permiso.
- **Skills** — Automatizaciones reutilizables como markdown en `05 Skills/`, no como skills de Claude Code.
- **No tocar el código original de los científicos** (`/home/alejandre/Programa_DM/`) sin permiso explícito — trabajar sobre la copia con git.
- **Nada de optimización sin benchmark** — todo cambio de rendimiento se mide antes/después con el caso de prueba.
- **La física manda** — si una optimización cambia energías/T/P/RDF fuera del error estadístico, no vale, sin importar cuánto acelere.
- **Un cambio por iteración** — para poder atribuir mejoras y regresiones.
- **Serena** (MCP de código a nivel de símbolo) está disponible en el entorno de Claude Code — usarlo para navegar el Fortran.

## Current Status

> **Last updated:** 2026-09-04 (noche) — **RONDA DE OPTIMIZACIÓN GPU CERRADA**
> **Status:** En `ca9ef61`. Acumulado validado (CT 901 verificado libre con `who`/`ps aux`/`nvidia-smi` antes de cada medición): debug original 3:00.14 → release `-O3` 2:10.10 (`c698cc7`) → reducción por bloque atomicAdd 2:06.21 (`978d385`) → buffers constantes persistentes 2:04.79 (`6c8db7d`) → `pow()`→multiplicación directa 1:57.02 (`90b2995`, cambio #6) → reestructura kernels Ewald por ocupación 1:39.98 (`2110700`, cambio #2c) → buffers persistentes en `lista_linkcell_cuda` 1:37.77 (`ca9ef61`, cambio #5). **Total: −45.7% wall time acumulado, física validada en cada paso, cero crashes.** Cerrado aquí por decisión explícita del usuario (2026-09-04) tras revisar las opciones restantes (ver abajo) y concluir que el riesgo/esfuerzo ya no compensa.
> **Corrección importante sobre Ewald:** una entrada anterior de este status decía "ya está bien optimizado — sin atomicAdd, no hay ganancia fácil ahí". Esa conclusión solo revisó si había `atomicAdd` (no lo hay) pero no revisó **ocupación de GPU**: con `nk≈2900` k-vectors, los kernels de Ewald lanzaban solo ~20-25 bloques (1 hilo por ik/átomo, loop serial larguísimo adentro) — la GPU quedaba casi vacía. Se reestructuró a 1 bloque por ik/átomo con reducción en memoria compartida (mismo patrón que ya funcionó en LJ) → −14.6% adicional. Lección: "sin atomicAdd" no es lo mismo que "bien paralelizado" — siempre revisar tamaño de grid vs. SMs disponibles antes de descartar un kernel.
> **Profiling real hecho (`nsys`)** — ver `01 Analisis/(C) 2026-09-04 Profiling real (nsys) - donde se va el tiempo.md` (nota: su tabla de prioridades quedó desactualizada por el punto anterior).
> **Cambio #3 INTENTADO Y REVERTIDO** — kernel por átomo-i sin atomicAdd de fuerza en LJ. Física correcta pero **≈4.1× MÁS LENTO** (construir la lista de adyacencia simétrica en cada llamada cuadruplicó el trabajo por-par). Revertido, sin commit. Detalle en `07 Iteration Logs/(C) 2026-09-04 Intento fallido - kernel por atomo-i sin atomicAdd de fuerza (cambio 3).md`.
> **#7 (OpenMP en CPU) y "bonos a GPU" (enlaces/ángulos/check) EVALUADOS Y DESCARTADOS** — con `gprof` (sin recompilar con privilegios, `perf` no se pudo instalar por falta de sudo) se midió que `fzas_angulo_`/`fzas_de_`/`check_` son ~19% del tiempo de pared pero se llaman ~200 000 veces con solo 14-20µs de trabajo cada una (enlaces=1600, ángulos=800 elementos — muy pocos). El overhead de abrir una región OpenMP o lanzar un kernel CUDA por llamada (15-30µs típico) es del mismo orden o mayor que el trabajo en sí — mismo modo de falla que el cambio #3. La única vía viable sería fusionar estos cálculos dentro del lanzamiento de kernel LJ ya existente (reusar posiciones ya residentes en GPU, un solo round-trip), pero eso es una reestructura de arquitectura de alto riesgo (condiciones de carrera silenciosas en `fx/fy/fz`) por, en el mejor caso, ~7% adicional. No se justifica frente a los cambios ya capturados.
> **Nota sobre concurrencia:** este proyecto se trabajó por al menos dos vías a la vez (Claude vía SSH + José directo en terminal en CT 901) en la misma sesión. Esto causó una corrida matada a medio camino (`SIGKILL`, exit 137) y una medición contaminada (2:15.76 en vez de ~2:00). **Regla: siempre verificar `who` + `ps aux | grep dm_mx_npt` en CT 901 inmediatamente antes de lanzar una corrida de benchmark**, y si hay trabajo concurrente ajeno sin commitear en el working tree, aislarlo con `git stash` (con permiso) antes de tocar los mismos archivos.
> **Nota sobre agentes en background:** un subagente autónomo no entregó nada usable en ~30 min y dejó procesos huérfanos que contaminaron mediciones posteriores — evitar delegar en agentes background sin verificar que terminen limpio antes de continuar.
> **Nota de protocolo:** cada cambio se corre 3 veces completas (10 000 pasos) antes de aceptarlo, con `cudaGetLastError()` en los kernels tocados, y verificación de que CT 901 esté libre de otra actividad antes de medir tiempo.
> **Si se retoma la optimización más adelante:** no repetir OpenMP ni bonos-a-GPU tal cual (ver arriba, ya descartados con datos). Caminos no explorados: fusionar cálculos de enlaces/ángulos en el kernel LJ existente (alto riesgo, ~7% techo), o pasar a la fase de reescritura a otro lenguaje mencionada como objetivo a largo plazo del proyecto.

> **REWRITE A C++ — Fase 0 completa (2026-09-04 noche).** Empezó la reescritura a C++ (meta: instalable multiplataforma, como GROMACS real). Ver plan completo en `02 Optimizacion/(C) 2026-09-04 Plan de reescritura a C++.md` y el registro de ejecución en `07 Iteration Logs/(C) 2026-09-04 Fase 0 del rewrite a C++ - completa.md`.
> - Nuevo directorio en CT 901: `/home/alejandre/GromacsMexicano/Programa_DM_cpp/` (proyecto CMake), junto al `Programa_DM/` de Fortran que **sigue siendo la referencia congelada, nunca se toca**. Commits `ca9ef61..ddbc798` en `master` (sin branches, mismo patrón que todo este proyecto).
> - Fase 0 (plomería, cero física portada): los 3 kernels CUDA ya validados se reubicaron byte-por-byte sin cambios; prueba de humo real vía CTest confirma que uno de ellos (`lista_linkcell_cuda`) funciona correctamente a través del build nuevo.
> - Ejecutado con subagentes (dispatcher/reviewer separados) — la revisión final de rama completa encontró un bug real y serio: el `CMakeLists.txt` tenía mal el orden de `CMAKE_CUDA_ARCHITECTURES` vs. `project()`, y el build compilaba para `sm_75` en vez de `sm_120`, corriendo en la RTX 5070 Ti solo por JIT del driver, no porque el binario fuera el correcto. Corregido y verificado con `cuobjdump` sobre el binario compilado. **Lección que aplica a cualquier build system nuevo:** verificar el binario compilado, no solo que la variable de configuración tenga el valor esperado.
> - **Corrección al roadmap:** la Fase 3 (portar el driver de LJ/Ewald/linkcell a C++) NO es solo pegamento — `fzas_lj_st_cuda.cu` tiene una guarda de buffers persistentes sin reinicio-si-cambia y teardown inconsistente entre los 3 archivos. Tocar eso es un cambio real de kernel que requiere el protocolo completo de validación física (3 corridas limpias, 1σ), no un simple cambio de quién llama a qué.
> - **Siguiente paso:** Fase 1 (parsers de `.gro`/`.mdp`/`.top`) — se planea en detalle recién cuando toque empezarla, no antes (mismo principio de nunca portar a ciegas que guio toda la optimización GPU).

<!-- TODO: Confirmar con José si quiere que el acceso SSH a CT 901 sea directo (agregar llave a alejandre@901) o siempre vía el host Proxmox -->
<!-- TODO: Confirmar ensamble/caso de prueba canónico para benchmarks (el actual: agua + NaCl, NPT) -->

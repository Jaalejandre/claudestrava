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
| Contenedor | CT **901** `ubuntu` en Proxmox (`192.168.0.52`) — inventario completo del server en [[(C) Mapa del servidor pve]] / skill [[proxmox.md]] |
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

## Cómo leer este vault (ahorro de tokens)

El historial documentado pesa ~30k tokens; el estado al día cabe en 2 notas. **Por defecto lee SOLO estas dos, sin escanear el resto:**

1. `02 Optimizacion/(C) 2026-09-08 Analisis - todo lo que falta (Fase 3 Task 6 + Fase 4 + Fase 5).md` — estado verificado del rewrite C++: snapshot del repo (commit, tests), qué está hecho y qué falta.
2. `04 System/(C) 2026-09-07 BASE para memoria del rewrite C++.md` — la memoria persistente del rewrite en CT 901 (qué es, dónde vive, cómo enruta por OmniRoute).

**NO leer por defecto** (leer solo si la tarea los toca explícitamente):

- Planes de fases ya implementadas en `02 Optimizacion/` (Fase 1 IO → `4547b7a`, Fase 2 bonded → `ee500a3`) — el código ya está en CT 901, el plan no aporta contexto nuevo.
- `03 Benchmarks/` y `07 Iteration Logs/` — histórico de la ronda de optimización GPU (cerrada 2026-09-04).
- `01 Analisis/` — mapeo/profiling del Fortran original; útil solo para entender el código base.
- `00 Codigo Fuente Original/` — solo si se necesita el Fortran de referencia.
- El estado vivo y detallado del rewrite está en la nota 1 (`02 Optimizacion/(C) 2026-09-08...`) y en `03 Benchmarks/(C) 2026-09-10 Fase 5...`; el `Current Status` de abajo es el resumen.
- En CT 901, no leer `build/`, binarios ni `.base*/` — estado de herramienta, no contexto.

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

> **Last updated:** 2026-09-10 — **REWRITE C++/CUDA COMPLETO (Fases 0–6).**
>
> **Repo CT 901** `/home/alejandre/GromacsMexicano/Programa_DM_cpp/`, rama `master` hasta `53b8dd0`. 20/20 tests (`ctest`) verde. El binario es `gmx_mexicano` (`build/src/`).
>
> **Qué hace hoy:** lee `file.gro`/`file.mdp`/`file.top`, corre dinámica **NPT** (integrador MTS r-RESPA velocity-Verlet + cadenas Nosé-Hoover para termostato y barostato MTTK isotrópico, LJ-ST + Coulomb real + Ewald recíproco en GPU, corrección de dispersión LRC), y reporta promedios ± σ. `--help`, detección automática de GPU/CPU, `install()` + CPack (tarball).
>
> **Validación (Fase 5, gate end-to-end):**
> - Gate corto 5 pasos NVE/NVT: **bit-idéntico** al Fortran (`etot` rel ~5e-15). NPT rel 1.1e-5.
> - 10 000 pasos NPT vs Fortran de referencia **parcheado**: todos los promedios dentro de 1σ (Total a 1.6σ = error estadístico), **`deltaE` 6× mejor que el Fortran**, T≈298 K y P≈1 bar (objetivos). **C++ ~1.5× más rápido** (10 ms/paso).
> - Detalle: `03 Benchmarks/(C) 2026-09-10 Fase 5 - Gate end-to-end (rewrite C++).md`.
>
> **⚠️ BUG en el Fortran de referencia (pendiente de confirmar con los científicos):** `main.f:1641` llama `KWALD` con `NATQ` (nunca inicializado → 0) y `CARGAQ` (nunca llenado) → **el Ewald recíproco está inactivo en la dinámica del Fortran** (energía y fuerzas). El bloque pre-loop "Valores iniciales" (`main.f:955`) sí es correcto. **Todos los benchmarks previos de este proyecto (incl. la ronda GPU −45.7%) corrieron con este bug.** El rewrite C++ corre la física correcta por default (`IntegratorParams::recip_in_loop = true`) y se valida contra un Fortran parcheado (`Programa_DM_cpp/reference/natq_ewald_fix.patch`). Flag para volver al comportamiento stock si los científicos dicen que era intencional.
>
> **Falta (nada bloqueante):**
> - Confirmar el fix de `NATQ` con el grupo de DM (decisión de física, es de ellos).
> - Fase 6: paquetes deb/rpm (CPack ya hace tarball; deb/rpm necesita decidir bundling del runtime CUDA).
> - Writers per-step (`energy.dat`/`movie.gro`/`dm.log`) — diferidos, YAGNI hasta que alguien quiera trayectorias.
> - `main.cpp` solo cubre casos MTS B/C; casos A/D, `fzas_diedro` y `fzas_15` (todos cero en el sistema de prueba) sin portar.
> - Benchmark de timing riguroso (3× limpio) vs GROMACS real — tarea aparte.

> **RONDA DE OPTIMIZACIÓN GPU sobre el Fortran — cerrada 2026-09-04 en `ca9ef61`, −45.7% wall time** (3:00.14 → 1:37.77, física validada en cada paso). Lecciones que siguen valiendo:
> - **"Sin `atomicAdd`" ≠ "bien paralelizado":** revisar siempre tamaño de grid vs. SMs disponibles antes de descartar un kernel. Los kernels de Ewald lanzaban ~20 bloques con `nk≈2900` k-vectors; reestructurar a 1 bloque/ik con reducción en shared memory dio −14.6%.
> - **OpenMP en CPU y "bonos a GPU" (enlaces/ángulos/check): descartados con datos.** Se llaman ~200k veces con 14-20µs de trabajo; el overhead de abrir región OpenMP / lanzar kernel (15-30µs) es igual o mayor que el trabajo. Único camino viable (no explorado): fusionar en el kernel LJ existente, alto riesgo por ~7%.
> - **Concurrencia:** verificar `who` + `ps aux | grep -E "dm_mx_npt|gmx_mexicano"` + `nvidia-smi` en CT 901 **antes** de cualquier corrida de benchmark. Trabajo concurrente contamina mediciones (histórico: exit 137, 2:15 en vez de 2:00).
> - **Build systems nuevos:** verificar el binario compilado (`cuobjdump`/`cuobjdump -sass`), no solo que la variable de config tenga el valor esperado (Fase 0 shipeaba `sm_75` con `CMAKE_CUDA_ARCHITECTURES=120` mal puesto).
> - Detalle histórico en `03 Benchmarks/` y `07 Iteration Logs/` (2026-09-04).

<!-- TODO: Confirmar con José si quiere que el acceso SSH a CT 901 sea directo (agregar llave a alejandre@901) o siempre vía el host Proxmox -->
<!-- TODO: Confirmar ensamble/caso de prueba canónico para benchmarks (el actual: agua + NaCl, NPT) -->

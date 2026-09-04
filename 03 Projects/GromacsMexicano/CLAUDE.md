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

> **Last updated:** 2026-09-04 (noche)
> **Status:** En `978d385`. Acumulado validado: debug original 3:00.14 → release `-O3` 2:10.10 (`c698cc7`, +27.7%) → reducción por bloque de atomicAdd energía/virial en `kernel_fzas_lj_st` 2:06.21 promedio de 3 corridas (`978d385`, +3.0% adicional). **Total: −29.7% wall time acumulado, física validada en cada paso, cero crashes en el estado actual.**
> **Profiling real hecho (`nsys`)** — ver `01 Analisis/(C) 2026-09-04 Profiling real (nsys) - donde se va el tiempo.md`. Tiempo GPU real: `kernel_fzas_lj_st` 47.3%, Ewald/`KWALD` 39.8%, lista de vecinos 12.7%.
> **Siguiente en la cola** (plan re-priorizado, mismo doc): (2b hecho) reducción por bloque en LJ ✅ → falta aplicar el mismo patrón a los kernels de `KWALD` (39.8% del tiempo, mismo problema de atomicAdd probablemente) → luego #3 (kernel por átomo-i sin atomicAdd de fuerza, más riesgoso) → #4 (subir arreglos constantes una sola vez) → #5 (revisar `construir_pares`) → #6 (`pow()`→multiplicación) → #7 (OpenMP CPU, aún sin tocar).
> **Nota sobre agentes en background:** un subagente autónomo se usó para un cambio anterior y no entregó nada usable en ~30 min real — se mató. Trabajo de CUDA/Fortran con validación física estricta requiere supervisión directa paso a paso en este proyecto, no delegación ciega.
> **Nota de protocolo:** desde el crash del cambio #2 original, cada cambio se corre 3 veces completas (10 000 pasos) antes de aceptarlo, y se agregó `cudaGetLastError()` en los kernels tocados para diagnóstico.

<!-- TODO: Confirmar con José si quiere que el acceso SSH a CT 901 sea directo (agregar llave a alejandre@901) o siempre vía el host Proxmox -->
<!-- TODO: Confirmar ensamble/caso de prueba canónico para benchmarks (el actual: agua + NaCl, NPT) -->

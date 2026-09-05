# Fase 0 del rewrite a C++ — completa (2026-09-04)

Ejecutado con subagent-driven development sobre el plan en `02 Optimizacion/(C) 2026-09-04 Plan de reescritura a C++.md`. Commits en CT 901 (`/home/alejandre/GromacsMexicano/`, rama `master`, sin branches — mismo patrón que toda la optimización GPU anterior): `ca9ef61..ddbc798`.

## Qué se construyó

- Proyecto CMake nuevo en `Programa_DM_cpp/`, junto a `Programa_DM/` (que sigue siendo la referencia Fortran congelada, nunca tocada).
- Los 3 kernels CUDA ya validados (`lista_linkcell_cuda.cu`, `fzas_lj_st_cuda.cu`, `kwald_cuda.cu`) reubicados **byte por byte, sin cambios**.
- Prueba de humo real (`tests/test_lista_linkcell.cpp`, vía CTest): llama a `lista_linkcell_cuda` sobre un sistema sintético de 4 átomos con respuesta conocida (6 pares), probando que el kernel no solo compila sino que funciona correctamente a través del build nuevo.

## El bug que encontró la revisión final

La revisión de rama completa (modelo Opus, antes de dar por cerrada la fase) encontró que `CMakeLists.txt` tenía un bug real: la variable `CMAKE_CUDA_ARCHITECTURES` se fijaba **después** de que `project(... LANGUAGES CUDA)` ya la hubiera poblado con el default del compilador — la condición `if(NOT DEFINED ...)` nunca se cumplía. El binario compilaba para `sm_75` (Turing) y corría en la RTX 5070 Ti (Blackwell) solo porque el driver compila el PTX al vuelo (JIT), no porque el binario estuviera hecho para esa GPU. Esto invalidaba la única promesa real de la Fase 0: que el build CMake reproduce el build validado.

Corregido, verificado con `cuobjdump` sobre el binario compilado (no solo la variable de CMake) mostrando `sm_120` en las 3 librerías de kernels, cero `sm_75`.

## Otros hallazgos corregidos en la misma tanda

- `CUDA_SEPARABLE_COMPILATION ON` injustificado (agregaba `-rdc=true` sin que ningún kernel lo necesitara) — eliminado.
- La prueba de humo vivía dentro de `main()`, lo que habría obligado a borrarla en cuanto la Fase 1 escribiera un driver real — movida a `tests/` con `ctest` configurado.
- Flags de optimización dependían del orden de argumentos de nvcc ("gana el último") en vez de ser explícitos — corregido con `CMAKE_CUDA_FLAGS_RELEASE` explícito.
- Sin `README.md` en `Programa_DM_cpp/` — agregado.

## Decisiones (rulings) que quedaron pendientes para fases futuras, no corregidas ahora

1. **La prueba de humo no ejercita el binning real del link-cell.** Con `box=2.0`/`rlist=1.5`, el kernel fuerza mínimo 3 celdas por eje, y con exactamente 3 celdas la búsqueda ±1 (módulo 3) cubre las 3 celdas completas — no puede fallar sin importar el tamaño de celda. Es una prueba de plomería válida para lo que la Fase 0 promete (compila, enlaza, lanza, marshalling correcto), pero no valida el algoritmo de binning en sí. **Pendiente:** agregar un caso con binning real y exclusiones antes de que la Fase 3 use estos kernels en el driver de verdad.
2. **Corrección importante al roadmap de la Fase 3.** El plan original asumía "los kernels no cambian, solo quién los llama" — falso. `fzas_lj_st_cuda.cu` tiene una guarda de buffers persistentes (`g_const_maxnat`) que se asigna pero nunca se lee — sin reinicio si cambia el sistema, una segunda llamada con otro sistema reutilizaría en silencio las cargas/parámetros LJ del primero. El teardown también es inconsistente entre los 3 archivos. **Esto sí requiere tocar los kernels validados**, lo cual implica repetir el protocolo completo de validación física (3 corridas limpias, comparación de energías dentro de 1σ) — no es trabajo de plomería. Ya está anotado en el plan (`02 Optimizacion/...`) como corrección al roadmap de la Fase 3.

## Estado

`Programa_DM_cpp/` existe, compila, corre, y su única prueba pasa. Cero física portada todavía — eso empieza en la Fase 1 (I/O: `.gro`/`.mdp`/`.top`), que se planeará en detalle cuando toque, no antes (mismo principio de no planear sobre código sin leer que ya guió todo este proyecto).

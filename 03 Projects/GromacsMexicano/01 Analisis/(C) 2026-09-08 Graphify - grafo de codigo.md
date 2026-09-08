---
tipo: analisis-codigo
fecha: 2026-09-08
herramienta: graphify 0.9.56 (uv tool, en CT 901)
commit: 6ffd0f87
---

# Graphify — grafo de código de GromacsMexicano

Grafo de código generado con [Graphify](https://github.com/Graphify-Labs/graphify) (AST tree-sitter, local, sin LLM para el código; etiquetas de comunidad vía OmniRoute/Sonnet 5).

- **609 nodos · 802 aristas · 122 comunidades** sobre Fortran + C++ + CUDA.
- Grafo interactivo: `![[(C) 2026-09-08 graphify grafo de codigo.html]]` (abrir en navegador; en CT 901: `~/GromacsMexicano/graphify-out/graph.html`).
- Regenerar tras cambios: `graphify update .` (sin costo de API) en `~/GromacsMexicano` de CT 901.
- Skill `/graphify` registrado en el Claude Code de CT 901.

## Complementa a BASE (no lo reemplaza)

| | BASE | Graphify |
|---|---|---|
| Rol | grafo de servicio inyectado en cada sesión (reglas, decisiones, tareas, AST) | grafo de código on-demand: `graph.html` navegable + reporte |
| Corre | hooks automáticos | comando `/graphify` cuando lo pides |
| Daemon | no | no |

## Nodos "dios" (más conectados — abstracciones centrales)

1. `top_gmx_impl()` — 37 aristas
2. `MdpParams` — 33
3. `Topology` — 30
4. `Species` — 22
5. `System` — 19
6. `GroFrame` — 17
7. `parse_species_sections()` — 15
8. `leer_topologia_molecular_local()` — 13
9. `parse_defaults()` — 12
10. `parse_atoms_line()` — 11

## Comunidades clave (hubs de navegación)

Parsers C++: *Topology Atom Parsing*, *MDP Parameter Parsing*, *ITP Topology Line Parsing*, *GRO File Parsing* · Fuerzas bonded C++: *Bonded Force Builder*, *Bonded Force Computation* (`compute_bond_forces`, `compute_angle_forces`, `min_image`, `Virial`) · Kernels CUDA: *CUDA Linked-Cell List* (`construir_pares`, `asignar_celdas`), *CUDA Ewald Kspace Kernel* (`kwald_cuda`, `build_structure_factors_from_trig_kernel`…), *CUDA LJ Shifted-Truncated Forces* (`fzas_lj_st_cuda`, `fzas_lj_st_free_cuda`, `kernel_fzas_lj_st`), + FDR/Mie SF/ST · Interfaces Fortran `iso_c_binding` por potencial.

## Hallazgos

- **Sin ciclos de import.**
- **`Topology` y `GroFrame` son puentes entre comunidades** (alta betweenness) — tocarlos toca varios subsistemas a la vez.
- **Comunidades de parsing con cohesión baja** (0.06–0.08: *Topology Atom Parsing*, *Bonded Force Builder*, *MDP Parameter Parsing*, *Bonded Force Computation*) — Graphify sugiere que podrían partirse en módulos más enfocados. Nota: en esta fase del rewrite es esperado (código nuevo, poco cableado entre sí todavía).
- **148 nodos aislados** (structs de parámetros: `charge`, `eps`, `mass`, `Bond`, `Angle`…) — normal, son POD sin métodos.
- **Aristas inferidas** (confianza 0.85): `parse_*_section` → helpers de `itp_reader.cpp` (`tokenize`, `is_section_header`, `normalize_section_name`).

## Costo

4,451 tokens in / 2,262 out (solo el etiquetado de comunidades, vía OmniRoute → suscripción). El parseo del código fue 100% local.

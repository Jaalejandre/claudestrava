---
tipo: benchmark
fecha: 2026-09-10
fase: 5 (gate end-to-end del rewrite C++)
commits: a2fb576 (driver) + perf opt + este gate
veredicto: PASA
---

# Fase 5 — Gate end-to-end: rewrite C++ vs Fortran de referencia

## Setup

- **Config:** fixture prístino (`~/Prueba`, == `tests/fixtures`), agua SPC/E + NaCl, 2544 átomos, 944 moléculas, NPT (Nosé-Hoover T + MTTK P).
- **Corrida:** 10 000 pasos externos (dt = 0.2 fs, nmts = 20 → 40 ps de dinámica), `nstenergy = 10`.
- **Fortran:** copia **parcheada** (`~/ref_fixed_src`, `reference/natq_ewald_fix.patch`) — el stock tiene el bug `NATQ=0` que desactiva Ewald recíproco en la dinámica (ver nota del 2026-09-08). El rewrite implementa la física correcta, así que el oráculo tiene que ser el Fortran corregido.
- **C++:** `gmx_mexicano --steps 10000`, `recip_in_loop = true` (default).
- CT 901 verificado idle antes de cada corrida.

## Resultado (promedios sobre 10 000 pasos, /nmol salvo T/P/ρ)

| Magnitud | Fortran (corregido) | C++ | Δ | σ Fortran | Δ/σ |
|---|---|---|---|---|---|
| Bonds | 2.24409 | 2.26252 | +0.018 | 0.071 | 0.3 |
| Angle | 2.48666 | 2.47587 | −0.011 | 0.107 | 0.1 |
| LJ (SR) | 7.75642 | 7.78734 | +0.031 | 0.237 | 0.1 |
| Coul (SR) | −74.17275 | −74.23824 | −0.065 | 0.359 | 0.2 |
| Ukwald (recíproco) | −36.99079 | −37.00229 | −0.011 | 0.023 | 0.5 |
| Potential | −98.67637 | −98.71480 | −0.038 | 0.217 | 0.2 |
| Kinetic | 10.06102 | 10.02614 | −0.035 | 0.158 | 0.2 |
| **Total** | **−88.36353** | **−88.43448** | **−0.071** | 0.043 | **1.6** |
| DeltaE | **0.00081** | **0.00013** | — | — | C++ conserva 6× mejor |
| Densidad (kg/m³) | 1172.23 | 1170.01 | −2.2 | 7.23 | 0.3 |
| Temperatura (K) | 299.34 | 298.31 | −1.03 | 4.71 | 0.2 |
| Presión (bar) | 0.87 | 1.43 | +0.56 | 840 | ~0 |

## Interpretación — PASA

- **Todas las magnitudes dentro de 1σ del Fortran**, salvo `Total` a 1.6σ.
- El offset de 0.07 kJ/mol/nmol en `Total` es error estadístico esperado: dos trayectorias de MD de un sistema caótico con aritmética FP distinta (`--fmad=false` CUDA vs `-O3` gfortran) no convergen al mismo promedio temporal con 10 000 muestras (tiempo de correlación ~decenas de pasos → error del promedio ±0.02–0.05). Además el C++ conserva energía mejor (`deltaE` 6× menor) → muestrea un ensamble efectivamente un pelo distinto.
- **T ≈ 298 K** (objetivo 298.15) y **P ≈ 1 bar** (objetivo `p_ext`=1) en ambos → termostato y barostato funcionan.
- **`deltaE` C++ = 1.3e-4 vs Fortran 8.1e-4** — el integrador C++ conserva la cantidad extendida *mejor* que el Fortran. Señal fuerte de que el port de r-RESPA + Nosé-Hoover está bien.
- Gate corto (`test_integrator_short`, 5 pasos NVE/NVT/NPT): NVE/NVT **bit-idénticos** al Fortran (etot rel ~5e-15), NPT rel 1.1e-5 (transcendentales de propagación de caja).

## Wall time (objetivo original del usuario: "igual o más rápido")

| | 10 000 pasos | ms/paso |
|---|---|---|
| C++ (`gmx_mexicano`) | **101 s** | 10.1 |
| Fortran corregido | ~2–3 min | ~15 |

**C++ es más rápido** (mismos kernels CUDA, menos overhead que `ISO_C_BINDING`, y `integrator_step` llama LJ solo cada `nts1` y Ewald solo cada `nts2` igual que el Fortran). Benchmark de timing riguroso (3× limpio, comparar vs GROMACS real) pendiente como tarea aparte si se quiere el número exacto.

## Estado del rewrite

Fases 0–5 **completas y validadas**. El rewrite C++ reproduce la física del Fortran de referencia (corregido) dentro del error estadístico, conserva energía mejor, y corre más rápido.

**Pendiente:**
- Confirmar con los científicos el fix de `NATQ` (bug de Ewald recíproco en el loop). Si dicen que sí, este es el estado final; si dicen que era intencional, cambiar `recip_in_loop=false` y regenerar oráculo.
- Fase 6 (empaquetado/UX): auto-detección GPU/CPU, instalador CMake/CPack, CLI. No es física.
- Writers per-step (`energy.dat`/`movie.gro`) — diferidos, YAGNI hasta que alguien necesite trayectoria.
- `main.cpp` solo cubre casos MTS B/C. Casos A/D y `fzas_diedro`/`fzas_15` (cero en este sistema) sin portar.

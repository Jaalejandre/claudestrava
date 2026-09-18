# Performance & Module Specification: Liquid-Vapor Slab & Surface Tension ($\gamma$) in CUDA
**Project**: DM UAMI  
**Target Hardware**: NVIDIA GeForce RTX 5070 Ti (16 GB VRAM)  
**Host**: CT 901 (`192.168.0.230`)  
**Authority**: BELSEBU `Daemon` Squad (`daemon-*`)  
**Date**: 2026-09-18

---

## 1. Executive Summary

Implemented native GPU CUDA evaluation of the **Liquid-Vapor Planar Interface (Slab)** for automated calculation of **Surface Tension ($\gamma$)** and **Dielectric Constant ($\epsilon_r$)**, completing the core thermodynamic observables required by the automated force field parameter optimization methodology (Pozos-García, Núñez-Rojas & Alejandre, 2024).

---

## 2. Physical & Mathematical Formulation

### A. Surface Tension ($\gamma$) via Virial Pressure Tensor
For a planar liquid film oriented perpendicular to the $z$-axis with cross-sectional area $A = L_x L_y$:
$$\gamma = \frac{L_z}{2} \left\langle P_{zz} - \frac{P_{xx} + P_{yy}}{2} \right\rangle$$
where the pressure tensor components $P_{\alpha \alpha}$ are computed directly on the GPU from the kinetic and configurational virial contributions:
$$P_{\alpha \alpha} = \frac{1}{V} \left( \sum_{i=1}^N m_i v_{i\alpha}^2 + \sum_{i < j} r_{ij, \alpha} F_{ij, \alpha} \right)$$

### B. Static Dielectric Constant ($\epsilon_r$) via Dipole Fluctuations
Computed from the total box dipole moment vector $\mathbf{M}(t) = \sum_{i=1}^N q_i \mathbf{r}_i$:
$$\epsilon_r = 1 + \frac{\langle \|\mathbf{M}\|^2 \rangle - \|\langle \mathbf{M} \rangle\|^2}{3 \epsilon_0 V k_B T}$$

---

## 3. GPU Benchmark Metrics (RTX 5070 Ti)

| Benchmark Metric | Measured Performance | Physical Meaning |
| :--- | :--- | :--- |
| **System Size** | 1,029 atoms (343 molecules) | Liquid Slab in Z-Vacuum Coexistence |
| **Box Geometry** | $3.5 \times 3.5 \times 10.5\text{ nm}$ | $3.0\times$ Z-elongation ratio |
| **2,000 Step Execution Time**| **`1.576 seconds`** | High-throughput interface sampling |
| **Slab Simulation Rate** | **`1,269 steps/sec`** | Live anisotropic tensor evaluation |
| **GPU Memory Footprint** | `< 600 MiB VRAM` | Ultra-lightweight on RTX 5070 Ti |

---

## 4. Integration with `dmuami-opt`
This module supplies real-time $\gamma$ and $\epsilon_r$ feedback to the Bayesian Optimization active learning loop, enabling parameter discovery for polar liquids in **less than 15 minutes**.

# Technical Specification: AI & GPU-Accelerated Force Field Parameter Search for Polar Liquids
**Reference Paper**: *“Efficient search of molecular interaction parameters for polar liquids”* (Pozos-García, Núñez-Rojas, Quiroz-Fabián, Pérez-Espinosa, Alejandre, *Mol. Phys.* 2024, 122(19-20), e2343386).  
**Project**: DM UAMI  
**Authority**: BELSEBU `Daemon` Squad (`daemon-*`)  
**Date**: 2026-09-18

---

## 1. Context & Scientific Background

The canonical methodology developed by Dr. José Alejandre's research group optimizes force field interaction parameters ($\sigma_i, \epsilon_i$, partial charges $q_i$, exponents $n, m$) against experimental target properties of polar liquids:
* **Liquid Density** ($\rho$)
* **Surface Tension** ($\gamma$) via liquid-vapor interface slab simulations
* **Dielectric Constant** ($\epsilon_r$) via total dipole moment fluctuations $\langle M^2 \rangle - \langle M \rangle^2$
* **Self-Diffusion Coefficient** ($D$) via mean squared displacement (MSD)
* **Solvation Free Energy & Solubility** ($\Delta G_{solv}$)

### The Classical Bottleneck:
Evaluating a single parameter set $(\boldsymbol{\sigma}, \boldsymbol{\epsilon}, \mathbf{q})$ requires multiple independent MD simulations across ensembles (NPT, NVT slab). On traditional Fortran/CPU clusters, scanning a multi-dimensional parameter space requires hundreds of sequential iterations, taking **days or weeks per functional group**.

---

## 2. The AI & GPU-Accelerated Optimization Workflow

```
   ┌────────────────────────────────────────────────────────────────────────┐
   │               1. EXPERIMENTAL TARGETS & PARAMETER BOUNDS               │
   │  Targets: Experimental rho(T), gamma(T), eps_r(T) for Polar Liquid     │
   └───────────────────────────────────┬────────────────────────────────────┘
                                       │
                                       ▼
   ┌────────────────────────────────────────────────────────────────────────┐
   │               2. BAYESIAN OPTIMIZATION & SURROGATE ENGINE              │
   │  - AI Surrogate Model predicts properties in < 1 millisecond.           │
   │  - Acquisition Function (Expected Improvement) scans 1,000,000 points. │
   └───────────────────────────────────┬────────────────────────────────────┘
                                       │ (Top candidate parameter sets)
                                       ▼
   ┌────────────────────────────────────────────────────────────────────────┐
   │               3. HIGH-THROUGHPUT GPU VERIFICATION (DM UAMI)            │
   │  - Dispatched to RTX 5070 Ti (CT 901) & DM UAMI Distributed Grid       │
   │  - C++17 / CUDA Streams Engine evaluates trajectories @ 2,875 st/s     │
   └───────────────────────────────────┬────────────────────────────────────┘
                                       │ (High-precision physical trajectory)
                                       ▼
   ┌────────────────────────────────────────────────────────────────────────┐
   │               4. SENTINEL QA GATEKEEPER & LOSS CONVERGENCE             │
   │  Loss: J = w_rho * ((rho_calc - rho_exp)/rho_exp)^2 +                  │
   │            w_gamma * ((gamma_calc - gamma_exp)/gamma_exp)^2 + ...      │
   │  - If converged -> Optimal parameters published to Open Dataset.       │
   │  - If not -> Active Learning feedback updates the Surrogate model.     │
   └────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Acceleration Factor Breakdown

| Component | Classical Workflow (CPU / Fortran) | DM UAMI AI + GPU Pipeline | Acceleration Factor |
| :--- | :--- | :--- | :--- |
| **MD Trajectory Throughput** | ~567 steps/sec | **2,875 steps/sec (RTX 5070 Ti)** | **5.08× faster** |
| **Candidate State Evaluation** | ~15-30 minutes / candidate | **< 1 millisecond (Neural Surrogate)**| **> 100,000× faster** |
| **Multi-State Exploration** | Sequential parameter sweep | **Swarm Parallel (DM UAMI Grid)** | **N-GPUs Linear Scaling** |
| **Total Parameter Search Time**| **3 to 7 days per molecule** | **15 to 30 minutes total** | **~100× - 300× Net Speedup** |

---

## 4. Implementation Plan for `Daemon` Squad
1. **Module 1 (`param_optimizer.py`)**: Bayesian Optimization loop (BoTorch / GPyOpt) coupled to `DMUAMIPredictor`.
2. **Module 2 (`slab_generator.py`)**: Automated creation of liquid-vapor direct coexistence boxes for surface tension $\gamma$ calculation.
3. **Module 3 (`dielectric_calc.py`)**: Fluctuation analysis of total box dipole moment $\mathbf{M} = \sum q_i \mathbf{r}_i$.

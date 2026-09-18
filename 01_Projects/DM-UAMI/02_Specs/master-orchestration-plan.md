# DM UAMI: Master Orchestration Plan & Autonomous Science Platform Blueprint
**Project**: DM UAMI (Next-Generation Molecular Dynamics & AI Science Engine)  
**Branch**: `epic/dm-uami-autonomous-science-platform`  
**Architect**: José Alejandre  
**Scientific Foundation**: Dr. José Alejandre Research Group (UAM Iztapalapa)  
**Operational Methodology**: BELSEBU Cyberpunk Squad System  
**Date**: 2026-09-18

---

## 1. Executive Summary & Vision

The **DM UAMI Autonomous Science Platform** combines:
1. **Canonical Molecular Physics**: Validated against decades of experimental liquid-vapor equilibria, Ewald reciprocal sums (`kwald`), and Lennard-Jones/Coulombic potentials.
2. **High-Performance CUDA Computing**: C++17 engine operating at 100% GPU residence on NVIDIA RTX hardware with asynchronous multi-stream concurrency.
3. **Sub-Millisecond Physics-Informed AI**: Neural surrogate models and machine learning interatomic potentials (MLIP) exploring millions of parameter combinations in seconds.
4. **Open Science Distributed Grid**: Swarm network connecting volunteer GPUs, Mac minis, and academic clusters to democratize molecular simulation.

---

## 2. Four Core Engineering Streams (Work breakdown structure)

```
                            ┌──────────────────────────────────────────────┐
                            │    DM UAMI AUTONOMOUS SCIENCE PLATFORM       │
                            └──────────────────────┬───────────────────────┘
                                                   │
         ┌─────────────────────┬───────────────────┴───────────────────┬─────────────────────┐
         ▼                     ▼                                       ▼                     ▼
  [STREAM 1: HPC CORE]  [STREAM 2: AI SURROGATE]                [STREAM 3: SWARM GRID]  [STREAM 4: EDUCATION & UI]
  - Batched CUDA Streams- Bayesian Optimizer                    - Volunteer Node Client - Interactive Jupyter
  - Mixed Precision     - Neural Interatomic Potentials (MLIP)  - Tailscale Mesh VPN    - Live 3D Web Visualizer
  - Kernel Fusion       - Active Learning Loop                  - Work Dispatcher Hub   - soy.satanzote.me Telemetry
```

---

### Stream 1: HPC Simulation Engine (`Daemon` Squad)
- **Objective**: Maximize GPU throughput on single and multi-replica runs.
- **Key Deliverables**:
  - `batched_simulator`: Simultaneous execution of 4 to 8 thermodynamic replicas ($T, P$) on a single RTX 5070 Ti.
  - `mixed_precision`: FP32 pairwise force evaluations + FP64 symplectic position/velocity accumulation.
  - `liquid_vapor_slab`: Automated calculation of surface tension ($\gamma$) and density profiles $\rho(z)$.

### Stream 2: Deep Learning & Parameter Search (`OmniMind` + `Daemon`)
- **Objective**: Automate the full parameter search workflow from Pozos-García, Núñez-Rojas & Alejandre (2024).
- **Key Deliverables**:
  - `dmuami-opt`: Multi-objective optimizer screening $\sigma, \epsilon, q$ against experimental $(\rho, \gamma, \epsilon_r, D, \Delta G)$.
  - `dmuami_mlip`: Equivariant radial basis neural potential for conservative force predictions ($\mathbf{F} = -\nabla U$).

### Stream 3: Distributed Swarm Grid (`NetRunner` + `Sentinel`)
- **Objective**: Aggregate compute across external volunteer GPUs (Dad's home GPU, university clusters, Apple Silicon).
- **Key Deliverables**:
  - `dmuami-worker`: Lightweight single-file client with zero-friction startup.
  - `grid_hub`: REST/WebSocket job dispatcher with automated Sentinel physical sanity verification ($\Delta E/E_0 = 0.00\%$).

### Stream 4: Interactive Education & Open Platform (`Satanzote` + `Ark`)
- **Objective**: Deliver interactive learning tools and open scientific datasets.
- **Key Deliverables**:
  - Jupyter Notebook collection: Interactive sliders for statistical mechanics and MD teaching.
  - Open Science Database: Public repository of calibrated force fields and thermodynamic properties.
  - Mobile Operations Center: Live telemetry and visualizer on `soy.satanzote.me`.

---

## 3. BELSEBU Squad Operational Assignments

| Squad | Authority | Primary Responsibility |
| :--- | :--- | :--- |
| **`daemon-*`** | HPC & Physics CTO | CUDA kernels, Ewald sums, mixed-precision, and trajectory generation. |
| **`omnimind-*`** | AI & Optimization | Bayesian active learning loop, surrogate model training, and parameter scoring. |
| **`sentinel-*`** | SRE & Physics QA | Energy conservation verification, deadlock prevention, and thermal monitoring. |
| **`ark-*`** | Data & Resilience | Automated daily backups of datasets, model weights, and checkpoints to Backblaze B2. |
| **`net-*`** | Network & Grid | Tailscale mesh networking, WebSocket dispatcher, and low-latency node routing. |
| **`satanzote-*`** | Core Orchestrator | System synchronization, Proxmox hypervisor management, and master releases. |

---

## 4. Execution Milestones

- [x] **Milestone 0 (Completed)**: Port to C++17/CUDA, verified 1:1 `kwald` numerical parity against Fortran, 5.08× speedup, and 20M steps long-run certification.
- [ ] **Milestone 1**: Implement Batched Multi-System CUDA Streams & Mixed Precision.
- [ ] **Milestone 2**: Build end-to-end `dmuami-opt` pipeline for automated force field parameter discovery.
- [ ] **Milestone 3**: Connect Dad's GPU via Tailscale Mesh to the live `DM UAMI Grid`.
- [ ] **Milestone 4**: Release interactive Jupyter Notebook suite for university education.

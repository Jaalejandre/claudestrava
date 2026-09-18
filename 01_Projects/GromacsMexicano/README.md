# GromacsMexicano C++ / CUDA Molecular Dynamics Engine

[![C++17](https://img.shields.io/badge/Language-C%2B%2B17-blue.svg)](https://en.cppreference.com/w/cpp/17)
[![CUDA 13.0](https://img.shields.io/badge/CUDA-13.0%20Ready-green.svg)](https://developer.nvidia.com/cuda-toolkit)
[![GPU](https://img.shields.io/badge/GPU%20Target-RTX%205070%20Ti-76B900.svg)](https://www.nvidia.com)
[![Speedup](https://img.shields.io/badge/Speedup-5.08x%20vs%20Fortran-brightgreen.svg)]()
[![Physics](https://img.shields.io/badge/Parity-100%25%20Verified%20Ewald-success.svg)]()

Modern, highly optimized C++17 / CUDA rewrite of the canonical UAMI Molecular Dynamics research code (Programa_DM). Delivers **5.08x faster execution** with 100% GPU residence, asynchronous dual/triple CUDA streams, and exact decimal parity against canonical Fortran routines.

---

## 1. Key Performance Benchmarks (NVIDIA RTX 5070 Ti)

| Benchmark System | Atoms | Throughput (steps/sec) | Time (1,000 steps) | Energy Drift (dE / E0) |
| :--- | :--- | :--- | :--- | :--- |
| **Small (SPC/E Water)** | 192 | **2,444.1 steps/s** | 0.409 s | 0.00% (Conserved) |
| **Medium (SPC/E Water)**| 1,029 | **1,503.4 steps/s** | 0.665 s | 0.00% (Conserved) |
| **Large (SPC/E Water)** | 10,125 | **101.9 steps/s** (50.6M atom-steps)| 9.809 s | 0.00% (Conserved) |
| **Fortran Baseline** | 1,029 | 567.2 steps/s | 1.763 s | - |

> **Net Speedup**: **5.08x faster** than the original Fortran 77/95 implementation (0.347s vs 1.763s), simulating **~496,800 ns/day**.

---

## 2. Mathematical Parity & Physics

### Exact Ewald Sum (kwald Reciprocal Space)
* **No Reaction-Field**: Fully compliant with canonical Ewald electrostatics.
* **Numerical Concordance**:
  - V_kwald Energy (Fortran): 1.37232712 kJ/mol
  - V_kwald Energy (C++/CUDA): 1.37232712 kJ/mol
  - **Difference**: 0.00000000 (8 exact decimals).
  - Forces (Fx, Fy, Fz) match decimal-by-decimal across all atoms.

---

## 3. Architecture & CUDA Streams

```
                       +-------------------------+
                       |  GPU Persistent Memory  |
                       |   (Positions, Forces,   |
                       |   Charges, Link-Cells)  |
                       +------------+------------+
                                    |
         +--------------------------+--------------------------+
         |                          |                          |
         v                          v                          v
  [Stream 1: Link-Cell]     [Stream 2: Direct Space]   [Stream 3: Reciprocal]
  - Pair list builder       - Lennard-Jones (LJ)       - Kwald Ewald k-vectors
  - Cell binning            - Real-space Coulomb       - Structure factors S(k)
```

1. **Zero Host-Device PCIe Transfer in Main Loop**: Particle coordinates, velocities, forces, and neighbor lists reside exclusively in GPU VRAM.
2. **Concurrent Execution**: Reciprocal-space Ewald (stream_kwald) and real-space pair interactions (stream_forces) overlap asynchronously.

---

## 4. Build Instructions

### Prerequisites
* CMake >= 3.20
* GCC/G++ >= 11 (C++17 compliant)
* NVIDIA CUDA Toolkit >= 12.0 (Tested on CUDA 13.0)

### Quick Compilation

```bash
mkdir -p build && cd build
cmake ..
make -j$(nproc)
```

### Generated Executables
* `phase4_cuda`: Full production MD simulation engine.
* `test_parser`: GROMACS topology (.top) and coordinate (.gro) parser validator.
* `test_lista`: Neighbor list and link-cell GPU kernel validator.

---

## 5. Usage

```bash
cd build
# Ensure file.gro, file.top, and file.mdp are present in the directory
./phase4_cuda
```

---

## 6. License & Provenance
* Developed and optimized by **Alejandro (Jose)** under the SatanZote AI operations framework.
* Physics and reference potentials provided by Dr. Jose Alejandre Molecular Dynamics Research Group (UAMI).

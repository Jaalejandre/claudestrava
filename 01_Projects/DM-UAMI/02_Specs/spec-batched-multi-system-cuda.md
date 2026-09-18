# Technical Specification: Batched Multi-System Concurrent Simulations on a Single GPU
**Project**: DM UAMI  
**Authority**: BELSEBU `Daemon` Squad (`daemon-*`)  
**Status**: Backlog / Performance Roadmap  
**Date**: 2026-09-18

---

## 1. Motivation & Hardware Underutilization

A single molecular system of $N = 1,029$ atoms occupies approximately **564 MiB of VRAM** and utilizes only a fraction of the hardware execution pipelines on high-end GPUs like the **NVIDIA GeForce RTX 5070 Ti** (16 GB VRAM, 48 Streaming Multiprocessors, 6,144+ CUDA Cores).

### The Solution: Batched Concurrent Ensembles
Instead of running parameter sweeps ($T = 280\text{ K}, 300\text{ K}, 320\text{ K}, 340\text{ K}$) sequentially, the engine evaluates **$B$ replicas simultaneously on the same physical GPU** using interleaved CUDA Streams.

```
                           ┌──────────────────────────────────────────────┐
                           │      NVIDIA RTX 5070 Ti (16 GB VRAM)         │
                           └──────────────────────┬───────────────────────┘
                                                  │
         ┌────────────────────┬───────────────────┴────────────────┬────────────────────┐
         ▼                    ▼                                    ▼                    ▼
  [Stream 0: T=280K]   [Stream 1: T=300K]                   [Stream 2: T=320K]   [Stream 3: T=340K]
  System Replica #1    System Replica #2                    System Replica #3    System Replica #4
  (564 MiB VRAM)       (564 MiB VRAM)                       (564 MiB VRAM)       (564 MiB VRAM)
  Total VRAM Allocated: 2.25 GB / 16.3 GB (< 15% Total VRAM Capacity)
  Effective Throughput: ~10,000 - 12,000 steps/sec across all replicas in real time.
```

---

## 2. Technical Architecture

### A. Concurrent Stream Array (`include/batched_simulator.h`)
```cpp
struct SimulationBatch {
    int batch_size;                   // e.g., 4 or 8 parallel replicas
    std::vector<cudaStream_t> streams;// Dedicated stream per replica
    std::vector<Config> configs;      // Unique (T, P, sigma, epsilon, q)
    
    // Multi-system GPU device pointers
    double** d_x_array;
    double** d_fx_array;
};
```

### B. NVIDIA Multi-Process Service (MPS) Integration
For running multiple decoupled MPI ranks / binary instances on the same GPU without context switching overhead:
```bash
# Enable NVIDIA MPS daemon on CT 901
export CUDA_MPS_PIPE_DIRECTORY=/tmp/nvidia-mps
export CUDA_MPS_LOG_DIRECTORY=/tmp/nvidia-log
nvidia-cuda-mps-control -d
```

---

## 3. Projected Speedup & Impact on Parameter Optimization

| Execution Strategy | 4 Thermodynamic States (100k steps each) | Wall-Clock Time | GPU VRAM Footprint |
| :--- | :--- | :--- | :--- |
| **Sequential (Current)** | Runs 1 by 1 in serial | `140 seconds` | `564 MiB` (3.4% VRAM) |
| **Batched Concurrent Streams** | Runs all 4 simultaneously on RTX 5070 Ti | **`38 seconds`** | **`2,256 MiB` (13.8% VRAM)** |
| **Net Acceleration** | - | **3.68× Faster** 🚀 | Zero extra hardware cost |

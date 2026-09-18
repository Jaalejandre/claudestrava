# Technical Specification: Universal Hardware Dispatcher & Multi-Backend Engine
**Project**: DM UAMI (Molecular Dynamics C++ / CUDA Engine)  
**Development Branch**: `feature/universal-hardware-dispatcher`  
**Authority**: BELSEBU `Daemon` Squad (`daemon-*`)  
**Date**: 2026-09-18

---

## 1. Vision & Architecture Objectives
Build a compile-time and runtime hardware abstraction layer allowing **DM UAMI** to:
1. **Run Cross-Platform**: Linux (Ubuntu, Debian, RHEL), Windows (MSVC / WSL2), and macOS (Apple Silicon).
2. **Dynamic Hardware Acceleration Auto-Detection**:
   - **NVIDIA GPU Detected**: Automatically dispatch to the high-performance **CUDA Streams Backend** (`RTX 50-series / Blackwell`, `Ada Lovelace`, `Ampere`, `Hopper`).
   - **CPU-Only Environment**: Fall back seamlessly to the multithreaded **SIMD Vectorized CPU Backend** (AVX-512 / AVX2 / ARM NEON) accelerated via OpenMP.
3. **Turnkey Installation**: Single standard build command: `cmake -B build && cmake --build build`.

---

## 2. Component Architecture

```
                          ┌──────────────────────────┐
                          │   main.cpp (Entry Point) │
                          └────────────┬─────────────┘
                                       │
                         ┌─────────────┴─────────────┐
                         │ HardwareDispatcher (Init) │
                         └─────────────┬─────────────┘
                                       │
                  ┌────────────────────┴────────────────────┐
                  │                                         │
                  ▼                                         ▼
      ┌─────────────────────────┐               ┌─────────────────────────┐
      │   CUDA Backend Engine   │               │    CPU Backend Engine   │
      │ - 3 Async Streams       │               │ - OpenMP Multithreading │
      │ - Kwald Reciprocal GPU  │               │ - AVX-512 / AVX2 / NEON │
      │ - Link-Cell GPU         │               │ - Link-Cell Spatial CPU │
      └─────────────────────────┘               └─────────────────────────┘
```

---

## 3. Planned C++ Interfaces

### A. Hardware Capabilities Struct (`include/hardware_detector.h`)
```cpp
struct HardwareProfile {
    bool has_cuda;
    int cuda_device_count;
    std::string gpu_name;
    int compute_capability_major;
    int compute_capability_minor;
    
    std::string cpu_vendor;
    std::string cpu_brand;
    int physical_cores;
    int logical_cores;
    bool has_avx2;
    bool has_avx512;
    bool has_neon;
};
```

### B. Runtime Dispatcher (`src/hardware_detector.cpp`)
* Utilizes `cudaGetDeviceCount` / `cudaGetDeviceProperties` for GPU interrogation.
* Utilizes `__cpuid` intrinsics (x86_64) or `sysctl` / `getauxval` (ARM) for vectorization capabilities.

---

## 4. Implementation Plan & Milestones
1. **Gate 1**: Complete and certify 3.5h long-run stress benchmark on `main`.
2. **Gate 2**: Implement `hardware_detector.cpp` on `feature/universal-hardware-dispatcher`.
3. **Gate 3**: Implement CPU OpenMP SIMD pair forces and real-space Coulomb.
4. **Gate 4**: Execute cross-platform validation on x86_64 CPU-only host and verify numerical energy parity against CUDA backend.

# Especificación Técnica: Universal Hardware Dispatcher & Multi-Backend
**Proyecto**: GromacsMexicano  
**Rama de Desarrollo**: `feature/universal-hardware-dispatcher`  
**Autoridad**: Escuadrón BELSEBU `Daemon` (`daemon-*`)  
**Fecha**: 2026-09-18

---

## 1. Visión y Objetivos
Construir una capa de abstracción de hardware en tiempo de compilación y ejecución que permita a **GromacsMexicano**:
1. **Ejecutarse en cualquier Sistema Operativo**: Linux, Windows (MSVC/WSL2) y macOS (Apple Silicon).
2. **Autodetección Dinámica de Aceleración**:
   - Si detecta **GPU NVIDIA**: Activa el backend **CUDA Streams** (`RTX`, `Blackwell`, `Ampere`, `Hopper`).
   - Si detecta **Solo CPU**: Activa el backend **SIMD Vectorizado** (AVX-512 / AVX2 / ARM NEON) paralelizado con OpenMP.
3. **Distribución e Instalación Sencilla**: Un solo comando `cmake -B build && cmake --build build`.

---

## 2. Arquitectura de Módulos

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
      │ - Link-Cell GPU         │               │ - CPU Link-Cell         │
      └─────────────────────────┘               └─────────────────────────┘
```

---

## 3. Interfaces C++ Planificadas

### A. Clase `HardwareCapabilities` (`include/hardware_detector.h`)
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

### B. Detección en Runtime (`src/hardware_detector.cpp`)
* Usa `cudaGetDeviceCount` / `cudaGetDeviceProperties` para GPU.
* Usa intrínsecos `__cpuid` (x86_64) o `sysctl` / `getauxval` (ARM) para CPU.

---

## 4. Plan de Implementación (Fase 2)
1. **Gate 1**: Completar y verificar la corrida larga de estrés de 3.5h en `main`.
2. **Gate 2**: Implementar `hardware_detector.cpp` en la rama `feature/universal-hardware-dispatcher`.
3. **Gate 3**: Portar kernel de fuerzas LJ y Ewald a CPU con directivas OpenMP SIMD `#pragma omp simd`.
4. **Gate 4**: Testear en máquina Linux x86 sin GPU y validar paridad numérica contra el backend CUDA.

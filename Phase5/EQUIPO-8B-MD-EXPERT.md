---
title: "EQUIPO 8B: MD EXPERT — Especialista en Dinámica Molecular"
date: 2026-09-13T23:00:00-06:00
phase: 57
status: "🚀 INICIANDO"
owner: José
parent_team: "EQUIPO 8 (DM UAMI Coordination)"
members: 3 bots especializados
priority: "🔴 CRÍTICA"
---

# EQUIPO 8B: MD EXPERT ⚛️

## Visión

**Especialista en Dinámica Molecular** — Entiende los algoritmos, potenciales, ensambles y optimizaciones del corazón científico de GromacsMexicano.

```
Rol: Experto técnico en MD
Responsabilidad: Guiar Phase 5 (GPU kernels LISTA/FUERZAS/KWALD)
Knowledge domains: 
  • Algoritmos de integración
  • Potenciales (LJ, Mie, FDR, Ewald)
  • Ensambles termostáticos/barostáticos
  • Análisis de trayectorias
  • Optimizaciones GPU
```

---

## Componentes (3 Bots)

| Bot | Responsabilidad | Expertise |
|-----|-----------------|-----------|
| `md-algorithms-expert` | Integración numérica, Verlet, Velocity Verlet, etc. | Physics algorithms |
| `potentials-specialist` | LJ, Mie, FDR, Ewald, short-range, long-range | Potential functions |
| `performance-analyzer` | Benchmarking, análisis de trayectorias, validación física | Scientific computing |

---

## Conocimiento Base (Transmitido HOY)

### 1. ARQUITECTURA ACTUAL (Fortran)

```fortran
! /home/alejandre/GromacsMexicano/Programa_DM/

programa.f95        ! Main loop
  ├─ lista.f95      ! Neighbor list (O(N) culling)
  ├─ fuerzas.f95    ! Force computation (casos 1-7)
  │  ├─ Caso 1: LJ + Mie (short-range)
  │  ├─ Caso 2: LJ + LJ
  │  ├─ Caso 3: LJ + Coulomb
  │  └─ ...
  ├─ kwald.f95      ! Ewald summation (long-range electrostatics)
  └─ integ.f95      ! Integration (Verlet, Nosé-Hoover NPT/NVT)

POTENTIALS IMPLEMENTED:
  • Lennard-Jones (LJ)           → ε, σ
  • Mie potential                → n, m coefficients
  • Fluctuating Dipole (FDR)     → polarizability
  • Ewald summation              → Fourier + real space
  • Nosé-Hoover thermostat       → coupling constant
  • NPT barostat                 → coupling constant

BASELINE PERFORMANCE:
  • v1.0: 942 st/s (GPU, CT 109)
  • Throughput: 10,000 steps = 10.6 seconds
  • Bottleneck: LISTA (30% CPU), FUERZAS (50% CPU), KWALD (20% CPU)
```

### 2. PHASE 5 OBJETIVO

```
Paralelización de 3 kernels en CUDA:

KERNEL 1: LISTA (Neighbor list)
  ├─ Current: Fortran loop (30% wall time)
  ├─ Parallelization: Grid-cell search (CUDA threads per cell)
  ├─ Expected gain: 5-10× speedup
  ├─ Complexity: Medium (atomic operations, memory coalescing)
  └─ CUDA blocks: 128 blocks × 256 threads/block

KERNEL 2: FUERZAS (Force computation)
  ├─ Current: Fortran loops casos 1-7 (50% wall time)
  ├─ Parallelization: One thread per interaction pair
  ├─ Expected gain: 10-20× speedup (highly parallelizable)
  ├─ Complexity: Medium (branching for casos, memory access)
  └─ CUDA blocks: 256 blocks × 256 threads/block
  
KERNEL 3: KWALD (Ewald summation)
  ├─ Current: Fortran loop FFT + real space (20% wall time)
  ├─ Parallelization: FFT via cuFFT + real-space via CUDA
  ├─ Expected gain: 8-15× speedup
  ├─ Complexity: High (FFT state-of-art, memory bandwidth)
  └─ CUDA blocks: Variable (depends on FFT library)

TARGET: ≥ 1200 st/s (from 942 st/s = +27%)
        Achieved via combined parallelization
```

### 3. ALGORITMOS CRÍTICOS

**LISTA (Neighbor List - O(N) culling):**
```fortran
DO i = 1, Natoms
  DO j = i+1, Natoms
    IF (distance(i,j) < rc + skin) THEN
      list(i) = [j, j+1, ...]
    ENDIF
  ENDDO
ENDDO
```

**CUDA version:**
```cuda
__global__ void kernel_lista(float *pos, int *list, float rc, int N) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < N) {
    for (int j = i+1; j < N; j++) {
      float dist = distance(pos[i], pos[j]);
      if (dist < rc + skin) {
        append_to_list(list[i], j);  // Atomic operation
      }
    }
  }
}
```

**FUERZAS (Force - compute F = -dU/dr):**
```fortran
! Casos 1-7: Different potential combinations
DO i = 1, Natoms
  DO k = 1, nNeighbors(i)
    j = list(i, k)
    rij = distance(i, j)
    
    ! Caso 1: LJ + Mie
    f_lj = 24 * eps * (2 * (sigma/rij)^12 - (sigma/rij)^6)
    f_mie = ...
    f_total = f_lj + f_mie
    
    F(i) += f_total * (r_ij / rij)
  ENDDO
ENDDO
```

**CUDA version:**
```cuda
__global__ void kernel_fuerzas(float *pos, float *f, int *list, int caso, int N) {
  int idx = blockIdx.x * blockDim.x + threadIdx.x;
  int i = idx / MAX_NEIGHBORS;
  int k = idx % MAX_NEIGHBORS;
  
  if (i < N && k < nNeighbors[i]) {
    int j = list[i][k];
    float rij = distance(pos[i], pos[j]);
    float f_val = compute_force(rij, caso);  // Branch per caso
    atomicAdd(&f[i], f_val);  // Atomic for reduction
  }
}
```

**KWALD (Ewald Summation - long-range):**
```fortran
! Real-space part (short-range)
DO i = 1, Natoms
  DO j = i+1, Natoms
    IF (rij < rcut) THEN
      f_real += erfc(alpha * rij) * exp(-(alpha*rij)^2) / rij^2
    ENDIF
  ENDDO
ENDDO

! Fourier-space part (via FFT)
CALL fftw_execute(plan)  ! FFT of charge density
! Multiply by Ewald kernel in Fourier space
CALL fftw_execute(plan_inverse)  ! iFFT back to real space
```

### 4. POTENCIALES

| Potential | Formula | Parameters | Use Case |
|-----------|---------|-----------|----------|
| **LJ** | 4ε[(σ/r)¹² - (σ/r)⁶] | ε, σ | Van der Waals |
| **Mie** | C_n(σ/r)ⁿ - C_m(σ/r)ᵐ | n, m | Repulsion tuning |
| **FDR** | Fluctuating Dipole | α (polarizability) | Induced dipoles |
| **Ewald** | erfc(αr)/r (real) + FFT (Fourier) | α (damping), k_max | Electrostatics |

### 5. ENSAMBLES

| Ensemble | NVE | NVT | NPT |
|----------|-----|-----|-----|
| Constant | E (energy) | T (temperature) | P, T |
| Variable | P, T | V, P | None |
| Thermostat | None | Nosé-Hoover | Nosé-Hoover |
| Barostat | None | None | Berendsen/MTK |
| Use | Microcanonical | Canonical | Isobaric-Isothermal |

---

## Knowledge Transfer Document

Este equipo recibe:

### 📄 Documentos Técnicos (a guardar en Vault)

```
/root/JarvisVault/Phase5/
├── 01-MD-FUNDAMENTALS.md
│   ├─ Integración numérica
│   ├─ Neighbor list algorithms
│   └─ Verlet vs. Velocity Verlet
│
├── 02-POTENTIALS.md
│   ├─ Lennard-Jones derivation
│   ├─ Mie modifications
│   ├─ FDR polarization model
│   └─ Ewald summation math
│
├── 03-CUDA-OPTIMIZATION.md
│   ├─ Memory coalescing
│   ├─ Atomic operations
│   ├─ Warp divergence
│   └─ Bank conflicts
│
├── 04-BENCHMARKING.md
│   ├─ Profiling tools (nvprof, nsys)
│   ├─ Memory bandwidth limits
│   ├─ Kernel optimization cycles
│   └─ Validation protocols
│
└── 05-TROUBLESHOOTING.md
    ├─ Common CUDA errors
    ├─ Physics validation checks
    ├─ Numerical stability
    └─ Performance bottlenecks
```

### 🔧 Herramientas Que Manejan

```
PROFILING:
  • nvprof (NVIDIA profiler)
  • nsys (system profiler)
  • CUPTI (performance API)

VALIDATION:
  • Benchmarking suite (10k, 100k, 1M step runs)
  • Trajectory analysis (RDF, MSD)
  • Energy conservation checks
  • Force validation (analytical vs. computed)

OPTIMIZATION:
  • CUDA kernel tuning (block/grid sizes)
  • Memory bandwidth utilization
  • Cache hit rates
  • Warp occupancy
```

---

## Integración con EQUIPO 8

```
EQUIPO 8 (DM UAMI Coordination)
├─ EQUIPO 8A: Phase 5 Coordinator (general orchestration)
└─ EQUIPO 8B: MD Expert ⭐ (THIS - technical guidance)
                ├─ Valida correctness de Phase 5
                ├─ Optimiza kernels CUDA
                ├─ Analiza benchmarks
                └─ Comunica con E19 (Vault)
```

---

## SOUL.md para cada bot

**Ejemplo: `md-algorithms-expert-SOUL.md`**

```
ROL: MD Algorithms Expert
RESPONSABILIDAD: Guiar Phase 5 en algorithms de integración
INPUTS: CUDA kernel code, test results, performance metrics
OUTPUTS: Optimizations, bug fixes, theoretical guidance
LATENCIA_SLA: < 1 hour (critical path)
EXPERTISE: Verlet, Velocity Verlet, Nosé-Hoover, leapfrog
ESCALABILIDAD: Advising 3+ parallel kernel development
```

---

## Estado

```
FASE: 57
STATUS: ✅ DISEÑO + KNOWLEDGE TRANSFER
COMPLEJIDAD: Alta (MD expertise requerida)
INTEGRACIÓN: Con EQUIPO 8, Phase 5
INICIO: HOY (2026-09-13 23:00 CST)
```

---

*"Experto en el corazón científico de GromacsMexicano"*
*EQUIPO 8B: Entiende algoritmos, potenciales, ensambles, GPU optimization*

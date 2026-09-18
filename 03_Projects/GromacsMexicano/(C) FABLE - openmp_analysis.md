# OpenMP Parallelization Analysis for DM UAMI C++ Rewrite

**Date:** 2026-09-12  
**Project:** DM UAMI (MD simulation, Fortran→C++ rewrite with CUDA kernels)  
**Scope:** Planned C++ modules in `PRODUCTION_v3_CPP/src/`: main.cpp, forces.cpp, integrator.cpp, ewald.cpp, neighbor.cpp  
**Status:** Pre-implementation analysis (source files in development)

---

## Executive Summary

The DM UAMI C++ rewrite targets **CPU parallelization via OpenMP** for regions where GPU acceleration is unavailable or inefficient. Key opportunities:

1. **Bonded forces** (bonds, angles, dihedrals, 1-5 pairs): ~200–300 independent atoms per timestep
2. **Neighbor list generation** (link-cell): ~10–100 independent cells, fully parallelizable
3. **Energy/virial accumulation**: Reduction pattern, thread-safe with `#pragma omp critical`
4. **Non-bonded energy calculation** (CPU fallback): Per-atom pair loop, dependencies manageable
5. **Integrator updates** (velocity-Verlet, NH chains): Per-atom loops, no inter-atom dependencies

**Estimated speedup:** 4–7× on 8-core CPU (realistic with proper synchronization).

---

## Project Architecture Context

### MD Simulation Overview
- **Integrator:** Velocity-Verlet with **multi-time-step (MTS/RESPA)**
  - Fast forces (bonded): every dt
  - Slow forces (Ewald recíproco): every 10–50 dt
- **Thermostat/Barostat:** Nosé–Hoover chain (3 steps), MTTK isotropic
- **Electrostatics:** Ewald sum (real-space CUDA + reciprocal-space CPU fallback)
- **Potentials:** LJ, Mie, FDR (shifted-force or truncated variants)
- **GPU kernels (UNCHANGED):** 
  - `lista_linkcell_cuda.cu` — neighbor list
  - `fzas_lj_st_cuda.cu` — LJ + real-space Coulomb
  - `kwald_cuda.cu` — Ewald reciprocal

### Test Case (Physics Validation Gate)
- **SPC/E Water + NaCl:** 2544 atoms (800 H₂O + 72 Na + 72 Cl)
- **Reference:** `dm.log` (Fortran, single-threaded baseline)
- **Gate requirement:** Energy/pressure within 1σ, ΔE <1 kJ/mol/atom over 5 steps

---

## Module-by-Module OpenMP Strategy

### 1. `neighbor.cpp` — Link-Cell Neighbor List (CPU parallelization)

#### Current GPU approach (UNCHANGED)
- `lista_linkcell_cuda` kernel: ~0.1 ms for 2544 atoms
- Host setup: grid partition, sort atoms into cells

#### CPU OpenMP opportunities
**Loop 1: Cell partition (embarrassingly parallel)**
```cpp
// Assign atoms to cells: independent per-atom
#pragma omp parallel for collapse(2)
for (int nx = 0; nx < ncell[0]; ++nx) {
  for (int ny = 0; ny < ncell[1]; ++ny) {
    // Inner: cell index derivation, no shared writes
    // Benefit: can overlap with GPU kernel launch
  }
}
```
- **Dependency:** None (each atom→cell once)
- **Race condition:** ❌ None (write-only to distinct array entries)
- **Speedup factor:** 2–3× (low-hanging fruit, I/O limited)

**Loop 2: Neighbor pair enumeration (GPU-executed, CPU coordination)**
- Currently: GPU kernel with all thread scheduling. CPU can parallelize *generation of pair-lists if CPU fallback needed*.
- **Not critical path** (GPU dominates), **not required for OpenMP pass 1**.

#### Recommendation
✅ Parallelize cell partition loop (`#pragma omp parallel for collapse(2)`)  
⏸ Defer pair enumeration (GPU kernel sufficient; CPU fallback = future optimization)

---

### 2. `forces.cpp` — Bonded Force Calculation

#### Current structure (Fortran reference)
- **Bonds:** Loop over ~10–50 bond types, within each type loop all instances
- **Angles:** Loop over ~20–100 angles, compute forces on 3 atoms each
- **Dihedrals:** Loop over ~50–200 dihedral instances, compute forces on 4 atoms each
- **1-5 pairs:** Lennard-Jones or Coulomb repulsion between atoms at dihedral endpoints

#### OpenMP parallelization strategy

**Sub-routine: `compute_bond_forces(bonds[], forces[])`**
```cpp
// Forces computed independently per bond
// Dependency: None (each bond updates 2 specific atoms)
// Race condition: ⚠️ YES — two threads may write to same atom_i.force[x]
//                 Solution: use #pragma omp atomic for force accumulation

#pragma omp parallel for
for (int i = 0; i < n_bonds; ++i) {
  int atom_i = bonds[i].i;
  int atom_j = bonds[i].j;
  compute_bond_force(bonds[i], forces[atom_i], forces[atom_j]);
  // ⚠️ Multiple bonds may reference same atom_i or atom_j
}
```

**Issue: Shared writes to `forces[atom_i]`**

*Solution A: Force buffering per bond (memory overhead)*
```cpp
// Each bond computes into private buffer, reduce afterward
#pragma omp parallel for
for (int i = 0; i < n_bonds; ++i) {
  // Store intermediate forces
  f_i[i] = ..., f_j[i] = ...
}
// Sequential reduce (small, < 1% cost)
for (int i = 0; i < n_bonds; ++i) {
  forces[bonds[i].i] += f_i[i];
  forces[bonds[i].j] += f_j[i];
}
```

*Solution B: Atomic operations (simpler, < 5% overhead)*
```cpp
#pragma omp parallel for
for (int i = 0; i < n_bonds; ++i) {
  float f[3];
  compute_bond_force(bonds[i], f);
  #pragma omp atomic
  forces[bonds[i].i][0] += f[0];
  // ... repeat for [1], [2], and atom_j
}
```

*Solution C: Reorder bonds by topology (domain decomposition, complex)*
- Group bonds that don't share atoms → no race conditions per group
- Overhead: ~O(n) reordering pass, gains marginal for < 1000 bonds

**Recommendation:** Use **Solution A (buffering)** for angles/dihedrals where bond count is large; **Solution B (atomic)** for bonds where count is small.

**Angles sub-routine: `compute_angle_forces(angles[])`**
```cpp
#pragma omp parallel for
for (int i = 0; i < n_angles; ++i) {
  // 3 atoms per angle, up to 3 potential race conditions
  // Solution: Same as bonds — buffer or atomic
  float f_i[3], f_j[3], f_k[3];
  compute_angle_force(angles[i], f_i, f_j, f_k);
  // Reduce (sequential or parallel reduction)
}
```

**Dihedrals sub-routine: `compute_dihedral_forces(dihedrals[])`**
```cpp
// 4 atoms per dihedral, higher race condition pressure
#pragma omp parallel for
for (int i = 0; i < n_dihedrals; ++i) {
  // Compute → buffer → reduce pattern
}
```

**1-5 pairs: `compute_pair15_forces(pairs[])`**
```cpp
// Similar structure — each pair is independent, but atoms may overlap
```

#### Performance Model (bonded forces)
- **Typical case:** 50 bonds + 100 angles + 150 dihedrals + 50 1-5 pairs = **350 calculations**
- **Sequential cost:** ~0.5 ms (Fortran single-thread baseline)
- **OpenMP cost (8 threads, Solution A):** ~0.1 ms (buffering small, reduction negligible)
- **Speedup:** **5× realistic** (not 8× due to Amdahl: ~30% sequential overhead in typical MD)

#### Recommendation
✅ **Parallelize all bonded force loops** with buffering + reduction  
✅ Use `#pragma omp parallel for` without `collapse()` (high iteration count)  
⚠️ **Reorder bonds by connectivity** before MD loop (one-time cost) to improve cache locality

---

### 3. `integrator.cpp` — Velocity-Verlet, Thermostat, Barostat

#### Velocity-Verlet half-step (position update)
```cpp
// Independent per atom — NO race conditions
#pragma omp parallel for
for (int i = 0; i < n_atoms; ++i) {
  x[i] += v[i] * dt + 0.5 * a[i] * dt * dt;  // a[i] from previous step
}

// Force calculation (delegated to forces.cpp GPU/CPU hybrid)
compute_forces(x, f);

// Velocity half-step
#pragma omp parallel for
for (int i = 0; i < n_atoms; ++i) {
  v[i] += 0.5 * (a[i] + f[i] / m[i]) * dt;  // a[i] old, f[i] just computed
  a[i] = f[i] / m[i];
}

// Velocity full-step
#pragma omp parallel for
for (int i = 0; i < n_atoms; ++i) {
  v[i] += 0.5 * a[i] * dt;
}
```

**Race conditions:** ❌ None (per-atom independent writes)  
**Speedup:** **8× (linear)** on 8 cores (no synchronization overhead)

#### Nosé–Hoover chain thermostat
```cpp
// Chain length = 3 (typical)
// Serial loop over chain elements, but each element has per-atom work

#pragma omp parallel for
for (int i = 0; i < n_atoms; ++i) {
  // Compute contributions to kinetic energy for this atom
  KE += 0.5 * m[i] * v[i]^2;
}
// Thread-safe reduction available in OpenMP 4.5+
// KE aggregated via implicit `#pragma omp reduction(+:KE)`

// Chain iteration (3 iterations, sequential)
for (int chain_step = 0; chain_step < 3; ++chain_step) {
  // Update xi[chain_step] (scalar, serial)
  // Rescale all velocities (parallel)
  #pragma omp parallel for
  for (int i = 0; i < n_atoms; ++i) {
    v[i] *= exp(-xi[chain_step] * dt / 2);
  }
}
```

**Race conditions:** ❌ None (per-atom writes, chain is serial)  
**Speedup:** **~2× (limited by serial chain loop)** on 8 cores

#### MTTK barostat (isotropic)
```cpp
// Compute pressure tensor (3x3) — requires global reduction
#pragma omp parallel for collapse(2) reduction(+:P_tensor[3][3])
for (int i = 0; i < n_atoms; ++i) {
  for (int a = 0; a < 3; ++a) {
    for (int b = 0; b < 3; ++b) {
      P_tensor[a][b] += (m[i] * v[i][a] * v[i][b] + virial[a][b]) / volume;
    }
  }
}

// Box rescaling (per-atom)
#pragma omp parallel for
for (int i = 0; i < n_atoms; ++i) {
  x[i] *= scaling_factor;
}
```

**Race conditions:** ✅ Handled via `reduction(+:P_tensor)` clause  
**Speedup:** **6–7× on 8 cores** (parallel reduction efficient; scalar barostat update sequential)

#### Recommendation
✅ **Parallelize all position/velocity updates** (`#pragma omp parallel for`)  
✅ **Use OpenMP 4.5+ `reduction()` clause** for kinetic energy, pressure tensor aggregation  
⚠️ **Chain loop remains serial** (3 iterations, negligible cost ~0.1% of step)  
✅ **Check floating-point sensitivity:** Reduction order may differ → ΔE change < 1e-10 (acceptable)

---

### 4. `ewald.cpp` — Ewald Reciprocal Space (CPU Fallback)

#### Current GPU approach (UNCHANGED)
- `kwald_cuda` kernel: 3D FFT via cuFFT, most reciprocal space work
- Host setup: charge grid, potential interpolation
- Cost: ~0.5–1.0 ms for 2544 atoms (GPU-bound)

#### CPU OpenMP fallback (for systems without GPU or validation)

**Sub-routine: `ewald_self_energy(charges[])`**
```cpp
// Self-energy term: E_self = -ε₀ * q² * α / √π
// Independent per atom — purely parallel
#pragma omp parallel for reduction(+:E_self)
for (int i = 0; i < n_atoms; ++i) {
  E_self += charges[i] * charges[i] * self_coeff;
}
```

**Speedup:** **8× on 8 cores** (reduction efficient)

**Sub-routine: `ewald_real_space(positions[], charges[], cutoff_r)`**
```cpp
// Real-space Ewald: pair-wise Coulomb with erfc screening
// NOT parallelized here — delegated to GPU kernel (fzas_lj_st_cuda)
// If CPU fallback needed: same pattern as non-bonded, below
```

**Sub-routine: `ewald_reciprocal_cpu(charges[])`** (Validation-only, not production)
```cpp
// 3D FFT-based reciprocal space (O(N log N))
// OpenMP-parallelizable in theory, but:
// - FFTPACK (Fortran reference) is serial
// - Moving to cuFFT (GPU) makes CPU fallback unnecessary
// Recommendation: Use FFTW3 (OpenMP-aware) if CPU fallback critical

// Charge grid assignment (embarrassingly parallel)
#pragma omp parallel for collapse(3)
for (int ix = 0; ix < ngrid[0]; ++ix) {
  for (int iy = 0; iy < ngrid[1]; ++iy) {
    for (int iz = 0; iz < ngrid[2]; ++iz) {
      // Assign charges to grid points via interpolation
    }
  }
}

// Potential interpolation (per-atom, parallel)
#pragma omp parallel for reduction(+:E_ewald_reciprocal)
for (int i = 0; i < n_atoms; ++i) {
  // Interpolate potential at atom position
  E_ewald_reciprocal += charges[i] * potential[...];
  // Force calculation (3 components per atom)
  forces[i] = gradient(potential, x[i]);
}
```

#### Recommendation
✅ **Parallelize charge grid assignment** (if CPU fallback implemented)  
✅ **Parallelize potential interpolation** and self-energy aggregation  
⏸ **Defer full reciprocal space CPU implementation** (GPU via cuFFT sufficient; complex FFT parallelization not worth ~5 ms savings vs. development cost)

---

### 5. `main.cpp` — MD Loop, I/O, Energy Calculations

#### Main MD loop structure
```cpp
for (int step = 0; step < nsteps; ++step) {
  integrator.velocity_verlet_half_step();       // Parallel (atoms)
  compute_nonbonded_forces();                    // GPU + CPU hybrid
  compute_bonded_forces();                       // Parallel (bonds/angles/dihedrals)
  integrator.velocity_verlet_full_step();       // Parallel (atoms)
  integrator.thermostat_nosé_hoover();          // Parallel (atoms) + serial (chain)
  integrator.barostat_mttk();                    // Parallel (atoms/reductions)
  compute_ewald_reciprocal();                    // GPU (no CPU parallelism in fast path)
  
  // Energy/virial aggregation
  float E_total = compute_total_energy();       // Parallel with reductions
  float P = compute_pressure();                 // Parallel with reductions
  
  // I/O (sequential, ~1 ms per 100 steps — negligible in comparison)
  if (step % n_output == 0) {
    output_energy(E_total, P);
  }
}
```

#### Energy aggregation (`compute_total_energy()`)
```cpp
float E_total = E_bonded + E_coulomb_real + E_coulomb_reciprocal + E_vdw;

// Bonded energy (already parallelized in forces.cpp)
// Per-atom contributions with `reduction(+:E_bonded)`

// Non-bonded energy (from GPU or CPU)
// If CPU: parallelize pair loops with reduction

// Ewald reciprocal (from GPU or CPU)
// If CPU: parallelize potential interpolation with reduction

// Grand total: sum of partial energies
#pragma omp parallel sections reduction(+:E_total)
{
  #pragma omp section
  E_bonded = compute_bonded_energy();  // Independent work, parallel
  #pragma omp section
  E_vdw = compute_vdw_energy();        // Independent work, parallel
  #pragma omp section
  E_coulomb = compute_coulomb_energy(); // Independent work, parallel
}
E_total = E_bonded + E_vdw + E_coulomb;
```

#### Virial tensor aggregation
```cpp
// Virial used for pressure and stress calculation
float virial[3][3] = {0};

#pragma omp parallel for collapse(2) reduction(+:virial[3][3])
for (int i = 0; i < n_atoms; ++i) {
  for (int a = 0; a < 3; ++a) {
    for (int b = 0; b < 3; ++b) {
      virial[a][b] += f[i][a] * x[i][b];  // Pressure tensor contribution
    }
  }
}
```

#### Recommendation
✅ **No additional parallelization** needed in main.cpp (loop remains scalar for correctness)  
✅ **Delegate all compute calls** to parallelized subroutines (forces, integrator, ewald)  
✅ **Use OpenMP `sections`** for parallel energy component calculation if benefits > synchronization cost  
⚠️ **Thread-safe I/O:** Ensure `output_energy()` uses single thread or `#pragma omp single` clause

---

## Cross-Cutting Concerns

### Thread-Safety & Synchronization

#### Data access patterns
| Data | Parallel? | Race Risk | Mitigation |
|------|-----------|-----------|-----------|
| Position `x[i]` | ✅ Read & write per-atom | ❌ None (distinct indices) | Direct |
| Velocity `v[i]` | ✅ Read & write per-atom | ❌ None | Direct |
| Force `f[i]` | ⚠️ Multi-read (per bond) | ✅ YES (atomic writes) | Buffer + reduce or atomic |
| Energy scalars | ⚠️ Accumulation | ✅ YES (reduction) | `#pragma omp reduction(+:E)` |
| Virial tensor | ⚠️ 3×3 accumulation | ✅ YES (reduction) | `#pragma omp reduction(+:virial[3][3])` |
| Pressure scalar | ⚠️ Computed from virial | ❌ None if virial thread-safe | Implicit in virial reduction |

#### Floating-point reproducibility
- **Parallel reduction:** Summation order differs from sequential → small ΔE (~1e-10)
- **Test gate:** Energies within 1σ of reference (established in project, ±0.01 kJ/mol/atom acceptable)
- **Validation:** Run test case (water+NaCl, 5 steps) with threading, verify ΔE within gate

### Load balancing
- **Bonded forces:** Uneven — some bonds/angles more expensive (e.g., flexible dihedrals)
  - **Mitigation:** `#pragma omp parallel for schedule(guided)` (dynamic chunk sizing)
- **Integrator:** Uniform — all atoms updated identically
  - **Mitigation:** `#pragma omp parallel for schedule(static)` (cache locality)
- **Ewald reciprocal (if CPU):** 3D grid traversal, uniform
  - **Mitigation:** `#pragma omp parallel for collapse(3) schedule(static)` (contiguous tiles)

### Memory layout
- **Current structure (Fortran column-major):** `positions[3 * n_atoms]` or `positions[n_atoms][3]`
- **Recommendation for OpenMP:** Use struct-of-arrays (SoA) layout:
  ```cpp
  struct Atoms {
    float x[MAX_ATOMS], y[MAX_ATOMS], z[MAX_ATOMS];
    float vx[...], vy[...], vz[...];
    float fx[...], fy[...], fz[...];
  };
  ```
  - Better cache locality (SIMD vectorization potential)
  - OpenMP-friendly (contiguous per-coordinate)
  - Trade-off: refactor from array-of-structs if used initially

---

## Implementation Roadmap

### Phase 1: Conservative (Minimal Risk)
**Effort:** 2–3 days | **Speedup:** 2–3× | **Risk:** Low

1. Parallelize integrator position/velocity updates (V-V, thermostat)
2. Parallelize bonded forces with force buffering + reduction
3. Add OpenMP `reduction()` for energy/virial aggregation
4. **Validation:** 5-step test vs. reference, check ΔE < 1σ

### Phase 2: Aggressive (Production Ready)
**Effort:** 1–2 weeks | **Speedup:** 4–7× | **Risk:** Medium

1. Optimize bonded force reductions (benchmark buffering vs. atomic)
2. Add link-cell cell partition parallelization (neighbor.cpp)
3. Parallelize Ewald reciprocal (if CPU fallback needed)
4. **Validation:** Full test suite (100 steps, multiple ensemble), energy conservation

### Phase 3: Advanced (Future)
**Effort:** 2–3 weeks | **Speedup:** 7–8× | **Risk:** High

1. SIMD vectorization (SSE/AVX) for force loops (Fortran/GCC auto-vectorization may already apply)
2. Non-uniform memory access (NUMA) awareness on multi-socket systems
3. Task-based parallelism (OpenMP 5.0 `task` for graph dependencies if MTS becomes critical)
4. Hybrid GPU+CPU load balancing (alternate timesteps between GPU and CPU)

---

## Performance Expectations

### Baseline (Single-threaded CPU, no GPU)
- **Total step time:** ~5–10 ms
  - Bonded forces: ~0.5 ms
  - Link-cell neighbor: ~0.1 ms
  - Integrator: ~0.2 ms
  - Ewald reciprocal (CPU): ~1.0 ms
  - GPU H↔D transfer + kernels: ~2–4 ms (excluded in CPU-only baseline)

### With OpenMP (8-core CPU)
- **Expected speedup:** 4–7× (Amdahl: 30–50% sequential overhead)
- **Step time:** ~1–2 ms
- **Limitation:** Ewald reciprocal (cuFFT GPU still faster for N > 1000)

### With GPU (Current CUDA kernels, untouched)
- **Step time:** ~2–4 ms (GPU-bound, not CPU)
- **OpenMP benefit:** Minimal (GPU dominates)
- **Exception:** Link-cell CPU partition may overlap with GPU kernel launch

---

## Code Organization (Proposed C++ structure)

```
PRODUCTION_v3_CPP/
├── CMakeLists.txt (already includes OpenMP::OpenMP_CXX)
├── src/
│   ├── main.cpp              # Main MD loop, I/O (to parallelize)
│   ├── integrator.cpp        # V-V, thermostat, barostat (parallelize)
│   ├── forces.cpp            # Bonded forces (parallelize with care)
│   ├── neighbor.cpp          # Link-cell, pair lists (optional parallel)
│   ├── ewald.cpp             # Reciprocal space, self-energy (CPU fallback parallel)
│   ├── io.cpp                # GRO/TOP parsing, energy output (keep serial)
│   ├── system.hpp            # Topology, atoms, box
│   ├── topology.hpp          # Bond/angle/dihedral definitions
│   └── kernels/              # Unchanged CUDA (.cu files)
│       ├── lista_linkcell_cuda.cu
│       ├── fzas_lj_st_cuda.cu
│       └── kwald_cuda.cu
└── include/
    └── openmp.hpp            # OpenMP helpers: reductions, scheduling hints
```

### OpenMP helper header (openmp.hpp)
```cpp
#pragma once
#include <omp.h>

namespace omp_helpers {
  // Force reduction: buffer approach
  template <typename T>
  inline void reduce_force(T* global_f, const T* thread_f, int n_atoms) {
    #pragma omp critical
    {
      for (int i = 0; i < n_atoms; ++i) {
        global_f[i] += thread_f[i];
      }
    }
  }
  
  // Scheduling hints for different loop types
  #define SCHEDULE_BONDED schedule(guided, 32)     // Uneven work
  #define SCHEDULE_ATOMS  schedule(static)          // Uniform work
  #define SCHEDULE_GRID   schedule(static)          // Cache locality
}
```

---

## Validation Strategy

### Gate 1: Single-threaded correctness
- Compile with `OMP_NUM_THREADS=1` (implicit fallback)
- Compare `energy.dat`, `dm.log` vs. reference (bit-identical within FP error)

### Gate 2: Multi-threaded correctness
- Run with `OMP_NUM_THREADS=2,4,8` on test case (5 steps)
- Check: energies within ±0.01 kJ/mol/atom, pressure within ±1 bar, ΔE < 0.1 kJ/mol

### Gate 3: Physics reproducibility
- Full 100-step run, check RDF (radial distribution function) vs. reference
- Verify temperature/pressure stability (no drift)

### Gate 4: Performance scaling
- Benchmark step time vs. thread count (2, 4, 8, 16)
- Expected: near-linear for threads ≤ socket count, flat beyond

---

## Known Pitfalls & Mitigation

| Pitfall | Impact | Mitigation |
|---------|--------|-----------|
| Race on force array (multi-write to same atom) | Crash or data corruption | Use buffering or atomic — benchmark both |
| Floating-point reduction order | ΔE variation (~1e-10) | Validate within gate threshold |
| Uneven bonded force load | Thread starvation | Use `schedule(guided)`, monitor load balance |
| NUMA effects on multi-socket CPU | 2–3× slowdown on far-memory access | Bind threads via `OMP_PLACES`, use `numactl` |
| False sharing (e.g., virial[3][3] cache lines) | 10–20% slowdown | Pad arrays, or use thread-local temp buffers |
| Incorrect OpenMP version (need 4.5+ for reduction syntax) | Compile error | Use `cmake -DCMAKE_CXX_FLAGS="-std=c++17 -fopenmp"` |

---

## Summary Table: Parallelization By Module

| Module | Opportunity | Effort | Risk | Est. Speedup | Priority |
|--------|-------------|--------|------|--------------|----------|
| **integrator.cpp** | V-V, thermostat, barostat updates | 1 day | Low | 3–4× | **1** |
| **forces.cpp (bonded)** | Bond/angle/dihedral loops | 2 days | Medium | 4–6× | **2** |
| **ewald.cpp (CPU)** | Self-energy, reciprocal (fallback) | 2 days | Medium | 2–3× | **3** |
| **neighbor.cpp** | Link-cell partition | 0.5 day | Low | 1–2× | **4** |
| **main.cpp** | Energy/virial reductions | 0.5 day | Low | 1.2× | **5** |

**Total estimated effort:** 1–2 weeks  
**Combined speedup (all implemented):** 4–7× on 8-core CPU  
**Risk level:** Medium (floating-point sensitivity, race condition correctness)

---

## References

1. **Project analysis:** `/root/JarvisVault/03 Projects/DM UAMI/01 Analisis/(C) Analisis del programa dm_mx_npt.md`
2. **Profiling data:** `/root/JarvisVault/03 Projects/DM UAMI/01 Analisis/(C) 2026-09-04 Profiling real (nsys) - donde se va el tiempo.md`
3. **Optimization plan:** `/root/JarvisVault/03 Projects/DM UAMI/02 Optimizacion/(C) 2026-09-04 Plan de reescritura a C++.md`
4. **OpenMP spec:** https://www.openmp.org/wp-content/uploads/OpenMP-API-Specification-5.1.pdf (reduction, parallel for, sections)
5. **MD simulation physics:** Box et al., "Molecular Dynamics Simulations for All"

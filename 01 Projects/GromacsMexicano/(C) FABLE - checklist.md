# OpenMP Parallelization Implementation Checklist

**Project:** GromacsMexicano C++ Rewrite (PRODUCTION_v3_CPP)  
**Target:** CPU parallelization via OpenMP, complement existing CUDA kernels  
**Date:** 2026-09-12

---

## Pre-Implementation Verification

### Build Environment
- [ ] CMake ≥ 3.20 installed
- [ ] GCC/Clang compiler with OpenMP support (`-fopenmp`)
- [ ] Verify OpenMP detection: `cmake -DCMAKE_CXX_FLAGS="-fopenmp" && make VERBOSE=1`
- [ ] Check CMakeLists.txt: `find_package(OpenMP REQUIRED)` and `target_link_libraries(...OpenMP::OpenMP_CXX)`
- [ ] Test single-threaded build: `OMP_NUM_THREADS=1 ./dm_mx_npt`

### Physics Validation Gate
- [ ] Reference data ready: `/home/alejandre/GromacsMexicano/UAMI_baseline/dm.log` (Fortran single-threaded)
- [ ] Test case available: water+NaCl, 2544 atoms, 5 steps
- [ ] Validation thresholds defined:
  - [ ] Energy precision: ±0.01 kJ/mol/atom
  - [ ] Pressure: ±1 bar
  - [ ] ΔE per step: < 0.1 kJ/mol (drifting energy indicates bug)

---

## Phase 1: Conservative Implementation (Days 1-3)

### Task 1.1: Integrator Position Update (`integrator.cpp`)

**Module:** `velocity_verlet_position_step()`

```cpp
#pragma omp parallel for schedule(static)
for (int i = 0; i < n_atoms; ++i) {
  x[i] += v[i] * dt + 0.5 * a_old[i] * dt²;
}
```

Checklist:
- [ ] Implement `#pragma omp parallel for` over atoms
- [ ] Use `schedule(static)` for cache locality
- [ ] Compile: `make -j$(nproc)`
- [ ] Test single-threaded: `OMP_NUM_THREADS=1 ./test_integrator`
- [ ] Test multi-threaded: `OMP_NUM_THREADS=4 ./test_integrator` — should match single-thread (within 1e-10 FP error)
- [ ] **Physics gate:** 5-step run, check ΔE < 0.1 kJ/mol

**Effort:** 0.5 day  
**Risk:** Low (no race conditions, per-atom independent)

---

### Task 1.2: Integrator Velocity Update (`integrator.cpp`)

**Module:** `velocity_verlet_velocity_step()` and `velocity_verlet_full_step()`

Checklist:
- [ ] Parallelize velocity half-step: `#pragma omp parallel for`
- [ ] Parallelize velocity full-step: `#pragma omp parallel for`
- [ ] Compile & test (same as 1.1)
- [ ] **Physics gate:** Kinetic energy stability (no acceleration)

**Effort:** 0.5 day  
**Risk:** Low

---

### Task 1.3: Thermostat Velocity Rescaling (`integrator.cpp`)

**Module:** `thermostat_velocity_rescale()`

Checklist:
- [ ] Compute kinetic energy: `#pragma omp parallel for reduction(+:KE)`
- [ ] Rescale velocities: `#pragma omp parallel for` (independent per-atom)
- [ ] Test: verify temperature convergence with thermostat
- [ ] **Physics gate:** Temperature stability, ΔKE controlled by thermostat

**Effort:** 0.5 day  
**Risk:** Low (reduction standard pattern)

---

### Task 1.4: Pressure Tensor Aggregation (`integrator.cpp` / `main.cpp`)

**Module:** `compute_pressure_tensor()`, `aggregate_virial()`

Checklist:
- [ ] Parallel reduction for virial tensor: `#pragma omp parallel for reduction(+:virial[3][3])`
- [ ] Parallel reduction for kinetic energy tensor: `#pragma omp parallel for reduction(+:pressure[3][3])`
- [ ] Test: reproduce pressure output with single/multi-thread
- [ ] **Physics gate:** Pressure matches reference ±1 bar

**Effort:** 0.5 day  
**Risk:** Low (2D reduction, standard pattern)

---

### Task 1.5: Energy Aggregation (`main.cpp`)

**Module:** `compute_total_energy()`, `compute_virial_from_forces()`

Checklist:
- [ ] Parallelize force-virial loop: `#pragma omp parallel for reduction(+:virial[3][3])`
- [ ] Aggregate energy components: `#pragma omp parallel sections`
- [ ] Test: single vs. multi-thread energy values
- [ ] **Physics gate:** Total energy matches reference within ±0.01 kJ/mol

**Effort:** 0.5 day  
**Risk:** Medium (floating-point reduction order sensitive)

**Gate 1 Summary:**
- [ ] All 5 tasks complete and tested independently
- [ ] Full 5-step MD run, all energies within gate
- [ ] Build times: < 30 seconds (should not increase)
- [ ] **Go/No-go decision:** Proceed to Phase 2 if ΔE < 0.1 kJ/mol on 5-step run

---

## Phase 2: Bonded Forces (Days 4-6)

### Task 2.1: Bond Force Parallelization (`forces.cpp`)

**Module:** `compute_bond_forces()`

**Approach:** Force buffering + reduction

```cpp
#pragma omp parallel for
for (int b = 0; b < n_bonds; ++b) {
  // Compute into f_buffer[b] (thread-local)
}
// Reduction (sequential, small O(n_bonds) cost)
```

Checklist:
- [ ] Implement force buffering (one temp buffer per thread)
- [ ] Compute bond forces in parallel loop
- [ ] Reduce thread-local buffers to global forces array
- [ ] Compile & test
- [ ] **Physics gate:** Bond energies match, no NaN/inf forces
- [ ] Benchmark: compare buffering vs. atomic approach (Task 2.2)

**Effort:** 1 day  
**Risk:** Medium (race condition correctness, buffering overhead)

---

### Task 2.2: Atomic Operations Benchmark (`forces.cpp`)

**Module:** Alternative `compute_bond_forces_atomic()`

**Approach:** Use `#pragma omp atomic` for force accumulation

```cpp
#pragma omp parallel for schedule(guided, 32)
for (int b = 0; b < n_bonds; ++b) {
  // Compute forces
  #pragma omp atomic
  forces[i][x] += f_mag * dx;
  // ... repeat for i,j and x,y,z
}
```

Checklist:
- [ ] Implement atomic version
- [ ] Profile: time 100 MD steps with atomic vs. buffering
- [ ] Compare accuracy (should be identical within FP error)
- [ ] **Decision:** Use faster approach (likely buffering for small n_bonds)

**Effort:** 0.5 day  
**Risk:** Low (both approaches well-established)

---

### Task 2.3: Angle Force Parallelization (`forces.cpp`)

**Module:** `compute_angle_forces()`

Checklist:
- [ ] Implement using chosen strategy (buffering or atomic)
- [ ] Parallelize per-angle loop: `#pragma omp parallel for schedule(guided, 16)`
- [ ] Test: angle energies and forces match reference
- [ ] **Physics gate:** Total energy within ±0.01 kJ/mol

**Effort:** 1 day  
**Risk:** Medium (3 atoms/angle, more race contention)

---

### Task 2.4: Dihedral Force Parallelization (`forces.cpp`)

**Module:** `compute_dihedral_forces()`

Checklist:
- [ ] Implement per-dihedral loop: `#pragma omp parallel for schedule(guided, 16)`
- [ ] Handle 4-atom dependencies carefully (buffering preferred)
- [ ] Test: dihedral energies correct, forces consistent with U
- [ ] **Physics gate:** Total energy within gate

**Effort:** 1 day  
**Risk:** Medium

---

### Task 2.5: 1-5 Pair Forces (`forces.cpp`)

**Module:** `compute_pair15_forces()` (Coulomb + LJ repulsion for 1-5 pairs)

Checklist:
- [ ] Parallelize 1-5 pair loop: `#pragma omp parallel for`
- [ ] Test: energies and forces
- [ ] **Physics gate:** Total energy within gate

**Effort:** 0.5 day  
**Risk:** Low

---

### Task 2.6: Bond Reordering (Optimization) (`forces.cpp`)

**Module:** Pre-MD routine `reorder_bonds_by_connectivity()`

Checklist:
- [ ] Group bonds that don't share atoms → independent groups
- [ ] Process groups sequentially, but atoms within group in parallel (optional)
- [ ] Benchmark: improvement in cache locality
- [ ] **Decision:** Worth the overhead? (Probably not for < 100 bonds, worth it for > 1000)

**Effort:** 1 day  
**Risk:** Low (optimization, not critical path)

---

**Gate 2 Summary:**
- [ ] All bonded force routines parallelized
- [ ] 100-step MD run, all energies within gate
- [ ] Profile bonded force time: should see 4–6× speedup on 8 cores
- [ ] **Go/No-go:** Proceed to Phase 3 if bonded speedup ≥ 2× observed

---

## Phase 3: Advanced (Weeks 2-3)

### Task 3.1: Link-Cell Cell Partition (`neighbor.cpp`)

**Module:** `build_link_cell()`, specifically cell assignment loop

```cpp
#pragma omp parallel for collapse(2)
for (int nx = 0; nx < ncell[0]; ++nx) {
  for (int ny = 0; ny < ncell[1]; ++ny) {
    // ... process cell (ny) ...
  }
}
```

Checklist:
- [ ] Parallelize cell grid traversal
- [ ] Test: link-cell structure identical single vs. multi-thread
- [ ] **Physics gate:** Neighbor lists correct, non-bonded energies match

**Effort:** 0.5 day  
**Risk:** Low

---

### Task 3.2: Ewald Reciprocal CPU Fallback (Optional)

**Module:** `ewald.cpp`, specifically `ewald_reciprocal_cpu()`

**Note:** Only if GPU fallback needed (unlikely in production)

Checklist:
- [ ] Parallelize charge grid assignment: `#pragma omp parallel for collapse(3)`
- [ ] Parallelize potential interpolation: `#pragma omp parallel for reduction(+:E_ewald)`
- [ ] Benchmark: CPU vs. GPU (GPU should win for N > 1000)

**Effort:** 1 day  
**Risk:** Medium (FFT parallelization complex)

---

### Task 3.3: SIMD Vectorization (Optional)

**Module:** All force/position loops

**Approach:** GCC/Clang auto-vectorization + manual SIMD hints

Checklist:
- [ ] Compile with `-O3 -march=native` (already in CMakeLists.txt)
- [ ] Check compiler vectorization: `gcc -O3 -fopt-info-vec-all -c file.cpp`
- [ ] Manual hints: `#pragma omp simd` for innermost loops (Fortran loops)
- [ ] Benchmark: SIMD speedup (expect ~2–3× on 256-bit AVX2)

**Effort:** 1–2 weeks  
**Risk:** High (platform-dependent, subtle bugs)

---

### Task 3.4: NUMA Awareness (Optional, Multi-socket Systems)

**Module:** Main MD loop initialization

Checklist:
- [ ] Detect NUMA: `numactl --hardware`
- [ ] Set thread affinity: `export OMP_PLACES=cores(4)` (8 cores = 2 places × 4 cores)
- [ ] Benchmark: NUMA vs. default (expect ~2–3× improvement on 2-socket)

**Effort:** 0.5 day  
**Risk:** Low (configuration-dependent)

---

## Compilation & Testing

### Build Commands

```bash
# Clone the project
cd /home/alejandre/GromacsMexicano/PRODUCTION_v3_CPP

# Create build directory
mkdir -p build && cd build

# Configure (OpenMP required)
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_FLAGS="-O3 -march=native -fopenmp" ..

# Build
make -j$(nproc)

# Verify OpenMP linking
ldd ./bin/dm_mx_npt | grep -i omp
```

### Testing Protocol

**Single-thread baseline (reproducibility check):**
```bash
export OMP_NUM_THREADS=1
./bin/dm_mx_npt < input.mdp > /tmp/serial.log
diff /tmp/serial.log reference.log  # Should be bit-identical
```

**Multi-thread (correctness check):**
```bash
export OMP_NUM_THREADS=4
./bin/dm_mx_npt < input.mdp > /tmp/parallel.log
# Check energies within ±0.01 kJ/mol, physics valid
```

**Scaling benchmark:**
```bash
for threads in 1 2 4 8 16; do
  export OMP_NUM_THREADS=$threads
  time ./bin/dm_mx_npt < input.mdp > /dev/null
done
# Plot speedup curve
```

---

## Risk Mitigation

### Issue: Race Condition on Force Array
**Symptom:** Energies mismatch, or segfault (data corruption)  
**Fix:**
- [ ] Verify force buffering is per-thread (thread-local storage)
- [ ] Ensure reduction loop is sequential (no `#pragma omp` on reduce)
- [ ] Use `#pragma omp atomic` if atomic approach chosen

### Issue: Floating-Point Reduction Differs
**Symptom:** ΔE = 0.05 kJ/mol (exceeds gate of 0.01)  
**Cause:** Summation order differs between serial and parallel  
**Fix:**
- [ ] Check gate threshold is within statistical error (project defines 1σ = ±0.01)
- [ ] Use `OMP_NUM_THREADS=1` to validate (should match reference)
- [ ] Consider using `kahan_sum()` for higher precision (unlikely needed)

### Issue: Uneven Load Balancing (Bonded Forces)
**Symptom:** Profile shows one thread at 100%, others idle  
**Fix:**
- [ ] Use `schedule(guided, chunk_size)` instead of `schedule(static)`
- [ ] Benchmark chunk sizes: 8, 16, 32

### Issue: Pressure Tensor `omp reduction(+:P[3][3])` Syntax Error
**Symptom:** Compiler error: "invalid syntax"  
**Fix:**
- [ ] Ensure **OpenMP 4.5+** (GCC 6.0+, Clang 4.0+)
- [ ] Alternative: Manually reduce (less efficient, but compatible with older compilers)
  ```cpp
  float P_temp[3][3] = {0};
  #pragma omp critical
  { for (int a=0; a<3; ++a) for (int b=0; b<3; ++b) P[a][b] += P_temp[a][b]; }
  ```

---

## Deliverables

### Code
- [ ] `src/integrator.cpp` — parallelized V-V, thermostat, barostat
- [ ] `src/forces.cpp` — parallelized bonded forces (bonds, angles, dihedrals, 1-5)
- [ ] `src/neighbor.cpp` — parallelized link-cell (optional)
- [ ] `src/ewald.cpp` — parallelized self-energy, reciprocal fallback (optional)
- [ ] `src/main.cpp` — parallelized energy/virial reductions

### Documentation
- [ ] `docs/openmp_parallelization.md` — this document
- [ ] `docs/openmp_implementation_notes.md` — per-module notes
- [ ] `docs/performance_scaling.txt` — benchmark results (speedup vs. threads)

### Tests
- [ ] `test/test_integrator.cpp` — single vs. multi-thread correctness
- [ ] `test/test_bonded_forces.cpp` — force magnitude + energy conservation
- [ ] `test/test_physics_gate.cpp` — 5/100-step runs, energy within gate

### Benchmarks
- [ ] `benchmarks/scaling_curve.txt` — speedup vs. thread count
- [ ] `benchmarks/profile_breakdown.txt` — % time per module (integrator, bonded, ewald, I/O)

---

## Timeline Estimate

| Phase | Tasks | Effort | Cumulative |
|-------|-------|--------|-----------|
| 1 (Conservative) | 1.1–1.5 (integrator, reductions) | 2.5 days | 2.5 days |
| 2 (Bonded) | 2.1–2.6 (bonds, angles, dihedrals) | 5 days | 7.5 days |
| 3 (Advanced) | 3.1–3.4 (link-cell, Ewald, SIMD, NUMA) | 5–10 days | 12–17 days |
| **Validation & Docs** | Testing, profiling, writeup | 2 days | 14–19 days |

**Best case (Phase 1 only):** 4–5 days → 2–3× speedup  
**Target case (Phases 1+2):** 10 days → 4–6× speedup  
**Full case (all phases):** 3 weeks → 7–8× speedup

---

## Success Criteria

✅ **All gates pass:**
1. Physics validation: ΔE < 0.1 kJ/mol (5 steps), ±0.01 kJ/mol (100 steps)
2. Pressure/temperature stable
3. Bit-identical results with `OMP_NUM_THREADS=1` vs. reference

✅ **Performance:**
- Speedup ≥ 4× on 8-core CPU (Phase 1+2)
- Scaling near-linear for threads ≤ socket count

✅ **Code quality:**
- No compiler warnings (`-Wall -Wextra`)
- Static analysis clean (`clang-tidy`, if available)
- Code review pass (if team policy)

---

## Contact & Escalation

**Questions on parallelization strategy?** Refer to:
- OpenMP spec: https://www.openmp.org/spec-html/5.1/openmp.html
- Project analysis: `/root/JarvisVault/03 Projects/GromacsMexicano/01 Analisis/`

**Physics validation issues?** Reference:
- Fortran code: `/home/alejandre/Programa_DM/` (scientists' baseline)
- Test case: `/home/alejandre/GromacsMexicano/Prueba/`

**Build issues?** Check:
- CMake version: `cmake --version` (require ≥ 3.20)
- OpenMP availability: `gcc -v 2>&1 | grep -i openmp`

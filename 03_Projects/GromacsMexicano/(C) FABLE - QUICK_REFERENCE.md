# Quick Reference: OpenMP Parallelization for DM UAMI

## TL;DR — Key Takeaways

| Aspect | Finding |
|--------|---------|
| **Source status** | C++ files don't exist yet; analysis is pre-implementation |
| **Parallelization targets** | Integrator loops (8× speedup), bonded forces (4–6×), energy reductions |
| **Critical issue** | Race conditions on force array `f[i]` — solve with force buffering |
| **Expected result** | 4–7× speedup on 8-core CPU (Amdahl-limited by GPU dominance + sequential I/O) |
| **Time to implement** | 1–2 weeks (Phase 1+2), 3 weeks with all optimizations |
| **Risk level** | Medium (floating-point sensitivity, race condition correctness) |
| **Physics validation** | Gate: ±0.01 kJ/mol on 100-step run, compare to Fortran reference |

---

## The Race Condition Problem (Must Solve)

**Scenario:** Multiple bonds write to same atom's force array
```
Bond A: atoms (1, 5)  → updates f[1] and f[5]
Bond B: atoms (1, 2)  → updates f[1] and f[2]  ← RACE on f[1]!
```

**Solutions:**

### ✅ Solution 1: Force Buffering (RECOMMENDED)
```cpp
#pragma omp parallel for
for (int b = 0; b < n_bonds; ++b) {
  f_thread[bonds[b].i] += ...;  // Private buffer, no race
}
// After loop: sequential reduction to global f[]
```
- Overhead: ~5% memory, ~5% time
- Best for: Small-to-medium bond count (< 1000)

### ⚠️ Solution 2: Atomic Operations
```cpp
#pragma omp parallel for
for (int b = 0; b < n_bonds; ++b) {
  #pragma omp atomic
  f[bonds[b].i] += ...;  // Serialized write
}
```
- Overhead: ~10–20% time
- Best for: Very uneven load distribution (dynamic scheduling benefits offset atomic cost)

**Decision:** Benchmark both on actual data; likely buffering wins by 2–5%.

---

## Parallelization Checklist (By Module)

### integrator.cpp ✅ (DO FIRST — easiest, lowest risk)
```cpp
// Velocity-Verlet position update
#pragma omp parallel for schedule(static)
for (int i = 0; i < n_atoms; ++i) {
  x[i] += v[i] * dt + 0.5 * a[i] * dt²;
}

// Kinetic energy + pressure tensor reductions
#pragma omp parallel for reduction(+:KE, pressure[3][3])
for (int i = 0; i < n_atoms; ++i) {
  KE += 0.5 * m[i] * v[i]²;
  pressure[a][b] += m[i] * v[i][a] * v[i][b] / volume;
}
```
- **Speedup:** 3–4× (Amdahl-limited by ~30% sequential overhead)
- **Risk:** LOW
- **Effort:** 2.5 days
- **Gate:** 5-step physics test, ΔE < 0.1 kJ/mol

### forces.cpp ✅ (DO SECOND — medium risk, high value)
```cpp
// Bonded force loop with buffering
#pragma omp parallel {
  float* f_thread = allocate_thread_private();
  #pragma omp for
  for (int b = 0; b < n_bonds; ++b) {
    // Compute into f_thread[i], f_thread[j]
  }
  #pragma omp barrier;
  #pragma omp critical
  reduce_forces_to_global(f_global, f_thread);
}

// Or: Atomic approach
#pragma omp parallel for schedule(guided, 32)
for (int b = 0; b < n_bonds; ++b) {
  #pragma omp atomic
  f[i] += ...; // x, y, z components
}
```
- **Speedup:** 4–6× (350 calculations/step, manageable contention)
- **Risk:** MEDIUM (race condition, but well-studied pattern)
- **Effort:** 4–5 days (including benchmark of both approaches)
- **Gate:** 100-step physics test, energies within ±0.01 kJ/mol

### main.cpp / ewald.cpp ✅ (DO THIRD — reductions, optional Ewald CPU)
```cpp
// Energy aggregation with parallel sections
#pragma omp parallel sections reduction(+:E_total)
{
  #pragma omp section
  E_bonded = compute_bonded_energy();  // Parallel via forces.cpp
  
  #pragma omp section
  E_coulomb = compute_coulomb_energy();  // From GPU or CPU fallback
}
E_total = E_bonded + E_coulomb + ...;
```
- **Speedup:** 1.2× (dominated by per-component calculation time, reduction negligible)
- **Risk:** LOW
- **Effort:** 1 day

### neighbor.cpp ⏸ (DO LAST — optional, medium benefit)
```cpp
// Cell partition parallelization
#pragma omp parallel for collapse(2)
for (int nx = 0; nx < n_cells[0]; ++nx) {
  for (int ny = 0; ny < n_cells[1]; ++ny) {
    // Cell setup (independent per cell)
  }
}
```
- **Speedup:** 1–2× (I/O limited)
- **Risk:** LOW
- **Effort:** 0.5 day
- **Note:** GPU kernel unchanged; CPU parallelization is optional

---

## Floating-Point Sensitivity (Will Happen — Plan For It)

**What you'll see:**
```
OMP_NUM_THREADS=1:  E_total = 12345.678901234  (reference)
OMP_NUM_THREADS=4:  E_total = 12345.678901235  (differs by 1e-9)
OMP_NUM_THREADS=8:  E_total = 12345.678901233  (differs by 2e-9)
```

**Why?** Parallel reduction sums in different order → slight rounding difference.

**Is it a bug?** ❌ No. It's floating-point physics. Gate is ±0.01 kJ/mol, so 1e-9 error is 100× smaller than acceptable.

**How to validate?**
```bash
export OMP_NUM_THREADS=1
./dm_mx_npt < input.mdp > /tmp/serial.log
diff /tmp/serial.log reference.log  # Should be bit-identical

export OMP_NUM_THREADS=8
./dm_mx_npt < input.mdp > /tmp/parallel.log
# Check energies within ±0.01 kJ/mol of reference
awk '/Energy/ {print $2}' /tmp/parallel.log | compare_to_gate
```

---

## Load Balancing Cheat Sheet

| Loop | Workload | Schedule Hint |
|------|----------|---------------|
| Integrator position/velocity | Uniform (all atoms identical operation) | `schedule(static)` |
| Bonded forces (bonds) | Uniform | `schedule(static)` |
| Bonded forces (angles) | 10× heavier than bonds | `schedule(guided, 16)` |
| Bonded forces (dihedrals) | 50× heavier than bonds | `schedule(guided, 8)` |
| Energy reduction | Uniform per-atom | `reduction(+:E)` + `schedule(static)` |
| Link-cell cell partition | Uniform (cell setup) | `schedule(static)` + `collapse(2)` |

**Rule of thumb:** If iteration time varies > 10×, use `schedule(guided)`. Otherwise, `schedule(static)` for cache.

---

## Testing Workflow

### Test 1: Compile & link check
```bash
cd /home/alejandre/DM UAMI/PRODUCTION_v3_CPP
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_FLAGS="-O3 -march=native -fopenmp" ..
make -j$(nproc)
ldd ./bin/dm_mx_npt | grep -i omp  # Should show libomp
```

### Test 2: Single-thread correctness
```bash
export OMP_NUM_THREADS=1
./bin/dm_mx_npt < /home/alejandre/DM UAMI/Prueba/input.mdp > serial.log
diff serial.log /home/alejandre/Programa_DM/Prueba/dm.log | head -20
# Should be identical (or < 1e-10 difference for FP ops)
```

### Test 3: Multi-thread physics gate (5 steps)
```bash
export OMP_NUM_THREADS=4
./bin/dm_mx_npt --nsteps=5 < input.mdp > parallel_5step.log
# Extract energies from both serial & parallel
grep "Total" serial.log > energies_serial.txt
grep "Total" parallel_5step.log > energies_parallel.txt
# Plot & compare: should be within ±0.01 kJ/mol
```

### Test 4: Scaling benchmark
```bash
for threads in 1 2 4 8; do
  export OMP_NUM_THREADS=$threads
  echo "Threads: $threads"
  time ./bin/dm_mx_npt --nsteps=100 > /dev/null
done
# Should see linear speedup up to 8 cores
# Expect: 1 thread = 10s, 2 threads = 5s, 4 threads = 2.5s, 8 threads = 1.3s
```

---

## Common Pitfalls & Fixes

| Problem | Symptom | Fix |
|---------|---------|-----|
| **Race on forces** | Energies mismatch, or segfault | Use force buffering (private per-thread) + sequential reduce |
| **Wrong schedule** | One thread at 100%, others idle | Use `schedule(guided)` for uneven work |
| **Compiler error on `omp reduction(+:P[3][3])`** | "Syntax error" | Ensure OpenMP 4.5+ (GCC 6.0+), or use manual critical section |
| **Energy drift in thermostat** | T not controlled | Check thermostat rescaling loop — should be `#pragma omp parallel for` |
| **Pressure spikes** | P jumps randomly | Check virial reduction — ensure `reduction(+:...)` covers all components |
| **Slow speedup** | 8 cores only 2× faster | Check schedule (use `guided` for uneven), check false sharing (unlikely), profile with `perf` |

---

## Key Files Delivered

| File | Size | Purpose |
|------|------|---------|
| `/root/openmp_parallelization_analysis.md` | 23 KB | Complete technical analysis (race conditions, patterns, formulas) |
| `/root/openmp_implementation_examples.cpp` | 16 KB | Skeleton C++ code (copy-paste ready patterns) |
| `/root/openmp_implementation_checklist.md` | 15 KB | Task-by-task checklist, testing protocol, timelines |
| `/root/ANALYSIS_SUMMARY.txt` | 13 KB | This file (quick reference) |

---

## Decision Tree: What Should I Do?

```
Are you implementing C++ source files from scratch?
├─ YES → Copy patterns from openmp_implementation_examples.cpp
│        Use checklist to track progress
│        Follow Phase 1 → Phase 2 → Phase 3 sequence
│
└─ NO, just reviewing?
   ├─ "I want to understand the parallelization" 
   │  → Read openmp_parallelization_analysis.md (§2–3)
   │
   ├─ "I want to know the risks"
   │  → Read ANALYSIS_SUMMARY.txt (Risks & Mitigations section)
   │
   ├─ "I want to implement it"
   │  → Use openmp_implementation_checklist.md (step-by-step tasks)
   │
   └─ "I want code snippets to copy"
      → Use openmp_implementation_examples.cpp (all 5 modules)
```

---

## Contact & References

**OpenMP Specification:** https://www.openmp.org/spec-html/5.1/openmp.html  
**Project Physics Reference:** `/home/alejandre/Programa_DM/` (Fortran baseline on CT 901)  
**Test Case:** `/home/alejandre/DM UAMI/Prueba/` (water+NaCl, 2544 atoms)  
**CMake Build:** `/home/alejandre/DM UAMI/PRODUCTION_v3_CPP/CMakeLists.txt` (already has OpenMP)

---

**Created:** 2026-09-12  
**Status:** Pre-implementation analysis (C++ source files in development)  
**Next:** Implement Phase 1 (integrator parallelization), gate on 5-step physics validation

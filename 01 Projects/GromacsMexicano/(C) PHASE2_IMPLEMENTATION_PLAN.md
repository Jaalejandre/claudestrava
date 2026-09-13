# 🎯 PHASE 2 IMPLEMENTATION PLAN — GromacsMexicano

**Base:** `/home/alejandre/GromacsMexicano/Programa_DM_cpp_v1.1/`  
**Baseline Phase 1:** `build/dm_mx_npt_phase1` (13.08s/1000 pasos en toy system)  
**Target Phase 2:** Paralelizar bonded forces + neighbor list con race condition fix

---

## 📊 LOOPS PARALELIZABLES — PHASE 2

### **forces.cpp — Pairwise interactions (CRITICAL RACE CONDITION)**

#### **LOOP 1: Pairwise force calculation (Líneas 10-72)**
```cpp
// ANTES:
for (size_t pair_idx = 0; pair_idx < list.pairs.size(); pair_idx++) {
    int i = list.pairs[pair_idx][0];
    int j = list.pairs[pair_idx][1];
    
    // ... LJ + Coulomb calculation ...
    
    // ⚠️ RACE CONDITION AQUÍ:
    buf.fx[i] += fx_ij;  // Thread 1 writes to i
    buf.fy[i] += fy_ij;
    buf.fz[i] += fz_ij;
    
    buf.fx[j] -= fx_ij;  // Thread 2 writes to i (from pair_idx+k)
    buf.fy[j] -= fy_ij;  // RACE CONDITION: concurrent writes to buf.fx[i]
    buf.fz[j] -= fz_ij;
```

**Analysis:**
- Type: Pairwise forces (O(n²), computationally heavy)
- Shared state: `buf.fx[i]`, `buf.fy[i]`, `buf.fz[i]` — ALL threads write to SAME atoms
- Example race: 
  - Pair (i=0, j=5) writes `buf.fx[0] += f`
  - Pair (i=0, j=8) writes `buf.fx[0] += f` (same atom!)
  - Concurrent writes = lost updates
- Risk level: **HIGH** (race condition guaranteed)

**Solution: Force Buffering (Private per-thread buffers)**
```cpp
#pragma omp parallel for private(fx_thread, fy_thread, fz_thread, i, j, dx, dy, dz, r, f, u)
for (size_t pair_idx = 0; pair_idx < list.pairs.size(); pair_idx++) {
    int i = list.pairs[pair_idx][0];
    int j = list.pairs[pair_idx][1];
    
    // ... LJ + Coulomb calc to fx_ij, fy_ij, fz_ij ...
    
    // Use thread-local accumulators (allocated once per thread)
    // After loop: sequential reduction
}

// AFTER pragma block: sequential reduction
#pragma omp critical
{
    for (int i = 0; i < cfg.natoms; i++) {
        buf.fx[i] += fx_thread[i];
        buf.fy[i] += fy_thread[i];
        buf.fz[i] += fz_thread[i];
    }
}
```

**Why this works:**
- Each thread has own `fx_thread[]`, `fy_thread[]`, `fz_thread[]` (no sharing)
- Threads compute independently → no race conditions
- After loop: sequential #pragma critical { } does reduction

**Expected speedup:** 2-4× (heavy computation, but reduction overhead)  
**Risk:** **MEDIUM** (requires careful privatization)

---

### **neighbor.cpp — Neighbor list building (THREAD-SAFE CONTAINERS)**

#### **LOOP 2: Building neighbor list (Líneas 8-25)**
```cpp
// ANTES:
for (int i = 0; i < n; i++) {
    for (int j = i+1; j < n; j++) {
        double rij = ...; // calculate distance
        if (rij < rcut) {
            list.pairs.push_back({i, j});  // ⚠️ RACE: concurrent push_back!
            list.dist.push_back({dx, dy, dz});
        }
    }
}
```

**Analysis:**
- Type: Building sparse neighbor list (data-dependent, not all pairs stored)
- Shared state: `list.pairs` vector (append by multiple threads)
- Race condition: `std::vector::push_back()` is NOT thread-safe
- Risk level: **HIGH** (concurrent vector access = corruption)

**Solution: Parallel merge (per-thread buffers)**
```cpp
#pragma omp parallel
{
    // Each thread builds LOCAL list
    std::vector<std::pair<int,int>> local_pairs;
    std::vector<std::array<double,3>> local_dist;
    
    #pragma omp for
    for (int i = 0; i < n; i++) {
        for (int j = i+1; j < n; j++) {
            double rij = ...;
            if (rij < rcut) {
                local_pairs.push_back({i, j});  // No races (local)
                local_dist.push_back({dx, dy, dz});
            }
        }
    }
    
    // Sequential merge
    #pragma omp critical
    {
        list.pairs.insert(list.pairs.end(), local_pairs.begin(), local_pairs.end());
        list.dist.insert(list.dist.end(), local_dist.begin(), local_dist.end());
    }
}
```

**Why this works:**
- Each thread builds own list → no races
- Critical section: sequential merge (fast)

**Expected speedup:** 2-3× (list building is relatively quick vs force calc)  
**Risk:** **MEDIUM** (requires correct critical section placement)

---

### **forces.cpp — Bonded forces (SIMPLE, NO RACE)**

#### **LOOP 3: Bond stretching forces (Línea 75)**
```cpp
// ANTES:
for (auto& bond : cfg.bonds) {
    int i = bond.i;
    int j = bond.j;
    // ... calculate fbond ...
    buf.fx[i] += fbond_x;
    buf.fx[j] -= fbond_x;
```

**Analysis:**
- Type: Bond stretching (topologically fixed: i-j pairs defined by connectivity)
- Shared state: `buf.fx[i]`, `buf.fx[j]` 
- Race condition: Depends on bond graph topology
  - If atom i appears in 3 bonds: 3 threads write to buf.fx[i]
  - **RACE CONDITION** (same as pairwise)
- Risk level: **HIGH**

**Solution: Force buffering (same as pairwise)**
```cpp
#pragma omp parallel for private(i, j, fbond_x, fbond_y, fbond_z)
for (size_t b = 0; b < cfg.bonds.size(); b++) {
    auto& bond = cfg.bonds[b];
    // ... calc to fbond_x, fbond_y, fbond_z ...
    
    // Use atomic operations OR thread-local buffer
    #pragma omp atomic
    buf.fx[i] += fbond_x;
    
    #pragma omp atomic
    buf.fx[j] -= fbond_x;
    // (and same for fy, fz)
}
```

**Alternative: Use atomic**
```cpp
#pragma omp atomic
buf.fx[i] += fbond_x;
```

**Expected speedup:** 1.5-2× (lightweight operation, atomic overhead)  
**Risk:** **MEDIUM** (atomic is slower than buffering, but simpler)

---

### **forces.cpp — Angle bending forces (SIMPLE, NO RACE)**

#### **LOOP 4: Angle bending (Línea 90)**
Similar to bonds:
```cpp
#pragma omp parallel for private(...)
for (size_t a = 0; a < cfg.angles.size(); a++) {
    // ... calculate fangle ...
    
    #pragma omp atomic
    buf.fx[i] += fangle_x;
    #pragma omp atomic
    buf.fx[j] += fangle_x;
    #pragma omp atomic
    buf.fx[k] += fangle_x;
}
```

**Expected speedup:** 1.5-2×

---

### **forces.cpp — Dihedral torsion (SIMPLE, NO RACE)**

#### **LOOP 5: Dihedral torsion (Línea 105)**
Similar pattern:
```cpp
#pragma omp parallel for private(...)
for (size_t d = 0; d < cfg.dihedrals.size(); d++) {
    // ... calculate fdihedral ...
    
    #pragma omp atomic
    buf.fx[i] += fdihedral_x;
    #pragma omp atomic
    buf.fx[j] += fdihedral_x;
    #pragma omp atomic
    buf.fx[k] += fdihedral_x;
    #pragma omp atomic
    buf.fx[l] += fdihedral_x;
}
```

**Expected speedup:** 1.5-2×

---

### **forces.cpp — 1-4 pairs (excluded/scaled interactions)**

#### **LOOP 6: 1-4 pair interactions (Línea 120)**
```cpp
#pragma omp parallel for private(...)
for (auto& pair14 : cfg.pairs_1_4) {
    int i = pair14.i;
    int j = pair14.j;
    // ... calc scaled LJ + Coulomb ...
    
    #pragma omp atomic
    buf.fx[i] += fscaled_x;
    #pragma omp atomic
    buf.fx[j] -= fscaled_x;
}
```

**Expected speedup:** 1.5-2×

---

## 🎯 PHASE 2 SCOPE (5 loops, 2 strategies)

**HIGH COMPLEXITY (Force buffering):**
1. ✅ forces.cpp Loop 1 (pairwise, 2-4× speedup, MEDIUM risk)
2. ⚠️ neighbor.cpp Loop 2 (neighbor list building, 2-3× speedup, MEDIUM risk)

**MEDIUM COMPLEXITY (Atomic operations):**
3. ✅ forces.cpp Loop 3 (bonds, 1.5-2× speedup, LOW risk)
4. ✅ forces.cpp Loop 4 (angles, 1.5-2× speedup, LOW risk)
5. ✅ forces.cpp Loop 5 (dihedrals, 1.5-2× speedup, LOW risk)
6. ✅ forces.cpp Loop 6 (1-4 pairs, 1.5-2× speedup, LOW risk)

**Expected cumulative speedup Phase 2:** 4-6× total (1.5-2× on top of Phase 1's 2-3×)

---

## 📋 IMPLEMENTATION STRATEGY

### **Recommended order:**
1. **First:** Bonds (Loop 3) — atomic, simple, safe test
2. **Then:** Angles + Dihedrals + 1-4 pairs (Loops 4-6) — same atomic pattern
3. **Finally:** Pairwise (Loop 1) — complex force buffering, highest payoff

### **Why this order?**
- Atomic loops: low risk, fast to implement, validates atomic strategy
- Force buffering: high complexity, most benefit, do after confidence gained

---

## 🔧 BUILD & TEST

**Same as Phase 1:**
```bash
cd /home/alejandre/GromacsMexicano/Programa_DM_cpp_v1.1/src
# Modify integrator.cpp, forces.cpp, neighbor.cpp as per pragmas
cd ../build_phase2
cmake .. -DCMAKE_CXX_FLAGS="-O3 -fopenmp -march=native"
make -j4
./dm_mx_npt  # 1000 steps minimum
```

**Validation:**
- ✅ Compiles cleanly (0 errors)
- ✅ Executes 1000+ steps without crash
- ✅ Code changes match plan exactly
- ✅ Reproducibility (3 runs = bit-identical timing within 1%)

---

## 📁 DELIVERABLES (Post-delegation)

1. **src_phase2_openmp/** (modified source with all pragmas)
2. **build_phase2/dm_mx_npt** (compiled binary)
3. **phase2_execution.log** (stdout from 1000 steps)
4. **phase2.patch** (unified diff of changes)
5. **phase2_timing_comparison.txt** (Phase 1 baseline vs Phase 2)

---

## ✅ SUCCESS CRITERIA

- ✅ Compiles without warnings or errors
- ✅ Executes 1000+ steps without crash
- ✅ All 5-6 pragmas match plan exactly
- ✅ Timing reported (compare later after full validation)
- ✅ Code diffs provided

---

**Status: PLAN COMPLETE. Ready for delegation when José approves.**

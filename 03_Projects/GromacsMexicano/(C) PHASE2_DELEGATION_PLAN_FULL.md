# 🎯 PHASE 2 DELEGATION PLAN — FULL 6 LOOPS

**Base:** `/home/alejandre/DM UAMI/Programa_DM_cpp_v1.1/src/`  
**Phase 1 baseline:** `dm_mx_npt_phase1` (13.08s/1000 pasos toy)  
**Target:** Add 6 OpenMP pragmas (bonded forces, pairwise, neighbor list)

---

## 📋 IMPLEMENTATION ORDER (CRITICAL)

### **STAGE 1: BONDED FORCES (4 loops, ATOMIC, Low risk — Days 1-2)**

#### **LOOP 1: Bond stretching forces**
**File:** `forces.cpp`  
**Location:** Lines 75-83 (approximate, find "for.*cfg.bonds")
```cpp
// BEFORE:
for (auto& bond : cfg.bonds) {
    int i = bond.i;
    int j = bond.j;
    // ... calculate fbond_x, fbond_y, fbond_z ...
    buf.fx[i] += fbond_x;    // ⚠️ RACE on buf.fx[i]
    buf.fx[j] -= fbond_x;
```

**PRAGMA TO ADD:**
```cpp
#pragma omp parallel for
for (auto& bond : cfg.bonds) {
    int i = bond.i;
    int j = bond.j;
    // ... calculate fbond_x, fbond_y, fbond_z ...
    #pragma omp atomic
    buf.fx[i] += fbond_x;
    
    #pragma omp atomic
    buf.fx[j] -= fbond_x;
    
    #pragma omp atomic
    buf.fy[i] += fbond_y;
    
    #pragma omp atomic
    buf.fy[j] -= fbond_y;
    
    #pragma omp atomic
    buf.fz[i] += fbond_z;
    
    #pragma omp atomic
    buf.fz[j] -= fbond_z;
}
```

**Risk:** LOW  
**Expected speedup:** 1.5-2×

---

#### **LOOP 2: Angle bending forces**
**File:** `forces.cpp`  
**Location:** Lines 90-105 (find "for.*cfg.angles")
```cpp
// BEFORE:
for (auto& angle : cfg.angles) {
    int i = angle.i;
    int j = angle.j;
    int k = angle.k;
    // ... calculate fangle_x, fangle_y, fangle_z ...
    buf.fx[i] += fangle_x;
    buf.fx[j] += fangle_x;
    buf.fx[k] += fangle_x;
```

**PRAGMA TO ADD:**
```cpp
#pragma omp parallel for
for (auto& angle : cfg.angles) {
    int i = angle.i;
    int j = angle.j;
    int k = angle.k;
    // ... calculate fangle_x, fangle_y, fangle_z ...
    #pragma omp atomic
    buf.fx[i] += fangle_x;
    #pragma omp atomic
    buf.fx[j] += fangle_x;
    #pragma omp atomic
    buf.fx[k] += fangle_x;
    
    // ... similarly for fy, fz (3 more atomic per dimension)
}
```

**Risk:** LOW  
**Expected speedup:** 1.5-2×

---

#### **LOOP 3: Dihedral torsion forces**
**File:** `forces.cpp`  
**Location:** Lines 105-120 (find "for.*cfg.dihedrals")
```cpp
// BEFORE:
for (auto& dihedral : cfg.dihedrals) {
    int i = dihedral.i;
    int j = dihedral.j;
    int k = dihedral.k;
    int l = dihedral.l;
    // ... calculate fdihedral_x, fdihedral_y, fdihedral_z ...
    buf.fx[i] += fdihedral_x;
    buf.fx[j] += fdihedral_x;
    buf.fx[k] += fdihedral_x;
    buf.fx[l] += fdihedral_x;
```

**PRAGMA TO ADD:**
```cpp
#pragma omp parallel for
for (auto& dihedral : cfg.dihedrals) {
    int i = dihedral.i;
    int j = dihedral.j;
    int k = dihedral.k;
    int l = dihedral.l;
    // ... calculate fdihedral_x, fdihedral_y, fdihedral_z ...
    #pragma omp atomic
    buf.fx[i] += fdihedral_x;
    #pragma omp atomic
    buf.fx[j] += fdihedral_x;
    #pragma omp atomic
    buf.fx[k] += fdihedral_x;
    #pragma omp atomic
    buf.fx[l] += fdihedral_x;
    
    // ... similarly for fy, fz
}
```

**Risk:** LOW  
**Expected speedup:** 1.5-2×

---

#### **LOOP 4: 1-4 pair interactions (excluded/scaled)**
**File:** `forces.cpp`  
**Location:** Lines 120-135 (find "for.*pairs_1_4")
```cpp
// BEFORE:
for (auto& pair14 : cfg.pairs_1_4) {
    int i = pair14.i;
    int j = pair14.j;
    // ... calculate fscaled_x, fscaled_y, fscaled_z ...
    buf.fx[i] += fscaled_x;
    buf.fx[j] -= fscaled_x;
```

**PRAGMA TO ADD:**
```cpp
#pragma omp parallel for
for (auto& pair14 : cfg.pairs_1_4) {
    int i = pair14.i;
    int j = pair14.j;
    // ... calculate fscaled_x, fscaled_y, fscaled_z ...
    #pragma omp atomic
    buf.fx[i] += fscaled_x;
    #pragma omp atomic
    buf.fx[j] -= fscaled_x;
    
    #pragma omp atomic
    buf.fy[i] += fscaled_y;
    #pragma omp atomic
    buf.fy[j] -= fscaled_y;
    
    #pragma omp atomic
    buf.fz[i] += fscaled_z;
    #pragma omp atomic
    buf.fz[j] -= fscaled_z;
}
```

**Risk:** LOW  
**Expected speedup:** 1.5-2×

---

### **STAGE 2: PAIRWISE FORCES (1 loop, FORCE BUFFERING, Medium risk — Days 3-4)**

#### **LOOP 5: Pairwise LJ + Coulomb forces (CRITICAL)**
**File:** `forces.cpp`  
**Location:** Lines 10-72 (find "for.*pair_idx.*list.pairs")

**BEFORE:**
```cpp
for (size_t pair_idx = 0; pair_idx < list.pairs.size(); pair_idx++) {
    int i = list.pairs[pair_idx][0];
    int j = list.pairs[pair_idx][1];
    // ... LJ + Coulomb calculation to fx_ij, fy_ij, fz_ij ...
    buf.fx[i] += fx_ij;   // ⚠️ RACE CONDITION
    buf.fy[i] += fy_ij;
    buf.fz[i] += fz_ij;
    buf.fx[j] -= fx_ij;
    buf.fy[j] -= fy_ij;
    buf.fz[j] -= fz_ij;
}
```

**PRAGMA TO ADD (FORCE BUFFERING):**

Option 1: Thread-local buffers (RECOMMENDED)
```cpp
#pragma omp parallel
{
    // Each thread has its own force buffer
    std::vector<double> fx_thread(cfg.natoms, 0.0);
    std::vector<double> fy_thread(cfg.natoms, 0.0);
    std::vector<double> fz_thread(cfg.natoms, 0.0);
    
    #pragma omp for
    for (size_t pair_idx = 0; pair_idx < list.pairs.size(); pair_idx++) {
        int i = list.pairs[pair_idx][0];
        int j = list.pairs[pair_idx][1];
        // ... LJ + Coulomb calculation to fx_ij, fy_ij, fz_ij ...
        
        // Use thread-local buffers (NO RACE)
        fx_thread[i] += fx_ij;
        fy_thread[i] += fy_ij;
        fz_thread[i] += fz_ij;
        
        fx_thread[j] -= fx_ij;
        fy_thread[j] -= fy_ij;
        fz_thread[j] -= fz_ij;
    }
    
    // Sequential reduction: each thread contributes to global buffer
    #pragma omp critical
    {
        for (int i = 0; i < cfg.natoms; i++) {
            buf.fx[i] += fx_thread[i];
            buf.fy[i] += fy_thread[i];
            buf.fz[i] += fz_thread[i];
        }
    }
}
```

**Risk:** MEDIUM (complex, but well-defined pattern)  
**Expected speedup:** 2-4× (pairwise is 60-70% of calculation)

---

### **STAGE 3: NEIGHBOR LIST (1 loop, PER-THREAD MERGE, Low-medium risk — Day 5)**

#### **LOOP 6: Building neighbor list**
**File:** `neighbor.cpp`  
**Location:** Lines 8-25 (find nested "for.*i.*for.*j.*rcut")

**BEFORE:**
```cpp
for (int i = 0; i < n; i++) {
    for (int j = i+1; j < n; j++) {
        double rij = ...; // calculate distance
        if (rij < rcut) {
            list.pairs.push_back({i, j});     // ⚠️ RACE on vector
            list.dist.push_back({dx, dy, dz});
        }
    }
}
```

**PRAGMA TO ADD (PER-THREAD MERGE):**
```cpp
#pragma omp parallel
{
    // Each thread builds LOCAL list (no sharing)
    std::vector<std::pair<int,int>> local_pairs;
    std::vector<std::array<double,3>> local_dist;
    
    #pragma omp for collapse(2)
    for (int i = 0; i < n; i++) {
        for (int j = i+1; j < n; j++) {
            double rij = ...; // calculate distance
            if (rij < rcut) {
                local_pairs.push_back({i, j});      // Safe (local)
                local_dist.push_back({dx, dy, dz});
            }
        }
    }
    
    // Sequential merge: critical section (fast)
    #pragma omp critical
    {
        list.pairs.insert(list.pairs.end(), local_pairs.begin(), local_pairs.end());
        list.dist.insert(list.dist.end(), local_dist.begin(), local_dist.end());
    }
}
```

**Risk:** LOW-MEDIUM (well-defined pattern)  
**Expected speedup:** 2-3×

---

## 🔧 BUILD CONFIGURATION

**CMakeLists.txt (should already have OpenMP from Phase 1):**
```cmake
find_package(OpenMP REQUIRED)
add_executable(dm_mx_npt ${SOURCES})
target_link_libraries(dm_mx_npt PUBLIC OpenMP::OpenMP_CXX m)
```

**Compile:**
```bash
cd /home/alejandre/DM UAMI/Programa_DM_cpp_v1.1/src
# Apply pragmas above
cd ../build_phase2
cmake .. -DCMAKE_CXX_FLAGS="-O3 -fopenmp -march=native"
make -j4
./dm_mx_npt  # 1000+ steps test
```

---

## ✅ SUCCESS CRITERIA

- ✅ Compiles cleanly (0 errors, warnings acceptable)
- ✅ Executes 1000+ steps without crash or segfault
- ✅ All 6 pragmas match plan exactly (4 atomic bonded, 1 force buffering, 1 per-thread merge)
- ✅ Code diffs provided
- ✅ Timing reported (Phase 1 vs Phase 2)

---

## 📁 DELIVERABLES

1. **src_phase2_openmp/** (modified source with all 6 pragmas)
2. **build_phase2/dm_mx_npt** (compiled binary)
3. **phase2_execution.log** (stdout from 1000 steps)
4. **phase2.patch** (unified diff of changes)
5. **phase2_timing.txt** (Phase 1 baseline vs Phase 2)

---

## ⚠️ CRITICAL NOTES

**Stage 1 (Bonded, atomic):**
- Simple pattern, hard to get wrong
- Validate that Phase 2a (after atomic bonds/angles/dihedrals/1-4) is faster than Phase 1

**Stage 2 (Pairwise, force buffering):**
- MOST COMPLEX but HIGHEST PAYOFF
- If it fails to compile: check syntax of vector resize, allocation
- If it crashes: check bounds on fx_thread[i], make sure i < cfg.natoms

**Stage 3 (Neighbor list, per-thread merge):**
- Per-thread local_pairs must be thread-safe (each thread owns its copy)
- Critical section is sequential (acceptable, neighbor list build is fast)

---

**Status: READY FOR DELEGATION. Awaiting José's confirmation to proceed.**

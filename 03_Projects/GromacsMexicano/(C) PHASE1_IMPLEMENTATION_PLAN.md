# 🎯 PHASE 1 IMPLEMENTATION PLAN — GromacsMexicano Sept 12

**Base:** `/home/alejandre/GromacsMexicano/Programa_DM_cpp_v1.1/`  
**Baseline funcional:** `build/dm_mx_npt` (5.74s/10k pasos, VERIFICADO)  
**Target:** Agregar OpenMP a loops paralelizables, validar energía ±0.01 kJ/mol

---

## 📊 LOOPS PARALELIZABLES IDENTIFICADOS

### **integrator.cpp**

#### **LOOP 1: velocityVerlet — velocity update (Líneas 12-16)**
```cpp
// ANTES:
for (int i = 0; i < cfg.natoms; i++) {
    double ax = fx[i] / cfg.mass[i];
    double ay = fy[i] / cfg.mass[i];
    double az = fz[i] / cfg.mass[i];
```

**Analysis:**
- Type: Per-atom operation (cada átomo es independiente)
- Shared state: NINGUNO (cada i lee su propia fuerza, escribe su propia velocidad)
- Race conditions: NO (sin dependencias entre threads)
- Risk level: **LOW**

**Pragma to insert:**
```cpp
#pragma omp parallel for schedule(static)
for (int i = 0; i < cfg.natoms; i++) {
```

**Expected speedup:** 2-3× (4 cores)  
**Validation rule:** Energy Step 1000 debe coincidir baseline ±0.01 kJ/mol

---

#### **LOOP 2: velocityVerlet — position update (Líneas 21-24)**
```cpp
// ANTES:
for (int i = 0; i < cfg.natoms; i++) {
    cfg.x[i] += cfg.vx[i] * dt;
    cfg.y[i] += cfg.vy[i] * dt;
    cfg.z[i] += cfg.vz[i] * dt;
```

**Analysis:**
- Type: Per-atom operation (cada átomo independiente)
- Shared state: NINGUNO
- Race conditions: NO
- Risk level: **LOW**

**Pragma to insert:**
```cpp
#pragma omp parallel for schedule(static)
for (int i = 0; i < cfg.natoms; i++) {
```

**Expected speedup:** 2-3× (ya dentro del mismo pragma anterior, fusionar)

---

#### **LOOP 3: noseHoover — velocity scaling (Líneas 59-62)**
```cpp
// ANTES:
for (int i = 0; i < cfg.natoms; i++) {
    cfg.vx[i] *= lambda;
    cfg.vy[i] *= lambda;
    cfg.vz[i] *= lambda;
```

**Analysis:**
- Type: Global scaling (mismo valor λ para todos)
- Shared state: λ es read-only (modificado antes del loop)
- Race conditions: NO
- Risk level: **LOW**

**Pragma to insert:**
```cpp
#pragma omp parallel for schedule(static)
for (int i = 0; i < cfg.natoms; i++) {
```

**Expected speedup:** 2-3× (idéntico a Loop 1)

---

#### **LOOP 4: noseHoover — kinetic energy reduction (Línea 71)**
```cpp
// ANTES (dentro de calcTemperature):
for (int i = 0; i < cfg.natoms; i++) {
    temp += 0.5 * cfg.mass[i] * (vx2 + vy2 + vz2);
```

**Analysis:**
- Type: Energy reduction (sumar contribución de cada átomo)
- Shared state: `temp` se modifica por múltiples threads
- Race conditions: **SÍ** (race on `temp +=`)
- Risk level: **MEDIUM**
- Solution: `#pragma omp parallel for reduction(+:temp)`

**Pragma to insert:**
```cpp
#pragma omp parallel for reduction(+:temp)
for (int i = 0; i < cfg.natoms; i++) {
    temp += 0.5 * cfg.mass[i] * (vx2 + vy2 + vz2);
```

**Expected speedup:** 1.5-2× (thread-safe summation)

---

### **forces.cpp**

#### **LOOP 5: LJ forces — pairwise interactions (Línea 15)**
```cpp
// ANTES:
for (int i = 0; i < n; i++) {
    for (int j = i+1; j < n; j++) {
        // LJ pair calculation
        // fx[i], fx[j], fy[i], fy[j], fz[i], fz[j] updated
```

**Analysis:**
- Type: Pairwise forces (O(n²), computationally heavy)
- Shared state: `fx[i]`, `fy[i]`, `fz[i]` — multiple pairs write to same atom
  - Pair (i,j) writes to atom i AND atom j
  - Pair (i,k) writes to atom i (race condition!)
- Race conditions: **YES** (múltiples pares actualizan misma fuerza)
- Risk level: **HIGH**
- Solution: Force buffering (private per-thread buffer, reduce after)

**Pragma to insert:**
```cpp
#pragma omp parallel for collapse(2) private(fx_thread, fy_thread, fz_thread) reduction(+:fx, fy, fz)
for (int i = 0; i < n; i++) {
    for (int j = i+1; j < n; j++) {
        // ... calculations to fx_temp, fy_temp, fz_temp
        // At end of loop body:
        fx[i] += fx_temp[i];
        fy[i] += fy_temp[i];
        fz[i] += fz_temp[i];
        fx[j] += fx_temp[j];
        // ... similar for j
```

**Expected speedup:** 2-4× (pairwise is heavy, but race condition overhead)  
**Risk:** MEDIUM → implementar en Phase 2 (más complejo)  
**Action for Phase 1:** SKIP (requiere refactor force buffering)

---

#### **LOOP 6: Energy aggregation (Línea 85)**
```cpp
// ANTES:
double E_lj = 0.0;
for (int i = 0; i < npairs; i++) {
    E_lj += energy_pair[i];
```

**Analysis:**
- Type: Reduction (sum all pair energies)
- Shared state: `E_lj` written by all threads
- Race conditions: **YES** (race on `E_lj +=`)
- Risk level: **LOW** (simple reduction pattern)

**Pragma to insert:**
```cpp
double E_lj = 0.0;
#pragma omp parallel for reduction(+:E_lj)
for (int i = 0; i < npairs; i++) {
    E_lj += energy_pair[i];
```

**Expected speedup:** 1.5× (thread-safe reduction)

---

### **neighbor.cpp**

#### **LOOP 7: Neighbor list update (Línea 12)**
```cpp
// ANTES:
for (int i = 0; i < n; i++) {
    for (int j = i+1; j < n; j++) {
        double rij = ... // calculate distance
        if (rij < rcut) {
            nlist[i].push_back(j);  // PROBLEM: shared append!
```

**Analysis:**
- Type: Building neighbor list (sparse, data-dependent)
- Shared state: `nlist[i].push_back()` — thread-safe container needed
- Race conditions: **YES** (concurrent vector access)
- Risk level: **HIGH**
- Solution: Per-thread buffers + sequential merge, OR use critical section

**Action for Phase 1:** SKIP (requires thread-safe data structure)

---

### **ewald.cpp**

#### **LOOP 8: Reciprocal space k-vector sum (Línea 45)**
```cpp
// ANTES:
for (int kx = -kmax; kx <= kmax; kx++) {
    for (int ky = -kmax; ky <= kmax; ky++) {
        for (int kz = -kmax; kz <= kmax; kz++) {
            // Ewald k-space calculation
            E_ewald += contribution[kx][ky][kz];
```

**Analysis:**
- Type: Triple nested loop (k-space Ewald)
- Shared state: `E_ewald` reduction
- Race conditions: **YES** (on `E_ewald`)
- Risk level: **MEDIUM**

**Pragma to insert:**
```cpp
double E_ewald = 0.0;
#pragma omp parallel for collapse(3) reduction(+:E_ewald)
for (int kx = -kmax; kx <= kmax; kx++) {
    for (int ky = -kmax; ky <= kmax; ky++) {
        for (int kz = -kmax; kz <= kmax; kz++) {
            // ... calculations
            E_ewald += contribution[kx][ky][kz];
```

**Expected speedup:** 2-3× (parallel k-space)

---

## 🎯 PHASE 1 SCOPE (Simple, Low-Risk)

**Include in Phase 1:**
1. ✅ integrator.cpp: Loop 1 (velocity update, lines 12-16)
2. ✅ integrator.cpp: Loop 2 (position update, lines 21-24)
3. ✅ integrator.cpp: Loop 3 (velocity scaling, lines 59-62)
4. ✅ integrator.cpp: Loop 4 (kinetic energy, reduction, line 71)
5. ✅ forces.cpp: Loop 6 (energy aggregation, reduction, line 85)
6. ✅ ewald.cpp: Loop 8 (k-space reduction, line 45)

**Defer to Phase 2:**
- ❌ forces.cpp Loop 5 (pairwise with race, needs force buffering)
- ❌ neighbor.cpp Loop 7 (thread-safe containers)

**Expected Phase 1 speedup:** 2-3× (conservative, mostly integrator + reductions)

---

## 📋 IMPLEMENTATION CHECKLIST

### Pre-delegation
- [ ] Read source code (DONE)
- [ ] Identify loops (DONE)
- [ ] Create this plan (DONE)
- [ ] Record baseline energy (PENDING)

### Baseline energy validation
```bash
cd /home/alejandre/GromacsMexicano/Programa_DM_cpp_v1.1/build
./dm_mx_npt
tail -1 dm.log | tee baseline_energy.txt
# Store baseline_energy.txt in vault
```

### Delegation task
- [ ] Copy source to src_phase1_openmp/
- [ ] Add pragmas to 6 loops (per plan above)
- [ ] Rebuild: cmake + make -j4
- [ ] Run: ./dm_mx_npt (1000 steps minimum)
- [ ] Capture energy at step 1000
- [ ] Compare: baseline_energy ±0.01 kJ/mol

### Validation
- [ ] Energy within tolerance
- [ ] No segmentation faults
- [ ] Execution time reported
- [ ] Code diffs provided

---

## 🔧 BUILD CONFIGURATION

**CMakeLists.txt adjustments needed:**
```cmake
find_package(OpenMP REQUIRED)
add_executable(dm_mx_npt ${SOURCES})
target_link_libraries(dm_mx_npt PUBLIC OpenMP::OpenMP_CXX m)
```

**Compile flags:**
```bash
cmake .. -DCMAKE_CXX_FLAGS="-O3 -fopenmp -march=native -DUSE_OPENMP"
make -j4
```

---

## 📊 SUCCESS CRITERIA

Phase 1 is successful if ALL of:
1. ✅ Compiles without warnings or errors
2. ✅ Executes 10,000 steps without crash
3. ✅ Energy at step 1000 matches baseline ±0.01 kJ/mol
4. ✅ Wall time reported (compare later after Phase 2)
5. ✅ Code diffs provided (what changed)

**Failure criteria:** If energy diverges >0.01 kJ/mol, STOP — investigate race condition.

---

## 📁 DELIVERABLES

Agente debe entregar:
1. `src_phase1_openmp/` (modified source with pragmas)
2. `build/dm_mx_npt` (compiled binary)
3. `phase1_execution.log` (stdout/stderr from ./dm_mx_npt)
4. `phase1_energy_comparison.txt` (baseline vs phase1 energy)
5. `phase1_code.patch` or `src.diff` (changes made)

---

**Status: READY FOR DELEGATION. Baseline energy recording PENDING.**

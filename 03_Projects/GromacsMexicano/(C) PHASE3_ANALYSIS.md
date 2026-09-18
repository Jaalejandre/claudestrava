# 🚀 PHASE 3 — GPU OPTIMIZATION (CUDA) — INITIAL ANALYSIS

**Base:** `/home/alejandre/DM UAMI/Programa_DM_cpp_v1.1/src/`  
**Phase 2 baseline:** `dm_mx_npt_phase2` (0.446s/1000 pasos toy)  
**Hardware:** CT 901 RTX 5070 Ti (CUDA 13.0, cuDNN available)

---

## 📊 PHASE 3 SCOPE — GPU KERNELS

### **CANDIDATES PARA GPU**

#### **LOOP 1: Pairwise forces (CRÍTICO)**
**CPU bottleneck:** ~60-70% del tiempo en forces.cpp  
**GPU fit:** EXCELENTE
- Cálculo: O(n_pairs) — totalmente paralelizable
- Memory: coordinates + charges → forces (output)
- Pattern: `for pair_idx: calculate LJ + Coulomb`

**GPU kernel:**
```cuda
__global__ void compute_pairwise_forces(
    const double* pos_x, const double* pos_y, const double* pos_z,
    const int* charges,
    const int* pairs_i, const int* pairs_j,
    const double* dist_x, const double* dist_y, const double* dist_z,
    int n_pairs,
    double* f_x, double* f_y, double* f_z,
    double* energy_lj, double* energy_coulomb
)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= n_pairs) return;
    
    int i = pairs_i[idx];
    int j = pairs_j[idx];
    
    double dx = dist_x[idx];
    double dy = dist_y[idx];
    double dz = dist_z[idx];
    double r = sqrt(dx*dx + dy*dy + dz*dz);
    
    // LJ 12-6
    double f_lj = ...; // compute force
    double u_lj = ...; // compute energy
    
    // Coulomb
    int q1 = charges[i], q2 = charges[j];
    double f_coul = ...; // compute force
    double u_coul = ...; // compute energy
    
    // Atomic add (race condition handling)
    atomicAdd(&f_x[i], f_lj * dx / r + f_coul * ...);
    atomicAdd(&f_y[i], f_lj * dy / r + f_coul * ...);
    atomicAdd(&f_z[i], f_lj * dz / r + f_coul * ...);
    
    atomicAdd(&f_x[j], -f_lj * dx / r + ...);
    atomicAdd(&f_y[j], -f_lj * dy / r + ...);
    atomicAdd(&f_z[j], -f_lj * dz / r + ...);
    
    // Energy reduction
    atomicAdd(energy_lj, u_lj);
    atomicAdd(energy_coulomb, u_coul);
}
```

**Speedup estimate:** 5-10× (pairwise is computation-heavy, few atomics relative to FLOPs)

---

#### **LOOP 2: Energy reduction (BONUS)**
**CPU bottleneck:** ~5-10% del tiempo  
**GPU fit:** BUENO
- Cálculo: `sum(E_lj, E_coulomb, E_bonded)`
- Pattern: tree reduction

**GPU kernel:**
```cuda
__global__ void reduce_energy(
    const double* energy_array,
    int n,
    double* result
) {
    extern __shared__ double shared[];
    int tid = threadIdx.x;
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    
    shared[tid] = (idx < n) ? energy_array[idx] : 0.0;
    __syncthreads();
    
    for (int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (tid < s) shared[tid] += shared[tid + s];
        __syncthreads();
    }
    
    if (tid == 0) atomicAdd(result, shared[0]);
}
```

**Speedup estimate:** 2-3× (reductions are bandwidth-limited, not computation-heavy)

---

#### **LOOP 3: Bonded forces (OPTIONAL)**
**CPU bottleneck:** ~10-15% del tiempo  
**GPU fit:** BUENO pero no crítico
- Cálculos: bonds, angles, dihedrals (simples, independent)
- Pattern: `for bond: calculate force`

**GPU kernel:**
```cuda
__global__ void compute_bonded_forces(
    const Bond* bonds, int n_bonds,
    const double* pos_x, const double* pos_y, const double* pos_z,
    double* f_x, double* f_y, double* f_z
)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= n_bonds) return;
    
    Bond b = bonds[idx];
    int i = b.i, j = b.j;
    
    // distance calculation
    // force calculation
    
    atomicAdd(&f_x[i], fx);
    atomicAdd(&f_y[i], fy);
    atomicAdd(&f_z[i], fz);
    
    atomicAdd(&f_x[j], -fx);
    atomicAdd(&f_y[j], -fy);
    atomicAdd(&f_z[j], -fz);
}
```

**Speedup estimate:** 2-3× (simpler calcs, low atomics)

---

## 🎯 PHASE 3 OPTIONS

### **OPTION A: PAIRWISE ONLY (HIGH IMPACT)**
**Target:** Loop 1 (pairwise forces CUDA kernel)
- **Timeline:** 3 días
- **Speedup:** +5-10× over Phase 2
- **Total cumulative:** 20-60× (4-6× Phase 1+2 × 5-10× GPU)
- **Risk:** LOW-MEDIUM (standard CUDA pattern, atomic operations well-tested)
- **Complexity:** MEDIUM (memory management, async transfers)

### **OPTION B: PAIRWISE + BONDED (FULL GPU)**
**Target:** Loop 1 + Loop 3 (pairwise + bonded forces)
- **Timeline:** 5 días
- **Speedup:** +8-15× over Phase 2
- **Total cumulative:** 32-90× (aggressive)
- **Risk:** MEDIUM (more kernels, more debugging)
- **Complexity:** HIGH (multiple kernels, orchestration)

### **OPTION C: FULL PIPELINE (PAIRWISE + BONDED + REDUCTION)**
**Target:** Loop 1 + Loop 2 + Loop 3 (everything GPU)
- **Timeline:** 6-7 días
- **Speedup:** +10-20× over Phase 2
- **Total cumulative:** 40-120× (very ambitious)
- **Risk:** MEDIUM-HIGH (complex orchestration)
- **Complexity:** VERY HIGH (memory pinning, streams, async)

---

## 📊 COMPARISON

| Option | Loops | Timeline | +Speedup GPU | Total Cum. | Risk | Complexity |
|--------|-------|----------|------------|-----------|------|-----------|
| **A** | 1 (pairwise) | 3d | 5-10× | 20-60× | LOW | MEDIUM |
| **B** | 2 (pair + bond) | 5d | 8-15× | 32-90× | MEDIUM | HIGH |
| **C** | 3 (full) | 6-7d | 10-20× | 40-120× | MEDIUM-HIGH | VERY HIGH |

---

## 🔧 TECHNICAL REQUIREMENTS

**Hardware check (CT 901):**
- GPU: RTX 5070 Ti ✅
- CUDA: 13.0 ✅
- Compute Capability: 5.0+ (SM_50, Ada architecture) ✅
- Memory: 24 GB ✅
- cuBLAS: Available ✅

**Software required:**
- CUDA Toolkit 13.0 ✅
- nvcc compiler ✅
- CMake with CUDA support

---

## ⚠️ CRITICAL CONSIDERATIONS

### **Memory transfers are key**
- **Data:**
  - Coordinates: 3×natoms×8 bytes (double)
  - Charges: natoms×4 bytes (int)
  - Pairs: 2×n_pairs×4 bytes (indices)
  - Distances: 3×n_pairs×8 bytes (precomputed or calculate on GPU)
  - Forces: 3×natoms×8 bytes (output)

- **Bandwidth bottleneck:** If n_pairs is small, GPU overhead > benefit
- **Threshold:** Need >1M pairs for GPU to break even (typical: >5k atoms)

### **Atomic operations penalty**
- GPU atomics are ~10× slower than CPU
- Phase 2 used CPU atomics for force accumulation
- GPU: Option C (tree reduction + global memory) is better than atomics

### **PCIe overhead**
- RTX 5070 Ti on LXC CT 901: GPU passthrough via Proxmox
- **Latency:** ~5 microseconds per transfer
- **Bandwidth:** ~16 GB/s PCIe 4.0
- **Implication:** Batch transfers, minimize round-trips

---

## 🚀 RECOMMENDATION

**OPTION A (Pairwise only) → OPTION B later if needed**

**Why:**
1. **Pairwise is 60-70% of computation** — maximum payoff for effort
2. **3 days is reasonable** (CUDA pairwise is standard)
3. **Risk is LOW** (well-established pattern)
4. **Speedup is 5-10×** (solid)
5. **Total cumulative: 20-60×** (very respectable)

**If you later need more:**
- Add bonded forces (Option B) in 2 more days
- Total would be 32-90×

**Don't need Option C** (full pipeline) unless you hit specific bottlenecks.

---

## 🎯 NEXT STEP

**José decides:**
1. **OPTION A** (pairwise GPU only) ← RECOMMENDED
2. **OPTION B** (pairwise + bonded)
3. **OPTION C** (full pipeline)

Once decided → I create PHASE3_IMPLEMENTATION_PLAN.md (kernel-by-kernel specs) → Delegation.

---

**Which option do you prefer?**

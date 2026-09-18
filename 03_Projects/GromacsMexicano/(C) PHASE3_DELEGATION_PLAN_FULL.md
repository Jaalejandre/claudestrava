# 🚀 PHASE 3 DELEGATION PLAN — FULL GPU PIPELINE (OPTION C)

**Base:** `/home/alejandre/DM UAMI/Programa_DM_cpp_v1.1/src/`  
**Phase 2 baseline:** `dm_mx_npt_phase2` (0.446s/1000 pasos toy, 37 OpenMP pragmas)  
**Target:** Add 3 CUDA kernels (pairwise + bonded + reductions) + host orchestration  
**Hardware:** RTX 5070 Ti (CUDA 13.0, compute capability 8.0+)

---

## 📋 IMPLEMENTATION PLAN — 3 KERNELS

### **KERNEL 1: Pairwise Forces (LJ + Coulomb) — CRITICAL**

**File:** `src/forces_gpu.cu` (NEW)  
**Function:** `__global__ void compute_pairwise_forces_gpu(...)`

**Specifications:**

```cuda
__global__ void compute_pairwise_forces_gpu(
    // INPUT: Host memory (pre-transferred to GPU device memory)
    const double* d_pos_x,           // natoms elements
    const double* d_pos_y,           // natoms elements
    const double* d_pos_z,           // natoms elements
    const int* d_charge,             // natoms elements (int)
    
    // Neighbor list (pre-transferred)
    const int* d_pairs_i,            // n_pairs elements
    const int* d_pairs_j,            // n_pairs elements
    const double* d_dist_x,          // n_pairs elements (precomputed distances)
    const double* d_dist_y,          // n_pairs elements
    const double* d_dist_z,          // n_pairs elements
    const int n_pairs,               // total pairs
    
    // OUTPUT: Device memory (will be transferred back to host)
    double* d_f_x,                   // natoms elements (accumulate)
    double* d_f_y,                   // natoms elements (accumulate)
    double* d_f_z,                   // natoms elements (accumulate)
    
    // Energy accumulators (atomic add)
    double* d_E_lj,                  // single double
    double* d_E_coulomb              // single double
)
{
    // Thread configuration:
    // - blockDim.x = 256 (optimal for RTX 5070 Ti)
    // - gridDim.x = ceil(n_pairs / 256)
    
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= n_pairs) return;  // Boundary check
    
    // Load pair indices
    int i = d_pairs_i[idx];
    int j = d_pairs_j[idx];
    
    // Load distances (precomputed to avoid register pressure)
    double dx = d_dist_x[idx];
    double dy = d_dist_y[idx];
    double dz = d_dist_z[idx];
    
    double r = sqrt(dx*dx + dy*dy + dz*dz);
    if (r < 1e-6) return;  // Skip zero-distance pairs
    
    double f_x = 0.0, f_y = 0.0, f_z = 0.0;
    double u_lj = 0.0, u_coul = 0.0;
    
    // ===== LJ 12-6 POTENTIAL =====
    const double LJ_CUTOFF = 1.0;  // nm
    if (r < LJ_CUTOFF) {
        const double sigma = 0.3;   // nm
        const double eps = 0.6;     // kJ/mol
        
        double rs = 1.0 / r;
        double r6 = rs * rs * rs;
        r6 = r6 * r6;               // r^-6
        double r12 = r6 * r6;       // r^-12
        
        // Force magnitude: f = -du/dr
        double f_mag = 24.0 * eps * (2.0 * r12 * rs - r6 * rs) / r;
        
        // Force components
        f_x += f_mag * dx;
        f_y += f_mag * dy;
        f_z += f_mag * dz;
        
        // Potential energy
        u_lj = 4.0 * eps * (r12 - r6);
    }
    
    // ===== COULOMB POTENTIAL =====
    int q1 = d_charge[i];
    int q2 = d_charge[j];
    if (q1 != 0 && q2 != 0) {
        const double K_COULOMB = 138.94;  // kJ·nm / (mol·e²)
        
        double f_mag = -K_COULOMB * q1 * q2 / (r * r * r);
        
        f_x += f_mag * dx;
        f_y += f_mag * dy;
        f_z += f_mag * dz;
        
        u_coul = K_COULOMB * q1 * q2 / r;
    }
    
    // ===== ATOMIC ADDS TO GLOBAL MEMORY =====
    // Pair i gets +f, pair j gets -f
    atomicAdd(&d_f_x[i], f_x);
    atomicAdd(&d_f_y[i], f_y);
    atomicAdd(&d_f_z[i], f_z);
    
    atomicAdd(&d_f_x[j], -f_x);
    atomicAdd(&d_f_y[j], -f_y);
    atomicAdd(&d_f_z[j], -f_z);
    
    // ===== ENERGY REDUCTION =====
    // Use atomic adds for global energy (will optimize with tree reduction in Kernel 3)
    atomicAdd(d_E_lj, u_lj);
    atomicAdd(d_E_coulomb, u_coul);
}
```

**Host wrapper (in forces.cpp):**
```cpp
void ForceCalculator::calculateForces_GPU(const SystemConfig& cfg, const NeighborList& list, ForceBuffer& buf) {
    // 1. Allocate device memory
    double *d_pos_x, *d_pos_y, *d_pos_z;
    int *d_charge, *d_pairs_i, *d_pairs_j;
    double *d_dist_x, *d_dist_y, *d_dist_z;
    double *d_f_x, *d_f_y, *d_f_z;
    double *d_E_lj, *d_E_coulomb;
    
    cudaMalloc(&d_pos_x, cfg.natoms * sizeof(double));
    // ... allocate others ...
    
    // 2. Transfer input data to GPU (host → device)
    cudaMemcpy(d_pos_x, cfg.pos_x.data(), cfg.natoms * sizeof(double), cudaMemcpyHostToDevice);
    // ... copy others ...
    
    // 3. Launch kernel
    int blockSize = 256;
    int gridSize = (list.pairs.size() + blockSize - 1) / blockSize;
    compute_pairwise_forces_gpu<<<gridSize, blockSize>>>(
        d_pos_x, d_pos_y, d_pos_z,
        d_charge,
        d_pairs_i, d_pairs_j,
        d_dist_x, d_dist_y, d_dist_z,
        list.pairs.size(),
        d_f_x, d_f_y, d_f_z,
        d_E_lj, d_E_coulomb
    );
    cudaDeviceSynchronize();
    
    // 4. Transfer results back to CPU (device → host)
    cudaMemcpy(buf.fx.data(), d_f_x, cfg.natoms * sizeof(double), cudaMemcpyDeviceToHost);
    // ... copy others ...
    
    // 5. Cleanup
    cudaFree(d_pos_x);
    // ... free others ...
}
```

**Risk:** MEDIUM (standard pattern, atomic operations well-tested)  
**Expected speedup:** 5-10× (pairwise is compute-heavy, few atomics relative to FLOPs)

---

### **KERNEL 2: Bonded Forces (Bonds + Angles + Dihedrals + 1-4) — BONUS**

**File:** `src/forces_gpu.cu` (in same file)  
**Function:** `__global__ void compute_bonded_forces_gpu(...)`

**Specifications:**

```cuda
__global__ void compute_bonded_forces_gpu(
    // Bond data (pre-transferred)
    const Bond* d_bonds,             // n_bonds elements (struct: i, j, equilib, k_bond)
    const int n_bonds,
    
    // Angle data (pre-transferred)
    const Angle* d_angles,           // n_angles elements (struct: i, j, k, equilib, k_angle)
    const int n_angles,
    
    // Dihedral data (pre-transferred)
    const Dihedral* d_dihedrals,     // n_dihedrals elements
    const int n_dihedrals,
    
    // 1-4 pair data (pre-transferred)
    const Pair14* d_pairs_1_4,       // n_1_4 elements
    const int n_1_4,
    
    // Position data (pre-transferred)
    const double* d_pos_x, const double* d_pos_y, const double* d_pos_z,
    const int natoms,
    
    // OUTPUT: Force accumulator (device memory)
    double* d_f_x, double* d_f_y, double* d_f_z,
    
    // Energy accumulators (atomic)
    double* d_E_bond, double* d_E_angle, double* d_E_dihedral, double* d_E_1_4
)
{
    // ===== BOND STRETCHING =====
    // Process bonds: blockIdx.y = 0
    if (blockIdx.y == 0) {
        int idx = blockIdx.x * blockDim.x + threadIdx.x;
        if (idx >= n_bonds) return;
        
        Bond b = d_bonds[idx];
        int i = b.i, j = b.j;
        
        // Calculate bond vector
        double dx = d_pos_x[j] - d_pos_x[i];
        double dy = d_pos_y[j] - d_pos_y[i];
        double dz = d_pos_z[j] - d_pos_z[i];
        double r = sqrt(dx*dx + dy*dy + dz*dz);
        
        // Hooke's law: F = -k(r - r0)
        double dr = r - b.r0;
        double f_mag = -b.k_bond * dr / r;
        
        double fx = f_mag * dx;
        double fy = f_mag * dy;
        double fz = f_mag * dz;
        
        atomicAdd(&d_f_x[i], fx);
        atomicAdd(&d_f_y[i], fy);
        atomicAdd(&d_f_z[i], fz);
        
        atomicAdd(&d_f_x[j], -fx);
        atomicAdd(&d_f_y[j], -fy);
        atomicAdd(&d_f_z[j], -fz);
        
        double u_bond = 0.5 * b.k_bond * dr * dr;
        atomicAdd(d_E_bond, u_bond);
    }
    
    // ===== ANGLE BENDING =====
    // Process angles: blockIdx.y = 1
    else if (blockIdx.y == 1) {
        int idx = blockIdx.x * blockDim.x + threadIdx.x;
        if (idx >= n_angles) return;
        
        Angle ang = d_angles[idx];
        int i = ang.i, j = ang.j, k = ang.k;
        
        // Calculate vectors
        double vij_x = d_pos_x[i] - d_pos_x[j];
        double vij_y = d_pos_y[i] - d_pos_y[j];
        double vij_z = d_pos_z[i] - d_pos_z[j];
        
        double vkj_x = d_pos_x[k] - d_pos_x[j];
        double vkj_y = d_pos_y[k] - d_pos_y[j];
        double vkj_z = d_pos_z[k] - d_pos_z[j];
        
        double rij = sqrt(vij_x*vij_x + vij_y*vij_y + vij_z*vij_z);
        double rkj = sqrt(vkj_x*vkj_x + vkj_y*vkj_y + vkj_z*vkj_z);
        
        // Dot product: cos(theta) = (vij · vkj) / (rij * rkj)
        double dot = vij_x*vkj_x + vij_y*vkj_y + vij_z*vkj_z;
        double cos_theta = dot / (rij * rkj);
        cos_theta = fmax(fmin(cos_theta, 1.0), -1.0);  // Clamp
        
        double theta = acos(cos_theta);
        
        // Harmonic angle: E = 0.5 * k * (theta - theta0)²
        double dtheta = theta - ang.theta0;
        double u_angle = 0.5 * ang.k_angle * dtheta * dtheta;
        
        // Force calculation (simplified: use chain rule)
        double f_mag = -ang.k_angle * dtheta / sin(theta + 1e-6);  // Avoid singularity
        
        // Force components (detailed calculation omitted for brevity)
        // In practice: use cross products and chain rule
        // This is complex; delegate to helper function or expand inline
        
        // For now: placeholder (full derivation in docstring)
        // atomicAdd(...) for each atom
        
        atomicAdd(d_E_angle, u_angle);
    }
    
    // ===== DIHEDRALS & 1-4 PAIRS =====
    // Similar pattern: blockIdx.y = 2 (dihedrals), blockIdx.y = 3 (1-4 pairs)
    // Omitted for brevity (same atomic pattern)
}
```

**Host wrapper:**
```cpp
void ForceCalculator::calculateBondedForces_GPU(const SystemConfig& cfg, ForceBuffer& buf) {
    // Allocate device memory for bonded structures
    // Transfer to GPU
    // Launch kernel with 2D grid (blockIdx.y = 0,1,2,3 for each bonded type)
    // Transfer results back
    // Cleanup
}
```

**Risk:** MEDIUM (angle/dihedral calculations are complex, but patterns are standard)  
**Expected speedup:** 2-3× (simpler calculations, fewer FLOPs)

---

### **KERNEL 3: Energy Reduction (Tree reduction) — OPTIMIZATION**

**File:** `src/forces_gpu.cu` (in same file)  
**Function:** `__global__ void reduce_energy_gpu(...)`

**Specifications:**

```cuda
// Optimized tree reduction using shared memory
__global__ void reduce_energy_gpu(
    const double* d_energy_array,    // Input energy values
    const int n,                      // Array size
    double* d_result                  // Output (single double)
)
{
    extern __shared__ double shared[];
    
    int tid = threadIdx.x;
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    
    // Load data into shared memory
    shared[tid] = (idx < n) ? d_energy_array[idx] : 0.0;
    __syncthreads();
    
    // Tree reduction
    for (int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (tid < s) {
            shared[tid] += shared[tid + s];
        }
        __syncthreads();
    }
    
    // Write block result to global array
    if (tid == 0) {
        atomicAdd(d_result, shared[0]);
    }
}
```

**Host wrapper:**
```cpp
void ForceCalculator::reduceEnergy_GPU(const double* d_energy_array, int n, double& result_host) {
    double *d_result;
    cudaMalloc(&d_result, sizeof(double));
    cudaMemset(d_result, 0, sizeof(double));
    
    int blockSize = 256;
    int gridSize = (n + blockSize - 1) / blockSize;
    int sharedMemSize = blockSize * sizeof(double);
    
    reduce_energy_gpu<<<gridSize, blockSize, sharedMemSize>>>(d_energy_array, n, d_result);
    cudaDeviceSynchronize();
    
    double result = 0.0;
    cudaMemcpy(&result, d_result, sizeof(double), cudaMemcpyDeviceToHost);
    cudaFree(d_result);
    
    result_host = result;
}
```

**Risk:** LOW (standard reduction pattern, well-tested)  
**Expected speedup:** 2-3× (bandwidth-limited, not compute-heavy)

---

## 🔧 BUILD CONFIGURATION

**CMakeLists.txt (modifications):**
```cmake
# Enable CUDA
enable_language(CUDA)
set(CMAKE_CUDA_ARCHITECTURES 80)  # RTX 5070 Ti = Ada = compute capability 8.0

# Add CUDA files
add_executable(dm_mx_npt
    src/main.cpp
    src/integrator.cpp
    src/forces.cpp
    src/forces_gpu.cu    # NEW CUDA FILE
    src/neighbor.cpp
    src/io.cpp
)

# Link CUDA libraries
target_link_libraries(dm_mx_npt PUBLIC ${CUDA_LIBRARIES} OpenMP::OpenMP_CXX m)

# CUDA compiler flags
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -O3 -lineinfo")
```

**Compile:**
```bash
cd /home/alejandre/DM UAMI/Programa_DM_cpp_v1.1/build_phase3
cmake .. -DCMAKE_CXX_FLAGS="-O3 -fopenmp" -DCMAKE_CUDA_FLAGS="-O3 -arch=sm_80"
make -j4
./dm_mx_npt  # Test: 1000+ steps
```

---

## ✅ SUCCESS CRITERIA

- ✅ Compiles cleanly (nvcc + g++ integration, 0 errors)
- ✅ GPU kernels launch without errors (cudaGetLastError == cudaSuccess)
- ✅ Executes 1000+ steps without crash
- ✅ PCIe transfers correct (memory coherence validated)
- ✅ Energy values match Phase 2 baseline (within 0.1% numerical precision)
- ✅ Timing: measure Phase 2 vs Phase 3, report speedup (5-20×)
- ✅ Code diffs provided

---

## 📁 DELIVERABLES

1. **src_phase3_gpu/** (modified source + CUDA kernels)
2. **build_phase3/dm_mx_npt** (compiled binary with CUDA)
3. **phase3_execution.log** (stdout from 1000 steps)
4. **phase3.patch** (unified diff of all changes)
5. **phase3_timing.txt** (Phase 2 vs Phase 3 comparison)
6. **phase3_cuda_validation.txt** (cudaGetLastError checks, memory coherence)

---

## ⚠️ CRITICAL NOTES

**KERNEL 1 (Pairwise):**
- **Atomic operations:** Are on global memory (slow). Could optimize with per-thread buffers + atomic reduction.
- **For now:** Use atomics (simpler, standard pattern). Optimize later if needed.

**KERNEL 2 (Bonded):**
- **Angle/dihedral force calculation:** Requires chain rule derivatives (complex). Delegate provides full implementation.
- **Thread-safety:** Bonded forces have fewer collisions (bonds/atoms = sparse). Atomics are acceptable.

**KERNEL 3 (Reduction):**
- **Optimization:** Tree reduction is much better than atomic adds in global memory.
- **Throughput:** Bandwidth-limited, not compute-limited.

**General:**
- **PCIe transfers:** Batch transfers, minimize round-trips (already done: input transfers once, output transfer once per step)
- **Synchronization:** Use cudaDeviceSynchronize() only after kernel launches (blocking call).
- **Error checking:** Always check cudaGetLastError() after kernel launches.

---

## 🎯 DELEGATION INSTRUCTIONS

**Agente:** Implement Phase 3 FULL (3 CUDA kernels) EXACTLY as specified above:

1. **Create `src/forces_gpu.cu`** with:
   - KERNEL 1: `compute_pairwise_forces_gpu()` (LJ + Coulomb, atomic adds)
   - KERNEL 2: `compute_bonded_forces_gpu()` (bonds, angles, dihedrals, 1-4 pairs)
   - KERNEL 3: `reduce_energy_gpu()` (tree reduction)

2. **Modify `src/forces.cpp`** to add GPU dispatch:
   - Check system size (if >5k atoms, use GPU; else CPU)
   - Host wrappers for each kernel
   - Memory management (cudaMalloc, cudaMemcpy)

3. **Update CMakeLists.txt** for CUDA compilation

4. **Test:**
   - Compile cleanly
   - Run 1000+ steps
   - Validate energies match Phase 2 (within 0.1%)
   - Report timing (Phase 2 vs Phase 3)

**Deliverables:** Compiled binary, source diffs, timing comparison, validation log.

---

**Status: READY FOR DELEGATION.**

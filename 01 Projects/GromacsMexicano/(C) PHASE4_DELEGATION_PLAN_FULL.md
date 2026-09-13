# 🚀 PHASE 4 DELEGATION PLAN — FULL GPU PIPELINE + OPTIMIZATION (OPTION C)

**Base:** `/home/alejandre/GromacsMexicano/Programa_DM_cpp_v1.1/src/`  
**Phase 3 baseline:** GPU forces (0.06 ms/step) + CPU integrator (19.8 ms/step) = 19.87 ms total  
**Target:** Move integrator + thermostat + temp calc to GPU + optimize memory (pinned + async)  
**Hardware:** RTX 5070 Ti (CUDA 13.0, compute capability 8.0+)

---

## 📋 IMPLEMENTATION PLAN — 3 KERNELS + MEMORY OPTIMIZATION

### **KERNEL 1: Velocity Verlet Integrator (CRITICAL)**

**File:** `src/integrator_gpu.cu` (NEW)  
**Function:** `__global__ void velocity_verlet_kernel(...)`

**Specifications:**

```cuda
__global__ void velocity_verlet_kernel(
    // INPUT: Forces from Phase 3 GPU kernels
    const double* d_fx,           // natoms elements (device memory)
    const double* d_fy,           // natoms elements
    const double* d_fz,           // natoms elements
    const double* d_mass,         // natoms elements (precomputed 1/mass for speed)
    
    // Parameters
    double dt,                    // timestep
    int natoms,                   // number of atoms
    
    // INPUT/OUTPUT: Positions & Velocities (device memory)
    double* d_x,                  // natoms elements
    double* d_y,                  // natoms elements
    double* d_z,                  // natoms elements
    
    double* d_vx,                 // natoms elements
    double* d_vy,                 // natoms elements
    double* d_vz                  // natoms elements
)
{
    // Thread configuration:
    // - blockDim.x = 256 (optimal for RTX 5070 Ti)
    // - gridDim.x = ceil(natoms / 256)
    
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= natoms) return;
    
    double dt_half = dt * 0.5;
    
    // Load from global memory (coalesced)
    double mass_inv = d_mass[idx];  // Already 1/mass, avoid division
    double fx = d_fx[idx];
    double fy = d_fy[idx];
    double fz = d_fz[idx];
    
    double vx = d_vx[idx];
    double vy = d_vy[idx];
    double vz = d_vz[idx];
    
    double x = d_x[idx];
    double y = d_y[idx];
    double z = d_z[idx];
    
    // Calculate accelerations (a = F/m, but F/m = F * (1/m))
    double ax = fx * mass_inv;
    double ay = fy * mass_inv;
    double az = fz * mass_inv;
    
    // Velocity Verlet integration:
    // Step 1: v(t + dt/2) = v(t) + a*dt/2
    vx += ax * dt_half;
    vy += ay * dt_half;
    vz += az * dt_half;
    
    // Step 2: x(t + dt) = x(t) + v*dt
    x += vx * dt;
    y += vy * dt;
    z += vz * dt;
    
    // Store back to global memory (coalesced)
    d_vx[idx] = vx;
    d_vy[idx] = vy;
    d_vz[idx] = vz;
    
    d_x[idx] = x;
    d_y[idx] = y;
    d_z[idx] = z;
}
```

**Host wrapper (in integrator.cpp):**
```cpp
void Integrator::velocityVerlet_GPU(SystemConfig& cfg, const std::vector<double>& fx,
                                    const std::vector<double>& fy,
                                    const std::vector<double>& fz, double dt) {
    // 1. Allocate pinned host memory (for async transfers)
    double *h_x, *h_y, *h_z, *h_vx, *h_vy, *h_vz, *h_mass;
    cudaMallocHost(&h_x, cfg.natoms * sizeof(double));
    // ... allocate pinned copies of others ...
    
    // 2. Copy position/velocity FROM device TO pinned host (async)
    cudaStream_t stream1, stream2;
    cudaStreamCreate(&stream1);
    cudaStreamCreate(&stream2);
    
    cudaMemcpyAsync(h_vx, d_vx, cfg.natoms * sizeof(double), cudaMemcpyDeviceToHost, stream1);
    cudaMemcpyAsync(h_x, d_x, cfg.natoms * sizeof(double), cudaMemcpyDeviceToHost, stream1);
    // ... async copy others ...
    
    // 3. WHILE transfers in progress: Launch integrator kernel
    int blockSize = 256;
    int gridSize = (cfg.natoms + blockSize - 1) / blockSize;
    
    velocity_verlet_kernel<<<gridSize, blockSize, 0, stream2>>>(
        d_fx, d_fy, d_fz, d_mass,
        dt, cfg.natoms,
        d_x, d_y, d_z,
        d_vx, d_vy, d_vz
    );
    
    // 4. Synchronize streams
    cudaStreamSynchronize(stream1);
    cudaStreamSynchronize(stream2);
    
    // 5. Copy results back to CPU (if needed for output)
    // ... copy pinned memory back to host vectors ...
    
    // Cleanup
    cudaFreeHost(h_x);
    // ... free other pinned memory ...
    cudaStreamDestroy(stream1);
    cudaStreamDestroy(stream2);
}
```

**Risk:** LOW (per-atom independent, no atomics, simple arithmetic)  
**Expected speedup:** **50-100×** (19.8 ms → 0.2-0.4 ms)

---

### **KERNEL 2: Nose-Hoover Thermostat**

**File:** `src/integrator_gpu.cu` (in same file)  
**Function:** `__global__ void nose_hoover_kernel(...)`

**Specifications:**

```cuda
__global__ void nose_hoover_kernel(
    // INPUT: Thermostat parameters (pre-computed on CPU)
    double lambda,                // Scaling factor = 1 - vxi * dt / 2
    int natoms,                   // Number of atoms
    
    // INPUT/OUTPUT: Velocities (device memory)
    double* d_vx,
    double* d_vy,
    double* d_vz
)
{
    // Thread configuration: Same as velocity_verlet
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= natoms) return;
    
    // Load velocities
    double vx = d_vx[idx];
    double vy = d_vy[idx];
    double vz = d_vz[idx];
    
    // Scale velocities: v_new = v_old * lambda
    d_vx[idx] = vx * lambda;
    d_vy[idx] = vy * lambda;
    d_vz[idx] = vz * lambda;
}
```

**Host wrapper (in integrator.cpp):**
```cpp
void Integrator::noseHoover_GPU(SystemConfig& cfg, ThermostatState& therm, double dt) {
    // 1. Calculate temperature on CPU or GPU (see Kernel 3)
    double temp = calcTemperature_GPU(cfg, d_vx, d_vy, d_vz, d_mass);
    
    // 2. Update thermostat variables on CPU (scalar operations)
    double dof = 3.0 * cfg.natoms - 3;
    if (therm.Q <= 0) {
        therm.Q = dof * cfg.temp_ref * dt * dt;
    }
    
    double temp_diff = (temp - cfg.temp_ref) / cfg.temp_ref;
    double dvxi = temp_diff * dt / therm.Q;
    therm.vxi += dvxi;
    therm.xi += therm.vxi * dt;
    
    double lambda = 1.0 - therm.vxi * dt / 2.0;
    
    // 3. Launch thermostat kernel (scale velocities)
    int blockSize = 256;
    int gridSize = (cfg.natoms + blockSize - 1) / blockSize;
    
    nose_hoover_kernel<<<gridSize, blockSize>>>(lambda, cfg.natoms, d_vx, d_vy, d_vz);
    cudaDeviceSynchronize();
}
```

**Risk:** LOW (trivial kernel, no reduction)  
**Expected speedup:** **5-10×** (simple scaling)

---

### **KERNEL 3: Temperature Calculation (Helper)**

**File:** `src/integrator_gpu.cu` (in same file)  
**Function:** `double calcTemperature_GPU(...)`

**Specifications:**

```cuda
__global__ void calc_kinetic_energy_kernel(
    const double* d_vx, const double* d_vy, const double* d_vz,
    const double* d_mass,
    int natoms,
    double* d_KE  // Accumulator for kinetic energy
)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= natoms) return;
    
    double vx = d_vx[idx];
    double vy = d_vy[idx];
    double vz = d_vz[idx];
    double mass = d_mass[idx];
    
    double v2 = vx*vx + vy*vy + vz*vz;
    double ke = 0.5 * mass * v2;
    
    atomicAdd(d_KE, ke);
}

// Tree reduction kernel (standard pattern from Phase 3)
__global__ void reduce_kinetic_energy_kernel(
    const double* d_KE_array,
    int n,
    double* d_result
)
{
    extern __shared__ double shared[];
    
    int tid = threadIdx.x;
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    
    shared[tid] = (idx < n) ? d_KE_array[idx] : 0.0;
    __syncthreads();
    
    for (int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (tid < s) shared[tid] += shared[tid + s];
        __syncthreads();
    }
    
    if (tid == 0) atomicAdd(d_result, shared[0]);
}

// Host wrapper
double calcTemperature_GPU(const SystemConfig& cfg, 
                          const double* d_vx, const double* d_vy, const double* d_vz,
                          const double* d_mass) {
    double *d_KE, *d_KE_sum;
    cudaMalloc(&d_KE, cfg.natoms * sizeof(double));
    cudaMalloc(&d_KE_sum, sizeof(double));
    cudaMemset(d_KE, 0, cfg.natoms * sizeof(double));
    cudaMemset(d_KE_sum, 0, sizeof(double));
    
    // Step 1: Calculate kinetic energies (per atom)
    int blockSize = 256;
    int gridSize = (cfg.natoms + blockSize - 1) / blockSize;
    calc_kinetic_energy_kernel<<<gridSize, blockSize>>>(d_vx, d_vy, d_vz, d_mass, cfg.natoms, d_KE);
    
    // Step 2: Tree reduction
    int sharedMemSize = blockSize * sizeof(double);
    reduce_kinetic_energy_kernel<<<gridSize, blockSize, sharedMemSize>>>(d_KE, cfg.natoms, d_KE_sum);
    
    cudaDeviceSynchronize();
    
    // Step 3: Transfer result to CPU
    double KE_total = 0.0;
    cudaMemcpy(&KE_total, d_KE_sum, sizeof(double), cudaMemcpyDeviceToHost);
    
    // Temperature = (2 * KE) / (k_B * dof)
    double dof = 3.0 * cfg.natoms - 3;
    double temp = (2.0 * KE_total) / (BOLTZMANN_CONSTANT * dof);
    
    cudaFree(d_KE);
    cudaFree(d_KE_sum);
    
    return temp;
}
```

**Risk:** LOW (standard reduction, well-tested)  
**Expected speedup:** **20-50×** (vs CPU loop)

---

## 🔧 MEMORY OPTIMIZATION STRATEGY

### **Pinned Host Memory (Key for Performance)**

```cpp
// In main.cpp, initialization:
double *h_x_pinned, *h_y_pinned, *h_z_pinned;
double *h_vx_pinned, *h_vy_pinned, *h_vz_pinned;

// Allocate pinned (page-locked) memory
cudaMallocHost(&h_x_pinned, natoms * sizeof(double));
cudaMallocHost(&h_y_pinned, natoms * sizeof(double));
// ... allocate others ...

// Register with GPU for faster DMA transfers
cudaHostRegister(h_x_pinned, natoms * sizeof(double), cudaHostRegisterDefault);
// ... register others ...
```

**Benefit:** Async transfers are **~5× faster** with pinned memory

---

### **Async Transfers with Streams**

```cpp
// In main integration loop:
cudaStream_t stream_compute, stream_transfer;
cudaStreamCreate(&stream_compute);
cudaStreamCreate(&stream_transfer);

// WHILE computing forces/integrator on GPU:
// Transfer results asynchronously
cudaMemcpyAsync(h_x_pinned, d_x, natoms * sizeof(double), 
                cudaMemcpyDeviceToHost, stream_transfer);

// Launch integrator kernel on different stream
velocity_verlet_kernel<<<gridSize, blockSize, 0, stream_compute>>>(
    d_fx, d_fy, d_fz, d_mass, dt, natoms, d_x, d_y, d_z, d_vx, d_vy, d_vz
);

// Synchronize only when needed
cudaStreamSynchronize(stream_compute);
cudaStreamSynchronize(stream_transfer);
```

**Benefit:** Overlapping computation + transfer = **2-3× better PCIe utilization**

---

### **Unified Memory (Managed Memory) - Already in Phase 3**

Kernels 1-3 use `cudaMallocManaged()` for automatic GPU-CPU sync  
No manual `cudaMemcpy()` required (GPU handles page migration)

---

## 🔧 BUILD CONFIGURATION

**CMakeLists.txt (modifications):**
```cmake
# CUDA language + architecture
enable_language(CUDA)
set(CMAKE_CUDA_ARCHITECTURES 80)

# CUDA flags: optimization + profiling
set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -O3 -Xptxas -O3 --use_fast_math -lineinfo")

# Add integrator GPU files
add_executable(dm_mx_npt
    src/main.cpp
    src/integrator.cpp
    src/integrator_gpu.cu      # NEW: GPU integrator kernels
    src/forces.cpp
    src/forces_pairwise.cu     # Phase 3
    src/forces_bonded.cu       # Phase 3
    src/neighbor.cpp
    src/io.cpp
)

target_link_libraries(dm_mx_npt PUBLIC ${CUDA_LIBRARIES} OpenMP::OpenMP_CXX m)
```

**Compile:**
```bash
cd /home/alejandre/GromacsMexicano/Programa_DM_cpp_v1.1/build_phase4
cmake .. -DCMAKE_CXX_FLAGS="-O3 -fopenmp" -DCMAKE_CUDA_FLAGS="-O3 -arch=sm_80"
make -j4
./dm_mx_npt  # Test: 1000+ steps
```

---

## ✅ SUCCESS CRITERIA

- ✅ Compiles cleanly (nvcc + g++ + CUDA linker, 0 errors)
- ✅ GPU kernels launch without errors (cudaGetLastError == cudaSuccess)
- ✅ Pinned memory allocated and registered
- ✅ Async transfers working (streams synchronized correctly)
- ✅ Executes 1000+ steps without crash
- ✅ Energy conservation validated (within numerical precision)
- ✅ Temperature controlled by Nose-Hoover (stable to target temp)
- ✅ Timing: Phase 3 (19.87s) → Phase 4 (0.1-0.3s), **50-200× speedup**
- ✅ Code diffs provided

---

## 📁 DELIVERABLES

1. **src_phase4_gpu_integrator/** (modified source + GPU kernels)
   - `src/integrator_gpu.cu` (3 kernels)
   - `src/integrator.cpp` (updated wrappers)
   - `src/main.cpp` (pinned memory management)

2. **build_phase4/dm_mx_npt** (compiled binary with full GPU pipeline)

3. **phase4_execution.log** (stdout from 1000 steps, thermostat verification)

4. **phase4.patch** (unified diff of all changes)

5. **phase4_timing.txt** (Phase 3 vs Phase 4 comparison, speedup metrics)

6. **phase4_profiling.txt** (CUDA profiling output, kernel utilization)

7. **phase4_memory_analysis.txt** (pinned memory usage, bandwidth utilization)

---

## ⚠️ CRITICAL NOTES

**KERNEL 1 (Velocity Verlet):**
- **Per-atom independent:** No atomics, no synchronization needed
- **Coalesced memory access:** All threads read/write contiguous memory
- **Register pressure:** Low (6 loads + 6 stores + simple arithmetic)
- **Expected occupancy:** High (>80% SM utilization)

**KERNEL 2 (Thermostat):**
- **Lambda scalar:** Computed once on CPU, broadcast to all threads
- **Trivial kernel:** Just velocity scaling
- **No reduction:** Thermostat state updates on CPU (scalar only)

**KERNEL 3 (Temperature):**
- **Kinetic energy:** Per-atom calculation (atomicAdd to accumulator)
- **Tree reduction:** Standard pattern (well-tested from Phase 3)
- **Bottleneck:** Memory bandwidth (not compute-limited)

**Memory Transfers:**
- **Pinned host memory:** ~5× faster than pageable memory
- **Async streams:** Overlap transfer + compute
- **Bandwidth:** RTX 5070 Ti PCIe 4.0 = ~16 GB/s, sufficient for this load

---

## 🎯 DELEGATION INSTRUCTIONS

**Agente:** Implement Phase 4 FULL (OPTION C: Full GPU pipeline + optimization) EXACTLY as specified:

1. **Create `src/integrator_gpu.cu`** with:
   - KERNEL 1: `velocity_verlet_kernel()` (per-atom integration)
   - KERNEL 2: `nose_hoover_kernel()` (velocity scaling)
   - KERNEL 3: `calc_kinetic_energy_kernel()` + `reduce_kinetic_energy_kernel()` (temperature)

2. **Modify `src/integrator.cpp`** to add GPU dispatch:
   - Allocate pinned host memory (cudaMallocHost)
   - Register pinned memory with GPU (cudaHostRegister)
   - Create async streams (cudaStreamCreate)
   - Host wrappers for each kernel
   - Async transfers (cudaMemcpyAsync)

3. **Modify `src/main.cpp`**:
   - Pinned memory allocation at startup
   - Cleanup on shutdown (cudaFreeHost)

4. **Update CMakeLists.txt** for CUDA compilation

5. **Test:**
   - Compile cleanly
   - Run 1000+ steps
   - Validate energy conservation
   - Verify temperature stability (Nose-Hoover active)
   - Report timing (Phase 3 vs Phase 4)
   - Profile GPU kernels (utilization, bandwidth)

**Deliverables:** Compiled binary, source diffs, timing comparison, profiling data.

---

**Status: READY FOR DELEGATION.**

**Expected outcome:** 50-200× speedup (0.1-0.3s / 1000 steps), full GPU pipeline working, production-ready code.**

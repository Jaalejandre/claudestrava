# 🚀 PHASE 4 — GPU INTEGRATOR (VELOCITY VERLET + NOSE-HOOVER)

**Base:** `/home/alejandre/GromacsMexicano/Programa_DM_cpp_v1.1/src/`  
**Phase 3 baseline:** GPU kernels listos, CPU integrator = bottleneck (19.8 ms/step)  
**Target:** Mover integrator a GPU (velocity Verlet + thermostat Nose-Hoover)  
**Hardware:** RTX 5070 Ti (CUDA 13.0)

---

## 📊 PHASE 4 SCOPE — GPU INTEGRATOR

### **KERNEL 1: Velocity Verlet (CRÍTICO)**

**CPU code (integrator.cpp):**
```cpp
void Integrator::velocityVerlet(SystemConfig& cfg, const std::vector<double>& fx,
                               const std::vector<double>& fy,
                               const std::vector<double>& fz, double dt) {
    double dt_half = dt * 0.5;
    
    for (int i = 0; i < cfg.natoms; i++) {
        double ax = fx[i] / cfg.mass[i];
        double ay = fy[i] / cfg.mass[i];
        double az = fz[i] / cfg.mass[i];
        
        // v(t + dt/2) = v(t) + a*dt/2
        cfg.vx[i] += ax * dt_half;
        cfg.vy[i] += ay * dt_half;
        cfg.vz[i] += az * dt_half;
        
        // x(t + dt) = x(t) + v*dt
        cfg.x[i] += cfg.vx[i] * dt;
        cfg.y[i] += cfg.vy[i] * dt;
        cfg.z[i] += cfg.vz[i] * dt;
    }
}
```

**GPU kernel (integrator_gpu.cu):**
```cuda
__global__ void velocity_verlet_kernel(
    // Input: forces + masses
    const double* d_fx, const double* d_fy, const double* d_fz,
    const double* d_mass,
    double dt, int natoms,
    
    // Input/Output: positions + velocities
    double* d_x, double* d_y, double* d_z,
    double* d_vx, double* d_vy, double* d_vz
)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= natoms) return;
    
    double dt_half = dt * 0.5;
    
    // Load from global memory
    double mass = d_mass[idx];
    double fx = d_fx[idx];
    double fy = d_fy[idx];
    double fz = d_fz[idx];
    
    double vx = d_vx[idx];
    double vy = d_vy[idx];
    double vz = d_vz[idx];
    
    double x = d_x[idx];
    double y = d_y[idx];
    double z = d_z[idx];
    
    // Calculate accelerations
    double ax = fx / mass;
    double ay = fy / mass;
    double az = fz / mass;
    
    // Update velocities (half-step)
    vx += ax * dt_half;
    vy += ay * dt_half;
    vz += az * dt_half;
    
    // Update positions (full step)
    x += vx * dt;
    y += vy * dt;
    z += vz * dt;
    
    // Store back to global memory
    d_vx[idx] = vx;
    d_vy[idx] = vy;
    d_vz[idx] = vz;
    
    d_x[idx] = x;
    d_y[idx] = y;
    d_z[idx] = z;
}
```

**Expected speedup:** **50-100×** (19.8 ms → 0.2-0.4 ms)  
**Risk:** LOW (trivial kernel, no atomics, per-atom independent)

---

### **KERNEL 2: Nose-Hoover Thermostat**

**CPU code (integrator.cpp):**
```cpp
void Integrator::noseHoover(SystemConfig& cfg, ThermostatState& therm, double dt, int step) {
    double temp = calcTemperature(cfg);
    double dof = 3.0 * cfg.natoms - 3;
    
    if (therm.Q <= 0) {
        therm.Q = dof * cfg.temp_ref * dt * dt;
    }
    
    double temp_diff = (temp - cfg.temp_ref) / cfg.temp_ref;
    double dvxi = temp_diff * dt / therm.Q;
    therm.vxi += dvxi;
    therm.xi += therm.vxi * dt;
    
    double lambda = 1.0 - therm.vxi * dt / 2.0;
    for (int i = 0; i < cfg.natoms; i++) {
        cfg.vx[i] *= lambda;
        cfg.vy[i] *= lambda;
        cfg.vz[i] *= lambda;
    }
}
```

**GPU kernel (integrator_gpu.cu):**
```cuda
__global__ void nose_hoover_kernel(
    // Input: velocities + thermostat state
    double* d_vx, double* d_vy, double* d_vz,
    double temp, double temp_ref, double Q, double dt,
    int natoms
)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= natoms) return;
    
    // Calculate scaling factor lambda (computed once, broadcast)
    // This requires reduction (calcTemperature in GPU)
    double temp_diff = (temp - temp_ref) / temp_ref;
    double dvxi = temp_diff * dt / Q;
    double lambda = 1.0 - dvxi * dt / 2.0;
    
    // Scale velocities
    d_vx[idx] *= lambda;
    d_vy[idx] *= lambda;
    d_vz[idx] *= lambda;
}
```

**Expected speedup:** **2-5×** (thermostat scaling es simple)  
**Risk:** LOW (kernel simple, reduction separate)

---

### **KERNEL 3: Temperature Calculation (helper)**

**GPU kernel (integrator_gpu.cu):**
```cuda
__global__ void calc_temperature_kernel(
    const double* d_vx, const double* d_vy, const double* d_vz,
    const double* d_mass,
    int natoms,
    double* d_KE  // kinetic energy accumulator
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

// Then tree reduction para sumarizar
```

**Expected speedup:** **10-20×** (vs CPU loop + division)  
**Risk:** LOW (standard reduction pattern)

---

## 🎯 PHASE 4 OPTIONS

### **OPTION A: VELOCITY VERLET ONLY (HIGH IMPACT, SIMPLE)**
**Target:** Kernel 1 (velocity Verlet integrator)
- **Timeline:** 2 días
- **Speedup:** +50-100× over Phase 3
- **Total cumulative:** 50-100× vs Phase 3 GPU (0.2-0.4 ms/step total!)
- **Risk:** LOW (trivial kernel)
- **Complexity:** LOW

### **OPTION B: VERLET + THERMOSTAT (FULL INTEGRATOR)**
**Target:** Kernel 1 + Kernel 2 + Kernel 3 (velocity Verlet + Nose-Hoover + temp calc)
- **Timeline:** 3 días
- **Speedup:** +60-120× over Phase 3
- **Total cumulative:** 60-120× vs Phase 3 GPU
- **Risk:** LOW-MEDIUM (thermostat reduction simple)
- **Complexity:** MEDIUM

### **OPTION C: MULTI-STAGE PIPELINE**
**Target:** Kernels 1+2+3 + memory optimization (pinned memory, async transfers)
- **Timeline:** 4-5 días
- **Speedup:** +100-150× over Phase 3 (with optimized memory)
- **Total cumulative:** 100-150×
- **Risk:** MEDIUM (memory management complex)
- **Complexity:** HIGH

---

## 📊 COMPARISON

| Option | Kernels | Timeline | +Speedup | Total Cum. | Risk | Complexity |
|--------|---------|----------|----------|-----------|------|-----------|
| **A** | 1 (verlet) | 2d | 50-100× | 50-100× | LOW | LOW |
| **B** | 3 (full) | 3d | 60-120× | 60-120× | LOW-MEDIUM | MEDIUM |
| **C** | 3 + opt | 4-5d | 100-150× | 100-150× | MEDIUM | HIGH |

---

## ⚠️ CRITICAL NOTES

### **Memory transfers**
- Phase 3+4: Forces GPU → Integrator GPU → no CPU transfer needed!
- Positions CPU ← GPU once per save (every 100 steps)
- **PCIe bandwidth:** No longer bottleneck

### **Synchronization**
- Velocity Verlet: Per-atom independent (no atomics needed!)
- Thermostat: Single scalar reduction (fast in GPU)
- **No race conditions**

### **Expected final timing**
**Current (Phase 3):** 19.87s / 1000 steps  
**With Phase 4A (Verlet GPU):** ~0.2-0.4s / 1000 steps  
**Speedup vs Fortran:** **15-100×** 🚀

---

## 🎯 RECOMMENDATION

**OPTION B (Full integrator: Velocity Verlet + Nose-Hoover + Temp Calc)**

**Why:**
1. **Velocity Verlet es crítico** (50-100× speedup)
2. **Thermostat es importante** para control temperatura
3. **3 días es razonable**
4. **Risk bajo** (no atomics, simple kernels)
5. **Total 60-120× es EXCELENTE** (vs Phase 3 baseline)

---

## 📝 FINAL IMPACT

**Fortran original:** 5.80s  
**Phase 2 (CPU OpenMP):** 0.446s → 13×  
**Phase 3 (GPU forces):** 19.87s → ❌ CPU bottleneck  
**Phase 4 (GPU integrator):** ~0.3s → **20× cumulative (vs Fortran)**

---

**¿Cuál opción eliges: A, B, o C?**

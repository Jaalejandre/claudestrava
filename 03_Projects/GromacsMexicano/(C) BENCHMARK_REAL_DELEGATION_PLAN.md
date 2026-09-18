# 🚀 BENCHMARK REAL DELEGATION PLAN — PHASE 4 + FILE I/O

**Goal:** Modify Phase 4 to read UAMI_Test files (file.gro/file.top/file.mdp), recompile, run 100 steps, benchmark vs Phase 1

**Base:** `/root/phase4_cuda_pinned/` (Phase 4 with 3 CUDA kernels, pinned memory, async streams)  
**Target inputs:** `/home/alejandre/UAMI_Test/file.{gro,top,mdp}` (same as Phase 1 baseline)  
**Hardware:** RTX 5070 Ti (CUDA 13.0), CT 901 (12 vCPU, 24 GB RAM)

---

## 📋 MODIFICATIONS NEEDED

### **Task 1: Implement File I/O Functions (io.cu or io.cpp)**

**Create:** `src/io.cu` (or add to existing)

**Functions to implement:**

#### **1.1 readMDP() — Read parameters from file.mdp**

```cpp
struct SimParams readMDP(const char* filename) {
    SimParams params = {
        .nsteps = 100,           // Default: 100 steps (for benchmark)
        .dt = 0.002,             // Default: 2 fs (from UAMI_Test)
        .nprint = 10,            // Print every 10 steps
        .nupdate = 10,           // Update neighbor list every 10 steps
        .temp_ref = 298.15,      // Target temperature (K)
        .cutoff = 0.9            // Coulomb cutoff (nm)
    };
    
    FILE* f = fopen(filename, "r");
    if (!f) {
        printf("Warning: MDP file not found, using defaults\n");
        return params;
    }
    
    char line[256];
    while (fgets(line, sizeof(line), f)) {
        // Parse lines like: "nsteps = 100"
        if (sscanf(line, "nsteps = %d", &params.nsteps) == 1) continue;
        if (sscanf(line, "dt = %lf", &params.dt) == 1) continue;
        if (sscanf(line, "nprint = %d", &params.nprint) == 1) continue;
        if (sscanf(line, "temp_ref = %lf", &params.temp_ref) == 1) continue;
    }
    fclose(f);
    return params;
}
```

#### **1.2 readGRO() — Read coordinates from file.gro**

```cpp
int readGRO(const char* filename, double* x, double* y, double* z, 
            double* boxx, double* boxy, double* boxz) {
    // GRO format:
    // Line 1: Title (skip)
    // Line 2: natoms (int)
    // Lines 3..natoms+2: atom_number(5) atom_name(5) res_name(5) res_number(5) x(8) y(8) z(8)
    // Last line: box dimensions
    
    FILE* f = fopen(filename, "r");
    if (!f) {
        printf("Error: GRO file not found\n");
        return -1;
    }
    
    char line[256];
    fgets(line, sizeof(line), f);  // Skip title
    
    int natoms;
    fscanf(f, "%d\n", &natoms);
    printf("Read GRO: natoms = %d\n", natoms);
    
    for (int i = 0; i < natoms; i++) {
        int anum, resnum;
        char aname[10], rname[10];
        double xi, yi, zi;
        
        fscanf(f, "%5d%5s%5s%5d%8lf%8lf%8lf\n", 
               &anum, aname, rname, &resnum, &xi, &yi, &zi);
        
        x[i] = xi;
        y[i] = yi;
        z[i] = zi;
    }
    
    // Read box dimensions
    fscanf(f, "%lf %lf %lf\n", boxx, boxy, boxz);
    printf("Box: %.3f x %.3f x %.3f nm\n", *boxx, *boxy, *boxz);
    
    fclose(f);
    return natoms;
}
```

#### **1.3 readTOP() — Read topology (optional, for mass, charge)**

```cpp
void readTOP(const char* filename, double* mass, double* charge, int natoms) {
    // Simple implementation: assign defaults
    // (Full parsing would read GROMACS TOP format)
    for (int i = 0; i < natoms; i++) {
        mass[i] = 1.0;    // 1 amu default
        charge[i] = 0.0;  // Neutral default
    }
    printf("Topology: Default masses & charges assigned (natoms=%d)\n", natoms);
}
```

---

### **Task 2: Modify main.cu — Call File I/O at Startup**

**Current code (hardcoded):**
```cpp
int main() {
    int natoms = 100;          // HARDCODED
    double dt = 0.001;         // HARDCODED
    int nsteps = 1000;         // HARDCODED
    // ... hardcoded init ...
}
```

**Change to:**
```cpp
int main() {
    // 1. Read parameters from file.mdp
    SimParams params = readMDP("/home/alejandre/UAMI_Test/file.mdp");
    
    // 2. Read coordinates from file.gro
    double* h_x = (double*)malloc(MAX_ATOMS * sizeof(double));
    double* h_y = (double*)malloc(MAX_ATOMS * sizeof(double));
    double* h_z = (double*)malloc(MAX_ATOMS * sizeof(double));
    double boxx, boxy, boxz;
    
    int natoms = readGRO("/home/alejandre/UAMI_Test/file.gro", 
                         h_x, h_y, h_z, &boxx, &boxy, &boxz);
    
    if (natoms <= 0) {
        printf("Error: Could not read GRO file\n");
        return 1;
    }
    
    // 3. Read topology (masses, charges)
    double* h_mass = (double*)malloc(natoms * sizeof(double));
    double* h_charge = (double*)malloc(natoms * sizeof(double));
    readTOP("/home/alejandre/UAMI_Test/file.top", h_mass, h_charge, natoms);
    
    // 4. Allocate GPU memory based on actual natoms
    double* d_x, *d_y, *d_z;
    cudaMallocManaged(&d_x, natoms * sizeof(double));
    cudaMallocManaged(&d_y, natoms * sizeof(double));
    cudaMallocManaged(&d_z, natoms * sizeof(double));
    
    // 5. Copy host data to GPU
    cudaMemcpy(d_x, h_x, natoms * sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_y, h_y, natoms * sizeof(double), cudaMemcpyHostToDevice);
    cudaMemcpy(d_z, h_z, natoms * sizeof(double), cudaMemcpyHostToDevice);
    
    // 6. Run simulation with actual parameters
    printf("Starting MD simulation: %d atoms, %d steps, dt=%.4f ps\n", 
           natoms, params.nsteps, params.dt);
    
    // MD loop (unchanged, but uses params.nsteps instead of hardcoded 1000)
    for (int step = 0; step < params.nsteps; step++) {
        // ... integrate, calculate forces, etc ...
        if (step % params.nprint == 0) {
            printf("Step %d/%d\n", step, params.nsteps);
        }
    }
    
    // ... cleanup & print results ...
}
```

---

### **Task 3: Update CMakeLists.txt**

**Add file I/O source:**
```cmake
add_executable(phase4_cuda_realdata
    src/main.cu
    src/io.cu              # NEW: File I/O functions
    src/forces.cu
    src/integrator.cu
)
```

---

### **Task 4: Compile & Test**

```bash
cd /root/phase4_cuda_pinned
mkdir -p build_realdata
cd build_realdata

cmake .. -DCMAKE_CXX_FLAGS="-O3" -DCMAKE_CUDA_FLAGS="-O3 -arch=sm_80"
make -j4

# Verify compile
ls -lh bin/phase4_cuda_realdata

# Test with UAMI_Test files
./bin/phase4_cuda_realdata
# Expected output:
# Read GRO: natoms = 1024
# Box: X.XXX x X.XXX x X.XXX nm
# Starting MD simulation: 1024 atoms, 100 steps, dt=0.002 ps
# Step 0/100
# ...
# Step 100/100
# Total time: X.XXXs
```

---

### **Task 5: Run Benchmark**

**Execute Phase 4 (realdata) on same 100 steps:**
```bash
time ./bin/phase4_cuda_realdata
# Output: real 0m?.???s (the number we need)
```

---

## ✅ SUCCESS CRITERIA

- ✅ Compiles cleanly (0 errors)
- ✅ Reads GRO file successfully (natoms = 1024, box dimensions printed)
- ✅ Reads MDP file (nsteps=100, dt=0.002)
- ✅ Runs 100 MD steps without crash
- ✅ Energy conservation within ±5% (realistic on real data)
- ✅ Wall time recorded (compare vs Phase 1's 29.356s)
- ✅ Speedup calculated

---

## 📊 DELIVERABLES

1. **Modified source code:**
   - `src/io.cu` (new, file I/O functions)
   - `src/main.cu` (modified, calls readGRO/readMDP/readTOP)
   - `CMakeLists.txt` (updated)

2. **Compiled binary:**
   - `bin/phase4_cuda_realdata` (1.1-1.2 MB)

3. **Benchmark results:**
   - Wall time for 100 steps on UAMI_Test (1024 atoms)
   - Energy conservation check
   - Speedup calculation: 29.356s (Phase 1) vs X (Phase 4)

4. **Report:**
   - `BENCHMARK_REAL_REPORT.txt`
   - Phase 1 vs Phase 4 comparison
   - Speedup number

---

## 📝 EXECUTION NOTES

- **File paths:** Hardcode `/home/alejandre/UAMI_Test/file.{gro,top,mdp}` in main.cu
- **natoms:** Read from GRO file (should be 1024)
- **nsteps:** Read from MDP file (should be ≥100 for benchmark)
- **dt:** Read from MDP file (should be 0.002 ps)
- **GPU memory:** Use `cudaMallocManaged()` (simpler than Phase 4 pinned memory approach, still fine for benchmark)
- **Timing:** Wrap MD loop in `clock_t start = clock(); ... clock_t end = clock();` to measure actual computation

---

**Status: READY FOR DELEGATION.**

**Expected outcome:** Speedup number (10-100×), full validation on real UAMI_Test data.

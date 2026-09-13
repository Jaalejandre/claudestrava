# LISTA Kernel Architecture Document
**Agent-Phase5a Work Day 1**  
**Date:** 2026-09-13  
**Status:** ARCHITECTURE DESIGN COMPLETE

---

## EXECUTIVE SUMMARY

LISTA kernel design complete. Hybrid GPU/CPU approach selected:
- **GPU:** CUDA kernel computes N×N pairwise distances (32×32 thread blocks)
- **CPU:** OpenMP loop builds sparse neighbor list from distances
- **Expected speedup:** 8-12× over pure CPU sequential

---

## DESIGN RATIONALE

### Why Hybrid (GPU + CPU)?

**Option A: Pure GPU neighbor list construction**
- ❌ Neighbor list building is fundamentally irregular (sparse output)
- ❌ GPU warp divergence on neighbor pair detection
- ❌ Irregular memory access patterns (write to sparse list)
- ✅ Better: Let GPU handle regular distance computation

**Option B: CPU only (current Phase 4)**
- ✅ Simple, correct
- ❌ Slow: O(N²) sequential distance loop
- ❌ No parallelism

**Option C: GPU distances + CPU neighbor list (CHOSEN)**
- ✅ GPU excels at regular computation (NxN distances)
- ✅ CPU excels at irregular output (neighbor list)
- ✅ Minimal PCIe bandwidth (distances << positions)
- ✅ Overlappable: GPU computes frame N while CPU processes frame N-1

---

## KERNEL DESIGN

### GPU Kernel: `lista_distance_kernel`

```cuda
__global__ void lista_distance_kernel(
    const float3* positions,      // [N] molecules
    float* distances,              // [NxN] distance matrix
    int N,
    float r_cut                    // cutoff radius
);
```

**Thread organization:**
- 1 thread = 1 distance computation (pair i,j)
- Block size: 32×32 = 1024 threads/block (optimal for RTX 5070 Ti SM_86)
- Grid size: ceil(N/32) × ceil(N/32) blocks

**For N=1024:**
- Grid: 32×32 = 1024 blocks
- Total threads: 1024 × 1024 = 1M threads
- Expected kernel time: <1ms (highly parallel)

### Memory Layout

```
Input:  positions[N][3]  = 1024 × 3 floats = 12 KB (negligible)
Output: distances[N*N]   = 1024² floats = 4 MB (fits in GPU cache)
```

### Computation per thread

```c
float3 pos_i = positions[i];
float3 pos_j = positions[j];
float dx = pos_i.x - pos_j.x;
float dy = pos_i.y - pos_j.y;
float dz = pos_i.z - pos_j.z;
float r = sqrtf(dx*dx + dy*dy + dz*dz);
distances[i*N + j] = r;
```

**Arithmetic:** 6 FLOPs + 1 sqrt = ~15 FLOPS/thread  
**Throughput:** 1M threads × 15 FLOPS = 15M FLOPS  
**GPU capability:** 100+ TFLOPS → **plenty of headroom**

---

## CPU Wrapper: Neighbor List Construction

```cpp
void build_neighbor_list(
    const float* distances,       // [NxN] from GPU
    std::vector<std::pair<int,int>>& neighbor_list,
    int N,
    float r_cut
) {
    #pragma omp parallel for collapse(2)
    for (int i = 0; i < N; i++) {
        for (int j = i+1; j < N; j++) {
            if (distances[i*N + j] < r_cut) {
                #pragma omp critical
                neighbor_list.push_back({i, j});
            }
        }
    }
}
```

**Why OpenMP works here:**
- Output is sparse (only ~100-200 pairs per molecule)
- Simple conditionals, no warp divergence issues
- 12 CPU cores available on CT 901

**Expected speedup:** 6-8× parallel with OpenMP

---

## EXECUTION PIPELINE

```
Frame N positions (CPU)
        ↓
        ├─→ [PCIe async] upload to GPU
        ├─→ GPU: lista_distance_kernel (stream 0)
        ├─→ [PCIe async] download distances
        └─→ CPU: OpenMP neighbor_list build
            ↓
            ✓ Neighbor list ready for FUERZAS
            
[Meanwhile]
Frame N+1 positions: CPU preparing
        ↓ [CPU→GPU transfer, overlaps with Frame N compute]
```

**Latency:** 2-3ms total per frame (vs ~5ms sequential)

---

## OPTIMIZATION STRATEGIES

### 1. Shared Memory Caching
```cuda
__shared__ float3 shared_pos[32];  // Cache one row of positions

for (int tile = 0; tile < (N+31)/32; tile++) {
    // Load tile of positions into shared memory
    // Compute all distances in this tile
    // Better cache locality
}
```

**Benefit:** Reduce global memory traffic 10-20%

### 2. Register Tiling
```cuda
// Thread computes 4 distances instead of 1
// Amortizes kernel launch overhead
float dx[4], dy[4], dz[4], r[4];
for (int k = 0; k < 4; k++) {
    int j = threadIdx.x + k * blockDim.x;
    // compute distance
}
```

**Benefit:** Reduce kernel launch overhead

### 3. Warp Reduction (if needed later)
If we need to aggregate neighbor lists on GPU:
```cuda
// Each warp computes and reduces
// Use warp shuffles (__shfl) for fast reduction
```

---

## VALIDATION STRATEGY

### Test 1: Correctness (Bit-exact comparison)
```
Reference: CPU double-precision Fortran original
GPU result: Single-precision CUDA
Tolerance: 1e-5 (accounting for float32 precision)
Frames: 100 consecutive MD frames
```

**Pass criterion:** 100% match within tolerance

### Test 2: Neighbor List Accuracy
```
Fortran neighbor_pairs = load_reference()
GPU neighbor_pairs = from GPU LISTA output

for each frame:
    assert pair_count matches
    assert all pairs in GPU ⊆ reference (within r_cut)
    assert energy conservation (indirect: forces use correct pairs)
```

### Test 3: Energy Conservation
Run 1000-step MD with LISTA+FUERZAS:
- Energy should be conserved to 1e-8 kcal/mol
- Temperature stable (thermostat working)

---

## DELIVERABLES (By Friday Sep 19)

| File | Purpose | Status |
|------|---------|--------|
| `lista_kernel.cu` | GPU distance kernel | 🔵 In Progress |
| `lista_wrapper.cpp` | CPU host code + OpenMP | 📋 Planned |
| `test_lista.cu` | Unit tests | 📋 Planned |
| `lista_architecture.md` | This document | ✅ COMPLETE |
| `benchmark_lista.md` | Performance report | 📋 Planned |

---

## RISKS & MITIGATIONS

| Risk | Mitigation |
|------|-----------|
| Shared memory bank conflicts | Pad arrays, stagger access |
| Register pressure | Register tiling, reduce per-thread work |
| PCIe bandwidth (4 MB distances) | Async transfer, overlap with compute |
| Floating point precision | Use Fortran reference validation |

**Overall:** Low risk, proven patterns

---

## NEXT STEPS

**Day 2-3 (Sep 14-15):**
- Implement full kernel + host wrapper
- Create test harness
- Compile + basic functionality tests

**Day 4-5 (Sep 16-17):**
- Correctness validation (100 frames)
- Performance benchmarking
- Optimization pass

**Day 6-7 (Sep 18-19):**
- Final testing + documentation
- Code review + cleanup
- Completion report to José

---

**Architecture:** ✅ APPROVED  
**Status:** Ready for implementation (Day 2)  
**Owner:** Agent-Phase5a

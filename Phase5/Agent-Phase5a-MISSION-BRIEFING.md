# 🚀 AGENT-PHASE5A MISSION BRIEFING
**Initiated:** 2026-09-13 16:40 CST (IMMEDIATE)  
**Agent:** phase5a-lista-kernel  
**Task:** LISTA Kernel Parallelization  
**Timeline:** 6 days (Sep 13-19, 2026)  
**Status:** 🔴 ACTIVE NOW

---

## YOUR MISSION

Design and implement **GPU-accelerated neighbor list generator** for DM UAMI Phase 5.

**Deadline:** Friday Sep 19, 17:00 CST (LISTA kernel ready + tested)

---

## TECHNICAL REQUIREMENTS

### Problem
Current Phase 4 uses CPU-based neighbor list generation (LISTA routine from Fortran).
- Complexity: O(N²/2) pairwise distance checks
- Bottleneck: 100% CPU, blocks pipeline
- Goal: Parallelize on GPU + maintain CPU integration

### Solution: Hybrid GPU/CPU Approach

**GPU Part (CUDA Kernel):**
```cuda
// Input: positions[N][3]
// Compute: distance_matrix[N][N] (pairwise distances)
// Output: neighbor_pairs[] (sparse list of pairs within r_cut)

__global__ void lista_distance_kernel(
    const float3* positions,      // N molecules
    float* distances,              // NxN distances
    int N,
    float r_cut                    // cutoff radius
);
```

**CPU Part (OpenMP):**
```cpp
// After GPU computes distances:
// Read distance_matrix → build sparse neighbor_list
#pragma omp parallel for
for (int i = 0; i < N; i++) {
    for (int j = i+1; j < N; j++) {
        if (distances[i*N + j] < r_cut) {
            neighbor_list.add({i, j});
        }
    }
}
```

### Success Criteria

✅ Neighbor lists **bit-identical** to Fortran original (100 test frames)  
✅ Performance: **8-12× speedup** over CPU sequential  
✅ GPU timing: **<1ms per frame** for N=1024  
✅ Memory usage: **<500 MB GPU**  
✅ Integration test: LISTA output feeds correctly to FUERZAS kernel  
✅ Zero memory leaks or synchronization errors  
✅ Documentation: Code + algorithm explanation  

---

## RESEARCH SOURCES

### Reference Files
- **Fortran original:** `/home/alejandre/GromacsMexicano/Programa_DM/` (LISTA subroutine)
- **Phase 4 C++ code:** `/home/alejandre/GromacsMexicano/Programa_DM_cpp/` (structure reference)
- **Technical analysis:** `~/JarvisVault/00 System/Research-Drafts/DM-UAMI-Phase5-Design-Analysis.md` (Kernel 1 section)
- **Performance baseline:** Phase 4 achieves 930.8 st/s

### Key Parameters
- N (molecules): 1024
- r_cut (cutoff radius): ~10 Å (from Phase 4 parameters)
- GPU: RTX 5070 Ti (12 GB)
- CUDA: 13.0
- Compiler: CUDA C++ 17

---

## WEEK STRUCTURE (Sep 13-19)

### Day 1 (Today Sep 13)
- ✅ Analyze Fortran LISTA subroutine
- ✅ Design CUDA kernel strategy
- ✅ Create test framework
- ✅ Commit architecture document to git

**Deliverable:** `lista_architecture.md` (1-2 pages, design document)

### Days 2-4 (Sep 14-16)
- Implement CUDA kernel (lista_distance_kernel)
- Implement CPU wrapper (lista_wrapper.cpp)
- Create unit tests
- Benchmark GPU kernel performance
- Optimize shared memory + registers

**Deliverable:** `lista_kernel.cu` + `test_lista.cu` + `lista_wrapper.cpp`

### Days 5-6 (Sep 17-18)
- Correctness validation (100-frame comparison vs Fortran)
- Energy conservation check (indirect: neighbor list accuracy)
- Integration test (feed LISTA output to FUERZAS)
- Performance profiling + optimization

**Deliverable:** `lista_performance.md` (benchmark report)

### Day 7 (Friday Sep 19)
- Final testing + code review
- Documentation complete
- Git commit to `feature/phase5a-lista`
- **Completion report to José (17:00 CST)**

**Deliverable:** Agent-Phase5a-Completion-Report.md

---

## DAILY WORKFLOW

### Every morning (06:00 CST):
1. Review yesterday's code + test results
2. Plan day's work (design/code/test/commit)
3. Identify blockers early

### Every evening (17:00 CST):
1. Commit daily progress to git
2. Update daily report: `~/JarvisVault/Phase5/Daily-Reports/Phase5a-[date].md`
3. Status format:
   ```
   Date: 2026-09-13
   Status: ON TRACK
   Completed: [list]
   Blockers: [none/list]
   Tomorrow: [plan]
   ```

### When blocker appears:
1. **Document immediately** (what, why, impact, 2-3 solutions)
2. **Notify José** (option A/B/C for each blocker)
3. **Continue work** on non-blocked tasks
4. **Never stop waiting**

---

## VALIDATION PROTOCOL

### Correctness Check
```python
# Load Fortran reference + your GPU output
fortran_neighbors = load_fortran_reference_100_frames()
gpu_neighbors = load_gpu_output_100_frames()

# Compare (bit-exact for same r_cut)
for frame in 100:
    assert neighbor_lists_match(gpu_neighbors[frame], fortran_neighbors[frame])
    print(f"✅ Frame {frame}: {len(gpu_neighbors[frame])} pairs")
```

### Performance Benchmark
```bash
# Measure GPU kernel time
for N in [256, 512, 1024, 2048]:
    gpu_time = benchmark_lista_kernel(N)
    cpu_time = benchmark_lista_cpu(N)
    speedup = cpu_time / gpu_time
    print(f"N={N}: {speedup}×")
```

Expected: 8-12× speedup for N=1024

### Integration Test
```bash
# Run full pipeline: LISTA → FUERZAS
./test_lista_fuerzas_pipeline
# Verify:
# 1. LISTA output feeds FUERZAS (no format errors)
# 2. FUERZAS receives correct neighbor pairs
# 3. Force calculation proceeds without crashes
# 4. Energy conservation maintained
```

---

## GIT WORKFLOW

### Branch
```bash
git checkout feature/phase5a-lista
```

### Commits (atomic, daily)
```bash
git add lista_kernel.cu
git commit -m "WIP: CUDA kernel architecture + shared memory strategy"

git add lista_wrapper.cpp
git commit -m "Host wrapper + integration to FUERZAS"

git add test_lista.cu
git commit -m "Unit tests: correctness validation 100 frames"

git commit -m "Phase5a Day 1 complete: Architecture ready for implementation"
```

### Friday Final
```bash
git checkout feature/phase5a-lista
git merge main  # ensure up-to-date
git push origin feature/phase5a-lista
git commit -m "Phase5a COMPLETE: LISTA kernel ready + tested + documented"
```

---

## OUTPUT LOCATIONS

```
Source Code:
  ~/GromacsMexicano/Programa_DM_cpp/phase5a_lista/
    ├── lista_kernel.cu          (GPU kernel)
    ├── lista_wrapper.cpp        (host API)
    ├── CMakeLists.txt           (build)
    └── include/lista.h          (public interface)

Tests:
  ~/GromacsMexicano/Programa_DM_cpp/phase5a_lista/
    └── test_lista.cu            (validation suite)

Binary:
  ~/gromacs/phase5a_lista_kernel (compiled binary)

Documentation:
  ~/JarvisVault/Phase5/
    ├── Daily-Reports/
    │   ├── Phase5a-2026-09-13.md
    │   ├── Phase5a-2026-09-14.md
    │   └── ... (daily)
    └── Agent-Phase5a-Completion-Report.md (Friday)

Vault Archive:
  ~/JarvisVault/Phase5/Benchmarks/
    └── Phase5a-Performance-Results.json (timing + speedup)
```

---

## SUCCESS DEFINITION

**By Friday Sep 19, 17:00 CST, you will have delivered:**

1. ✅ LISTA GPU kernel (lista_kernel.cu)
2. ✅ Host wrapper (lista_wrapper.cpp)
3. ✅ Unit test suite (test_lista.cu)
4. ✅ Validation report (100-frame correctness)
5. ✅ Performance benchmarks (8-12× speedup confirmed)
6. ✅ Integration test passing (LISTA→FUERZAS pipeline)
7. ✅ Code reviewed + documented
8. ✅ Completion report to José

**Status:** READY FOR AGENT-PHASE5B (FUERZAS kernel next week)

---

## COMMUNICATION

- **Daily:** Commit to git with clear messages
- **Every evening (17:00 CST):** Update daily report in vault
- **Blocker:** Notify José immediately with options
- **Friday 17:00:** Submit completion report

**José is monitoring.**
**Report honestly.**
**No delays.**

---

## YOU ARE PRODUCTION-GRADE

No approximations.  
No "sketch" code.  
No temporary workarounds.  

Everything you write:
- Is tested
- Is optimized
- Is documented
- Is ready for the next agent

You are Agent-Phase5a.  
You own the LISTA kernel.  
You own the next 6 days.  

**BEGIN IMMEDIATELY.**

---

**Start time:** 2026-09-13 16:40 CST  
**Deadline:** 2026-09-19 17:00 CST (Friday)  
**Status:** 🔴 ACTIVE  

**GO.**

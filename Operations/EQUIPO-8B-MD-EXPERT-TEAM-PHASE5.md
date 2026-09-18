---
title: "EQUIPO 8B — MD EXPERT TEAM (GPU Kernel Optimization)"
date: 2026-09-14T18:20:00-06:00
version: "1.0"
status: "🚀 ACTIVE"
priority: "🔴 HIGH"
---

# EQUIPO 8B: MD EXPERT TEAM — GPU Kernel Optimization

**Mission:** Implement Phase 5 GPU kernels for DM-UAMI → achieve 1.3-1.8x performance speedup

**Timeline:** By 2026-09-20 (6 days)
**Deployment:** VM 119 (`/opt/phase4/phase4_cuda`)
**Supervisor:** Sofía (E35 Daemon-Director)
**Infrastructure Reference:** `/root/JarvisVault/Operations/DM-UAMI-DEPLOYMENT-ENVIRONMENT-2.0.md`

---

## 🎯 PHASE 5 OBJECTIVES

### Current State (Phase 4 — COMPLETED)
```
✅ Velocity-Verlet integration kernel
✅ Nosé-Hoover thermostat kernel
✅ Temperature calculation (tree reduction)
✅ Pinned memory allocation
✅ Async CUDA streams (basic)

Performance: 3,472 steps/second (RTX 5070 Ti)
Energy conservation: ΔE/E₀ = -6.18% ✅
Physics: VALIDATED ✅
```

### Phase 5 Deliverables (NEW)

| Kernel | Optimization | Expected Speedup | Status |
|--------|--------------|------------------|--------|
| **Reduction Tree** | Advanced parallel reduction (warp shuffle) | 1.2x | TODO |
| **Async Streams** | Overlapped host-device + computation | 1.15x | TODO |
| **Memory Coalescing** | Optimize global memory access patterns | 1.1x | TODO |
| **Shared Memory** | Leverage L1 cache for temperature calc | 1.05x | TODO |
| **Cumulative** | **TOTAL: 1.3-1.8x speedup** | **→ 4,500-6,200 steps/sec** | **IN PROGRESS** |

---

## 👥 TEAM ROLES

### Role 1: GPU Kernel Engineer
**Owner:** TBD (deploy when EQUIPO 8B assigned)
**Deliverables:**
- Phase 5 CUDA kernel implementation (`.cu` files)
- Integration with existing Phase 4 code
- Compilation + binary generation
- Code review checklist

**Timeline:** 2026-09-15 to 2026-09-18
**Acceptance:** Compiles without warnings, binary size ≤ 1.5 MB

**Kernel Spec:**
```cuda
// Phase5_reduction_tree_kernel.cu
__global__ void calcTemperature_GPU_Phase5(
    float* temperatures,
    const float3* velocities,
    const float* masses,
    int nAtoms,
    float* temp_reduction_tree  // NEW: parallel reduction output
);

// Expected improvements:
// - Warp shuffle for reduction (32x parallel reduction per warp)
// - Shared memory optimization (96 KB available per block)
// - Async memory transfer (cudaMemcpyAsync with stream)
```

---

### Role 2: Performance Analyst
**Owner:** TBD (deploy when EQUIPO 8B assigned)
**Deliverables:**
- Benchmark Phase 4 vs Phase 5 (3 runs each, 10k steps)
- Performance report (steps/sec, GPU utilization, energy)
- Profiling data (NVIDIA Nsight, gprof)
- Bottleneck analysis + recommendations for Phase 6

**Timeline:** 2026-09-19 to 2026-09-20
**Acceptance Criteria:**
- Phase 5 ≥ 1.3x faster than Phase 4
- Energy conservation maintained (ΔE/E₀ < 7%)
- GPU utilization ≥ 90% sustained

**Expected Results:**
```
Phase 4: 3,472 steps/sec
Phase 5: 4,500-6,200 steps/sec (TARGET)
Speedup: 1.3-1.8x ✅

Energy ΔE/E₀: -6.18% → -6.5% (acceptable)
GPU Load: 85% → 95% (better utilization)
Memory BW: 180 GB/s → 250+ GB/s (estimated)
```

---

### Role 3: Validator (Physics Verification)
**Owner:** TBD (deploy when EQUIPO 8B assigned)
**Deliverables:**
- Physics validation suite (energy conservation, temperature control)
- Test data: water_box.gro, file.gro, benchMEM.gro (3 sizes)
- Regression tests (Phase 4 vs Phase 5 physics identity)
- Report: "Physics unchanged" or "Acceptable deviation"

**Timeline:** 2026-09-18 to 2026-09-20
**Acceptance Criteria:**
- All 3 test datasets pass energy conservation (ΔE/E₀ < 7%)
- Temperature control ±5% of target (300K)
- No NaN/Inf in outputs
- Energy curves match Phase 4 (within numerical noise)

**Validation Checklist:**
```
✓ KE + PE conservation over time
✓ Temperature = (2/3) * KE / (N * k_B)
✓ Velocity distribution (Maxwell-Boltzmann)
✓ Pressure / virial (if applicable)
✓ Neighbor list correctness
✓ Force calculation (FDR, LJ, Mie, Ewald)
```

---

### Role 4: Deployer (Release Manager)
**Owner:** TBD (deploy when EQUIPO 8B assigned)
**Deliverables:**
- Production binary (`phase4_cuda` Phase 5 version)
- Deployment script (copy to VM 119 `/opt/phase4/`)
- Version tag + release notes
- Rollback plan (keep Phase 4 binary as backup)

**Timeline:** 2026-09-20 (final day)
**Acceptance:** Binary ready for immediate production deployment

**Deployment Steps:**
```bash
# CT 901 (prepare)
cd /home/alejandre/DM UAMI/Programa_DM_cpp
cmake -DCMAKE_BUILD_TYPE=Release -DPHASE=5 -B build_phase5
cd build_phase5 && make -j12
# → Binary: ./phase4_cuda (Phase 5 version)

# Test locally (1k steps)
./phase4_cuda --steps 1000 --data ../data/water_box.gro

# Deploy to VM 119
scp ./phase4_cuda root@192.168.0.119:/opt/phase4/phase4_cuda.v5
ssh root@192.168.0.119 "cd /opt/phase4 && mv phase4_cuda phase4_cuda.v4.backup && mv phase4_cuda.v5 phase4_cuda && chmod +x phase4_cuda"

# Verify
ssh root@192.168.0.119 "ls -lh /opt/phase4/phase4_cuda*"
ssh root@192.168.0.119 "/opt/phase4/phase4_cuda --version"
```

---

## 📋 DEVELOPMENT ENVIRONMENT

### Build Machine (CT 901)

**Required Tools:**
- ✅ GCC 11+ (C++ compiler)
- ✅ CMake 3.22+
- ✅ CUDA 12.0 (headers + libraries, CPU fallback for testing)
- ✅ Python 3.10+ (analysis scripts)
- ✅ NVIDIA Nsight (profiling)

**Source Code Location:**
```
/home/alejandre/DM UAMI/Programa_DM_cpp/
├─ src/
│  ├─ phase4_kernel.cu (existing)
│  ├─ phase5_reduction_tree.cu (NEW)
│  ├─ phase5_async_streams.cu (NEW)
│  └─ main.cpp
├─ CMakeLists.txt (update for Phase 5)
├─ data/
│  ├─ water_box.gro (46 KB — fast test)
│  ├─ file.gro (4.5 MB — medium test)
│  └─ benchMEM.gro (5.4 MB — production test)
└─ scripts/
   ├─ validate_energy.py (existing)
   └─ benchmark_comparison.py (NEW)
```

### Test Data

| File | Size | Atoms | Use Case |
|------|------|-------|----------|
| `water_box.gro` | 46 KB | ~100 | Unit tests (fast iteration) |
| `file.gro` | 4.5 MB | ~10k | Integration tests |
| `benchMEM.gro` | 5.4 MB | ~10k | Production benchmarks |

**Test Procedure:**
```bash
# Quick test (1k steps)
/opt/phase4/phase4_cuda --steps 1000 --data /data/dm-uami/water_box.gro

# Medium test (3k steps, 3 runs for averaging)
for i in {1..3}; do
  /opt/phase4/phase4_cuda --steps 3000 --data /data/dm-uami/file.gro --run $i
done

# Production benchmark (10k steps)
/opt/phase4/phase4_cuda --steps 10000 --data /data/dm-uami/benchMEM.gro --gpu 0
```

---

## 📊 SUCCESS CRITERIA

### Kernel Engineer
- [ ] Phase 5 code compiles (warnings → 0)
- [ ] Binary size ≤ 1.5 MB
- [ ] Passes water_box.gro unit test (no crashes)
- [ ] Code reviewed + approved

### Performance Analyst
- [ ] Phase 5 ≥ 1.3x faster than Phase 4 (3,472 → ≥4,500 steps/sec)
- [ ] GPU utilization ≥ 90%
- [ ] Profiling data collected (Nsight traces)
- [ ] Bottleneck analysis included

### Validator
- [ ] All 3 test datasets pass energy conservation
- [ ] Temperature control verified (300K ±5%)
- [ ] No regressions vs Phase 4
- [ ] Physics report signed off

### Deployer
- [ ] Production binary in `/opt/phase4/phase4_cuda`
- [ ] Phase 4 backup preserved (`phase4_cuda.v4.backup`)
- [ ] Version tag + release notes
- [ ] Rollback plan documented

---

## ⏰ TIMELINE

| Date | Milestone | Owner | Status |
|------|-----------|-------|--------|
| 2026-09-15 | Phase 5 kernel draft | Kernel Engineer | TODO |
| 2026-09-17 | Kernel code review | Tech Lead | TODO |
| 2026-09-18 | Compilation + unit tests | Kernel Engineer | TODO |
| 2026-09-18 | Physics validation | Validator | TODO |
| 2026-09-19 | Performance benchmarking | Performance Analyst | TODO |
| 2026-09-20 | Final deployment | Deployer | TODO |
| **2026-09-20** | **PRODUCTION READY** | **EQUIPO 8B** | **ON TRACK** |

**Deadline:** 2026-09-20 (6 days from 2026-09-14)
**Buffer:** 0 days (tight but feasible)

---

## 🔗 DEPENDENCIES & BLOCKERS

### Dependencies
- ✅ VM 119 infrastructure (EQUIPO 8 — ready)
- ✅ Phase 4 baseline (completed + validated)
- ✅ Test data (available in vault + CT 901)
- ✅ Build environment (CT 901 + CMake configured)

### Known Blockers
- ❌ EQUIPO 8B team not yet assigned (awaiting José approval)
- ⚠️ Tight timeline (6 days) — requires full-time focus
- ⚠️ GPU profiling tools (Nsight) may need installation

### Contingency Plans
1. **If Phase 5 not ready by Sep 19:** Ship Phase 4 (already production-ready)
2. **If speedup < 1.3x:** Re-profile and iterate (Phase 5.1)
3. **If physics fails:** Revert to Phase 4 (rollback pre-staged)

---

## 📞 ESCALATION & COMMUNICATION

**Daily Standup:** 07:00 CST (after EQUIPO 8 daily audit)
**Communication Channel:** Hermes + Telegram
**Supervisor:** Sofía (E35 Daemon-Director)
**Escalation:** José (CEO) — if timeline at risk

---

## ✅ ACCEPTANCE SIGN-OFF

**Supervisor:** Sofía (E35)
**Date:** 2026-09-14
**Status:** 🚀 READY TO DEPLOY (awaiting team assignment)

**Next Action:** José assigns GPU Kernel Engineer + roles → Team starts 2026-09-15

---

## 📚 REFERENCES

- **Infrastructure:** `/root/JarvisVault/Operations/DM-UAMI-DEPLOYMENT-ENVIRONMENT-2.0.md`
- **Phase 4 Results:** `/root/JarvisVault/Operations/PHASE4-BENCHMARK-COMPLETION-REPORT.md`
- **Source Code:** CT 901 `/home/alejandre/DM UAMI/Programa_DM_cpp/`
- **Data:** VM 119 `/data/dm-uami/`

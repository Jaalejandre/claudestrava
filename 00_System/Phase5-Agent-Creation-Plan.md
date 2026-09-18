# 🚀 PHASE 5 AGENT CREATION PLAN
**Created:** 2026-09-13 15:45 CST  
**For:** DM UAMI Phase 5 Parallelization  
**Timeline:** Week 1-4 (Sep 15 - Oct 12)

---

## 4 SPECIALIZED AGENTS (Serial Execution)

### AGENT 1: Phase5a — LISTA Kernel Parallelization
**Duration:** Sep 15-21 (Week 1)  
**Output:** GPU-accelerated neighbor list generator

**Responsibilities:**
1. Analyze Fortran LISTA subroutine (cutoff radius, pair detection logic)
2. Design hybrid GPU/CPU strategy:
   - GPU: CUDA kernel for distance matrix computation
   - CPU: OpenMP for neighbor list construction from distances
3. Implement CUDA kernel:
   - Block size tuning for N=1024 molecules
   - Shared memory strategy for distance caching
   - Warp-level reduction for pair detection
4. Test:
   - Correctness: Compare neighbor lists vs Fortran (100 frames)
   - Performance: Measure GPU + PCIe transfer time
   - Integration: Feed output to FUERZAS kernel
5. Deliver:
   - Source code (lista_kernel.cu + host wrapper)
   - Benchmark report (speedup vs Fortran)
   - Integration test passing

**Success Criteria:**
- ✅ Neighbor lists bit-identical to Fortran
- ✅ 8-12× speedup over CPU sequential
- ✅ <1ms per frame for N=1024
- ✅ Memory: <500 MB GPU usage

---

### AGENT 2: Phase5b — FUERZAS Kernel Optimization
**Duration:** Sep 22-28 (Week 2)  
**Output:** Optimized 7-case LJ force calculator

**Responsibilities:**
1. Analyze Fortran FUERZAS routine:
   - 7 force calculation branches (distance-dependent)
   - Current performance bottlenecks
   - Optimization opportunities (SIMD, register tiling)
2. Design GPU optimization:
   - Eliminate branch divergence (compute all 7 cases, mask)
   - Thread-per-pair strategy (1 warp = 32 pairs)
   - Register tiling (8 pairs per thread, 4 iterations)
3. Implement CUDA kernel:
   - Vectorized arithmetic (4-wide float operations)
   - Shared memory for coalesced loads
   - Warp shuffles for force reduction
4. Test:
   - Correctness: Energy conservation (1e-10 tolerance)
   - Performance: Peak TFLOP/s utilization
   - Integration: Combine with LISTA output
5. Deliver:
   - Source code (fuerzas_kernel.cu)
   - Roofline performance analysis
   - Combined LISTA+FUERZAS timing

**Success Criteria:**
- ✅ All 7 force cases validated
- ✅ Energy conservation within tolerance
- ✅ 30-50× speedup over CPU loop
- ✅ GPU utilization >70%

---

### AGENT 3: Phase5c — KWALD Stream Parallelization
**Duration:** Sep 29-Oct 5 (Week 3)  
**Output:** Asynchronous Ewald calculation with triple-buffering

**Responsibilities:**
1. Analyze current KWALD implementation:
   - Real space kernel (already GPU-optimized)
   - Reciprocal space convolution (slow on GPU)
   - Synchronization points (inefficient)
2. Design stream-level parallelism:
   - Stream 0: Real space kernel (r < r_cut sums)
   - Stream 1: Reciprocal space (3D convolution or FFT)
   - Stream 2: PCIe transfers (frame N+1 positions)
3. Implement async execution:
   - Persistent kernels (avoid launch overhead)
   - Triple-buffering: Process frame N, transfer N+1, prep N+2
   - Minimize cudaDeviceSynchronize() calls
4. Test:
   - Electrostatic forces match Fortran
   - Timeline overlap effectiveness (measure stall time)
   - Peak GPU utilization (should >80%)
5. Deliver:
   - Refactored KWALD kernel (async-safe)
   - Timing breakdown (real/recip/transfer)
   - Bottleneck analysis report

**Success Criteria:**
- ✅ Async execution reduces idle time by 20%+
- ✅ Electrostatic forces validated
- ✅ Peak PCIe bandwidth utilization >50%
- ✅ Full 3-kernel pipeline verified

---

### AGENT 4: Phase5d — Integration & Validation
**Duration:** Oct 6-12 (Week 4)  
**Output:** Final Phase 5 release v1.1 + publication package

**Responsibilities:**
1. Integrate all 3 kernels:
   - Combine LISTA → FUERZAS → KWALD pipeline
   - Ensure data flow (positions → neighbors → forces → energies)
   - Verify no memory leaks or synchronization issues
2. Comprehensive validation:
   - 1000-step MD simulation vs original Fortran (UAMI dataset)
   - Energy conservation (global statistics)
   - Temperature stability (Nosé-Hoover thermostat)
   - Pressure (if NPT ensemble enabled)
3. Performance benchmarking:
   - Scaling test: N=256, 512, 1024, 2048 (if GPU memory allows)
   - Strong scaling: GPU only vs CPU+GPU
   - Weak scaling: Measure efficiency per particle
4. Code cleanup:
   - Remove debug code, optimize register usage
   - Add inline documentation for publication
   - Create build system (CMake finalization)
5. Deliver:
   - Phase 5 v1.1 binary (production-ready)
   - Publication-ready documentation (algorithms, performance)
   - UAMI release notes
   - Test suite (regression + validation)

**Success Criteria:**
- ✅ 1000-step run matches Fortran energy within 1e-8 kcal/mol
- ✅ Overall speedup ≥1200 steps/sec (30% gain over Phase 4)
- ✅ GPU memory peak <8 GB
- ✅ Code reviewed + documentation complete

---

## EXECUTION MODEL

### Serial Execution (as José prefers)

```
Week 1 (Sep 15-21):
  Agent-Phase5a starts Monday
  ├─ Day 1-2: Design + code review
  ├─ Day 3-4: CUDA kernel implementation
  ├─ Day 5: Integration test + timing
  └─ Friday: DELIVERABLE (neighbor list kernel ready)

Week 2 (Sep 22-28):
  Agent-Phase5a completes → Agent-Phase5b starts
  ├─ Day 1-2: FUERZAS kernel design
  ├─ Day 3-4: CUDA + tuning
  ├─ Day 5-6: Energy validation
  └─ Friday: DELIVERABLE (forces kernel optimized + tested)

Week 3 (Sep 29-Oct 5):
  Agent-Phase5b completes → Agent-Phase5c starts
  ├─ Day 1-2: Stream architecture design
  ├─ Day 3-4: Async implementation
  ├─ Day 5: Performance profiling
  └─ Friday: DELIVERABLE (async execution working)

Week 4 (Oct 6-12):
  Agent-Phase5c completes → Agent-Phase5d starts
  ├─ Day 1-2: Full integration testing
  ├─ Day 3-4: Validation suite execution
  ├─ Day 5-6: Performance benchmarking
  └─ Friday: DELIVERABLE (Phase 5 v1.1 final release)
```

### Parallel Safety Measures

**Even though agents run sequentially:**
- Each agent's output is tested before next agent starts
- No code merge conflicts (each agent owns 1-2 files)
- Performance regression testing gates each phase
- Rollback procedure if issue found

---

## RESOURCE ALLOCATION

| Resource | Allocation | Status |
|----------|-----------|--------|
| **GPU (RTX 5070 Ti)** | Dedicated to Phase 5 agents | ✅ Available |
| **CPU (CT 901, 12 core)** | Shared (agents use 4 cores max) | ✅ Available |
| **Memory (24 GB system)** | 8 GB reserved for Phase 5 work | ✅ Available |
| **Storage (100 GB)** | 2 GB for builds + logs | ✅ Available |
| **Network (Proxmox)** | Standard (git push, small data) | ✅ Available |

---

## HANDOFF PROTOCOL

Each agent delivers to José:

**Deliverable Format:**
```
📊 Agent-Phase5X COMPLETION REPORT
Date: [date]
Agent: [name]
Status: ✅ COMPLETE

WHAT WAS DONE:
- [task 1 completed]
- [task 2 completed]
- [test results]

PERFORMANCE:
- Speedup: X×
- GPU utilization: Y%
- Memory usage: Z MB

ARTIFACTS:
- Binary: /path/to/phase5x_kernel
- Source: GitHub commit [hash]
- Test results: /path/to/results.json
- Documentation: /path/to/README.md

NEXT STEP:
- [Ready for next agent]
- [Potential blockers]
- [Recommendations]
```

**Approval Gate:**
José reviews → Approves or requests revision → Agent proceeds to next phase

---

## GO-LIVE CHECKLIST

Before Phase 5 starts Monday:

- [ ] Agent-Phase5a created + configured
- [ ] GPU node verified (CUDA working)
- [ ] Git branches ready (feature/phase5a, etc.)
- [ ] Fortran reference code accessible
- [ ] Baseline benchmarks recorded
- [ ] Test suite framework prepared
- [ ] Notification system live (daily reports)

---

## SUMMARY

**4 specialized agents, 4 weeks, 3 kernels parallelized, 30% speedup target.**

Each agent owns a specific kernel + its tests. Sequential execution prevents interference. Clear handoff protocol. Production-ready release by early October.

**Status:** ✅ PLAN READY FOR APPROVAL

---

**Next:** José approves → Agents created + started Monday Sep 15 at 06:00 CST

# 🔬 DM UAMI RESEARCH SESSION
**Created:** 2026-09-13 15:35 CST  
**Bots:** Orchestrator-Bot, Researcher-Bot, Librarian-Bot  
**Purpose:** Analyze Fortran original + Phase 4 C++ → Design Phase 5 (Parallelization)

---

## SESSION WORKFLOW

### STEP 1: Initial Greeting (Verify Communication)
**Send to group:**
```
Everyone, say hi and give me your favourite colour. 
Then @orchestrator, tell me each Bot's favourite colour.
```

### STEP 2: Research Task (Main Analysis)
**Send to group:**
```
@orchestrator, research and analyze the following:

TASK: Design GPU/CPU parallelization strategy for DM UAMI Phase 5

SOURCES:
1. /home/alejandre/DM UAMI/Programa_DM/ (Fortran original)
2. /home/alejandre/DM UAMI/Programa_DM_cpp/ (Phase 4 C++)
3. Phase 4 Performance data (930.8 st/s baseline)
4. Architecture: RTX 5070 Ti, CT 901, CUDA 13.0

DELIVERABLE: Analysis report <500 words with citations

FOCUS AREAS:
- Kernel 1: Neighbor List (dependencia, complexity)
- Kernel 2: Fuerzas (7 cases LJ, GPU optimization)
- Kernel 3: Kwald/Ewald (O(N²) vs SPME O(N ln N))
- Parallelization strategy (GPU streams, CPU threads)
- Testing validation approach
- Timeline estimate for each kernel

DELEGATION:
1. @researcher: Read source code + create detailed analysis
2. @orchestrator: Review + create architecture diagram
3. Ask before involving @librarian

REQUEST ONE FOCUSED REVISION if needed.
```

### STEP 3: Approval Gate 1 (Handoff to Wiki)
**After researcher completes:**
```
@orchestrator, I approve handoff. Move this report to:
~/JarvisVault/00 System/Research-Drafts/DM-UAMI-Phase5-Design.md

Ask @librarian-bot to run llm-wiki-review. Hold Wiki changes for my approval.
```

### STEP 4: Approval Gate 2 (Finalize)
**After librarian proposes Wiki:**
```
[Inspect proposed content, then choose:]

APPROVE:
@orchestrator, approve librarian-bot's Wiki proposal. Execute all changes.

OR REVISE:
@orchestrator, ask librarian-bot to:
[specific revision requests]

OR DEFER:
@orchestrator, defer Wiki publishing. Save draft and re-review tomorrow.
```

### STEP 5: Save Preferences
**At end:**
```
@orchestrator, save useful operating preferences from this session 
to built-in memory, not research claims. Tell me what changed.
```

---

## RESEARCH QUESTIONS FOR BOTS

When you analyze, answer these:

### About Neighbor List (Kernel 1)
- [ ] What data structures does Fortran use?
- [ ] How is the cutoff radius enforced?
- [ ] Can this be GPU-parallelized? (yes/no + why)
- [ ] Expected speedup if parallelized?
- [ ] Complexity: O(?) in Fortran, expected O(?) on GPU

### About Fuerzas (Kernel 2)
- [ ] How many distinct force calculation cases in Fortran?
- [ ] Which are parallelizable (GPU)?
- [ ] Memory bandwidth requirements?
- [ ] Can we batch calculations (SoA vs AoS)?
- [ ] Current bottleneck: compute or memory?

### About Kwald/Ewald (Kernel 3)
- [ ] Current implementation: O(N²) direct sum?
- [ ] Breakdown: Real space + Reciprocal space costs?
- [ ] SPME feasibility: Worth it for N=1024?
- [ ] CUFFT 3D dependency: Already in toolkit?
- [ ] Phase 5 goal: Keep O(N²) or upgrade to O(N ln N)?

### About Parallelization
- [ ] Independent tasks that can run in parallel?
- [ ] Data dependencies between kernels?
- [ ] GPU memory constraints (12GB)?
- [ ] CPU threading (OpenMP + CUDA)?
- [ ] Stream-level parallelization (async compute + transfer)?

### About Timeline
- [ ] Estimated dev time per kernel (Week 1/2/3)?
- [ ] Testing complexity per kernel?
- [ ] Validation approach vs original Fortran?
- [ ] Risk factors + mitigation?

---

## EXPECTED OUTPUT

Bots will produce:
1. **Architecture Analysis** (detailed breakdown of 3 kernels)
2. **Parallelization Strategy** (GPU/CPU approach for each)
3. **Implementation Plan** (Phase 5a/b/c timeline)
4. **Validation Checklist** (how to verify correctness)
5. **Risk Assessment** (blockers + mitigations)

Then saved to Wiki + linked in vault.

---

## READY FOR BOTS TO ANALYZE

Start with the research workflow above.

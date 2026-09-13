# PHASE 5 — LONG RUN TEST + error.dat VALIDATION
**Status:** PENDING (after parallelization complete)  
**Trigger:** Agent-Phase5a completion (Friday Sep 19)  
**Timeline:** Sep 20-22  

---

## PROTOCOL: Long Run Test

### PHASE 1: RUN SIMULATION
```
When: After all 3 kernels parallelized (Sep 19 completion)
Where: CT 901 (GPU)
Steps: 10,000 (or more for stability)
Config: Same as Phase 4 validation (NVE ensemble, Lennard-Jones)
Output: error.dat (energy/temp/pressure vs step)
```

### PHASE 2: EXTRACT error.dat
```
Location: ~/GromacsMexicano/Programa_DM_cpp/output/error.dat

Format:
  Step  Energy(eV)  KinE(eV)  PotE(eV)  Temp(K)  Press(bar)
  1     -1234.567   456.789   -1691.356 298.15   1.013
  2     -1234.521   456.801   -1691.322 298.20   1.015
  ...
  10000 -1234.489   456.775   -1691.264 298.18   1.012
```

### PHASE 3: VALIDATE PHYSICS
```
Look for:
  ✅ Energy oscillates around AVERAGE (not drifting up/down)
  ✅ Temperature stable ±2% around target
  ✅ Pressure fluctuates but stable mean
  ✅ Total energy conserved (ΔE < 0.1%)

Visual inspection:
  Plot 1: Total Energy vs Step (should be flat line ±noise)
  Plot 2: Temperature vs Step (should oscillate around 298K)
  Plot 3: Pressure vs Step (should be random around 1 bar)

If stable → Physics correct ✅
If drifting → Bug in parallelization ❌
```

---

## TEAM: Benchmark Validator Bot

Will automatically:
1. Read error.dat
2. Generate plots
3. Check oscillations
4. Report: Stable or Unstable
5. Send graphs to José

---

**Timeline:**
- Sep 19 (Fri): Phase 5a complete
- Sep 20-22 (Sat-Mon): Run long test + validate
- Sep 23 (Tue): Report results to José

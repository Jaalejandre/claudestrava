---
name: DM UAMI Parallelization Workflow
purpose: Systematic approach to parallelizing C++ MD code without rework
tags: [gromacs, openmp, c++, molecular-dynamics, parallelization]
date_created: 2026-09-12
---

# DM UAMI OpenMP Parallelization Workflow

**CRÍTICO:** Este flujo previene rework. Aplica para TODOS los proyectos futuros.

---

## 🎯 El Error que Cometimos Hoy

**Problema:** Delegué sin plan específico → Agente creó toy code → No funcionó con datos reales → Tiempo perdido.

**Raíz:** Saltamos Phase 2 (crear plan específico línea por línea).

---

## ✅ WORKFLOW CORRECTO (de aquí en adelante)

### **FASE 0: PRE-PLANIFICACIÓN (ANTES DE DELEGAR)**

#### Paso 0a: Identificar baseline funcional
- ❌ NO uses codebases nuevos o no testeados
- ✅ USA código que ya compila y ejecuta correctamente
- **NUESTRO baseline:** `Programa_DM_cpp_v1.1/build/dm_mx_npt` (verificado, 5.74s/10k pasos)
- **Verifica:** `./dm_mx_npt < /dev/null` → debe salir sin error

#### Paso 0b: Leer el código
**TÚ lo haces (no delegues esto):**

```bash
ssh alejandre@192.168.0.230 \
  "cd /home/alejandre/DM UAMI/Programa_DM_cpp_v1.1/src && \
   wc -l *.cpp && \
   grep -n 'for.*natoms\|for.*i < ' *.cpp | head -20"
```

Documenta:
- Lines of code por archivo
- Loops: dónde están, qué iteran, qué hacen
- Shared state: arrays de fuerzas, energías

#### Paso 0c: Baseline de validación física
Antes de modificar nada, corre 3 veces y guarda energías:

```bash
cd Programa_DM_cpp_v1.1/build
for run in 1 2 3; do
  ./dm_mx_npt
  tail -1 dm.log | tee baseline_run_$run.txt
done
```

Guardar energías en vault: `baseline_energies.txt`

---

### **FASE 1: ANÁLISIS (Fable)**

**Input a Fable (SÍ delegues esto):**

```
Analiza EXACTAMENTE estos archivos:
- /home/alejandre/DM UAMI/Programa_DM_cpp_v1.1/src/integrator.cpp (líneas X-Y)
- /home/alejandre/DM UAMI/Programa_DM_cpp_v1.1/src/forces.cpp (líneas A-B)
- /home/alejandre/DM UAMI/Programa_DM_cpp_v1.1/src/ewald.cpp (líneas P-Q)

Para CADA loop:
1. Número de línea exacto
2. Tipo: per-atom work, global reduction, etc.
3. Dependencias: qué lee, qué escribe
4. Race conditions: ¿múltiples threads escriben misma variable?
5. Pragma OpenMP ESPECÍFICO: el texto exacto #pragma omp parallel for ...
6. Speedup esperado: 1x, 2x, 4x?
7. Risk level: LOW, MEDIUM, HIGH

Entregar:
- integrator_analysis.md (pragmas para cada loop)
- forces_analysis.md
- ewald_analysis.md
```

---

### **FASE 2: PLAN ESPECÍFICO (TÚ lo haces)**

**Documento: PHASE1_IMPLEMENTATION_PLAN.md**

Formato EXACTO:

```markdown
## integrator.cpp

### Loop 1: velocityVerlet position update
- Location: Line 14-21
- Current code:
  ```cpp
  for (int i = 0; i < cfg.natoms; i++) {
      cfg.x[i] += cfg.vx[i] * dt;
      ...
  }
  ```
- Pragma to add: `#pragma omp parallel for schedule(static)`
- Risk: LOW (cada átomo es independiente)
- Expected speedup: 2-3× (4 cores)
- Validation: Energía Step 1000 debe coincidir con baseline ±0.01 kJ/mol

### Loop 2: noseHoover scaling
- Location: Line 50-52
- Current code: for (int i = 0; i < cfg.natoms; i++) { cfg.vx[i] *= lambda; ... }
- Pragma: `#pragma omp parallel for schedule(static)`
- Risk: LOW
- Expected speedup: 1.5×
- Validation: bit-identical output (same order of operations)

## forces.cpp

### Energy aggregation
- Location: Line 34-38
- Current: E += contribution[i] in loop
- Pragma: `#pragma omp parallel for reduction(+:E)`
- Risk: MEDIUM (race condition on E)
- Expected speedup: 2×
- Solution: reduction clause (thread-safe sum)

[... cada loop similar ...]

## Build config
- CMakeLists.txt: Ensure OpenMP flags present
- Command: cmake .. -DCMAKE_CXX_FLAGS="-O3 -fopenmp -march=native"
- Test size: 1000 steps (valida compilación antes de 10k)
```

**GENERA ESTO antes de delegar, NO hagas que el agente lo adivine.**

---

### **FASE 3: DELEGACIÓN (CON PLAN ESPECÍFICO)**

**Context a agente:**

```
Base: /home/alejandre/DM UAMI/Programa_DM_cpp_v1.1/
Binary funcional: build/dm_mx_npt
Test inputs: /home/alejandre/UAMI_Test/file.{gro,top,mdp}

PLAN ESPECÍFICO (ver PHASE1_IMPLEMENTATION_PLAN.md adjunto)

Tu trabajo:
1. Copy src/ → src_phase1_openmp/
2. Modifica CADA archivo según plan:
   - integrator.cpp: Insert pragma línea 14, línea 50
   - forces.cpp: Modify línea 34 (add reduction clause)
   - [... follow plan exactly ...]
3. Rebuild: cmake + make -j4
4. Test 1000 pasos: ./dm_mx_npt (debe terminar sin error)
5. Compara energy Step 1000:
   - Baseline energy: [X] kJ/mol
   - Phase 1 energy: should be within ±0.01 kJ/mol
6. Entrega:
   - src_phase1_openmp/ (modified code)
   - build/ con ejecutable
   - Log: timing + energy comparison
   - Diff: git diff o patch file

Si hay divergencia en energía: STOP, no continúes. Report el delta.
```

**NO DIGAS "implementa OpenMP"** — SAY "sigue este plan línea por línea".

---

### **FASE 4: VALIDACIÓN (TÚ lo haces)**

#### Test 1: Correctitud
```bash
# Baseline (ya hiciste esto en 0c)
cd Programa_DM_cpp_v1.1/build
baseline_energy=$(tail -1 dm.log | awk '{print $NF}')

# Phase 1
cd ../../PRODUCTION_v3_CPP/build
phase1_energy=$(tail -1 dm.log | awk '{print $NF}')

# Comparar
delta=$(echo "$baseline_energy - $phase1_energy" | bc)
if [ $(echo "$delta < 0.01" | bc) -eq 1 ]; then
  echo "✅ Energy match within tolerance"
else
  echo "❌ Energy diverged: $delta kJ/mol"
fi
```

#### Test 2: Performance
```bash
export OMP_NUM_THREADS=1
/usr/bin/time -v ./dm_mx_npt > /tmp/single.log

export OMP_NUM_THREADS=4
/usr/bin/time -v ./dm_mx_npt > /tmp/multi.log

echo "Speedup: $(awk '/Elapsed/{print $NF}' /tmp/single.log) / $(awk '/Elapsed/{print $NF}' /tmp/multi.log)"
```

#### Test 3: Reproducibilidad (CRÍTICO para MD)
```bash
export OMP_NUM_THREADS=4
./dm_mx_npt > run1.log
./dm_mx_npt > run2.log
./dm_mx_npt > run3.log

# Outputs deben ser BIT-IDÉNTICOS
diff run1.log run2.log
diff run2.log run3.log
# Si hay diferencias: reproducibilidad rota (agregar #pragma omp flush)
```

---

## 📋 CHECKLIST ANTES DE DELEGAR

- [ ] Working baseline compilado y testeado
- [ ] Baseline energies guardadas (3 runs)
- [ ] Code inventory completo (línea de cada loop)
- [ ] Fable analysis recibido (con pragmas específicos)
- [ ] PHASE1_IMPLEMENTATION_PLAN.md escrito (pragma by pragma)
- [ ] CMakeLists.txt listo (OpenMP flags)
- [ ] Test inputs disponibles
- [ ] Contexto a agente incluye EXACTAMENTE líneas y código

---

## 🎯 Aplicar a TODOS los proyectos

Esto no es solo para Gromacs. Próximas veces:
1. **Cualquier proyecto:** Baseline → Plan específico → Delegation → Validation
2. **Nunca:** "Implementa X" sin plan línea-por-línea
3. **Siempre:** Escribe el plan TÚ, no hagas que el agente lo cree

---

## 📁 Archivos a guardar en vault (post-completion)

```
(C) DM UAMI Phase 1 - Baseline energies.txt
(C) DM UAMI Phase 1 - Implementation plan.md
(C) DM UAMI Phase 1 - Code diffs.patch
(C) DM UAMI Phase 1 - Benchmark results.txt
(C) DM UAMI Phase 1 - Validation report.md
```

Update memory with:
- Baseline: 5.74s
- Phase 1: [time] ([speedup]×)
- Issues
- Next phase ready when...

---

**Resumen:** Hoy aprendimos por error. De aquí en adelante: ANÁLISIS → PLAN ESPECÍFICO → DELEGACIÓN → VALIDACIÓN.

# COMPARATIVA: Self-Improving Skills vs Claude Code vs Memento

## 📊 MATRIZ DE DECISIÓN (PARA HERMES)

```
╔════════════════════════════════════════════════════════════════════════════════╗
║         REPOSITORIO      │  INSTALABILIDAD  │  UTILIDAD   │  TIMING             ║
╠════════════════════════════════════════════════════════════════════════════════╣
║ self-improving-skills    │  ✅ INSTALADO    │  🟢 ALTO    │ ✅ IMMEDIATE (HOY)  ║
║ (monitoring loop)        │  (Python plugin) │  (skills)   │                     ║
╠════════════════════════════════════════════════════════════════════════════════╣
║ claude-code-best-practice│  ⚠️  REFACTOR    │  🟡 MEDIO   │ ⏳ DESPUÉS Phase 4  ║
║ (patterns + standards)   │  (update skills) │  (arch)     │  (~4 horas total)   ║
╠════════════════════════════════════════════════════════════════════════════════╣
║ Memento                  │  🟠 INTEGRACIÓN  │  🟡 MEDIO   │ 🔄 NEXT WEEK        ║
║ (memory + CI/CD)         │  (new modules)   │  (debug)    │  (phase 4 confirmed)║
╚════════════════════════════════════════════════════════════════════════════════╝
```

## 🎯 ANÁLISIS POR CASO DE USO (GROMACSMEXICANO)

### 1. AUTOCOMPILACIÓN (Phase 4 C++ Rewrite)

| Repo | Ayuda | Cómo | ROI |
|------|-------|------|-----|
| **self-improving** | ✅ YES | Audit skills si compilador cambia | Detección temprana |
| **claude-code** | ⚠️ MAYBE | Estructurar phase4-compiler agent | Legibilidad solo |
| **Memento** | ✅ YES | Guard past compile errors → instant fix next time | 30-40% faster debug |

### 2. BENCHMARK PHASE 4

| Repo | Ayuda | Cómo | ROI |
|------|-------|------|-----|
| **self-improving** | ❌ NO | Benchmark es artifact, no skill | N/A |
| **claude-code** | ❌ NO | Benchmark no es workflow | N/A |
| **Memento** | ❌ NO | Physics correctness no es learnable | N/A |

### 3. CONTINUOUS VALIDATION (Post-Benchmark)

| Repo | Ayuda | Cómo | ROI |
|------|-------|------|-----|
| **self-improving** | ✅ YES | Audit gromacs-development skill monthly | Skill health |
| **claude-code** | ✅ YES | /phase4-continuous-validation command | Native interface |
| **Memento** | ✅ YES | Remember physics checks → faster validation | Speedup |

## 🚀 RECOMENDACIÓN SECUENCIAL (JOSÉ)

### PASO 1: HOY (2026-09-13) ✅ DONE
- [x] Self-improving-skills instalado + activo
- [x] Análisis de repos completado
- [ ] Esperar GPU benchmark (10-15 min)

### PASO 2: HOY (Después Benchmark)
- [ ] Reportar speedup % + GitHub push
- [ ] Update memory + vault

### PASO 3: LUNES (2026-09-15)
- [ ] Apply claude-code patterns (light refactor, 2-3 horas)
  - Update SKILL.md: add when_to_use
  - Create .claude/commands/phase4-orchestrator.md
  - NO full refactor (preserve working code)

### PASO 4: NEXT WEEK (2026-09-20)
- [ ] Integrar Memento para CI/CD + debugging
- [ ] Initialize memory.jsonl for Phase 4
- [ ] Train parametric retriever (optional)

### PASO 5: ONGOING
- [ ] Weekly skill audit (self-improving-skills, Domingos 08:00)
- [ ] Monitor memory growth (Memento → cleanup when >1GB)
- [ ] Update .claude/commands/ for new workflows

---

## 💡 TRES HERRAMIENTAS, TRES ROLES

### self-improving-skills →監視 (Monitoring)
```
Role: Audit + detect skill degradation
When: Weekly (cron)
Output: Skill health report + auto-fixes (manual-only policy)
Best for: Continuous operations
```

### claude-code-best-practice → 建築 (Architecture)
```
Role: Define clean interfaces + declarative workflows
When: Refactor (quarterly)
Output: .claude/commands/ + Agent definitions
Best for: New projects + major features
```

### Memento → 学習 (Learning)
```
Role: Capture + replay past solutions
When: Ongoing (every execution)
Output: memory.jsonl + retrieval on demand
Best for: Debugging + CI/CD + repetitive tasks
```

---

## 🎓 KEY DECISION POINTS

### ¿Por qué instalar self-improving HOY?
✅ Zero refactor needed
✅ Runs in background (no blocking)
✅ Detects issues early (proactive monitoring)
✅ Complements Phase 4 certification

### ¿Por qué REFACTOR claude-code patterns después?
⚠️ Requires modification to existing skills
⚠️ Must test thoroughly (risk of breaking Phase 4)
⚠️ Nice-to-have, not critical
✅ After Phase 4 stable → safe to refactor

### ¿Por qué Memento NEXT WEEK?
❌ Not useful until Phase 4 is certified
❌ Requires training data (phase4_errors.jsonl)
❌ Integration takes time (2-3 days)
✅ Huge ROI for future debugging (CI/CD speedup)

---

## 📋 CHECKLIST: CUAL INSTALAR CUANDO

**TODAY (2026-09-13):**
- [x] self-improving-skills → Installed ✓

**AFTER GPU BENCHMARK:**
- [ ] GitHub push (manual unblock)
- [ ] Phase 4 certified "cien porciento"

**MONDAY (2026-09-15):**
- [ ] Adopt claude-code patterns (light)
  - [ ] Add `when_to_use` to top 5 skills
  - [ ] Create phase4-orchestrator command
  - [ ] Estimate: 2-3 hours

**WEDNESDAY (2026-09-17):**
- [ ] Memento design doc (do NOT install yet)
- [ ] Plan memory.jsonl schema for Phase 4

**NEXT WEEK (2026-09-20+):**
- [ ] Install Memento
- [ ] Train BM25 retriever (1 day)
- [ ] Optional: Train parametric retriever (2 days)

---

## RESPUESTA CORTA (PARA JOSÉ)

**¿Instalar claude-code-best-practice + Memento HOY?**

**NO.** Secuencia:

1. ✅ self-improving → INSTALLED
2. ⏳ GPU benchmark → AWAIT RESULTS
3. 🔧 Claude-code patterns → LUNES (light refactor only)
4. 📚 Memento → NEXT WEEK (after Phase 4 stable)

**Why?** Reduce risk + maximize ROI + respect your "no parrelo" rule.

**ROI summary:**
- self-improving: 10% efficiency gain (monitoring)
- claude-code: 5% efficiency gain (clarity) + long-term maintainability
- Memento: 30% efficiency gain (debugging) — pero AFTER Phase 4

Total expected: 45% efficiency improvement over 3 weeks (Phase 4 stable + CI/CD faster)


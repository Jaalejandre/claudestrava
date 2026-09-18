# Claude Code Best Practice - Análisis Completo

## 📊 REPOSITORIO OVERVIEW
**shanraisshan/claude-code-best-practice** (65.8K ⭐, MIT license)

### Objetivo
"from vibe coding to agentic engineering - practice makes claude perfect"
→ Reference implementation de patrones avanzados para Claude Code

### Estructura
```
root/
├── .claude/              # Claude Code workspace config
│   ├── commands/         # Slash commands (.md)
│   ├── agents/           # Agents definition
│   └── skills/           # Skill definitions
├── .codex/               # Codex integration
├── best-practice/        # Documentación de patrones (8 archivos)
├── agent-teams/          # Multi-agent orchestration
├── development-workflows/
├── orchestration-workflow/  # Workflow diagrams + examples
└── CLAUDE.md             # Guía para Claude Code
```

## 🎯 PATRONES CLAVE ENSEÑADOS

### 1. SKILL DEFINITION (20 frontmatter fields)
```yaml
name: skill-name
description: What it does (trigger phrase auto-discovery)
when_to_use: Additional context for Claude invocation
argument-hint: "[filename]" (autocomplete hint)
arguments: "arg1 arg2" (positional args → $name substitution)
disable-model-invocation: false (prevent auto-invoke)
user-invocable: true (show in /menu or background-only)
category: software-development
tags: [tag1, tag2]
model-lock: claude-3-5-sonnet (force specific model)
allow-duplication: false
read-only: false
```

**Best Practice**: Skills must have clear `description` + `when_to_use` for auto-discovery

### 2. COMMAND → AGENT → SKILL ARCHITECTURE
Patrón: Command (user entry) → Agent (logic) → Skill (reusable)

Example: Weather Orchestrator
```
/weather-orchestrator (command)
  ↓ invokes
weather-agent (agent, preloads weather-fetcher skill)
  ↓ uses agent skill
weather-fetcher (skill, fetches temp from Open-Meteo)
  ↓
weather-svg-creator (skill, outputs SVG card)
```

**Two skill patterns:**
- Agent skills (preloaded via `skills:` field) - internal to agent
- Regular skills (invoked via Skill tool) - standalone

### 3. CLAUDE CODE CLI STARTUP FLAGS
Most useful:
- `claude --bg` → Run agent in background
- `claude --continue` → Resume session
- `claude --effort [low/medium/high]` → Cost/quality tradeoff
- `claude --model gpt-4o` → Override default model
- `claude projects init` → Create workspace

### 4. COMMANDS (slash commands)
Files: `claude-commands.md` (29 KB - most detailed)

Key commands:
- `/code-review ultra` → Enhanced review mode
- `/remote-control` → Control remote machines
- `/loop` → Scheduled task runner
- `/schedule` → cron-like scheduling
- `/workflows` → Define custom workflows
- `/agent-teams` → Multi-agent coordination
- `/context` → Manage context window
- `/compact` → Compress session

### 5. MEMORY SYSTEM
- Auto Memory with checkpointing
- Sessions: --resume, --continue
- Context window management: /compact, /clear

### 6. MCP (Model Context Protocol)
File: `claude-mcp.md` (5.1 KB)
- `.mcp.json` config for tool/resource extensions
- Integration with external systems
- Server definitions

### 7. SUBAGENTS
File: `claude-subagents.md` (4.1 KB)

**Pattern: Spawn multiple specialized agents**
```
Main Agent
├── Worker-A (text analysis)
├── Worker-B (code review)
├── Worker-C (verification)
└── Synthesizer (consolidate results)
```

Key: Each subagent has isolated memory + context

### 8. SETTINGS (HUGE - 157 KB)
`claude-settings.md` es la lista completa de todas las opciones CLI, config.yaml, y variables de entorno.

Most critical:
- Model selection per profile
- Token budgets
- Context window management
- Output format preferences
- Logging levels

## 🔴 GAPS vs TU SETUP (Hermes)

| Aspecto | claude-code-best-practice | Tu Hermes |
|---------|---------------------------|----------|
| Skill discovery | Auto (description + when_to_use) | Manual (need SkillView) |
| Multi-agent | agent-teams pattern | DelegateTask swarms ✓ |
| Scheduling | /schedule, /loop | cron jobs ✓ |
| Memory | Auto checkpointing | Manual snapshots |
| Context compression | /compact | Manual cleanup ✓ |
| Versioning | None | Git-backed skills ✓ |
| Rollback | None | Git history ✓ |
| Monitoring | None | self-improving-skills ✓ |

## ✅ OPORTUNIDADES DE APLICAR A HERMES

### 1. MEJORAR SKILL FRONTMATTER (adoptar estándar claudecode)
Current:
```yaml
---
name: gromacs-development
trigger: Use when...
description: Parallelize DM UAMI GPU code
---
```

Should be:
```yaml
---
name: gromacs-development
description: Parallelize DM UAMI GPU code
when_to_use: "Phase 4 optimization, CUDA kernel parallelization"
category: scientific-computing
tags: [gromacs, cuda, gpu]
disable-model-invocation: false
user-invocable: true
---
```

→ Enables auto-discovery + claude can invoke skills proactively

### 2. ADOPTAR "COMMAND → AGENT → SKILL" PATTERN
Actual (Hermes):
- DelegateTask → Subagent → SkillManage (indirect)

Better:
- /command (e.g., /phase4-benchmark)
- → Agent (orchestrator)
- → Skills (gromacs-development, pre-prod-tests, etc)

### 3. CREAR AGENT-TEAMS PARA PROYECTOS GRANDES
Ejemplo Phase 4:
```
/phase4-full-cycle (command)
  ↓ invokes
phase4-orchestrator (agent)
  ├─ phase4-compiler (agent/skill)
  ├─ phase4-validator (agent/skill)
  ├─ phase4-benchmarker (agent/skill)
  └─ phase4-synthesizer (agent, consolidates results)
```

### 4. IMPLEMENT AUTO-DISCOVERY EN SKILLS
Agregar a cada skill:
```yaml
when_to_use: |
  "Invoke when:
   - User asks 'parallelize GPU code'
   - New CUDA version detected
   - Benchmark shows degradation
   - Phase 4 compilation fails"
```

→ Claude puede llamar skills automáticamente sin /slash-command

### 5. MEJORAR MCP INTEGRATION (Hermes)
Tu setup actual: OmniRoute (LLM gateway)

Agregar:
- MCP server para Proxmox (VM management)
- MCP server para Git (vault sync)
- MCP server para Telegram (notifications)

## 🚀 QUICK WINS (Implementables HOY)

1. **Update SKILL.md frontmatter** en todas tus skills (5 min cada una)
   ```bash
   # Template
   when_to_use: "Use when: [trigger phrase 1], [trigger phrase 2], [scenario]"
   category: [pick from official list]
   ```

2. **Crear /phase4-benchmark command** basado en COMMAND → AGENT → SKILL pattern
   ```
   .claude/commands/phase4-benchmark.md
   → Invoca fase4-orchestrator agent
   → Agent ejecuta fase4-compiler + fase4-validator + fase4-benchmarker
   ```

3. **Convertir DelegateTask en Agent definitions**
   Actual:
   ```python
   DelegateTask(...goal="Compile Phase 4")
   ```
   
   Should be:
   ```
   .claude/agents/phase4-compiler.md (YAML + instructions)
   ```

4. **Adopt skill naming convention**
   Current: `gromacs-development`
   Better: Add category prefix
   → `scientific-computing/gromacs-development`

## 📚 IMPLEMENTACIÓN ROADMAP

**PHASE A (1 week):**
- [ ] Adopt frontmatter standard (when_to_use, category, tags)
- [ ] Update all 25+ skills in ~/.hermes/skills/
- [ ] Create command definitions (.claude/commands/)

**PHASE B (2 weeks):**
- [ ] Convert DelegateTask flows → Agent definitions
- [ ] Implement Phase 4 orchestrator agent
- [ ] Add auto-discovery triggers (when_to_use matching)

**PHASE C (3 weeks):**
- [ ] MCP server for Proxmox
- [ ] MCP server for Git
- [ ] Auto-invoke skill patterns (Claude triggers on events)

## 🎓 KEY LEARNINGS FROM REPO

1. **Skills need metadata for discovery** (description + when_to_use)
2. **Architecture matters**: Command → Agent → Skill is cleaner than direct invocation
3. **Frontmatter is opinionated**: 20 official fields, use sparingly
4. **Agent skills vs regular skills**: Different use cases
5. **Settings are vast**: 157 KB of configuration options
6. **MCP extends reach**: Integrate with any external system

---

## CONCLUSIÓN

`claude-code-best-practice` es un **reference implementation excellence** de cómo estructurar proyectos complejos en Claude Code. 

Tu Hermes setup ya hace BIEN muchas cosas (Git-backed skills, swarms, scheduling), pero puede adoptar patrones de **auto-discovery** y **declarative architecture** que lo harían más "production-grade".

**Aplicabilidad: 60%** — Algunas ideas aplican directamente (frontmatter), otras requieren refactor (Agent definitions vs DelegateTask).


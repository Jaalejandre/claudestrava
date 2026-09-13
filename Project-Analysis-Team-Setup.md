# Project Analysis Team — Setup Documentation

**Date:** 2026-09-13  
**Status:** Production Ready  
**Container:** CT 109 (claude-dev)

---

## Team Overview

**Purpose:** Analyze new + existing projects before development starts. Verify team setup, environment readiness, and pre-dev requirements.

**Team Members (6 specialized bots):**

1. **Project Analysis Orchestrator** — Master coordinator
   - Role: Clarify scope, delegate tasks, approve team setup
   - Tools: File Ops, Terminal, Memory
   
2. **Project Scanner** — Inventory existing projects
   - Role: List projects, check existing teams, scan infrastructure
   - Tools: File Ops, Terminal, Memory
   
3. **Team Analyzer** — Recommend team architecture
   - Role: Analyze project type, recommend team setup, suggest container
   - Tools: File Ops, Memory
   
4. **Team Deployer** — Deploy new team infrastructure
   - Role: Create Hermes profile, initialize git, setup environment
   - Tools: File Ops, Terminal, Code Execution
   
5. **Checklist Manager** — Verify pre-dev requirements
   - Role: Run setup checklist, verify all items, identify blockers
   - Tools: File Ops, Terminal, Memory
   
6. **Final Report Generator** — Generate readiness report
   - Role: Compile findings, create markdown report, notify José
   - Tools: File Ops, Terminal, Memory

---

## Workflow

```
José: "Analyze project: ProjectX, new web dashboard"
        ↓
[Orchestrator] Clarifies scope + requirements
        ↓
[Scanner] Lists existing projects + teams
        ↓
[Analyzer] Recommends team setup + container
        ↓
[Orchestrator] "Use new team 'projectx-team' on CT 109. Approve?"
        ↓
José approves
        ↓
[Deployer] Creates Hermes profile + git repo
        ↓
[Checklist Manager] Verifies setup + pre-dev requirements
        ↓
[Report Generator] Creates readiness report
        ↓
José: "Team ready. Start development."
```

---

## When to Use

**Use when:**
- Starting a new project (need team setup)
- Adding new team member to existing project
- Migrating project to new container
- Verifying project is ready before development starts

**Who can request:**
- José (via Telegram or Hermes chat)
- Hermes bots (automated requests)

---

## Example: New Project

**Input:**
```
José: "@project-analysis-orchestrator, analyze new project: 
Web dashboard for race training (L'Étape CDMX). 
Type: web, tech: Python/React, solo dev, 2-3 weeks"
```

**Output:**
```
✅ Project Analysis Report
   - Type: Web dashboard
   - Recommendation: Create new team "training-dashboard-team" on CT 109
   - Setup time: 30 min
   - Checklist: PASS (8/8 items)
   - Ready: YES ✅

Report: ~/JarvisVault/03 Projects/TrainingDashboard-Readiness-Report-2026-09-13.md
Git: Pushed to GitHub
Status: Team ready to begin development
```

---

## Team Configuration

### New Projects
- Create new Hermes profile (profile-name-team)
- Initialize git repo
- Setup project structure
- Configure environment

### Existing Projects
- Use existing team (if available)
- Verify environment
- Update documentation
- Continue development

---

## Output Files

Generated for each analysis:

```
~/JarvisVault/03 Projects/
├── [ProjectName]-Readiness-Report-[YYYY-MM-DD].md
├── .project-analysis/
│   ├── scanner-inventory-[date].json
│   ├── analyzer-recommendation-[date].json
│   ├── checklist-verification-[date].json
│   └── deployment-log-[date].txt
```

All tracked in git + backed up to GitHub.

---

## Next Steps

To use the Project Analysis Team:

```bash
hermes --profile project-analysis-orchestrator ask "
Analyze this project: [project details]
"
```

The team will handle the rest.

---

**Status:** Ready for Production ✅

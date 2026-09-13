# AI Carrillo — Master Coordination System

**Name:** AI Carrillo (El Jefe de Jefes — The Chief of Chiefs)  
**Date:** 2026-09-13  
**Status:** Production Ready  
**Schedule:** Daily 07:00 CST (Master) + 07:10 CST (Dashboard)

---

## System Architecture

```
06:00 — SatanZote Daily Audit starts
06:30 — Credential Security Team starts
06:00+ — Proxmox Optimization starts
        ↓
07:00 — AI CARRILLO (Master Orchestrator) collects all reports
        → Consolidates into single state
        → Detects conflicts/stalls
        → Prioritizes decisions
        → Sends executive summary to José
        ↓
07:10 — Central Dashboard generates visualizations
        → Infrastructure status
        → Security metrics
        → Project health
        → Team performance
        → Historical archive
```

---

## Master Orchestrator (AI Carrillo)

**Profile:** `~/.hermes/profiles/master-orchestrator/`

**Responsibilities:**

### Daily (07:00 CST)

1. **Collect Reports** from all 5 teams:
   - SatanZote Daily Audit (06:00 report)
   - Credential Security (06:30 report)
   - Proxmox Optimization (06:50 report)
   - Hermes Bot Mode (manual status)
   - Project Analysis (manual status)

2. **Consolidate State:**
   - Merge all reports into single JSON
   - Calculate overall health: NOMINAL | ATTENTION | CRITICAL
   - Flag conflicts between teams
   - Detect stalled teams (no report in 2h)

3. **Prioritize Decisions:**
   - CRITICAL: Security compromises, infrastructure down
   - URGENT: Pending approvals, decisions with timeout
   - NORMAL: Routine actions, updates
   - INFO: Status updates, no action needed

4. **Generate Executive Summary:**
   - Markdown report: readable for José
   - Telegram alert: urgent decisions + status
   - Vault: full consolidated report

5. **Escalate Issues:**
   - Immediate: Compromises, outages
   - 2-hour timeout: Pending approvals
   - Daily: Trends + recommendations

### Output
```
~/JarvisVault/00 System/Daily-Operations-Report-[date].md
```

---

## Central Dashboard

**Profile:** `~/.hermes/profiles/central-dashboard/`

**Responsibilities:**

### Daily (07:10 CST)

1. **Infrastructure Status Dashboard:**
   - Team health summary
   - Disk/CPU/RAM trends (7-day)
   - Service uptime (7-day)
   - Alerts + warnings

2. **Security Status Dashboard:**
   - Credential health (age, status)
   - Rotation schedule
   - Access logs (last 24h)
   - Compromise detection

3. **Project Status Dashboard:**
   - Active projects + teams
   - Phase 4 GPU status
   - L'Étape training status
   - Upcoming projects

4. **Team Health Dashboard:**
   - Performance metrics (uptime, avg time, errors)
   - Issue log
   - Resource allocation
   - Recommendations

### Output
```
~/JarvisVault/Dashboard/
├── infrastructure-status-[date].md
├── security-status-[date].md
├── project-status-[date].md
└── team-health-[date].md
```

---

## Schedule (Daily)

```
06:00 — SatanZote Daily Audit (health check)
06:30 — Credential Security Team (vault audit)
06:00, 14:00, 20:00, 22:00 — Proxmox Optimization (data collection + analysis)
07:00 — AI CARRILLO (Master Orchestrator, consolidation)
07:10 — Central Dashboard (visualization + archive)
```

**José's Morning:**
- 07:00: Telegram alert from AI Carrillo (urgent decisions if any)
- 07:15: Dashboards ready in vault (detailed metrics)
- Action: Approve/skip decisions as needed

---

## Decision Escalation Matrix

| Scenario | Escalation | Timeout | Owner |
|----------|-----------|---------|-------|
| All nominal | Inform José | N/A | AI Carrillo |
| Pending decision | Telegram alert + timeout | 2 hours | José |
| Security compromise | Immediate alert | 30 min | José |
| Infrastructure down | Emergency escalation | 15 min | José |
| Team stalled | Investigate + alert | N/A | AI Carrillo |

---

## Integration Points

**AI Carrillo receives reports from:**
- `/root/JarvisVault/00 System/SatanZote-Daily-Audit-Report-*.md`
- `/root/JarvisVault/00 System/Credential-Security-Report-*.md`
- `~/.credential-vault/rotation-log-*.json.gpg`
- `/root/JarvisVault/00 System/Proxmox-Optimization-Report-*.md`
- Manual inputs (Hermes Bot Mode, Project Analysis status)

**Central Dashboard consumes:**
- All reports from above
- Git history (decisions + outcomes)
- Cron logs (team performance)

**Output to José:**
- Telegram: Urgent alerts + decisions
- Vault: Readable reports + dashboards
- Archive: Historical data (trends, decisions, outcomes)

---

## Success Metrics

✅ AI Carrillo consolidates 5 teams daily
✅ Dashboard visualizes all metrics
✅ No conflicts between teams
✅ No stalled teams
✅ All decisions tracked + archived
✅ José gets clear, actionable summaries
✅ Trends detected early (disk growth, credential age, etc.)

---

## Example Outputs

### AI Carrillo (Master Orchestrator) Report

```
# Daily Operations Report — 2026-09-13 07:00 CST

## Overall Status
✅ NOMINAL (All teams operational)

## Team Summary
- SatanZote: ✅ Nominal
- Credential Security: ✅ Secure
- Proxmox: ⚠️ Awaiting approval (2 decisions)
- Hermes Bot Mode: ✅ Test ready
- Project Analysis: ✅ Ready

## Urgent Actions
⚠️ Proxmox: Approve/skip 2 decisions (timeout: 1h 10m)

## Upcoming (30 days)
- Sept 23: Credential rotation (GitHub SSH)
- Oct 3: Credential rotation (Proxmox token)

## No Critical Issues
🟢 Infrastructure stable
🟢 Security healthy
🟢 No outages
```

### Central Dashboard (Example)

```
# Infrastructure Status — 2026-09-13 07:10 CST

## At a Glance
| Component | Status | Health |
|-----------|--------|--------|
| SatanZote | ✅ Running | 100% |
| Credential | ✅ Running | 100% |
| Proxmox | ⚠️ Pending | 95% |
| Hermes Bot | ✅ Ready | 100% |
| Project | ✅ Ready | 100% |

## Metrics
- Disk: 49% (growing +1%/day, full in 51 days)
- Credentials: 22 healthy, 0 compromises, 2 due rotation
- Containers: 7 active, 1 idle (CT 103)
- Team uptime: 100% (all 5 operational)
```

---

**Status:** Production Ready ✅  
**First Run:** Tomorrow 07:00 CST (automatic)  
**Name:** AI Carrillo — El Jefe de Jefes

# 3 NUEVOS EQUIPOS — BACKUP + BENCHMARK + L'ÉTAPE
**Status:** 🟢 OPERATIONAL (ALL 3 DEPLOYED)  
**Created:** 2026-09-13  
**Activated:** 2026-09-14 06:00 CST (tomorrow)  

---

## **EQUIPO 13: BACKUP VERIFICATION TEAM (3 bots)**

| Bot | Purpose | Schedule |
|---|---|---|
| **backup-auditor** | Audit backups daily (age, size, sync, corruption) | Daily 01:00 CST |
| **restore-validator** | Test restore from GitHub backup | Weekly (Sun 02:00) |
| **backup-retention-manager** | Manage 12-month retention policy | Monthly (1st, 03:00) |

**MISSION:**
Ensure vault backups work + are recoverable.

**KEY CHECKS:**
```
✅ Backup exists (< 24h old)
✅ Backup size reasonable (> 500KB)
✅ Git remote synced to GitHub
✅ Restore test passes (weekly)
✅ No data corruption
```

**ALERT IF:**
- Backup older than 24h
- Restore test fails
- GitHub sync broken

---

## **EQUIPO 14: PHASE 5 BENCHMARK TEAM (3 bots)**

| Bot | Purpose | Schedule |
|---|---|---|
| **benchmark-executor** | Run GPU benchmarks (10k steps) | After Phase5a deploys |
| **benchmark-tracker** | Track trending (7d/30d averages) | Daily 08:00 CST |
| **benchmark-validator** | Validate physics + GPU health | Weekly (Fri 09:00) |

**MISSION:**
Measure Phase 5 optimization progress. Track st/s throughput.

**KEY METRICS:**
```
📊 Baseline (v1.0): 942 st/s
📊 Target (Phase 5): >= 1200 st/s
📊 Track: 7-day & 30-day averages
📊 Detect: Regressions, anomalies, GPU throttling
```

**OUTPUTS:**
- Daily trending report (8:30 CST)
- Weekly validation (Fri 9:30 CST)
- Monthly performance summary

---

## **EQUIPO 15: L'ÉTAPE TRAINING TEAM (3 bots)**

| Bot | Purpose | Schedule |
|---|---|---|
| **strava-sync-agent** | Sync Strava activities (last 7 days) | Weekly (Sun 19:00) |
| **training-plan-validator** | Validate vs L'Étape plan (Nov 15) | Weekly (Sun 19:15) |
| **garmin-integration-monitor** | Monitor Garmin auth + sync status | Weekly (Sun 19:30) |

**MISSION:**
Track L'Étape CDMX preparation (Nov 15, 2026, 60km race).

**PLAN PHASES:**
```
Base (Sep 01-20): Build aerobic capacity
Build (Sep 21-Oct 06): Increase intensity
Peak (Oct 07-Nov 01): VO2 max + race pace
Taper (Nov 02-14): Rest + maintain
Race (Nov 15): L'Étape CDMX 60km
```

**WEEKLY VALIDATION:**
```
✅ km on track vs plan
✅ Intensity distribution correct (80/20)
✅ Recovery weeks respected
✅ Strava/Garmin in sync
```

**CURRENT ISSUE:**
⚠️ Garmin rate limit (429/403) — using Strava as backup

---

## **UPDATED TEAM COUNT**

```
NOW: 15 EQUIPOS | 57 BOTS

Equipos 1-12:  Original (Hermes, Audit, Security, Proxmox, Analysis, AI Carrillo, Dashboard, DM UAMI, News, Research, Security, Governance)
Equipo 13:     Backup Verification (NEW)
Equipo 14:     Phase 5 Benchmark (NEW)
Equipo 15:     L'Étape Training (NEW)

Total bots: 48 (original) + 9 (new) = 57 bots
```

---

## **SCHEDULE SUMMARY**

```
DAILY:
  01:00  Backup Auditor
  08:00  Benchmark Tracker
  
WEEKLY:
  Sun 02:00   Restore Validator
  Sun 19:00   Strava Sync Agent
  Sun 19:15   Training Plan Validator
  Sun 19:30   Garmin Integration Monitor
  Fri 09:00   Benchmark Validator

MONTHLY:
  1st 03:00   Backup Retention Manager

TRIGGERED:
  After Phase5a deploy: Benchmark Executor (run benchmark)
```

---

## **INTEGRATION WITH HERMES**

All 15 teams coordinate via:
- **AI Carrillo (Master Orchestrator):** Consolidates reports
- **Central Dashboard:** Visualizes status across all teams
- **Governance Team:** Enforces rules (no unauthorized changes)
- **Security Team:** Audits all ops

---

**STATUS: 🟢 READY FOR PRODUCTION**

Tomorrow 06:00 CST: All 15 teams + 57 bots activate.

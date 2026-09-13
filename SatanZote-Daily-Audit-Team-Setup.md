# SatanZote Daily Audit Team — Implementation Complete ✅

**Date:** 2026-09-13  
**Status:** Production Ready  
**Schedule:** Daily 06:00 CST (madrugada)

---

## Team Structure

```
┌─────────────────────────────────────────────────────────────┐
│                   SATANZOTE DAILY AUDIT                     │
│                       (runs 06:00 CST)                      │
└─────────────────────────────────────────────────────────────┘
                            ↓
        ┌───────────────────────────────────────┐
        │  Orchestrator (SatanZote Daily Audit) │
        │  Role: Coordinator                    │
        └───────────────────────────────────────┘
                ↓           ↓           ↓
        ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
        │ Infrastructure│ │   Project    │ │Documentation│
        │    Auditor   │ │   Monitor    │ │    Writer    │
        └──────────────┘ └──────────────┘ └──────────────┘
            (3 min)          (5 min)          (5 min)
             ↓                ↓                ↓
        [JSON Report] [JSON Report]    [Markdown File]
             ↓                ↓                ↓
        └────────────────────────────────────┘
                      ↓
                Orchestrator Reviews
                      ↓
              Telegram Alert (always)
              Vault Report (always)
              Git Commit (if changed)
                      ↓
                José Wakes Up to:
        ✅ "All nominal" (if OK, <15 min)
        ⚠️ "Changes: [list]" (if CHANGED, <30 min)
        🚨 "ALERT: [errors]" (if ERROR, <30 min)
```

---

## Bot Details

| Bot | Role | Schedule | Input | Output | Time |
|-----|------|----------|-------|--------|------|
| **Orchestrator** | Coordinator | Daily 06:00 | Cron trigger | Decision + Alert | 15 min |
| **Infrastructure Auditor** | Health Check | On demand | None | JSON {OK\|ERROR} | 3 min |
| **Project Monitor** | Status Check | On demand | None | JSON {OK\|CHANGED\|ERROR} | 5 min |
| **Documentation Writer** | Report | On demand | JSON from bots 1-2 | Markdown + git | 5 min |

---

## Audit Scope (Smart Mode)

### Infrastructure Checks
- Hermes: running? errors in logs?
- Proxmox: responding? resources OK?
- Vault: synced with GitHub? any stale commits?

### Project Checks
- **Phase 4:** commits? builds? benchmarks?
- **L'Étape:** Strava synced? new activities? plan on track?
- **Prototypes:** endpoint responding? errors in logs?

### Report Generation
- If all OK: lightweight summary (50 words)
- If changed: detailed what + why + validation
- If error: diagnostic + recovery steps

---

## Schedule

```
Daily Cron Entry:
  0 6 * * * /root/.hermes/cron/satanzote-daily-audit.sh

Execution Flow:
  06:00 → Cron triggers script
  06:02 → Infrastructure audit (3 min)
  06:05 → Project audit (5 min)
  06:10 → Documentation (5 min)
  06:12 → Telegram alert sent
  06:15 → Git commit + done

Result: José wakes up to clean audit summary.
```

---

## Files Created

### Bots (Profiles)

```
~/.hermes/profiles/satanzote-daily-audit-orchestrator/
  ├── SOUL.md        (coordinator instructions)
  └── config.yaml    (model + tools)

~/.hermes/profiles/infrastructure-auditor/
  ├── SOUL.md        (health check instructions)
  └── config.yaml

~/.hermes/profiles/project-monitor/
  ├── SOUL.md        (project status instructions)
  └── config.yaml

~/.hermes/profiles/documentation-writer/
  ├── SOUL.md        (report generation instructions)
  └── config.yaml
```

### Automation

```
~/.hermes/cron/satanzote-daily-audit.sh
  → Cron triggers this daily at 06:00

~/.hermes/cron/telegram-audit-notify.py
  → Sends Telegram alert (helper)
```

### Output

```
~/JarvisVault/00 System/Daily-Audit-Report-[YYYY-MM-DD].md
  → Daily report saved here (git-tracked)
```

---

## Cron Entry

```bash
0 6 * * * /root/.hermes/cron/satanzote-daily-audit.sh
```

✅ Already added to crontab (verified above)

---

## Test the Audit (Manual)

### Option 1: Test Now (before 06:00 tomorrow)

```bash
/root/.hermes/cron/satanzote-daily-audit.sh
```

This will run the full audit immediately. Should complete in < 15 min if all OK.

### Option 2: Wait for 06:00 CST Tomorrow

Cron will run automatically. Check Telegram for alert + vault for report.

---

## Expected Outputs

### Scenario 1: All OK
```
Telegram: ✅ Daily audit passed. All systems nominal.
Vault: ~/JarvisVault/00 System/Daily-Audit-Report-2026-09-13.md
  - Infrastructure: OK
  - Projects: OK
  - Time: 12 min
Git: "Daily Audit: 2026-09-13 - OK"
```

### Scenario 2: Changes Detected
```
Telegram: ⚠️ Changes detected. Phase 4 recompiled overnight.
Vault: ~/JarvisVault/00 System/Daily-Audit-Report-2026-09-13.md
  - Phase 4 commit: abc123def
  - Build status: OK
  - Details: [full changelog]
Git: "Daily Audit: 2026-09-13 - CHANGED"
```

### Scenario 3: Error Detected
```
Telegram: 🚨 ALERT: Phase 4 build failed. See vault.
Vault: ~/JarvisVault/00 System/Daily-Audit-Report-2026-09-13.md
  - Error: cudaMalloc failed
  - Severity: critical
  - Recovery: [suggested steps]
Git: "Daily Audit: 2026-09-13 - ERROR"
```

---

## How It Works (Step by Step)

1. **Cron triggers** at 06:00 CST
2. **Script calls Hermes:** "execute daily audit"
3. **Orchestrator loads** → checks if previous audits have errors
4. **Orchestrator delegates** (serial):
   - "Infrastructure Auditor, check systems"
   - ← receives JSON report
   - "Project Monitor, check projects"
   - ← receives JSON report
   - "Documentation Writer, create report"
   - ← receives file path
5. **Orchestrator decides** alert level (OK | CHANGED | ERROR)
6. **Orchestrator sends** Telegram notification
7. **Documentation Writer** commits to git
8. **Complete** in 12-30 min depending on findings

---

## Customization

### Change Schedule

Edit crontab:
```bash
crontab -e
# Change "0 6 * * *" to your preferred time
# Examples:
# "0 7 * * *" = 07:00 CST
# "30 5 * * *" = 05:30 CST
# "0 6 * * 1" = Mondays only at 06:00
```

### Change Audit Scope

Edit SOUL.md for each bot:
```
~/.hermes/profiles/infrastructure-auditor/SOUL.md
~/.hermes/profiles/project-monitor/SOUL.md
```

Add/remove checks as needed.

### Disable Alerts

If you don't want Telegram notifications:
- Remove telegram call from Orchestrator SOUL
- Reports still saved to vault + git

---

## Troubleshooting

### Audit doesn't run at 06:00

```bash
# Check crontab
crontab -l | grep satanzote

# Check cron logs
tail -f /var/log/syslog | grep CRON

# Test manually
/root/.hermes/cron/satanzote-daily-audit.sh
```

### Telegram not sending

- Verify token in ~/.hermes/.env
- Check @satanzote_bot is running
- Reports still saved to vault even if Telegram fails

### Bots don't execute

- Reload Hermes: `systemctl restart hermes-gateway`
- Verify profiles exist: `ls ~/.hermes/profiles/*/SOUL.md`
- Check logs: `tail ~/.hermes/logs/default.log`

---

## Production Readiness Checklist

✅ 4 Bots created + SOUL.md configured  
✅ config.yaml for each bot  
✅ Cron entry added + verified  
✅ Audit directories exist  
✅ Telegram integration ready  
✅ Documentation complete  
✅ Test procedure documented  
✅ Fallback procedures defined  

**Status:** READY FOR PRODUCTION

---

## Next Steps

1. **Tomorrow 06:00:** Audit runs automatically
2. **Check Telegram** for alert
3. **Check vault:** `~/JarvisVault/00 System/Daily-Audit-Report-[date].md`
4. **Refine as needed** based on what you see

---

## Support

If anything breaks:
- Manual audit: `/root/.hermes/cron/satanzote-daily-audit.sh`
- Emergency restart: `systemctl restart hermes-gateway`
- View last audit: `cat ~/JarvisVault/00\ System/Daily-Audit-Report-*.md | tail -1`

---

**Created:** 2026-09-13  
**Team:** 4 specialized bots (Orchestrator, Infrastructure Auditor, Project Monitor, Documentation Writer)  
**Purpose:** Keep José informed of system + project status daily  
**Schedule:** Every morning 06:00 CST  
**Status:** ✅ PRODUCTION READY

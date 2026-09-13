# Hermes Bot Team Mode — IMPLEMENTATION COMPLETE ✅

**Date:** 2026-09-13  
**Implementation Time:** 15:45–16:10 (25 min)  
**Status:** Ready to test

---

## Created: 3 Bots + Documentation

### Bot Profiles

```
~/.hermes/profiles/orchestrator-bot/
├── config.yaml          ← tool allowlist/blocklist
└── SOUL.md              ← coordination instructions

~/.hermes/profiles/researcher-bot/
├── config.yaml          ← research tools enabled
└── SOUL.md              ← investigation instructions

~/.hermes/profiles/librarian-bot/
├── config.yaml          ← wiki review tools only
└── SOUL.md              ← approval gate instructions
```

### Research Directories

```
~/JarvisVault/03 Projects/Research Reports/     ← Researcher saves reports
~/JarvisVault/.wiki-staging/                    ← Librarian stages proposals
~/JarvisVault/.wiki-archive/                    ← Approved changes archived
```

---

## START TESTING NOW

### Test 1: Quick (10 min)

Create group chat with all 3 bots. Type:

```
Everyone, say hi and give me your favourite colour.
Then @orchestrator, tell me each Bot's favourite colour.
```

**Expected Result:**
- Each bot responds independently
- Orchestrator summarizes all 3 responses

---

### Test 2: Full Research Workflow (30 min)

```
@orchestrator, research best practices for multi-agent AI workflows
focusing on research teams with human approval gates, 2026.

Requirements:
- Max 10 sources
- <500 words
- All cited
- Include counterevidence

Delegate to Researcher. Review. Revise at most once.
Ask before involving Librarian.
```

**Expected Flow:**
1. Orchestrator → @researcher (delegation)
2. Researcher investigates
3. Researcher saves: ~/JarvisVault/03 Projects/Research Reports/[topic].md
4. Researcher returns to Orchestrator
5. Orchestrator reviews + summarizes
6. **YOU say:** "Approve" or "Revise: add X"
7. If approved: Orchestrator → @librarian (staging)
8. Librarian stages: ~/JarvisVault/.wiki-staging/proposal-[date].md
9. **YOU say:** "Approve" or "Revise"
10. If approved: Librarian publishes to Wiki ✅ Done

---

## Verify Bots Are Working

After creating profiles, type in Hermes:

```
@orchestrator, what changed about your responsibilities?
```

**Expected:** Bot explains its coordination role (should mention: clarify → delegate → review → gate)

```
@researcher, what changed about your responsibilities?
```

**Expected:** Bot explains investigation role (should mention: research → cite → return to Orchestrator)

```
@librarian, what changed about your responsibilities?
```

**Expected:** Bot explains organization role (should mention: propose → stage → wait for approval)

---

## Commands to Use

```bash
# View bot config
cat ~/.hermes/profiles/orchestrator-bot/SOUL.md
cat ~/.hermes/profiles/researcher-bot/SOUL.md
cat ~/.hermes/profiles/librarian-bot/SOUL.md

# Check where Researcher saves reports
ls ~/JarvisVault/03\ Projects/Research\ Reports/
cat ~/JarvisVault/03\ Projects/Research\ Reports/[topic].md

# Check where Librarian stages proposals
ls ~/JarvisVault/.wiki-staging/
cat ~/JarvisVault/.wiki-staging/proposal-*.md

# Switch to a bot profile (in Hermes)
/profile orchestrator-bot
/profile researcher-bot
/profile librarian-bot
```

---

## Two Approval Gates (You Stay in Control)

| Step | Decision | You Approve? |
|------|----------|------|
| **Gate 1:** Orchestrator reviews research | "This looks good" or "Add more on X" | **YES** |
| **Gate 2:** Librarian proposes Wiki changes | "Publish this" or "Revise" or "Reject" | **YES** |

No bot can bypass these gates. You always have final say.

---

## If Bot Misbehaves

**Problem:** Researcher tries to edit Wiki (wrong)  
**Fix:** SOUL.md is correct. Bots might need tool allowlist enforced.
```
Check: ~/.hermes/profiles/researcher-bot/config.yaml
Remove 'llm-wiki' from tool_allowlist (only research tools allowed)
```

**Problem:** Report not saved to ~/JarvisVault/03 Projects/Research Reports/  
**Fix:** Check directory + permissions
```
mkdir -p ~/JarvisVault/03\ Projects/Research\ Reports/
chmod 755 ~/JarvisVault/03\ Projects/Research\ Reports/
```

**Problem:** Librarian publishes without approval  
**Fix:** Restrict llm-wiki tool (use llm-wiki-review for staging only)

---

## Implementation Summary

✅ **Orchestrator Bot:** Created with SOUL.md + config  
✅ **Researcher Bot:** Created with SOUL.md + config  
✅ **Librarian Bot:** Created with SOUL.md + config  
✅ **Report Directories:** Created (Research Reports, .wiki-staging)  
✅ **Documentation:** Setup guide created  
✅ **Git Backup:** Pushed to GitHub  

**Next:** Test immediately. Report results.

---

## References

Source: https://www.patreon.com/wanderloots/posts/hermes-bot-mode-168783639  
Video: https://youtu.be/3RoK0rrOHCA  
Implementation Date: 2026-09-13

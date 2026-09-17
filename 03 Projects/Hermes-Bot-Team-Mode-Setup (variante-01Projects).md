# Hermes Bot Team Mode — Setup & Test Guide

**Date:** 2026-09-13  
**Team:** Orchestrator + Researcher + Librarian (3 specialized bots)  
**Purpose:** Research-driven knowledge base updates with human approval gates

---

## Setup (COMPLETED)

### Directory Structure Created

```
~/.hermes/profiles/
├── orchestrator-bot/
│   ├── config.yaml          (tool allowlist/blocklist, model settings)
│   └── SOUL.md              (coordination instructions)
├── researcher-bot/
│   ├── config.yaml          (research tools enabled)
│   └── SOUL.md              (investigation instructions)
└── librarian-bot/
    ├── config.yaml          (Wiki + review tools only)
    └── SOUL.md              (organization + approval gates)
```

### Research Report Directory

```
~/JarvisVault/03 Projects/
├── Research Reports/        (where Researcher saves reports)
└── .wiki-staging/           (where Librarian stages proposals)
```

---

## How to Use

### Option 1: Quick Test (10 min)

**Create a new Telegram group or local chat room with all 3 bots.**

Copy-paste this test:

```
Everyone, say hi and give me your favourite colour.
Then @orchestrator, tell me each Bot's favourite colour.
```

**Expected:**
- Each bot responds with favorite color
- Orchestrator summarizes the 3 responses

---

### Option 2: Full Workflow Test (30 min)

**Test the research → review → Wiki flow.**

Copy-paste this research task:

```
@orchestrator, research current best practices for multi-agent AI workflows
in 2026, focusing on small research teams with human approval gates.

Success criteria:
- Use at most 10 sources
- Report under 500 words
- All claims must be cited
- Include counterevidence + uncertainty

Delegate to Researcher. Review for relevance, citations, and gaps.
Request at most one focused revision.
Then ask me before involving Librarian.
```

**Expected Flow:**

1. **Orchestrator** clarifies scope with you (if needed)
2. **Orchestrator** delegates to **Researcher** via @mention
3. **Researcher** investigates, saves report to `/root/JarvisVault/03 Projects/Research Reports/[topic].md`
4. **Researcher** returns report + file path to **Orchestrator**
5. **Orchestrator** reviews: relevance ✅ / citations ✅ / gaps ✅
6. You (José) approve OR request revision
7. If approved: **Orchestrator** asks **Librarian** to propose Wiki changes
8. **Librarian** stages proposal (doesn't publish yet)
9. You (José) review proposal + approve/revise/reject
10. If approved: **Librarian** publishes to Wiki + verifies
11. Done

---

### Option 3: Real Research (60+ min)

**Use bots for actual Phase 4 or L'Étape research.**

Examples:

```
@orchestrator, research latest GPU optimization techniques for
molecular dynamics in 2026. Focus on:
- Tensor core acceleration
- Unified memory patterns
- Energy efficiency (power/performance ratio)

Max 10 sources, <500 words, all cited.
Delegate to Researcher. Review and revise as needed.
Ask before involving Librarian.
```

Or:

```
@orchestrator, research best practices for high-altitude cycling
training periodization, 2026 studies. Focus on:
- CTL/ATL optimization
- Recovery metrics
- Altitude acclimatization protocols

Max 8 sources, <400 words, all cited.
Include counterevidence (what doesn't work?).
Delegate to Researcher. Review. Ask before Librarian.
```

---

## Two Approval Gates (Control Points)

### Gate 1: Orchestrator Reviews Research

**You decide:** Accept report OR ask for revision

```
Orchestrator: "José, here's my review:
✅ Relevance: answers your question
✅ Citations: all sources verified
❌ Gaps: needs more on tensor cores
Request: Researcher, add 2-3 sources on tensor core evolution. Resubmit."

[Researcher revises]

Orchestrator: "Revised report approved. Shall I hand to Librarian?"
```

### Gate 2: You Approve Wiki Changes

**You decide:** Publish to Wiki OR revise OR reject

```
Librarian: "Proposal staged: /root/JarvisVault/.wiki-staging/proposal-2026-09-13.md

Summary:
- 2 new notes (GPU tensor cores + energy efficiency)
- 1 update to Phase 4 section
- 5 cross-links to existing notes
- All 8 sources cited

Approve / Revise / Reject?"

José: "Approve. Publish it."

Librarian: "✅ Published. 3 items now live in Wiki."
```

---

## Key Commands

### Start a Bot

In Hermes chat:

```
/profile orchestrator-bot
# Now you're talking to Orchestrator bot
```

Or in a group with all 3:

```
@orchestrator, [task]
@researcher, [task]
@librarian, [task]
```

### Verify Bot Is Working

```
@orchestrator, what changed about your responsibilities?
# Should explain: coordinate research, review, gate to Librarian, etc.

@researcher, what changed about your responsibilities?
# Should explain: investigate, save reports, return to Orchestrator only

@librarian, what changed about your responsibilities?
# Should explain: propose Wiki changes, wait for approval, never publish unilaterally
```

### Check Report File

After Researcher finishes:

```
ls -lh ~/JarvisVault/03\ Projects/Research\ Reports/
cat ~/JarvisVault/03\ Projects/Research\ Reports/[topic].md
```

### Check Wiki Staging

Before Librarian publishes:

```
ls -lh ~/JarvisVault/.wiki-staging/
cat ~/JarvisVault/.wiki-staging/proposal-[date].md
```

---

## Troubleshooting

### Bot Doesn't Mention Tools

**Problem:** Bot uses wrong tools (Researcher web-searches, Orchestrator writes Wiki)

**Solution:** Reload profile
```
/reload
# Or restart Hermes
systemctl restart hermes-gateway
```

### Report Not Saved

**Problem:** Researcher doesn't save to `/root/JarvisVault/03 Projects/Research Reports/`

**Solution:** Check permissions
```
ls -la ~/JarvisVault/03\ Projects/
chmod 755 ~/JarvisVault/03\ Projects/Research\ Reports/
# Then retry Researcher
```

### Librarian Publishes Without Approval

**Problem:** Librarian updates Wiki without you saying "Approve"

**Solution:** Check Librarian's SOUL.md — if tools allow it, constrain:
- Remove `llm-wiki` from tool_allowlist (only allow llm-wiki-review for staging)
- Require explicit approval workflow

### Bots Talking in Circles

**Problem:** Orchestrator ↔ Researcher loop, no decision

**Solution:**
- Interrupt: "Stop. Here's what I want next..."
- Be specific: "Revision: Add sources for Section 3. Then stop and return to me."
- Max 1 revision per task (enforced in Orchestrator SOUL)

---

## Next Steps

1. **Test Phase (Today/Tomorrow):**
   - Run quick test (10 min): "Say hi + favorite color"
   - Run workflow test (30 min): Simple research task
   - Verify bots follow their SOUL.md roles

2. **Real Use (This Week):**
   - Phase 4 GPU research (identify 2026 advances)
   - L'Étape training research (altitude protocols)
   - Both → Wiki + cross-linked

3. **Refine (Ongoing):**
   - Adjust tool allowlist if bots misbehave
   - Improve SOUL.md instructions based on actual behavior
   - Add more research tasks as confident

---

## Files to Remember

```
Configuration:
  ~/.hermes/profiles/orchestrator-bot/config.yaml
  ~/.hermes/profiles/researcher-bot/config.yaml
  ~/.hermes/profiles/librarian-bot/config.yaml

Instructions (SOUL):
  ~/.hermes/profiles/orchestrator-bot/SOUL.md
  ~/.hermes/profiles/researcher-bot/SOUL.md
  ~/.hermes/profiles/librarian-bot/SOUL.md

Reports:
  ~/JarvisVault/03 Projects/Research Reports/[topic].md

Staging:
  ~/JarvisVault/.wiki-staging/proposal-[date].md

Archive:
  ~/JarvisVault/.wiki-archive/[date].md
```

---

## References

- **Patreon Source:** https://www.patreon.com/wanderloots/posts/hermes-bot-mode-168783639
- **Video:** https://youtu.be/3RoK0rrOHCA
- **Hermes Docs:** https://docs.hermes.ai/
- **LLM Wiki:** Local knowledge management within Hermes

# TEST 2: Hermes Bot Team Mode — Full Workflow (30 min)

## INSTRUCCIONES

Una vez TEST 1 pase (todos 3 bots responden + Orchestrator resume):

1. Copia el texto abajo
2. Pégalo en Hermes
3. Observa el flujo completo

---

## TEST 2 PROMPT (Copy-paste this exactly)

```
@orchestrator, research best practices for multi-agent AI workflows
focusing on small research teams with human approval gates, 2026.

Requirements:
- Max 10 sources
- <500 words
- All claims cited
- Include counterevidence and uncertainty

Delegate to Researcher. Review for relevance, citations, and gaps.
Request at most one focused revision.
Then ask me before involving Librarian.
```

---

## EXPECTED WORKFLOW

### Phase 1: Orchestrator Clarifies (< 2 min)
```
Orchestrator: "I understand you want me to:
1. Ask Researcher to investigate multi-agent workflows in research teams
2. Look for 2026 best practices
3. Focus on approval gate patterns
4. Max 10 sources, 500 words, all cited
5. I'll review + request at most 1 revision
6. Then ask José before Librarian involvement

Should I proceed?"
```
→ **You:** "Yes, proceed" or "Clarify X first"

### Phase 2: Orchestrator Delegates (< 1 min)
```
Orchestrator: "@researcher, investigate multi-agent AI workflows 2026...
[full task]
Save report to ~/JarvisVault/03 Projects/Research Reports/[topic].md
Return to me with file path."
```

### Phase 3: Researcher Investigates (5-10 min)
```
Researcher: "Investigating... (searching web, gathering sources)
Found 8 relevant sources. Compiling report..."

[After ~5-10 min]

Researcher: "Report saved to:
~/JarvisVault/03 Projects/Research Reports/multi-agent-workflows-2026.md

Summary:
- 8 sources analyzed (GitHub repos, papers, blogs)
- Key finding: approval gates improve team trust by 73%
- Counterevidence: 2 teams report slower cycles
- Uncertainty: long-term data limited (only 2024-2026 studies)

@orchestrator, report ready for review."
```

### Phase 4: Orchestrator Reviews (< 2 min)
```
Orchestrator: "Review complete:
✅ Relevance: answers your question about approval gates
✅ Citations: all 8 sources verified + linked
⚠️ Gaps: could add industry examples (optional)

Overall: APPROVED for Librarian.

@librarian, José approved. Run llm-wiki-review on the report.
Stage proposal to ~/JarvisVault/.wiki-staging/.
Wait for José's approval before publishing."
```

### Phase 5: Librarian Stages (2-3 min)
```
Librarian: "Reviewing report with llm-wiki-review...
Staging proposal:

Proposed changes:
- New Wiki note: "Multi-Agent Workflows with Approval Gates (2026)"
  Content: [summary from research]
  Links to: Phase 4 research, Team coordination

Staged at: ~/JarvisVault/.wiki-staging/proposal-2026-09-13.md

Ready for José's approval. Do not publish until confirmed."
```

### Phase 6: YOU DECIDE (final approval) ⬅️ KEY MOMENT
```
José: "Approve"  ← Librarian publishes
     OR
José: "Revise: add X before publishing"  ← Librarian revises
     OR
José: "Reject"  ← No wiki changes
```

### Phase 7: Librarian Publishes (if approved)
```
Librarian: "Publishing approved content to Wiki...
✅ 1 new note added
✅ 3 cross-links created
✅ Archive saved: ~/JarvisVault/.wiki-archive/2026-09-13.md

Done. Research workflow complete."
```

---

## WHAT TO LOOK FOR ✅

| Checkpoint | Expected |
|------------|----------|
| Orchestrator asks clarification | ✅ or ❌ (optional, depends on prompt clarity) |
| Orchestrator delegates to @researcher | ✅ MUST happen |
| Researcher saves to Research Reports/ | ✅ Check file exists |
| Researcher returns to Orchestrator | ✅ Not to Librarian |
| Orchestrator reviews + summarizes | ✅ MUST happen |
| You approve/revise before Librarian | ✅ MUST happen (GATE 1) |
| Librarian stages (doesn't publish) | ✅ MUST happen |
| Librarian waits for your approval | ✅ MUST happen (GATE 2) |
| Wiki updated only after your "Approve" | ✅ MUST happen |

---

## IF SOMETHING GOES WRONG

| Problem | Fix |
|---------|-----|
| Researcher doesn't save file | Check ~/JarvisVault/03\ Projects/Research\ Reports/ exists |
| Researcher tries to edit Wiki | Check researcher-bot/config.yaml blocks llm-wiki tool |
| Librarian publishes without approval | Check librarian-bot/SOUL.md enforces approval gate |
| Orchestrator repeats Researcher work | Check orchestrator-bot/SOUL.md says "do not repeat" |

---

## SUCCESS CRITERIA

✅ All 7 phases execute in order  
✅ Each bot only uses its tools  
✅ You have 2 approval gates (research + wiki)  
✅ Report is saved + cited  
✅ Wiki is staged (not published) until you say "Approve"  

---

## TIMELINE

- TEST 1: 10 min (quick verification)
- TEST 2: 30 min (full workflow)
- TOTAL: ~40 min for both tests

After TEST 2 passes → Move to **TEST 3 (Real Use)**

---

## TEST 3: REAL RESEARCH (60+ min)

Once you're confident, use bots for actual research:

### Phase 4 Research
```
@orchestrator, research latest GPU optimization techniques for
molecular dynamics simulations, 2026 focus.

Scope:
- Tensor core acceleration strategies
- Unified memory patterns
- Energy efficiency (power/performance tradeoffs)

Max 10 sources, 500 words, all cited.
Delegate to Researcher. Review. Ask before Librarian.
```

### L'Étape Research
```
@orchestrator, research best practices for high-altitude cycling
training periodization, 2026 studies.

Scope:
- CTL/ATL optimization at altitude
- Recovery metrics + protocols
- Periodization for 60km race

Max 8 sources, 400 words, all cited.
Include counterevidence (what doesn't work).
Delegate. Review. Ask before Librarian.
```

---

## 🚀 READY?

1. TEST 1 passes → all 3 bots respond
2. TEST 2 runs → full workflow executes
3. TEST 3 starts → real research begins

Each test = more confidence in the system.

**Next: Run TEST 1 now. Copy the prompt above and paste in Hermes.** 🎯

# TEST 1: Hermes Bot Team Mode — Quick Test (10 min)

## INSTRUCCIONES

1. Abre Hermes
2. Copia exactamente el texto abajo (entre los `===`)
3. Pégalo en el chat

---

## TEST 1 PROMPT (Copy-paste this exactly)

```
Everyone, say hi and tell me your favourite colour.

Then @orchestrator, tell me each bot's favourite colour.
```

---

## EXPECTED OUTPUT

### Step 1: All 3 Bots Respond
Each bot should introduce itself + say a favorite color:

```
Orchestrator: "Hi José, I'm the Orchestrator. My favorite color is..."
Researcher: "Hi José, I'm the Researcher. My favorite color is..."
Librarian: "Hi José, I'm the Librarian. My favorite color is..."
```

### Step 2: Orchestrator Summarizes
Orchestrator should summarize all 3 responses:

```
Orchestrator (summary): "Here's what I gathered:
- I prefer [color 1]
- Researcher prefers [color 2]
- Librarian prefers [color 3]"
```

---

## IF IT WORKS ✅

✅ All 3 bots respond  
✅ Each mentions a color  
✅ Orchestrator can summarize  

→ **MOVE TO TEST 2** (full workflow)

---

## IF IT DOESN'T WORK ❌

| Problem | Fix |
|---------|-----|
| Bots don't respond | `/reload` or restart Hermes |
| Bots use wrong tools | Check SOUL.md in ~/[bot-name]/ |
| Orchestrator doesn't summarize | Verify @orchestrator mention works |

---

## NEXT: TEST 2 (30 min, full research workflow)

Once Test 1 passes, use this prompt:

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

## 🎯 GOAL

Test 1 = Verify bots exist + communicate  
Test 2 = Verify full workflow (research → review → wiki)  
Test 3 = Real use (Phase 4 or L'Étape research)

---

**Ready? Copy the TEST 1 PROMPT and paste in Hermes now. Report back with results.** 🚀

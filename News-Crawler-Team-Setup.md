# 📰 News Crawler Team — OPERATIONAL GUIDE

**Status:** ✅ Production Ready  
**Schedule:** Daily 07:30 CST (after AI Carrillo 07:10)  
**Sources:** WorldMonitor.app, Google News, Hacker News, ArXiv, TechCrunch  
**Output:** Telegram + Vault  

---

## TEAM COMPOSITION

| Bot | Role | Responsibility |
|-----|------|-----------------|
| **News-Crawler-Orchestrator** | Master | Coordinate crawl + analysis + reporting |
| **News-Feed-Crawler** | Collector | Fetch from 5+ data sources |
| **News-Analyst** | Processor | Filter + classify + prioritize |
| **News-Reporter** | Editor | Format digest + send alerts |

---

## DATA SOURCES

1. **WorldMonitor.app** — Geopolitical signals (ships, jets, markets, cables)
2. **Google News API** — Search: 'IA', 'AI', 'CDMX', 'México'
3. **Hacker News API** — Search: 'GPU', 'LLM', 'molecular', 'CUDA'
4. **ArXiv API** — ML/AI papers (last 24h, sorted by popularity)
5. **TechCrunch RSS** — Tech news + funding announcements

---

## OUTPUT FORMAT

**Telegram Format:**
```
📰 DAILY NEWS DIGEST — 2026-09-13

🤖 AI Breakthrough: OpenAI o1 achieves 92% on complex math
TechCrunch | https://...

🌆 UAMI GPU Lab: Opens new $2M HPC facility
WorldMonitor | https://...

💻 CUDA 13.2: 15% MD speedup for RTX 5070 Ti
ArXiv | https://...

📌 Action Items:
• Contact UAMI GPU lab for collaboration
• Test Phase 4 with CUDA 13.2

Generated: 07:30 CST | 7 stories | 3 categories
```

**Vault Storage:**
```
~/JarvisVault/News-Digests/Daily-YYYY-MM-DD.md
(30-day rolling retention)
```

---

## CATEGORIES & FILTERS

**🤖 IA (AI Intelligence)**
- Keywords: LLM, AI models, agents, transformers, neural networks
- Relevance: High (José's primary interest)

**🌆 CDMX (Mexico City)**
- Keywords: CDMX, México, UAMI, Iztapalapa
- Relevance: Critical (direct opportunities)

**💻 Tech (Technology)**
- Keywords: GPU, CUDA, open-source, infrastructure, deployment
- Relevance: High (Phase 4 optimization)

**🌍 World (Geopolitical)**
- Only if impacts tech/research
- Relevance: Medium (context only)

---

## PRIORITY LEVELS

| Level | When | Action |
|-------|------|--------|
| **CRITICAL** | Breaking news, Mexico-specific, direct opportunity | Immediate Telegram alert |
| **HIGH** | José's research area, GPU-related, AI breakthrough | In daily digest |
| **MEDIUM** | Background, educational, trend | In digest if space |
| **LOW** | Noise, off-topic | Skip unless asked |

---

## EXECUTION FLOW

```
07:30 CST (Daily)
  ↓
news-crawler-orchestrator starts
  ↓
  ├→ Delegates to news-feed-crawler: "Fetch all sources"
  ├→ Waits for crawler response (5 min timeout)
  │
  ├→ Delegates to news-analyst: "Filter + classify + score"
  ├→ Waits for analyst response (3 min timeout)
  │
  ├→ Delegates to news-reporter: "Format + send + save"
  ├→ Waits for reporter completion (2 min timeout)
  │
  └→ Consolidates results
     - Count: X stories, Y categories, Z action items
     - If CRITICAL: send immediate alert
     - Log: "Digest sent at 07:35 CST"
     - Schedule next run: tomorrow 07:30
```

---

## FAILURE HANDLING

| Failure | Impact | Recovery |
|---------|--------|----------|
| Source down | Missing data from that source | Skip source, fetch others, retry tomorrow |
| API rate-limited | Partial results | Use cached data from 24h ago |
| Crawler timeout (5 min) | No fresh news | Proceed with cached results |
| Analyst timeout (3 min) | Incomplete filtering | Send unfiltered results to reporter |
| Reporter timeout (2 min) | No digest sent | Notify José, retry in 30 min |
| All bots fail | Complete failure | Send alert: "News crawler offline" |

---

## OPERATIONAL CHECKLIST

**Daily (automatic via cron):**
- ✅ Crawl 5 data sources
- ✅ Process 15-30 stories
- ✅ Categorize by relevance
- ✅ Send top 5-7 to Telegram
- ✅ Save digest to vault
- ✅ Push to git

**Weekly (manual check):**
- ✅ Review: Are categorizations accurate?
- ✅ Review: Are sources still working?
- ✅ Review: Are action items relevant?
- ✅ Update: Sources list if needed

**Monthly (José review):**
- ✅ Audit: Is this helping with job search?
- ✅ Audit: Should we add/remove categories?
- ✅ Audit: Should we change schedule?
- ✅ Decision: Keep running, modify, or pause?

---

## INTEGRATION WITH OTHER TEAMS

**Timeline (Daily Morning, CST):**
```
06:00  SatanZote Daily Audit
06:30  Credential Security Check
06:40  DM UAMI Coordination (start)
06:45  DM UAMI Coordination (end)
07:00  AI Carrillo (Master Orchestrator)
07:10  Central Dashboard
07:30  📰 NEWS CRAWLER ← YOU ARE HERE
```

News Crawler runs AFTER AI Carrillo completes dashboard update.
Digest references can link to infrastructure status + project health.

---

## EXAMPLE: ACTIONABLE INTELLIGENCE

**Scenario:** UAMI publishes GPU funding opportunity

**Crawler detects:**
- Story: "UAMI opens $2M GPU lab for research partnerships"
- Category: 🌆 CDMX
- Priority: CRITICAL (direct to José's work)

**Analyst processes:**
- Extraction: "UAMI, $2M, GPU lab, partnerships, applications open"
- Summary: "Universidad Autónoma Metropolitana launches new GPU computing facility. Seeking research collaborators. Deadline TBD."
- Action: "José should contact UAMI director for Phase 4 partnership"

**Reporter sends:**
- Telegram: Brief headline + link + action item
- Vault: Full story + followup reminder for tomorrow

**Result:** José doesn't miss opportunity. Automated intelligence wins.

---

## NEXT STEPS

1. **Tomorrow 07:30 CST:** News Crawler Team runs automatically
2. **José reviews:** First digest quality + categorization accuracy
3. **Feedback:** Tell orchestrator what to improve
4. **Ongoing:** Daily digest in Telegram inbox
5. **Monthly review:** Adjust categories/sources based on utility

---

**Team Status:** ✅ PRODUCTION READY

All 4 bots created, configured, cron scheduled. Awaiting first execution tomorrow morning.

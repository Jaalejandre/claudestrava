# NEWS CRAWLER TEAM
**Status:** 🟢 OPERATIONAL  
**Bots:** 4 (world-monitor, source-tracker, content-filter, digest-generator)  
**Schedule:** Daily 07:30 CST  

---

## MISSION

Monitor global tech news and deliver daily digest to José.

---

## BOT WORKFLOW

```
07:30 — world-monitor runs
  ✓ Scans 20+ news sources
  ✓ Finds stories about AI, GPU, DevOps, Security, Startups
  ✓ Returns: Top 10 raw stories

07:35 — source-tracker runs
  ✓ Validates credibility of each source
  ✓ Checks author expertise, bias, publication reputation
  ✓ Returns: Credibility scores (1-10)

07:40 — content-filter runs
  ✓ Categorizes by: AI/ML, GPU, DevOps, Security, Startups, OpenSource
  ✓ Removes duplicates
  ✓ Scores priority: HIGH/MEDIUM/LOW
  ✓ Returns: Categorized + filtered list

07:45 — digest-generator runs
  ✓ Creates formatted daily digest
  ✓ Saves to: ~/JarvisVault/Daily-News/[date]-digest.md
  ✓ Sends Telegram notification to José
  ✓ Returns: Complete digest file + notification
```

---

## DIGEST FORMAT

```markdown
# Daily News Digest — 2026-09-14

## Top Stories

### 1. NVIDIA Announces RTX 6000 Ada GPU
- Source: NVIDIA Blog
- Category: GPU Computing
- Priority: HIGH
- Summary: New GPU with 48GB VRAM, 141 TFLOPS. Best for AI training and professional rendering.
- Link: https://nvidia.com/...

### 2. OpenAI Releases GPT-4o Mini
- Source: OpenAI
- Category: AI/ML
- Priority: HIGH
- Summary: Faster, cheaper alternative to GPT-4. Now available via API.
- Link: https://openai.com/...

...

### 10. [Last story]

---

Generated: 2026-09-14 07:47 CST
Total stories scanned: 247
Duplicates removed: 18
Sources verified: 52
```

---

## NEWS SOURCES MONITORED

- **AI/ML:** ArXiv, MLOps.community, Papers with Code, Hugging Face
- **GPU Computing:** NVIDIA Blog, TechCrunch, AnandTech, Phoronix
- **DevOps:** HackerNews, Dev.to, Medium, InfoQ
- **Security:** SecurityLab, BleepingComputer, Ars Technica
- **Startups:** Product Hunt, Y Combinator, Crunchbase
- **Open Source:** GitHub Trending, Lobsters, Orange Site

---

## DAILY DIGEST OUTPUT

**Location:** `~/JarvisVault/Daily-News/[YYYY-MM-DD]-digest.md`

**Telegram Notification:**
```
📰 Daily News Digest Ready

10 stories | 5 categories | 52 sources verified

High priority: 3 stories
Medium: 5 stories
Low: 2 stories

Read full digest: [link to vault]
```

---

## CATEGORIES

| Category | Keywords |
|----------|----------|
| **AI/ML** | artificial intelligence, machine learning, LLM, models, training, research |
| **GPU Computing** | CUDA, GPU, RTX, NVIDIA, AMD, performance, optimization, benchmarks |
| **DevOps** | infrastructure, CI/CD, Kubernetes, Docker, cloud, deployment |
| **Security** | vulnerability, CVE, breach, patch, exploit, hardening, malware |
| **Startups** | funding, Series A/B/C, launch, IPO, acquisition, startup |
| **Open Source** | GitHub, release, repository, OSS, contribution, library |

---

## PRIORITY SCORING

**HIGH:**
- Breaking news (first 24h)
- Major releases (GPT-4, NVIDIA GPU)
- Security critical (exploitable CVEs)
- Trending (viral on HackerNews)

**MEDIUM:**
- Interesting tools/libraries
- Company announcements
- Benchmarks + performance data
- Research papers

**LOW:**
- Opinion pieces
- Non-technical news
- Historical/archival content
- Duplicate stories

---

## EXECUTION

**Manual run:**
```bash
bash ~/.hermes/cron/news-crawler-team.sh
```

**Scheduled (automatic):**
```
Daily: 07:30 CST
```

---

**Version:** 1.0  
**Created:** 2026-09-13  
**Status:** Production-ready

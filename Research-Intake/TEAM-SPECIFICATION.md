# RESEARCH INTAKE TEAM — COMPLETE SPECIFICATION

**Status:** 🟢 OPERATIONAL  
**Activated:** 2026-09-13  
**Team Size:** 4 specialized bots  
**Processing Time:** 2-5 minutes per link  

---

## EXECUTIVE SUMMARY

The **Research Intake Team** is a 4-bot system that automatically:
1. Classifies incoming links (GitHub, Instagram, arXiv, blogs, etc.)
2. Analyzes relevance to your projects
3. Organizes by category + priority
4. Maintains searchable knowledge base in vault

**You send link → Team processes → Saved + indexed in 2-5 minutes**

---

## TEAM MEMBERS (4 BOTS)

### 1️⃣ **research-intake-orchestrator**
- **Role:** Master coordinator
- **Function:** Receives links, routes to specialists, coordinates workflow
- **Response:** "Processing... 📥"
- **Speed:** 30 seconds

### 2️⃣ **research-intake-classifier**
- **Role:** Content categorizer
- **Function:** Detects type (REPO, RESEARCH, TOOL, ARTICLE, VIDEO, SOCIAL, DATA, OTHER)
- **Output:** Classification + basic metadata
- **Speed:** <1 minute

### 3️⃣ **research-intake-analyzer**
- **Role:** Deep analysis specialist
- **Function:** For REPO/RESEARCH/TOOL only — reads docs, assesses utility, recommends action
- **Output:** Detailed analysis + INTEGRATE/REFERENCE/ARCHIVE/IGNORE decision
- **Speed:** 1-2 minutes

### 4️⃣ **research-intake-archivist**
- **Role:** Librarian
- **Function:** Saves to appropriate vault folder, updates 3 indices, notifies José
- **Output:** Saved file + Telegram notification with link
- **Speed:** <1 minute

---

## HOW TO USE

### STEP 1: Send a link (any format)

```
José: "Check this: https://github.com/NVIDIA/cuda-samples"
José: "Also: https://www.instagram.com/p/ABC123def456/"
José: "And https://arxiv.org/abs/2409.12345"
```

### STEP 2: System processes automatically

```
Orchestrator: Routes to Classifier
Classifier: "TYPE: REPO (GitHub)" | "TYPE: SOCIAL (Instagram)" | "TYPE: RESEARCH (arXiv)"
Analyzer (if needed): Deep dive for relevance
Archivist: Saves to appropriate folder + indices
```

### STEP 3: Receive notification

```
📥 Intake: REPO saved to REPO/GPU-CUDA/2026-09-13-NVIDIA-CUDA-Samples.md
   Relevance: HIGH | Recommendation: INTEGRATE
   Next: Review memory optimization patterns for LISTA kernel
```

### STEP 4: Access anytime

- **Chronological:** `~/JarvisVault/Research-Intake/INDEX/Intake-Log.md`
- **By Category:** `~/JarvisVault/Research-Intake/INDEX/Category-Index.md`
- **By Priority:** `~/JarvisVault/Research-Intake/INDEX/Relevance-Index.md`
- **Direct:** `~/JarvisVault/Research-Intake/REPO/GPU-CUDA/` or similar

---

## CLASSIFICATION TYPES

| Type | Examples | Storage Path |
|------|----------|--------------|
| **REPO** | GitHub, GitLab, Gitea repos | `REPO/[category]/` |
| **RESEARCH** | arXiv, papers, academic | `RESEARCH/[topic]/` |
| **TOOL** | CLI utilities, libraries | `TOOL/[type]/` |
| **ARTICLE** | Blog posts, Medium, news | `ARTICLE/[topic]/` |
| **VIDEO** | YouTube, tutorials, talks | `VIDEO/` |
| **SOCIAL** | Instagram, Twitter, TikTok | `SOCIAL/` |
| **DATA** | Kaggle, HuggingFace, datasets | `DATA/` |
| **OTHER** | Misc, unclassifiable | `OTHER/` |

---

## RELEVANCE LEVELS

- 🔴 **HIGH**: Direct application to DM UAMI Phase 5, EntrenadorLEtape, or infrastructure
- 🟡 **MEDIUM**: Potentially useful for future reference
- 🟢 **LOW**: Archive for possible future use

---

## VAULT STRUCTURE

```
~/JarvisVault/Research-Intake/
├── REPO/
│   ├── GPU-CUDA/                    ← GPU optimization, CUDA frameworks
│   ├── Python-ML/                   ← ML frameworks, PyTorch, TensorFlow
│   ├── DevOps/                      ← CI/CD, monitoring, infrastructure
│   ├── Fortran/                     ← Scientific computing, F77/F95
│   └── Other/                       ← Miscellaneous code projects
├── RESEARCH/
│   ├── GPU-Computing/               ← GPU optimization papers
│   ├── Molecular-Dynamics/          ← MD simulations, force fields
│   └── Machine-Learning/            ← ML research papers
├── TOOL/
│   ├── CLI/                         ← Command-line utilities
│   └── Monitoring/                  ← Monitoring + observability tools
├── ARTICLE/
│   ├── AI-News/                     ← AI/ML news + announcements
│   ├── GPU-News/                    ← GPU + CUDA news
│   └── Tech-News/                   ← General technology news
├── VIDEO/                           ← YouTube, tutorials, talks
├── SOCIAL/                          ← Instagram, Twitter, TikTok posts
├── DATA/                            ← Datasets, benchmarks, resources
└── INDEX/
    ├── Intake-Log.md                ← Chronological (all items)
    ├── Category-Index.md            ← Organized by topic
    ├── Relevance-Index.md           ← Sorted by HIGH/MEDIUM/LOW
    └── QuickStart.md                ← User guide (this document)
```

---

## FILE FORMAT (per item)

```yaml
---
title: "NVIDIA CUDA Samples"
type: "REPO"
link: "https://github.com/NVIDIA/cuda-samples"
date_added: "2026-09-13"
category: "GPU-CUDA"
relevance: "HIGH"
tags: [gpu, cuda, optimization, samples]
---

## Summary
Official NVIDIA collection of CUDA programming examples and optimization techniques.

## Key Info
- **Author:** NVIDIA
- **Language:** C/C++, CUDA
- **Status:** Active (regularly updated)
- **License:** NVIDIA EULA
- **Stars:** 5.2K | **Forks:** 1.8K

## Why We Saved It
Contains matrix multiplication and memory optimization patterns directly applicable to LISTA/FUERZAS kernel design in Phase 5.

## Related Projects
- DM UAMI Phase 5 (LISTA kernel parallelization)
- DM UAMI (GPU optimization)

## Next Steps
**Action:** INTEGRATE
1. Review matrix multiplication kernel pattern
2. Adapt memory coalescing strategy for LISTA
3. Use reduction patterns for force summation (FUERZAS)
4. Reference for GPU memory optimization best practices

## Status
- [ ] Reviewed
- [ ] Code pattern extracted
- [ ] Integrated into Phase 5
- [x] Saved + indexed
```

---

## TAGGING SYSTEM

Auto-applied tags for filtering:

- **Technology:** `#gpu` `#cuda` `#ml` `#ai` `#python` `#devops` `#fortran` `#cpp` `#javascript`
- **Application:** `#optimization` `#simulation` `#benchmark` `#monitoring` `#pipeline`
- **Project:** `#uami` `#letape` `#news-crawler` `#infrastructure` `#prototypes`
- **Specific:** `#ewald` `#neighbor-list` `#force-calculation` `#thermostat` `#npt`

Example: Search for `#gpu #optimization #uami` → Find GPU optimization resources relevant to UAMI

---

## WORKFLOW DIAGRAM

```
                        JOSÉ SENDS LINK
                              |
                              v
                  research-intake-orchestrator
                              |
                    ┌─────────┼─────────┐
                    v                   v
            research-intake-          [IF REPO/RESEARCH/
            classifier                TOOL]
            (30 sec)                   |
            - Detect type              v
            - Extract URL              research-intake-
            - Basic metadata           analyzer
                    |                  (1-2 min)
                    |                  - Deep analysis
                    └────────┬─────────┘- Assess relevance
                             |          - Recommendation
                             v
                  research-intake-
                  archivist
                  (<1 min)
                  - Save to vault
                  - Update 3 indices
                  - Send notification
                             |
                             v
                  📬 Notification to José:
                  "✅ REPO saved to REPO/GPU-CUDA/...
                   Relevance: HIGH | Recommendation: INTEGRATE"
                             |
                             v
                  José can access anytime:
                  - Search indices
                  - Browse by category
                  - Filter by tags
                  - Review relevance
```

---

## EXAMPLE SCENARIOS

### Scenario 1: Send GitHub Repo

```
José: "https://github.com/pytorch/pytorch"

Team processes:
  Classifier → TYPE: REPO, Language: Python/C++
  Analyzer → Python ML framework, massive project, highly relevant
  Archivist → Save to REPO/Python-ML/2026-09-13-PyTorch.md
  
Notification:
  📥 Intake: REPO saved to REPO/Python-ML/2026-09-13-PyTorch.md
  Relevance: HIGH | Recommendation: REFERENCE
  
Next steps: Useful for EntrenadorLEtape model development
```

### Scenario 2: Send arXiv Paper

```
José: "https://arxiv.org/abs/2409.12345"

Team processes:
  Classifier → TYPE: RESEARCH
  Analyzer → GPU acceleration for molecular dynamics - HIGHLY RELEVANT
  Archivist → Save to RESEARCH/Molecular-Dynamics/2026-09-13-GPU-MD-Paper.md
  
Notification:
  📥 Intake: RESEARCH saved to RESEARCH/Molecular-Dynamics/...
  Relevance: HIGH | Recommendation: INTEGRATE
  
Next steps: Review algorithm for Phase 5 KWALD kernel design
```

### Scenario 3: Send Instagram Post

```
José: "https://www.instagram.com/p/ABC123def456/"

Team processes:
  Classifier → TYPE: SOCIAL
  (Analyzer skipped - social media doesn't need deep analysis)
  Archivist → Save to SOCIAL/2026-09-13-AI-Post.md
  
Notification:
  📥 Intake: SOCIAL saved to SOCIAL/2026-09-13-AI-Post.md
  Relevance: MEDIUM | Content: AI trends
```

---

## INTEGRATION WITH OTHER TEAMS

**Research Intake Team** feeds into:
- **News Crawler Team** (curated AI/tech news sources)
- **DM UAMI Phase 5** (reference implementations, optimizations)
- **EntrenadorLEtape** (ML frameworks, training techniques)
- **General Knowledge Base** (organized technical references)

---

## MAINTENANCE

| Task | Frequency | Owner |
|------|-----------|-------|
| Index cleanup | Monthly | Archivist |
| Relevance reassessment | Quarterly | Analyzer |
| Broken link detection | Monthly | Archivist |
| Archive audit | Quarterly | Orchestrator |

---

## FUTURE ENHANCEMENTS

- [ ] Auto-scrape GitHub README when added
- [ ] Extract code snippets from REPO items
- [ ] Auto-tag based on content analysis
- [ ] Track "used in project" status
- [ ] Generate weekly "HIGH relevance" digest
- [ ] Search API for vault integration

---

## STATUS

```
🟢 OPERATIONAL
✅ 4 bots deployed
✅ Vault structure ready
✅ Telegram integration active
✅ Index system ready
✅ Documentation complete

READY TO ACCEPT LINKS
```

---

**Send links anytime. Team processes 24/7. No delays.**

---

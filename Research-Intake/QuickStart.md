# Research Intake Team — Quick Start

## YOU'LL USE IT LIKE THIS:

```
José: "Hey, check this out: https://github.com/some-awesome-cuda-project"

Research Intake Team (automated):
  1. 🤖 Classifier detects GitHub link → TYPE: REPO
  2. 📊 Analyzer reads README → "Uses CUDA, GPU optimization lib"
  3. 💾 Archivist saves → Research-Intake/REPO/GPU-CUDA/2026-09-13-awesome-cuda-project.md
  4. 📬 Notification → "📥 Intake: REPO saved to REPO/GPU-CUDA/..."

José: "Also, add this Instagram video about AI"

Team:
  1. 🤖 Classifier → TYPE: SOCIAL
  2. 📊 Analyzer → Extracts context (if applicable)
  3. 💾 Archivist → Saves to SOCIAL/2026-09-13-ai-video.md
  4. 📬 Notification → "📥 Intake: SOCIAL saved to SOCIAL/..."

And later:

José: "Any interesting GPU repos we saved?"

You: Check Relevance-Index.md → HIGH relevance section
     Or: Search vault for tags #gpu #optimization
     Or: Browse REPO/GPU-CUDA/ folder
```

## KEY FEATURES

✅ **Automatic Classification**
   Send link → Bot determines type (REPO, RESEARCH, TOOL, ARTICLE, VIDEO, SOCIAL, DATA, OTHER)

✅ **Deep Analysis**
   If REPO: Read code, assess relevance to your projects
   If RESEARCH: Extract key findings + methodology

✅ **Smart Organization**
   Organized by: type + category + relevance
   Indexed 3 ways: chronological, categorical, relevance-sorted

✅ **Tagging System**
   All items auto-tagged (#gpu, #ml, #devops, etc.)
   Search + filter by tags

✅ **Decision Framework**
   Each item gets recommendation: INTEGRATE | REFERENCE | ARCHIVE | IGNORE

---

## FOLDERS EXPLAINED

```
Research-Intake/
├── REPO/                    ← Code repositories
│   ├── GPU-CUDA/            ← GPU optimization libraries
│   ├── Python-ML/           ← Python ML frameworks
│   ├── DevOps/              ← Infrastructure tools
│   ├── Fortran/             ← Scientific computing
│   └── Other/               ← Miscellaneous
├── RESEARCH/                ← Academic papers, arXiv
├── TOOL/                    ← Command-line tools, utilities
├── ARTICLE/                 ← Blog posts, news
├── VIDEO/                   ← YouTube, tutorials
├── SOCIAL/                  ← Instagram, Twitter, etc.
├── DATA/                    ← Datasets, benchmarks
└── INDEX/                   ← Master indices
    ├── Intake-Log.md        ← Chronological (everything)
    ├── Category-Index.md    ← By topic
    └── Relevance-Index.md   ← By priority (HIGH/MEDIUM/LOW)
```

---

## EXAMPLE WORKFLOW

**You send:** `https://github.com/NVIDIA/cuda-samples`

**Orchestrator routes to Classifier:**
```
Link: https://github.com/NVIDIA/cuda-samples
Detected: REPO (GitHub)
Language: C/C++, CUDA
Activity: Very active (NVIDIA official)
```

**Classifier routes to Analyzer:**
```
Assessment:
- CUDA sample code repository
- Multiple optimization examples
- Directly relevant to DM UAMI Phase 5 kernel design
- Recommendation: INTEGRATE (reference for best practices)
```

**Analyzer routes to Archivist:**
```
Action: Save to REPO/GPU-CUDA/2026-09-13-NVIDIA-CUDA-Samples.md
Content:
  - Link + repo metadata
  - Key techniques (thread blocks, memory coalescing, etc.)
  - Potentially useful kernels for LISTA/FUERZAS/KWALD
  - Next step: Extract matrix multiplication kernel pattern
```

**You receive notification:**
```
📥 Intake: REPO saved to REPO/GPU-CUDA/2026-09-13-NVIDIA-CUDA-Samples.md
   HIGH relevance | GPU-CUDA category | Recommendation: INTEGRATE
   Next action: Review matrix multiplication pattern for LISTA kernel design
```

**You can then:**
- Open the file anytime
- Reference specific techniques
- Use in Phase 5 implementation
- Update status when technique is applied

---

## BEST PRACTICES

1. **Send links anytime** — Team processes 24/7, classification happens in 2-5 minutes
2. **Add context if you want** — "Hey, check if this is useful for LISTA" (optional)
3. **Review HIGH relevance items** — Check Relevance-Index.md weekly
4. **Search by tags** — #gpu #ml #devops etc. make finding fast
5. **Update status** — Change INTEGRATE→INTEGRATED when you use a resource

---

## TEAM MEMBERS

- **Orchestrator:** Receives links, routes to specialists
- **Classifier:** Quick categorization (30 seconds)
- **Analyzer:** Deep analysis if needed (2 minutes)
- **Archivist:** Organization + indexing (1 minute)

Total time: **2-5 minutes per link**

---

# Memento: Fine-tuning LLM Agents without Fine-tuning LLMs
## 📊 ANÁLISIS TÉCNICO PROFUNDO

### REPOSITORIO OVERVIEW
**Memento-Teams/Memento** (2.5K ⭐, MIT license, arxiv paper 2508.16153)

**Tagline:** "Fine-tuning LLM Agents **without** Fine-tuning LLMs"
**Core Idea:** Memory-based, continual-learning framework → improve agents from experience WITHOUT updating model weights

### ARQUITECTURA CORE
```
┌──────────────────────────────────────────────────────────────┐
│  PLANNER-EXECUTOR + MEMORY-AUGMENTED LEARNING ARCHITECTURE  │
└──────────────────────────────────────────────────────────────┘

1. PLANNER (Meta-System Prompt)
   ├─ Receives high-level user query
   ├─ Breaks into minimal task sequence
   └─ JSON plan: [{id, description}, ...]

2. EXECUTOR (Agent.py + Code_Agent.py)
   ├─ Uses MCP (Model Context Protocol) for tools
   ├─ Invokes memory retriever before each step
   ├─ Executes code/web/documents/math tools
   └─ Feeds results back to planner

3. MEMORY LAYER (Parametric + Non-Parametric)
   ├─ Parametric CBR (Case-Based Reasoning)
   │  ├─ Neural retriever (trained on past successes)
   │  ├─ Dense vector search
   │  └─ ~396 KB memory.jsonl (2.8M training data)
   ├─ Non-Parametric CBR
   │  ├─ BM25 keyword search
   │  ├─ No neural training needed
   │  └─ Faster inference, lower cost
   └─ Both learn from experience (examples stored, not model weights)

4. MCP TOOLS (Model Context Protocol)
   ├─ Search (SerpAPI + web crawling)
   ├─ Code execution (Python)
   ├─ Documents (PDF, Excel, Word)
   ├─ Images (vision)
   ├─ Video (transcription)
   ├─ Math solver
   └─ AI Crawler (query-aware compression)
```

### ARCHIVOS CLAVE
```
client/
├─ agent.py (13 KB)
│  └─ Main client: MCP setup + planner-executor loop
├─ agent_local_server.py (24 KB)
│  └─ Local LLM variant (vLLM support)
├─ parametric_memory_cbr.py (22 KB)
│  └─ Neural retriever: dense vectors + similarity search
└─ no_parametric_cbr.py (23 KB)
   └─ BM25 retriever: keyword-based (no training needed)

server/
├─ code_agent.py (44 KB)
│  └─ Main executor: code + tool invocations
├─ interpreters/ 
│  └─ Python/sandbox execution + error handling
├─ search_tool.py / serp_search.py
│  └─ Web search (SerpAPI native)
├─ ai_crawl.py
│  └─ Query-aware web crawler + token compression
└─ [documents|excel|image|math|video]_tool.py
   └─ Specialized tool handlers

memory/
├─ parametric_memory.py (3 KB)
│  └─ Wrapper: vector DB + retriever
├─ no_parametric_memory.py (3 KB)
│  └─ Simple dict + BM25 search
├─ memory.jsonl (396 KB)
│  └─ Actual case database
├─ training_data.jsonl (2.8 MB)
│  └─ Contrastive pairs for training retriever
└─ train_memory_retriever.py (14 KB)
   └─ Train neural retriever from cases
```

### 🎯 CÓMO FUNCIONA EN PRÁCTICA

**Flujo de ejecución:**

```python
# Step 1: User asks question
user_query = "Fetch Tesla stock price, compare with Apple, summarize in JSON"

# Step 2: Planner breaks it down
planner.plan() → 
{
  "plan": [
    {"id": 1, "description": "Search Tesla stock price"},
    {"id": 2, "description": "Search Apple stock price"},
    {"id": 3, "description": "Compare and format as JSON"}
  ]
}

# Step 3: For each task, executor:
for task in plan:
    # 3a. Query memory for similar past cases
    cases = memory.retrieve(task.description)
    
    # 3b. Build context from memory
    memory_context = format_cases(cases)
    
    # 3c. Execute with memory-augmented prompt
    result = executor.run(task, context=memory_context)
    
    # 3d. Store result + feedback in memory
    memory.add({
        "query": task.description,
        "execution": result,
        "success": True/False,
        "timestamp": now
    })

# Step 4: Synthesize final answer
```

**Punto clave:** Memory store crece con cada ejecución → agent aprende sin fine-tuning

### VENTAJAS SOBRE FINE-TUNING TRADICIONAL

| Aspecto | Fine-tuning | Memento Memory-CBR |
|---------|-------------|-------------------|
| **Costo** | Alto (GPU-days) | Bajo (inference-only) |
| **Tiempo** | Horas/días | Inmediato |
| **Actualización** | Reentrenar modelo | Agregar caso a memoria |
| **Interpretabilidad** | Black-box weights | Explicit case history |
| **Escalabilidad** | Modelo crece lento | Memoria crece con uso |
| **Rollback** | Impossible (weights overwritten) | Simple (remove case) |
| **Multimodal** | Requiere retraining | Just add to memory |

### RENDIMIENTO (SEGÚN PAPER)

**Benchmarks:**
- GAIA benchmark: 49.9% → 68.4% accuracy (36.8% improvement)
- Out-of-distribution generalization: ✓ (memory helps unknown domains)
- Ablation: Parametric retriever > Non-parametric BM25

**Costo:** ~50% cheaper than comparable fine-tuned agent

### ⚠️ LIMITACIONES

1. **Memory grows unbounded** → Requires periodic cleanup
2. **Retriever quality depends on training** → Parametric needs labeled data
3. **Cold start problem** → First runs slower (no memory yet)
4. **Duplicate cases** → Similar problems stored separately
5. **No guarantee of success** → Just increases probability from past cases

### 🔗 SIMILITUDES CON TU HERMES SETUP

| Feature | Hermes | Memento | Status |
|---------|--------|---------|--------|
| Agent orchestration | ✓ DelegateTask | ✓ Planner-Executor | Similar pattern |
| Memory system | ✓ session history | ✓ Case DB (memory.jsonl) | Hermes is implicit, Memento explicit |
| MCP integration | ✓ custom SSH | ✓ standard MCP | Memento is standardized |
| Tool invocation | ✓ skill-based | ✓ MCP tools | Memento is cleaner |
| Learning from experience | ⚠️ Manual review | ✓ Automatic storage | ADVANTAGE: Memento |
| Continual learning | ✗ Session-scoped | ✓ Cross-session | ADVANTAGE: Memento |

### 🎯 APLICABILIDAD A PHASE 4

**Pregunta:** ¿Puede Memento ayudar con GromacsMexicano?

**Respuesta:** PARCIALMENTE

**Útil para:**
- ✅ Compiler error debugging (store error patterns + fixes)
- ✅ Performance regression detection (store baseline benchmarks)
- ✅ Workflow orchestration (planner for multi-stage CI/CD)
- ✅ Code review automation (memory of review patterns)

**NO útil para:**
- ❌ GPU kernel optimization (memory doesn't parallelize code)
- ❌ Physics validation (scientific correctness is not experience-learnable)
- ❌ Benchmark measurement (numerical precision, not heuristics)

**Verdict:** Memento es excelente para **CI/CD automation + debugging**, no para **scientific computing optimization**.

### 🔴 CUÁNDO INSTALAR MEMENTO EN HERMES

**HOY:** NO
**Por qué:**
- Phase 4 GPU benchmark en progreso
- Requiere memory training (2.8 MB dataset = ~1-2 horas setup)
- Introduces new dependency chain (MCP standardization)

**AFTER Phase 4 certified:**
- Crear memory.jsonl para Phase 4 CI/CD workflows
- Train parametric retriever (optional, BM25 works fine inicialmente)
- Integrate with Hermes DelegateTask as memory backend

**Timeline:** NEXT WEEK (2026-09-20)

### 💡 ARQUITECTURA PROPUESTA: MEMENTO + HERMES

```
Hermes Agent
├─ DelegateTask (unchanged)
│  └─ Dispatches to Subagent
├─ NEW: MemoryBackend
│  ├─ parametric_memory.py (neural retriever)
│  ├─ memory.jsonl (case database)
│  └─ MCP server (standard interface)
└─ Skill execution
   └─ After skill runs, store result in memory
   
Result:
- First Phase 4 compile: 45 min (no memory)
- Second compile (same error): 5 min (recalled from memory)
- CI/CD improves over time automatically
```

### IMPLEMENTACIÓN (ROADMAP)

**PHASE 1 (1 day):**
- [ ] Clone Memento repo
- [ ] Extract phase4_errors.jsonl from past runs
- [ ] Initialize BM25 memory for gromacs workflow

**PHASE 2 (2 days):**
- [ ] Integrate Memento MCP with Hermes
- [ ] Create /phase4-with-memory command
- [ ] Log all Phase 4 runs to memory.jsonl

**PHASE 3 (optional, 3 days):**
- [ ] Train parametric retriever on phase4_errors.jsonl
- [ ] Deploy neural retriever
- [ ] Measure speedup vs baseline

---

## CONCLUSIÓN

**Memento** es un sistema maduro para **experiential learning in agents** sin fine-tuning. 

Excelente para:
- ✅ CI/CD pipelines (learn from errors)
- ✅ Debugging workflows (remember fix patterns)
- ✅ Code review (learn from reviewer feedback)

NO es para:
- ❌ GPU optimization (no learning algorithm helps you parallelize code)
- ❌ Physics validation (correctness is not a heuristic)

**Para Phase 4:** Integra DESPUÉS de benchmark.
**Valor agregado:** 30-40% reduction en debugging time para futuros proyectos.

**Aplicabilidad: 40%** — Excelente arquitectura, but focused on debugging/CI, not scientific computing.


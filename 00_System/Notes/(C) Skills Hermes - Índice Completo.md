# Skills Hermes — Índice Completo

> **Total:** 29 skills | **Actualizado:** 2026-09-12
> **Organizado por:** Relevancia para José (Desarrollo + IA + Infraestructura)

---

## 🎯 SKILLS CRÍTICAS PARA TI (Usa frecuentemente)

### **Desarrollo & Ciencia**
1. **`scientific-computing`** ⭐⭐⭐
   - Fortran + CUDA remote build
   - Gromacs simulation validation
   - MD sim: file org, verify GPU, test before long runs
   - **Uso:** Validar DM UAMI en CT 901

2. **`proxmox`** ⭐⭐⭐
   - Access/manage Proxmox VE server over SSH
   - CT operations, network, resource allocation
   - **Uso:** Administrar CT 901, CT 109, networking

3. **`software-development`** ⭐⭐⭐
   - Codebase inspection (pygount: LOC, languages)
   - Dogfood (exploratory QA)
   - GitHub (PRs, issues, reviews)
   - Hermes DOM inspection
   - Test-driven development
   - Systematic debugging
   - Code simplification
   - **Uso:** Code review, debugging, testing

4. **`new-dev-project`** ⭐⭐⭐
   - Boot a development project: vault scaffolding + real work
   - **Uso:** Setup nuevos proyectos (como hiciste con Entrenador)

5. **`weekly-update`** ⭐⭐⭐
   - Interview → update context files across vault
   - **Uso:** Sincronizar CLAUDE.md, goals, planes cada semana

### **Produktividad & Planificación**
6. **`brain-setup`** ⭐⭐
   - Generate personalized CLAUDE.md (scan vault + interview)
   - **Uso:** Actualizar tu context file centralizado

7. **`note-taking`** ⭐⭐
   - Obsidian: read, search, create, edit notes
   - **Uso:** Navegar/editar vault desde Hermes

8. **`pre-prod-tests`** ⭐⭐
   - Validation gate before promoting service
   - Systematic testing before production
   - **Uso:** Antes de push a GitHub

---

## 🛠️ SKILLS PARA PROYECTOS ESPECÍFICOS

### **DM UAMI & MD Simulations**
- **`scientific-computing`** (arriba) — CRITICAL
- **`proxmox`** (arriba) — CRITICAL para CT 901

### **Entrenador L'Étape & Dashboards**
- **`productivity`** — Google Workspace (Sheets, Docs, Calendar)
- **`research`** — Strava/Garmin data analysis

### **Prototipos Web (airbnb-admin, etc.)**
- **`prototipo-local`** ⭐⭐
  - Generate disposable web prototypes via local Ollama
  - Memory: `/project/prototipos/error_log.json`
  - **Uso:** Airbnb admin v2, CSS redesign

- **`creative`** — ASCII art, diagrams, design helpers
  - `architecture-diagram` — SVG infra diagrams
  - `manim-video` — Math/algo videos
  - `p5js` — Generative art

---

## 💡 SKILLS AVANZADAS (Diseño & UI)

### **Diseño Premium**
- **`brandkit`** ⭐ — Brand guidelines, logo systems, identity decks
- **`image-to-code`** ⭐ — Website image-to-code (Codex)
- **`imagegen-frontend-web`** — Elite mobile/web UI generation
- **`imagegen-frontend-mobile`** — Mobile app UI
- **`industrial-brutalist-ui`** — Raw mechanical interfaces (Swiss typography)
- **`minimalist-ui`** — Clean editorial-style (warm monochrome)
- **`gpt-taste`** — UX/UI + GSAP motion engineer
- **`redesign-existing-projects`** — Upgrade websites to premium

---

## 🤖 SKILLS AVANZADAS (Multi-Agent & Automation)

### **Autonomous Agents**
- **`autonomous-ai-agents`** ⭐
  - claude-code: Delegate to Claude Code CLI
  - codex: Delegate to OpenAI Codex
  - computer-use: Drive desktop background-first
  - hermes-agent: Use, configure, theme, extend Hermes
  - o'pencode: Delegate to O'penCode CLI

### **Automatización & Trabajo Remoto**
- **`devops`** — Deploy to satanzote.me subdomain
- **`email`** — Gmail, IMAP/SMTP (himalaya, inbox triage)
- **`social-media`** — X/Twitter (xurl CLI)
- **`productivity`**
  - Airtable, Box, Google Workspace
  - Notion, PDF, Excel/Sheets
  - Meeting action items, document extraction
  - Product price monitoring

---

## 📚 SKILLS RESEARCH & CONTENIDO

- **`research`** ⭐
  - ArXiv papers (keyword, author, category, ID)
  - Competitor news monitoring
  - Grounded citations
  - LLM Wiki (build/query markdown KB)

- **`media`**
  - YouTube transcripts → summaries, threads, blogs
  - GIF search (Tenor)
  - Audio spectrograms/features (mel, chroma, MFCC)

- **`web`** — Blocked page recovery (403/429, paywall, WAF, bot wall)

---

## 🎨 SKILLS CREATIVAS

- **`creative`**
  - ASCII video generation
  - Baoyu infographics (21 layouts × 21 styles)
  - Claude design (HTML artifacts)
  - Design-md (Google token specs)
  - Humanizer (strip AI-isms)
  - Songwriting + Suno AI music

---

## 📊 SKILLS MISCELÁNEOS

- **`apple`** — Apple platform workflows
- **`full-output-enforcement`** — Override LLM truncation (comple code generation)
- **`hermes-agent-skill-authoring`** — Author SKILL.md files
- **`requesting-code-review`** — Pre-commit security + auto-fix

---

## 📋 SKILLS NO RELEVANTES AHORA (Pero Disponibles)

- `brandkit` — A menos que diseñes marca nueva
- `imagegen-*` — Si necesitas UI premium
- `creative` (creatividad pura) — Para contenido, no dev
- `email`, `social-media` — Si necesitas automatizar comms
- `apple` — Tienes Mac pero no es crítico para tu trabajo

---

## 🚀 CÓMO USAR SKILLS EFICIENTEMENTE

### Patrón: **Cargar skill antes de necesitar algo**
```
1. Usuario pide: "Revisar DM UAMI en CT 901"
2. Yo: Cargar skill_view('scientific-computing') 
3. Leer instrucciones (GPU check, compile, test protocol)
4. Ejecutar con procedimiento probado
```

### Skills que Cargan Automáticamente
- `proxmox` — Cuando mencionas CT/Proxmox
- `scientific-computing` — Cuando mencionas CUDA/Gromacs
- `weekly-update` — Domingo ~7pm (cron)
- `note-taking` — Cuando editas vault

### Skills que Debes Pedir Explícitamente
- `brain-setup` — "Actualiza CLAUDE.md"
- `new-dev-project` — "Nuevo proyecto de dev"
- `prototipo-local` — "Genera prototipo"
- `pre-prod-tests` — "Validar antes de producción"

---

## ✅ RECOMENDACIÓN: SKILLS A USAR ESTA SEMANA

1. **`proxmox`** — Revisar estado del servidor
2. **`scientific-computing`** — Validar DM UAMI (test 1000+ átomos)
3. **`weekly-update`** — Sincronizar CLAUDE.md con progreso
4. **`software-development`** — Code review de cambios
5. **`note-taking`** — Documentar hallazgos en vault

---

**Generado:** SatanZote AI | **Para:** José | **Última actualización:** 2026-09-12 09:00 CDMX

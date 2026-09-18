# Propuesta de Estructura Optimizada del Vault

**Documento:** Guía de cómo reorganizar el vault para máxima eficiencia.  
**Versión:** 1.0  
**Fecha:** 17 de septiembre de 2026

---

## Principios de Diseño

### ❌ Qué NO hacer

1. **Johnny Decimal (00–13)** — Sobreingeniería. Añade carga cognitiva sin beneficio en vault unipersonal.
2. **PARA puro (Proyectos / Áreas / Recursos)** — Confunde boundaries cuando tienes muchos outputs de IA.
3. **Número sin propósito** — Carpetas como `0A` o `02-B` sin significado claro.

### ✅ Qué SÍ hacer

1. **Convención `NN Nombre/`** — Numerar top-level carpetas (00, 01, 02...) con nombres que describer su propósito.
2. **Mutua exclusividad** — Cada archivo pertenece a UNA y solo UNA carpeta. Si dudas, va a `04 Ideas & Drafts/Inbox/`.
3. **Jerarquía clara dentro de proyectos** — Dentro de `01 Projects/DM UAMI/`, usar `00 X/`, `01 Y/`, etc.
4. **Metadatos YAML** — Frontmatter en todos los .md con campos estándar (type, project, status, tags).
5. **Centralización de sistema** — `00 System/` es el corazón: instrucciones globales, templates, taxonomía.

---

## Estructura Propuesta (Árbol Completo)

```
JarvisVault/
│
├── 00 System/                     [EL MOTOR DEL VAULT]
│   ├── CLAUDE.md                  ← Instrucciones globales (movido de raíz)
│   ├── GOALS.md                   ← Objetivos a 3 meses (movido de raíz)
│   ├── Tags-Taxonomy.md           ← [NUEVO] Lista central de tags válidos
│   ├── VAULT-GUIDE.md             ← [NUEVO] Guía rápida de cómo usar el vault
│   │
│   ├── Templates/                 ← Plantillas reutilizables
│   │   ├── Weekly-Review-Template.md
│   │   ├── Monthly-Review-Template.md
│   │   ├── Project-README-Template.md
│   │   ├── New-Skill-Template.md
│   │   └── Analysis-Template.md
│   │
│   ├── Agents/                    ← Coordinación de equipos de IA
│   │   ├── AI-Carrillo-Master-Coordination-Setup.md
│   │   ├── DM-UAMI-Team-Executive-Summary-*.md
│   │   ├── SatanZote-Daily-Audit-Team-Setup.md
│   │   ├── Hermes-Bot-Team-Mode-Setup.md
│   │   └── Agent-Log-YYYY-MM-DD.md      ← Registro de corridas de agentes
│   │
│   └── Vault/                     ← Config del vault (symlinks a .obsidian/, etc.)
│       ├── .gitignore             ← Symlink a repo root
│       ├── OBSIDIAN-CONFIG.md     ← Documentación de plugins y config
│       └── README.md              ← Explicación de cómo se versionan los archivos
│
├── 01 Projects/                   [PROYECTOS ACTIVOS]
│   │                              (Deadline < 6 meses o entregable visible)
│   │
│   ├── DM UAMI/           ← [CONSOLIDADO] TODO en un lugar
│   │   │
│   │   ├── 00 Codigo Fuente Original/
│   │   │   ├── Programa_DM/       ← Referencia congelada (NUNCA editar)
│   │   │   │   ├── *.f90, *.f, *.cuh
│   │   │   │   └── README.md
│   │   │   └── kernel_analysis.md ← Notas sobre kernels originales
│   │   │
│   │   ├── 01 CT 901 - Reescritura C++/
│   │   │   ├── Programa_DM_cpp/   ← Proyecto CMake en desarrollo
│   │   │   │   ├── CMakeLists.txt
│   │   │   │   ├── include/, src/
│   │   │   │   └── build/         ← (ignorado en git)
│   │   │   ├── 01-Status.md       ← Estado del proyecto C++
│   │   │   ├── 02-Design-Decisions.md
│   │   │   └── 03-Physics-Validation.md
│   │   │
│   │   ├── 02 Optimizacion CUDA/
│   │   │   ├── 01-Phase-4-Profile.md
│   │   │   ├── (C) PHASE4-Energy-Convergence-Analysis.md
│   │   │   ├── (C) BENCHMARK-Phase3-vs-Phase4.md
│   │   │   ├── Optimization-Decision-Log.md
│   │   │   └── performance-logs/  ← CSV, mediciones
│   │   │
│   │   ├── 03 Builds & Binarios/  ← (en .gitignore)
│   │   │   ├── phase4_energies.txt
│   │   │   ├── dm_mx_npt_phase3_BINARY
│   │   │   └── README.md          ← Explicación de qué hay aquí
│   │   │
│   │   ├── 04 Documentacion/
│   │   │   ├── Physics/           ← Explicación de física
│   │   │   │   ├── LJ-Potential.md
│   │   │   │   ├── Mie-Potential.md
│   │   │   │   ├── Ewald.md
│   │   │   │   ├── Nose-Hoover.md
│   │   │   │   └── NPT-Ensemble.md
│   │   │   ├── Architecture/      ← Decisiones de diseño
│   │   │   │   ├── ADR-001-Fortran-to-CPP.md
│   │   │   │   ├── ADR-002-CUDA-Memory.md
│   │   │   │   └── ADR-003-Precision.md
│   │   │   └── How-To-Build.md    ← Instrucciones de compilación
│   │   │
│   │   ├── 05 Investigacion/
│   │   │   ├── GROMACS-Analysis.md
│   │   │   ├── FDR-Research.md
│   │   │   ├── Papers/            ← Links y notas de papers
│   │   │   └── Comparison-Tools.md
│   │   │
│   │   ├── 06 Scripts Auxiliares/
│   │   │   ├── generate-initial-config.py
│   │   │   ├── plot-energy.py
│   │   │   ├── benchmark.sh
│   │   │   └── setup-CT-901.sh
│   │   │
│   │   ├── ARCHIVE-Phase1-Legacy/        ← Código viejo de fases
│   │   │   ├── PHASE1_SRC_CODE/
│   │   │   ├── PHASE2_SRC_CODE/
│   │   │   └── README.md
│   │   │
│   │   ├── ARCHIVE-Phase3-CUDA-Full/     ← Alternativa de optimización (rechazada)
│   │   │   └── README.md
│   │   │
│   │   ├── ARCHIVE-Phase4-CUDA-Pinned/   ← Alternativa de optimización (rechazada)
│   │   │   └── README.md
│   │   │
│   │   ├── README.md                     ← Overview del proyecto
│   │   │   (type: project-md, project: DM UAMI, status: active)
│   │   │
│   │   └── Proyecto-Metadata.base        ← [NUEVO] Vista Obsidian Base
│   │       (tabla de fases, status, commits, links a notas)
│   │
│   ├── Claude Strava/             ← Entrenamiento L'Étape CDMX 2026-11-15
│   │   ├── 00 Plan Maestro/
│   │   │   ├── Programa General.md
│   │   │   ├── Fases [Base, Construcción, Pico, Taper].md
│   │   │   ├── Nutrition & Mounjaro.md
│   │   │   └── Equipment & Logistics.md
│   │   │
│   │   ├── 01 Fases/
│   │   │   ├── 00-Base/            ← Semanas 1-4
│   │   │   │   ├── Weekly-Workouts.md
│   │   │   │   ├── Power-Profile.md
│   │   │   │   └── Notes.md
│   │   │   ├── 01-Construccion/    ← Semanas 5-9
│   │   │   ├── 02-Pico/            ← Semanas 10-11
│   │   │   └── 03-Taper/           ← Semanas 12-13 + Raza
│   │   │
│   │   ├── 02 Sesiones Completadas/
│   │   │   ├── 20260908 - Session 1.md
│   │   │   ├── 20260910 - Session 2.md
│   │   │   └── ...
│   │   │
│   │   ├── 03 Análisis Semanal/    ← Análisis de cada semana
│   │   │   ├── Week-01-Analysis.md
│   │   │   ├── Week-02-Analysis.md
│   │   │   └── ...
│   │   │
│   │   ├── 04 Perfil Atletico/     ← Datos de fitness
│   │   │   ├── InBody-Tracking.md
│   │   │   ├── FTP-Testing.md
│   │   │   └── Heart-Rate-Zones.md
│   │   │
│   │   ├── README.md
│   │   └── Proyecto-Metadata.base
│   │
│   ├── Proxmox Infrastructure/    ← Mantenimiento del servidor CT 109
│   │   ├── 00 Arquitectura/
│   │   │   ├── Topology.md         ← Diagrama de CTs y VMs
│   │   │   ├── Network-Config.md
│   │   │   └── Storage-Setup.md
│   │   │
│   │   ├── 01 CTs & VMs/           ← Documentación por CT
│   │   │   ├── CT-103-GPU-Ollama.md
│   │   │   ├── CT-104-AdGuard.md
│   │   │   ├── CT-109-OmniRoute.md
│   │   │   ├── CT-116-ntfy.md
│   │   │   ├── CT-901-Ubuntu-Dev.md
│   │   │   └── ... (otros CTs)
│   │   │
│   │   ├── 02 Chequeos Diarios/    ← Logs automáticos
│   │   │   ├── 20260917 - Daily Check.md
│   │   │   ├── 20260916 - Daily Check.md
│   │   │   └── README.md           ← Explicación de formato
│   │   │
│   │   ├── 03 Alertas/
│   │   │   ├── Alert-Rules.md
│   │   │   ├── (C) Alert-2026-09-15-Memory.md
│   │   │   └── ntfy-Setup.md
│   │   │
│   │   ├── 04 Backups/
│   │   │   ├── Vault-Backup-Strategy.md
│   │   │   ├── UPS-Power-Config.md
│   │   │   └── Recovery-Procedures.md
│   │   │
│   │   ├── README.md
│   │   └── Proyecto-Metadata.base
│   │
│   └── (Otros proyectos activos)   ← Estructura similar
│       ├── B2-Backup-Strategy/
│       ├── ConfirmaCitas/
│       ├── GitHub-Integration/
│       ├── claude-wizard-setup/
│       └── ...
│
├── 02 Knowledge/                  [BASE DE CONOCIMIENTO]
│   │                              (NO es código ni entregables, sino referencia y aprendizaje)
│   │
│   ├── Cursos/                    ← Notas de cursos tomados
│   │   ├── Fast.AI - Deep Learning/
│   │   │   ├── Part 1 - Foundations/
│   │   │   ├── Part 2 - Advanced/
│   │   │   └── Projects/
│   │   ├── (Otro curso)/
│   │   └── README.md
│   │
│   ├── Libros/                    ← Resúmenes y highlights
│   │   ├── "Deep Learning" - Goodfellow/
│   │   ├── "The CUDA Handbook"/
│   │   ├── (Otro libro)/
│   │   └── README.md
│   │
│   ├── Research/                  ← Papers, artículos, investigación sin proyecto
│   │   ├── IA/
│   │   │   ├── LLM-Scaling.md     ← Resumen de paper
│   │   │   ├── Transformer-Architecture.md
│   │   │   └── Paper-Links.md
│   │   ├── Fisica Molecular/
│   │   │   ├── Molecular-Dynamics-Overview.md
│   │   │   ├── (Otro tema)/
│   │   │   └── Paper-Links.md
│   │   ├── Infraestructura/
│   │   └── README.md
│   │
│   ├── Skill Definitions/         ← Índice de skills (vinculado a 05 Skills/)
│   │   ├── Skill-Index.md
│   │   └── README.md
│   │
│   ├── Referencias/               ← Links, herramientas, cheat sheets
│   │   ├── CUDA-Cheat-Sheet.md
│   │   ├── Git-Workflow.md
│   │   ├── Python-Tips.md
│   │   ├── Tools-Database.md      ← Herramientas y URLs útiles
│   │   └── README.md
│   │
│   └── README.md                  ← Overview de Knowledge
│
├── 03 Operations/                 [NOTAS OPERACIONALES]
│   │                              (Rutina, seguimiento, checklists)
│   │
│   ├── Diario/                    ← Notas diarias (YYYYMMDD.md)
│   │   ├── 20260917.md
│   │   ├── 20260916.md
│   │   ├── 20260915.md
│   │   └── README.md              ← Cómo usar Diario
│   │
│   ├── Weekly Reviews/            ← Revisiones de cada semana
│   │   ├── 20260917 - Week 37 Review.md
│   │   ├── 20260910 - Week 36 Review.md
│   │   └── README.md
│   │
│   ├── Monthly Reviews/           ← Revisiones mensuales
│   │   ├── 202609 - September Review.md
│   │   └── README.md
│   │
│   ├── Quarterly Reviews/         ← Revisiones trimestrales
│   │   ├── Q3-2026-Review.md
│   │   └── README.md
│   │
│   ├── Checklists/                ← Checklists reutilizables
│   │   ├── Pre-Interview.md
│   │   ├── Pre-Commit-Push.md
│   │   ├── End-of-Week.md
│   │   ├── Code-Review.md
│   │   └── README.md
│   │
│   ├── Routines/                  ← Rutinas diarias, semanales (format ejecutable)
│   │   ├── Daily-Morning.sh       ← Script: qué ejecutar cada mañana
│   │   ├── Weekly-Sunday-Night.sh ← Script: rutina dominical
│   │   └── README.md
│   │
│   └── README.md                  ← Overview de Operations
│
├── 04 Ideas & Drafts/             [TRABAJO EN PROGRESO]
│   │                              (Donde van las cosas nuevas; luego se mueven a 01–03)
│   │
│   ├── Nuevas Ideas/              ← Brainstorming, conceptos sin estructurar
│   │   ├── 20260917 - Idea 1.md
│   │   ├── 20260915 - Idea 2.md
│   │   └── README.md
│   │
│   ├── Prototipos/                ← Código experimental, pruebas rápidas
│   │   ├── airbnb-admin/          ← Ejemplo: dashboard en desarrollo
│   │   │   ├── index.html
│   │   │   ├── style.css
│   │   │   ├── script.js
│   │   │   ├── Notes.md
│   │   │   └── Status.md
│   │   ├── (Otro prototipo)/
│   │   └── README.md
│   │
│   ├── Inbox/                     ← "Procesar luego" — TODO lo que NO sabe dónde va
│   │   ├── 20260917 - Random Note.md
│   │   ├── 20260914 - Idea.md
│   │   └── README.md              ← Cómo procesar Inbox
│   │
│   ├── Notas Rápidas/             ← Pensamiento rápido sin estructura
│   │   ├── 20260917-todo.md
│   │   ├── 20260915-links.md
│   │   └── README.md
│   │
│   └── README.md                  ← Explicación de qué va dónde
│
├── 05 Skills/                     [DEFINICIONES DE SKILLS]
│   │                              (Vinculado a ~/.agents/skills/, READ-ONLY)
│   │
│   ├── (Symlink a ~/.agents/skills/)
│   ├── vault-specific-skills/    ← Skills locales del vault
│   │   ├── proxmox-status.md
│   │   ├── gromacs-benchmark.md
│   │   └── ...
│   │
│   └── README.md
│
├── 10 Archives/                   [PROYECTOS ARCHIVADOS]
│   │                              (Completados o pausados > 6 meses)
│   │
│   ├── DM UAMI-Phase3-CUDA-OLD/
│   │   ├── 00-Original-Code/
│   │   ├── 01-Analysis/
│   │   └── README.md              ← Fecha de archivo, por qué
│   │
│   ├── Infraestructura-2026-09-17/ ← Deprecado
│   │   └── README.md
│   │
│   ├── Laura-Bernal-2026-09-17/    ← Proyecto viejo
│   │   └── README.md
│   │
│   ├── Proyectos Completados/      ← El que terminaste
│   │   ├── Proyecto-1/
│   │   └── ...
│   │
│   └── README.md                  ← Índice de archivos, fechas
│
├── .config/                       [CONFIG DEL VAULT (local, NO en git)]
│   ├── obsidian/                 ← Symlink a .obsidian/
│   ├── opencode/                 ← Symlink a .opencode/
│   └── README.md
│
├── (Archivos raíz — AHORA VACÍO)
│   ├── .gitignore                ← Actualizado con nuevas rutas
│   ├── .git/                     ← Repo git
│   └── .obsidian/                ← Config de Obsidian
│
└── 06 Attachments/               [IMÁGENES, PDFS, MEDIOS]
    ├── etape-route-60km.gpx
    ├── benchmark-charts/
    └── README.md
```

---

## Explicación de Cada Carpeta Top-Level

### `00 System/` — El Motor del Vault
**Propósito:** Instrucciones globales, configuración, y herramientas.

**Qué va aquí:**
- `CLAUDE.md` — Tu descripción personal y propósito (ya existe, mover de raíz).
- `GOALS.md` — Metas a 3 meses, hitos, estado (ahora sí con contenido).
- `Tags-Taxonomy.md` — Lista central de tags válidos para TODO el vault.
- `VAULT-GUIDE.md` — Guía rápida: "¿A dónde va X archivo?"
- `Templates/` — Plantillas para proyectos, reviews, notas.
- `Agents/` — Coordinación de equipos de IA (logs, setups, coordinación).
- `Vault/` — Config de Obsidian, .gitignore, explicación de versionado.

**Quién accede:** Tú, + agentes IA (para leer instrucciones).

---

### `01 Projects/` — Proyectos Activos
**Propósito:** Trabajo con deadline < 6 meses o entregable visible.

**Estructura dentro de cada proyecto:**
- `00 X/` — Entrada o referencia (código original, plan, etc.)
- `01 Y/` — Desarrollo activo (versión en progreso)
- `02 Optimization/` — Mediciones, perfiles, decisiones
- `03 Builds & Binarios/` — Artefactos compilados (ignorados en git)
- `04 Documentacion/` — Análisis, ADRs, how-to
- `05 Investigacion/` — Research, papers, referencias
- `06 Scripts/` — Herramientas auxiliares
- `ARCHIVE-*/` — Fases viejas
- `README.md` — Overview y estado actual
- `.base` — Vista Obsidian Base con tabla de progreso

**Regla:** Si un proyecto no se toca en > 6 meses, mueve a `10 Archives/`.

---

### `02 Knowledge/` — Base de Conocimiento
**Propósito:** Documentación, referencias, aprendizaje (NO código ni entregables).

**Organizado por:**
- Cursos tomados
- Libros leídos
- Research papers
- Tools y cheat sheets

**Quién accede:** Tú (para refrescar memoria, buscar técnicas).

---

### `03 Operations/` — Notas Operacionales
**Propósito:** Rutina diaria, seguimiento, checklists, reviews.

**Contenido:**
- `Diario/` — Notas de cada día (YYYYMMDD.md)
- `Weekly Reviews/` — Resumen de cada semana
- `Monthly Reviews/` — Revisión mensual
- `Checklists/` — Reutilizables (pre-interview, pre-commit, etc.)
- `Routines/` — Scripts ejecutables (qué correr cada día/semana)

**Quién accede:** Tú + automatización (scripts que actualizan chequeos).

---

### `04 Ideas & Drafts/` — Trabajo en Progreso
**Propósito:** Brainstorming, prototipos, cosas sin clasificar.

**Contenido:**
- `Nuevas Ideas/` — Conceptos sin estructurar (pueden ser valiosos después)
- `Prototipos/` — Código experimental (airbnb-admin, etc.)
- `Inbox/` — **"Procesar después"** — si no sabes dónde va, va aquí
- `Notas Rápidas/` — Pensamiento veloz

**Limpieza trimestral:** Revisar qué tiene > 3 meses sin tocar y mover a `10 Archives/` o a su proyecto final.

---

### `05 Skills/` — Definiciones de Skills
**Propósito:** Documentación de skills para opencode (read-only).

**Contenido:**
- Symlink a `~/.agents/skills/`
- Skills locales del vault (proxmox-status, gromacs-benchmark, etc.)

**Regla:** NO editar manualmente (son generados por opencode).

---

### `10 Archives/` — Proyectos Archivados
**Propósito:** Proyectos completados o pausados.

**Estructura:** Espejo de `01 Projects/` (misma jerarquía interna).

**Quién accede:** Tú (raramente, para referencia histórica).

---

## Convención de Nombres

### Carpetas

| Patrón | Ejemplo | Uso |
|--------|---------|-----|
| `NN Nombre/` | `00 System/`, `01 Projects/` | Top-level (propósito claro) |
| `NN X/` dentro de proyecto | `00 Codigo Fuente/`, `01 CT 901/` | Subcarpetas (orden lógico) |
| `Nombre-Proyecto/` | `DM UAMI/`, `Claude Strava/` | Nombres de proyectos (sin número) |
| `YYYYMMDD - Evento` | `2026-09-17 - Session 1/` | Sesiones/eventos con fecha |

### Archivos Markdown

| Patrón | Ejemplo | Uso |
|--------|---------|-----|
| `YYYYMMDD - Descripcion.md` | `20260917 - Week Review.md` | Notas con fecha |
| `Descripcion.md` | `Weekly-Review-Template.md` | Documentación sin fecha |
| `PascalCase-Words.md` | `README.md`, `VAULT-GUIDE.md` | Documentos importantes |
| (Rara vez `(C) Name.md`) | `(C) Analysis.md` | **Evitar — usar type: en frontmatter** |

**Regla de oro:** Evita guiones bajos (`_`), usa espacios o guiones (`-`). Obsidian ordena mejor.

---

## Metadatos YAML (Frontmatter)

### Estructura Mínima

```yaml
---
type: [note | project-md | review | skill | draft | analysis | code | howto | reference]
project: [DM UAMI | Claude Strava | Proxmox Infrastructure | ...] 
priority: [high | medium | low]
status: [active | draft | completed | archived | deprecated]
tags: [tag1, tag2, tag3]           # Solo de Tags-Taxonomy.md
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

### Ejemplos

**Análisis generado por IA:**
```yaml
---
type: analysis
project: DM UAMI
priority: high
status: active
tags: [gromacs, cuda, benchmark, completed]
created: 2026-09-04
updated: 2026-09-17
---
# (C) PHASE4 Energy Convergence Analysis
```

**Weekly Review:**
```yaml
---
type: review
project: Claude Strava
priority: high
status: active
tags: [review, weekly, strava]
created: 2026-09-17
updated: 2026-09-17
---
# Weekly Review — Week of 2026-09-17
```

**Notas de proyecto:**
```yaml
---
type: project-md
project: DM UAMI
priority: medium
status: active
tags: [gromacs, decision, cuda]
created: 2026-01-15
updated: 2026-09-17
---
# README — DM UAMI
```

---

## Reglas de Uso

### Regla 1: Un Archivo, Una Casa

Cada archivo .md pertenece a UNA y solo UNA carpeta. Si dudas:

```
¿Es un proyecto activo?          → 01 Projects/
¿Es una idea sin estructura?     → 04 Ideas & Drafts/Inbox/
¿Es una revisión de semana?      → 03 Operations/Weekly Reviews/
¿Es documentación de referencia? → 02 Knowledge/
```

### Regla 2: Frontmatter en Todos los .md

Cada archivo Markdown debe tener frontmatter YAML mínimo. **Sin excepciones** (excepto templates de Obsidian y config files).

Beneficios:
- Puedes filtrar por `type`, `project`, `status` en Obsidian.
- Los agentes IA pueden leer metadatos y evitar duplicación.
- Buscar "todos los drafts" es una query simple.

### Regla 3: Binarios No en Git

Archivos > 5 MB van a `.gitignore`. Ejemplos:
- Builds compilados (`*.o`, `*.a`, `build/`)
- Binarios ejecutables
- Logs muy grandes
- Datos brutos (phase4_energies.txt)

Estos se guardan **localmente en CT 901** (no en el vault versionado).

### Regla 4: Archivos de Raíz = Cero

La raíz del vault debe estar **limpia**. Todos los archivos van en carpetas:

```
❌ ANTES
/Users/josealejandre/Obsidian/JarvisVault/
├── CLAUDE.md
├── GOALS.md
├── AI-Carrillo-Setup.md
├── DM-UAMI-Research.md
└── ...

✅ DESPUÉS
/Users/josealejandre/Obsidian/JarvisVault/
├── 00 System/
│   ├── CLAUDE.md
│   ├── GOALS.md
│   └── Agents/
│       ├── AI-Carrillo-Setup.md
│       └── DM-UAMI-Research.md
└── ...
```

---

## Flujo de Trabajo Diario

### Mañana (5 min)
1. Abre `03 Operations/Diario/YYYYMMDD.md`.
2. Escribe tareas, notas, momentum.

### Durante el día
1. Trabaja en proyectos en `01 Projects/`.
2. Toma notas en la carpeta del proyecto o en `03 Operations/Diario/`.

### Fin del día (5 min)
1. Revisa `03 Operations/Diario/` — mueve notas valiosas a sus carpetas finales.
2. Si es domingo, crea `03 Operations/Weekly Reviews/YYYYMMDD - Review.md`.

### Fin de semana (30 min)
1. Revisa `GOALS.md` en `00 System/`.
2. Actualiza estado de proyectos en `01 Projects/*/README.md`.
3. Commita a git (rutina automática).

---

## FAQs de Ubicación

| Pregunta | Respuesta |
|----------|-----------|
| ¿A dónde va un análisis nuevo de DM UAMI? | `01 Projects/DM UAMI/02 Optimizacion/` |
| ¿Dónde guardo un paper sobre CUDA? | `02 Knowledge/Research/IA/` (o bajo DM UAMI si es muy específico) |
| ¿Dónde van las notas de entrenamiento? | `01 Projects/Claude Strava/` (si es sesión completada → `02 Sesiones Completadas/`) |
| ¿Dónde guardo un script de testing? | `01 Projects/DM UAMI/06 Scripts Auxiliares/` |
| ¿Dónde va un checklist reutilizable? | `03 Operations/Checklists/` |
| ¿Dónde va una idea loca sin proyecto? | `04 Ideas & Drafts/Nuevas Ideas/` o `Inbox/` |
| ¿Dónde va un benchmark que generó IA? | `01 Projects/DM UAMI/02 Optimizacion/` (con `type: analysis` en frontmatter) |
| ¿Dónde va la documentación de un skill nuevo? | `05 Skills/vault-specific-skills/` o `02 Knowledge/Skill Definitions/` |
| ¿Dónde va un proyecto viejo de Laura? | `10 Archives/Laura-Bernal-[date]/` |

---

## Próximas Acciones

1. **Revisa este documento** — ¿Tiene sentido la estructura?
2. **Ejecuta el plan de migración** — Ver `(C) Audit-Report-2026-09-17-FINAL.md` Fase 0–8.
3. **Crea `Tags-Taxonomy.md`** — Centraliza los tags que usas.
4. **Escribe `VAULT-GUIDE.md`** — Guía rápida para futuro (cuando olvides dónde va algo).
5. **Automatiza limpieza trimestral** — Script que busca archivos viejos.

---

**Fin de propuesta de estructura — 17 de septiembre de 2026**

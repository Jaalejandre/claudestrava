# Auditoría Completa del Vault — SatanZote AI
**Fecha:** 17 de septiembre de 2026  
**Auditor:** Equipo de tres agentes (Estructura, Contenido, Diseño)  
**Scope:** `/Users/josealejandre/Obsidian/JarvisVault/`  
**Modificaciones:** NINGUNA (solo lectura)

---

## Índice
1. [Resumen ejecutivo](#resumen-ejecutivo)
2. [Hallazgos críticos](#hallazgos-críticos)
3. [Auditoría de estructura](#auditoría-de-estructura)
4. [Auditoría de contenido](#auditoría-de-contenido)
5. [Auditoría de convencionesy metadatos](#auditoría-de-convenciones-y-metadatos)
6. [Diseño de estructura optimizada](#diseño-de-estructura-optimizada)
7. [Reglas de almacenamiento](#reglas-de-almacenamiento-eficiente)
8. [Plan de migración](#plan-de-migración-ejecutable)

---

## Resumen Ejecutivo

El vault contiene **477 archivos** (448 Markdown + 29 binarios/datos) distribuidos en 45 directorios. La estructura actual es **pragmática pero fragmentada**:

| Métrica | Valor | Severidad |
|---------|-------|-----------|
| Tamaño total | 113 MB (61 MB en .opencode, ~30 MB contenido) | Normal |
| Archivos vacíos | 5 | Baja (limpieza fácil) |
| Duplicación DM UAMI | 3 ubicaciones (01, 03, raíz) | **CRÍTICA** |
| Archivos sin frontmatter | 301/448 (67%) | Alta |
| Wikilinks rotos detectados | 37 | Media |
| Convención de nombres | Inconsistente (espacios, _, mayúsculas) | Media |
| Directorios con backslash literal | 2 | **CRÍTICA** (bloquea Samba) |

**Diagnóstico:** El vault es **funcional pero requiere consolidación**. La fragmentación de DM UAMI es el bloqueador #1. El sistema de metadatos es débil (32.8% frontmatter, sin tags centralizados).

**Recomendación:** Reorganizar en 7 carpetas top-level mutuamente excluyentes, consolidar DM UAMI, estandarizar metadatos YAML, y eliminar archivos huérfanos.

---

## Hallazgos Críticos

### 🔴 Crítica 1: DM UAMI — Triple Fragmentación

**Ubicaciones:**
- `01 Projects/DM UAMI/` — **381 archivos, 22 MB** (fases de código IA históricas: PHASE1–PHASE4 con builds completos)
- `03 Projects/DM UAMI/` — **60 archivos, 2.4 MB** (estructura organizada: 00 Código Fuente Original → 07 Iteration Logs)
- Raíz y subcarpetas — **binarios, builds, logs dispersos** (~14 MB en `phase4_energies.txt`, `PHASE3_CUDA_FULL/build/`, `PHASE4_CUDA_PINNED/build/`)

**Contenido duplicado:** 6 archivos idénticos en ambas ubicaciones:
- `CMakeLists.txt`
- `config.h`, `forces.cu`, `integrator.cu`, `main.cu`
- `phase4_cuda` (binario)

**Impacto:** Búsqueda confusa, actualización de código incierta (¿cuál es la versión de verdad?), desperdicio de espacio.

**Causa raíz:** El proyecto pasó por varias fases de reorganización (01 Projects era lo antiguo; 03 Projects es lo nuevo). Los builds y logs nunca se consolidaron.

---

### 🔴 Crítica 2: Directorios Mal Creados (Backslash Literal)

Existen dos directorios con barra invertida **literal** en el nombre (no escapada):

```bash
ls -d /Users/josealejandre/Obsidian/JarvisVault/*\ Projects
```

Resultado: `01\ Projects` y `03\ Projects` como nombres reales (no son lo mismo que `01 Projects`).

**Por qué pasó:** Script o agente ejecutó `mkdir 01\ Projects` (sin comillas) y la shell interpretó el backslash. En Samba (montaje del servidor), estos aparecen como `01\` y `03\`.

**Impacto:** Los clientes Samba ven nombres raros, los scripts que iteran directorios fallan.

**Solución:** Renombrar o eliminar (`rm -rf` si están vacíos).

---

### 🟠 Alta 3: Falta de Metadatos Estructurados

**67% de archivos Markdown SIN frontmatter YAML:**
- `00 Notes/`: 37/55 con FM (67%)
- `01 Projects/`: 1/72 con FM (1%) ← **crítico**
- `03 Projects/`: 32/144 con FM (22%)
- `00 System/`: bajo pero mejor

**Tags:** Solo ~30 usos en todo el vault, 16 archivos con `tags:` vacío. Sin taxonomía centralizada.

**Impacto:** No hay forma de filtrar notas por proyecto, prioridad, o estado. Las búsquedas son solo por nombre/contenido.

---

### 🟠 Alta 4: Wikilinks Rotos

**37 wikilinks detectados como potencialmente rotos:**

Ejemplos:
- `[[SatanZote AI]]` (el nombre usado para referencias, pero el archivo es `CLAUDE.md`)
- `[[Chequeos Diarios]]` (en `Servidor Proxmox/`, pero archivo real es en subcarpeta)
- `[[CT 118 control]]`, `[[My Base.base]]` — referencias a cosas externas o mal formadas

**Causa:** Cambios de nombre de archivos sin actualizar wikilinks (peligro con refactor).

---

### 🟡 Media 5: Archivos Sueltos en Raíz

**11 archivos .md en la raíz del vault** (no en carpetas):

- `CLAUDE.md` (instrucciones globales)
- `GOALS.md` (metas — **vacío**)
- `AI-Carrillo-Master-Coordination-Setup.md`
- `DM-UAMI-Research-Session-Plan-*.md`
- `SatanZote-Daily-Audit-Team-Setup.md`
- y otros `.txt` de auditoría

**Impacto:** Raíz desorganizada, difícil de navegar. Archivos de "operaciones" mezclados con "documentación global".

---

### 🟡 Media 6: Nombres Inconsistentes

- **172 archivos con espacios:** "00 Notes", "03 Projects", "Claude Strava"
- **116 archivos con guion bajo:** `Test_Sync_`, `phase4_`, `_agent__se_me_acabaron_`
- **~15 con fecha YYYY-MM-DD:** Usados en DM UAMI (buena práctica, pero no sistemática)
- **~20 PascalCase:** README.md, SKILL.md, CLAUDE.md (documentación + tools)

**Problema:** Sin convención clara, las búsquedas alfanuméricas ordenan raramente.

---

### 🟡 Baja 7: Archivos Vacíos

5 archivos con 0 bytes:

1. `00 Notes/Servidor Proxmox/(C) Flujo de despliegue dev-test-prod.md`
2. `00 System/Untitled.md`
3. `03 Projects/Entrenador L'Etape CDMX/03 Plan de Desarrollo/todo.md`
4. `GOALS.md` — **debería tener contenido**
5. `copilot/.../._agent__...@...md` — archivo `.\_` de macOS (ignorable)

**Acción:** Eliminar 1–3 y 5, llenar `GOALS.md`.

---

## Auditoría de Estructura

### Árbol Actual (simplificado)

```
JarvisVault/
├── 00 Notes/                       (55 archivos, 316K)
│   ├── Books/
│   ├── Courses/
│   ├── Servidor Proxmox/           (14 CT/VMs documentados)
│   │   ├── Arquitectura/
│   │   ├── Chequeos Diarios/       (7 chequeos automáticos, con (C))
│   │   └── (otros)
│   └── ...
│
├── 00 System/                      (17 archivos, ~400K)
│   ├── AI-CARRILLO-*
│   ├── DM-UAMI-*
│   ├── Research-Drafts/            (Phase 5 design)
│   └── ...
│
├── 01 Projects/                    (72 archivos, 22.4 MB) ← DM UAMI v1
│   └── DM UAMI/            (PHASE1–PHASE4 histórico)
│
├── 01\ Projects/                   ← ERROR: backslash literal, vacío o casi
│
├── 02 Plan de Entrenamiento/       (14 archivos)
│
├── 03 Projects/                    (144 archivos, 2.8 MB) ← DM UAMI v2 + otros
│   ├── DM UAMI/            (estructura nueva: 00–07)
│   ├── Claude Strava/              (entrenamiento L'Étape)
│   ├── Entrenador L'Etape CDMX/
│   ├── Infraestructura/
│   ├── Prototipos/
│   ├── Proxmox-Infrastructure/
│   ├── B2-Backup-Strategy/
│   ├── GitHub-Integration/
│   ├── ConfirmaCitas/
│   ├── Research Reports/
│   ├── (PROJECT TEMPLATE)/
│   ├── auditoria/                  ← NUEVO (este reporte)
│   └── claude-wizard-setup/
│
├── 03\ Projects/                   ← ERROR: backslash literal
│   └── Laura-Bernal-Visibilidad/
│
├── Projects/                       (raíz, 2 archivos)
│   ├── Laura-Bernal/
│   └── Laura-Strava-Garmin/
│
├── 04 Reviews/                     (12 archivos)
├── 05 Skills/                      (skill docs + git refs)
├── 10 Archives/                    (archivos viejos)
│
├── Archivos sueltos en raíz:       (11 .md, varios .txt)
│   ├── CLAUDE.md
│   ├── GOALS.md
│   ├── AI-Carrillo-*.md
│   ├── DM-UAMI-*.md
│   └── *.txt (auditoría)
│
├── .opencode/                      (61 MB — tooling)
├── .obsidian/, .claude/, .git/     (config, ignorar)
└── ...

```

### Estadísticas por Carpeta

| Carpeta | Archivos | Tamaño | Descripción |
|---------|----------|--------|-------------|
| 01 Projects/DM UAMI/ | 381 | 22 MB | **CRÍTICA:** Código antiguo + builds |
| 03 Projects/DM UAMI/ | 60 | 2.4 MB | Reorganizado, pero duplicado |
| 03 Projects/ (otras) | 84 | 400K | Claude Strava, Prototipos, etc. |
| 00 Notes/Servidor Proxmox/ | 35 | 180K | Documentación infra OK |
| 00 System/ | 17 | 400K | Coordinación IA dispersa |
| 04 Reviews/ | 12 | 80K | Weekly/Monthly/Quarterly reviews |
| 05 Skills/ | 9 | 120K | Skill YAML docs |
| 10 Archives/ | 5 | 50K | Almacenado viejo |
| Raíz | 11 | 95K | Archivos huérfanos |

---

## Auditoría de Contenido

### Archivos Generados por IA (Prefijo `(C)`)

**Total:** 171 archivos (38% del vault)

**Distribución:**
- `01 Projects/DM UAMI/` — 74 (43%)
- `03 Projects/DM UAMI/` — 45 (26%)
- `00 Notes/Servidor Proxmox/` — 17 (10%)
- `03 Projects/Prototipos/` — 10 (6%)
- `03 Projects/Claude Strava/` — 9 (5%)
- Otros — 16 (9%)

**Patrón:** La mayoría son análisis, benchmarks, logs, y código fuente generado. Son valiosos pero no están indexados (no frontmatter, sin tags).

### Calidad de Frontmatter YAML

**Con frontmatter:** 147/448 (32.8%)  
**Sin frontmatter:** 301/448 (67.2%)

Por carpeta:
- `00 Notes/Servidor Proxmox/`: 95% con FM ✅
- `03 Projects/Claude Strava/`: 40% con FM ⚠️
- `01 Projects/`: 1% con FM ❌ (crítico)
- `00 System/`: bajo, pero esperado para ops

**Tags usados:** Solo ~30 instancias, sin patrón. Ejemplos: `tags: [IA, autoscript]`, `tags: [gromacs, cuda]`.

**Recomendación:** Imponer frontmatter YAML en todos los archivos Markdown con campos estándar.

### Tipos de Contenido Detectados

| Tipo | Ejemplos | Cantidad |
|------|----------|----------|
| Documentación de proyecto | DM UAMI/*.md | 110+ |
| Análisis/Benchmarks | `(C) BENCHMARK_*.md` | 25+ |
| Notas de entrenamiento | Claude Strava/... | 30+ |
| Documentación de infraestructura | Servidor Proxmox/... | 35+ |
| Skill definitions | 05 Skills/*.md | 9 |
| Reviews (Weekly/Monthly/Quarterly) | 04 Reviews/... | 12 |
| Código fuente generado | (C) PHASE*.cpp, .cu, .h | 60+ |
| Configuration/Setup | `*-Setup.md`, `*-Coordination.md` | 15+ |
| Archives (viejo) | 10 Archives/... | 5 |

---

## Auditoría de Convenciones y Metadatos

### Convención de Nombres

**Espacios en nombres:** 172 archivos (38%)
- Ejemplos: `00 Notes/`, `Claude Strava`, `00 System/`

**Guion bajo (_):** 116 archivos (26%)
- Ejemplos: `Test_Sync_`, `phase4_energies`, `_agent__se_me_acabaron_`

**PascalCase:** ~20 archivos (4%)
- Ejemplos: `README.md`, `SKILL.md`, `CLAUDE.md`

**Fecha YYYY-MM-DD:** ~15 archivos (3%)
- Ejemplos: `2026-09-04 - Estrategia.md` (buena práctica, pero rara)

**Problema:** Sin convención clara, Obsidian ordena alfabéticamente, pero los espacios y underscores crean agrupamientos no intuitivos.

### Wikilinks

**Total únicos:** 68  
**Potencialmente rotos:** 37 (54%)

Ejemplos de rotos:
- `[[SatanZote AI]]` → archivo es `CLAUDE.md` (ambigüedad)
- `[[Chequeos Diarios]]` → en `Servidor Proxmox/Chequeos Diarios/README.md`
- `[[CT 118 control]]` → no existe archivo
- `[[My Base.base]]` → referencia a una vista de Base, no un archivo

**Causa:** Cambios de nombres sin refactor de links (manual error).

---

## Diseño de Estructura Optimizada

### Filosofía de Diseño

**Rechazos:**
- ❌ **Johnny Decimal (00–13)** — Sobreingeniería para vault unipersonal. Añade carga cognitiva sin beneficio.
- ❌ **PARA puro (Proyectos / Áreas / Recursos)** — Confunde "Projects" vs "Areas" cuando hay muchos outputs de IA.

**Adopción:**
- ✅ **Convención NN Nombre/** (que ya usan) — Funciona, legible, ordena bien.
- ✅ **7 carpetas top-level mutuamente excluyentes** — Cada archivo pertenece a una y solo una. Si dudas, va a `07 Inbox/`.
- ✅ **Metadatos YAML estándar en todos los .md** — Frontmatter obligatorio: tipo, proyecto, estado, tags.
- ✅ **Sistema de tags centralizado** — Documento único con taxonomía (tags válidos).

### Estructura Propuesta

```
JarvisVault/
│
├── 00 System/                  ← El motor del vault. Config, agentes, templates, instrucciones globales.
│   ├── CLAUDE.md               ← (movido de raíz)
│   ├── GOALS.md                ← (movido de raíz, **ahora sí con contenido**)
│   ├── Tags-Taxonomy.md        ← (NUEVO: lista central de tags válidos)
│   ├── Templates/              ← Plantillas para nuevos proyectos, notas diarias, etc.
│   ├── Agents/                 ← Coordinación de equipos de IA
│   │   ├── AI-Carrillo-Master-Coordination-Setup.md
│   │   ├── DM-UAMI-Team-Executive-Summary-*.md
│   │   ├── SatanZote-Daily-Audit-Team-Setup.md
│   │   └── ...
│   └── Vault/                  ← Config del vault (vinculaciones simbólicas a .obsidian/, .gitignore, etc.)
│
├── 01 Projects/                ← Proyectos ACTIVOS con deadline o entregable visible.
│   │                              Regla: si no se ha tocado en > 6 meses, mover a 10 Archives.
│   ├── DM UAMI/        ← (CONSOLIDADO: TODO de 01 Projects + 03 Projects + raíz)
│   │   ├── 00 Codigo Fuente Original/   ← Referencia congelada (nunca editar)
│   │   ├── 01 CT 901 - Reescritura C++/ ← Versión en desarrollo (CT 901 Ubuntu)
│   │   ├── 02 Optimizacion CUDA/        ← Benchmarks, perfiles, decisiones
│   │   ├── 03 Builds & Binarios/        ← Compilados, binarios, libs (NO en git)
│   │   ├── 04 Documentacion/            ← ADRs, decisiones, análisis de física
│   │   ├── 05 Investigacion/            ← Papers, notas de research, GROMACS refs
│   │   ├── 06 Scripts Auxiliares/       ← Python, Bash para mantenimiento
│   │   ├── README.md                    ← Overview, how-to, link a memoria en CT 901
│   │   └── Proyecto-Metadata.base       ← (NUEVO) Vista Obsidian Base con estado de fases
│   │
│   ├── Claude Strava/          ← Plan de entrenamiento L'Étape CDMX 2026-11-15
│   │   ├── 00 Plan Maestro/
│   │   ├── 01 Fases/           ← Base, Construcción, Pico, Taper
│   │   ├── 02 Sesiones Completadas/
│   │   ├── 03 Análisis Semanal/
│   │   └── README.md
│   │
│   ├── Proxmox Infrastructure/ ← Actualización/mantenimiento del servidor (CT 109)
│   │   ├── 00 Arquitectura/
│   │   ├── 01 CTs & VMs/       ← Documentación de cada CT (104, 103, 901, etc.)
│   │   ├── 02 Chequeos Diarios/ ← Logs automáticos de salud
│   │   ├── 03 Alertas/
│   │   └── README.md
│   │
│   └── (Otros proyectos activos)
│       ├── B2-Backup-Strategy/
│       ├── ConfirmaCitas/
│       ├── GitHub-Integration/
│       └── ...
│
├── 02 Knowledge/               ← Documentación, referencias, resúmenes, no-proyectos.
│   │                              (NO es código ni entregables, sino la base de conocimiento)
│   ├── Cursos/                 ← Notas de cursos tomados (secciones temáticas)
│   ├── Libros/                 ← Resúmenes, highlights de libros leídos
│   ├── Research/               ← Papers, artículos, investigación sin proyecto asociado
│   │   ├── IA/
│   │   ├── Física Molecular/
│   │   ├── Infraestructura/
│   │   └── ...
│   ├── Skill Definitions/      ← Copia de 05 Skills/ (índice + links)
│   └── Referencias/            ← Links, herramientas, cheat sheets
│
├── 03 Operations/              ← Notas operacionales, rutinas, checklists, seguimiento.
│   │                              (Lo que hoy está disperso en 04 Reviews + notas sueltas)
│   ├── Diario/                 ← Notas diarias (YYYYMMDD.md)
│   ├── Weekly Reviews/         ← Revisiones semanales (domingo, resumen en el repo)
│   ├── Monthly Reviews/        ← Revisiones mensuales (primer día)
│   ├── Quarterly Reviews/      ← Revisiones trimestrales
│   ├── Checklists/             ← Checklists reutilizables (pre-entrevista, pre-commit, etc.)
│   ├── Routines/               ← Rutinas diarias, semanales (formato ejecutable)
│   └── Goals Tracking/         ← Seguimiento de GOALS.md (ahora en 00 System/)
│
├── 04 Ideas & Drafts/          ← Trabajo en progreso, ideas sin estructurar, drafts.
│   │                              (Donde van las cosas nuevas; luego se mueven a 01–03 o Archive)
│   ├── Nuevas Ideas/
│   ├── Prototipos/             ← Código experimental, pruebas rápidas
│   ├── Inbox/                  ← "Procesar luego" — **todo lo que no encaja va aquí**
│   └── Notas Rápidas/          ← Pensamiento rápido sin estructura
│
├── 05 Skills/                  ← Definiciones de skills para opencode (NO cambiar)
│   │                              (Symlink a ~/.agents/skills/ + vault-specific skills)
│   └── (read-only, git-tracked)
│
├── 10 Archives/                ← Proyectos inactivos (> 6 meses sin tocar)
│   │                              o decididos como "no seguir". Estructura espejo de 01 Projects.
│   ├── DM UAMI-Phase3-CUDA-OLD/
│   ├── (otros proyectos viejos)/
│   └── README.md               ← Índice de archivos, por qué se archivó
│
└── .config/                    ← Config del vault (local, NO en git)
    ├── obsidian/               ← Symlink a .obsidian/
    ├── opencode/               ← Symlink a .opencode/
    └── ...

```

### Cambios Clave

| Cambio | Anterior → Nuevo | Razón |
|--------|------------------|-------|
| **DM UAMI** | Fragmentado (01, 03, raíz) → **01 Projects/DM UAMI/** (consolidado) | Evita duplicación, versión única |
| **CLAUDE.md, GOALS.md** | Raíz → **00 System/** | Instrucciones globales centralizadas |
| **Archivos de IA-Coordinación** | Raíz + 00 System → **00 System/Agents/** | Operaciones centralizadas |
| **Reviews** | 04 Reviews/ (estructura plana) → **03 Operations/Weekly|Monthly|Quarterly/** | Jerarquía clara de cadencia |
| **Prototipos** | 03 Projects/Prototipos → **04 Ideas & Drafts/Prototipos/** | WIP ≠ Proyecto activo |
| **Knowledge** | Disperso → **02 Knowledge/** (centralizado) | Búsqueda más fácil |
| **Raíz limpia** | 11 archivos sueltos → **0 (todos movidos)** | Claridad visual |

---

## Reglas de Almacenamiento Eficiente

### Regla 1: Frontmatter YAML Obligatorio

**Aplica a:** Todos los .md (excepto templates de Obsidian y config files).

**Plantilla mínima:**

```yaml
---
type: [note | project-md | review | skill | draft | analysis]
project: [DM UAMI | Claude Strava | Proxmox Infrastructure | ...]
priority: [high | medium | low]
status: [active | draft | completed | archived]
tags: [tag1, tag2, tag3]              # Usar solo de Tags-Taxonomy.md
created: YYYY-MM-DD
updated: YYYY-MM-DD
---
```

**Ej:**
```yaml
---
type: analysis
project: DM UAMI
priority: high
status: active
tags: [gromacs, cuda, optimization]
created: 2026-09-04
updated: 2026-09-17
---
# (C) Análisis de Optimización CUDA Phase 4
...
```

### Regla 2: Convención de Nombres

**Formato:** `YYYYMMDD - Descripcion.md` (para notas con fecha) o `Descripcion.md` (sin fecha)

**Ejemplos válidos:**
- `20260917 - Weekly Review Claude Strava.md` ✅
- `DM UAMI Phase 4 Benchmark.md` ✅
- `CT 901 Setup Log.md` ✅

**Ejemplos inválidos:**
- `(C) OLD Phase 1 code.md` ❌ (prefijo (C) ya está en el archivo; usa type: generado en frontmatter)
- `CT_901_setup.md` ❌ (guion bajo; usa espacios)
- `My Note (old).md` ❌ (nota vaga; sé específico)

**Regla de oro:** Si dudas, pregunta: "¿Podría alguien más encontrar este archivo en 2 meses?"

### Regla 3: Archivos Generados por IA

**Ubicación:** Siempre en la carpeta del proyecto correspondiente, NO en raíz.

**Naming:** **No uses prefijo `(C)`** — en su lugar, usa metadato `type: analysis` o `type: generated-code` en frontmatter.

**Ejemplo:**
```
03 Projects/DM UAMI/04 Documentacion/
├── (C) PHASE4 Energy Convergence Analysis.md  ← Cambiar a:
├── PHASE4 Energy Convergence Analysis.md      ✅
└── (frontmatter: type: analysis, project: DM UAMI)
```

### Regla 4: Gestión de Archivos Grandes

**Límite:** No subir binarios > 5 MB a git.

**Protocolo:**

| Tamaño | Qué hacer |
|--------|-----------|
| < 500 KB | Subir directo (markdown, images, PDFs) |
| 500 KB — 5 MB | Usar Git LFS si es archivo final, o .gitignore si es temporal |
| > 5 MB | Ignorar (comprimido en zip si se debe archivar), guardar en CT 901 localmente |

**Archivos del vault a .gitignore ya:**
```
01 Projects/DM UAMI/**/build/
03 Projects/DM UAMI/03 Builds & Binarios/
*.o, *.a, *.so, *.exe
phase4_energies.txt (>5MB)
PHASE3_CUDA_FULL/build/
PHASE4_CUDA_PINNED/build/
```

### Regla 5: Limpieza Trimestral

**Cada 3 meses (fin de trimestre):**

1. **Auditoría de 04 Ideas & Drafts/** — Si > 6 meses sin tocar, mover a 10 Archives.
2. **Verificación de wikilinks** — Buscar rotos con `[[...]]`.
3. **Vacuuming de frontmatter** — Asegurar que todos los .md tienen type, project, status.
4. **Review de size** — Identificar binarios grandes para .gitignore.

**Comando:**
```bash
# Buscar archivos no modificados en > 6 meses
find /Users/josealejandre/Obsidian/JarvisVault/04\ Ideas\ \&\ Drafts -mtime +180 -type f
```

### Regla 6: Archivos de Código Fuente — Nunca Editación Manual

**Aplica a:** `01 Projects/DM UAMI/00 Codigo Fuente Original/`

**Protocolo:**
- Marcar carpeta como **read-only** en git:
  ```bash
  git update-index --assume-unchanged 01\ Projects/DM UAMI/00\ Codigo\ Fuente\ Original/*
  ```
- Si necesitas cambiar: crear rama (`feature/refactor-*`), cambiar en `01 .../01 CT 901 - Reescritura C++/`, luego validar contra original.
- Nunca editar directamente `00 Codigo Fuente Original/` — es referencia congelada.

### Regla 7: Revisiones Semanales y Rutin de Git

**Cada domingo ~19:00 CDMX (rutina automatizada):**

1. Ejecutar `git status` en `/root/JarvisVault` (CT 109).
2. Agregar nuevos archivos: `git add -A`.
3. Commit: `git commit -m "Weekly review + vault updates — $(date +%Y-%m-%d)"`.
4. Push: `git push origin main` (con reintentos, alerta ntfy si falla).
5. En Obsidian, escribir `03 Operations/Weekly Reviews/20260917 - Week Review.md`.

**Commit típico:**
```
Weekly review + vault updates — 2026-09-17

- Consolidated DM UAMI sources (01 Projects → 03 Projects)
- Added Phase 4 energy convergence analysis
- Updated Claude Strava training week 8
- Cleaned up old audit reports
```

---

## Plan de Migración Ejecutable

### Fase 0: Preparación (30 min)

**Paso 0.1: Crear rama de git para migración**
```bash
cd /Users/josealejandre/Obsidian/JarvisVault
git checkout -b refactor/vault-reorganization-2026-09-17
git branch -u origin/refactor/vault-reorganization-2026-09-17
```

**Paso 0.2: Backup**
```bash
tar -czf ~/Desktop/vault-backup-20260917.tar.gz /Users/josealejandre/Obsidian/JarvisVault/ \
  --exclude=.git --exclude=.opencode --exclude=node_modules
```

**Paso 0.3: Crear estructura nueva (carpetas) en raíz**
```bash
cd /Users/josealejandre/Obsidian/JarvisVault
mkdir -p "00 System/Templates" "00 System/Agents" "00 System/Vault"
mkdir -p "01 Projects"
mkdir -p "02 Knowledge/Cursos" "02 Knowledge/Libros" "02 Knowledge/Research"
mkdir -p "03 Operations/Diario" "03 Operations/Weekly Reviews" "03 Operations/Monthly Reviews"
mkdir -p "04 Ideas & Drafts/Nuevas Ideas" "04 Ideas & Drafts/Prototipos" "04 Ideas & Drafts/Inbox"
mkdir -p "10 Archives"
```

### Fase 1: Limpiar Errores (20 min)

**Paso 1.1: Eliminar directorios con backslash literal**
```bash
cd /Users/josealejandre/Obsidian/JarvisVault
ls -d "01 Projects" "01\ Projects"  # Ver qué existe
# Si "01 Projects" tiene contenido, mover a "01 Projects" correctamente
# Si "01\ Projects" está vacío o es duplicado:
rm -rf "01\ Projects"
rm -rf "03\ Projects"
```

**Paso 1.2: Eliminar/completar archivos vacíos**
```bash
# Eliminar
rm "00 Notes/Servidor Proxmox/(C) Flujo de despliegue dev-test-prod.md"
rm "00 System/Untitled.md"
rm "03 Projects/Entrenador L'Etape CDMX/03 Plan de Desarrollo/todo.md"
rm "copilot/copilot-conversations/._agent__se_me_acabaron_tokens...@...md" 2>/dev/null

# Llenar
echo "# Objetivos — SatanZote AI" > "GOALS.md"
echo "(Pendiente de completar: metas a 3 meses, hitos, estado)" >> "GOALS.md"
```

**Paso 1.3: Eliminar archivos sueltos de auditoría (.txt)**
```bash
rm -f ".bot-team-final-summary.txt"
rm -f ".satanzote-daily-audit-summary.txt"
```

### Fase 2: Consolidar DM UAMI (2 horas)

**Paso 2.1: Determinar fuente de verdad**

Necesitas decidir manualmente: ¿cuál es la versión "oficial"?

- **`01 Projects/DM UAMI/`** — Código histórico de fases (PHASE1–PHASE4)
- **`03 Projects/DM UAMI/`** — Estructura nueva, organizada

Recomendación: **Fusionar ambas en `01 Projects/DM UAMI/`** siguiendo esta estructura:

```
01 Projects/DM UAMI/
├── 00 Codigo Fuente Original/          ← (de 03 Projects, congelado)
├── 01 CT 901 - Reescritura C++/        ← (de 03 Projects, en desarrollo)
├── 02 Optimizacion CUDA/               ← (de 03 Projects)
├── 03 Builds & Binarios/               ← (de raíz + 01 Projects, ignorado en git)
├── 04 Documentacion/                   ← (de 03 Projects + fase analysis de 01)
├── 05 Investigacion/                   ← (de 01 Projects)
├── 06 Scripts Auxiliares/              ← (nuevo, helpers)
├── ARCHIVE-Phase1-Legacy/              ← (de 01 Projects/DM UAMI/PHASE1*, PHASE2*)
├── ARCHIVE-Phase3-CUDA-Full/           ← (de 01 Projects/DM UAMI/PHASE3*)
├── ARCHIVE-Phase4-CUDA-Pinned/         ← (de 01 Projects/DM UAMI/PHASE4*)
├── README.md                           ← (nuevo, overview)
└── Proyecto-Metadata.base              ← (nuevo, vista de estado)
```

**Paso 2.2: Mover archivos manualmente**

```bash
# Backup of both before we start
cp -r "01 Projects/DM UAMI" "/tmp/gromacs-01-backup"
cp -r "03 Projects/DM UAMI" "/tmp/gromacs-03-backup"

# Move 03 structure to 01 (es más organizada)
rsync -av "03 Projects/DM UAMI/00 Codigo Fuente Original/" \
  "01 Projects/DM UAMI/00 Codigo Fuente Original/" --delete

rsync -av "03 Projects/DM UAMI/01 CT 901"* \
  "01 Projects/DM UAMI/01 CT 901 - Reescritura C++/"

rsync -av "03 Projects/DM UAMI/02 Optimizacion"* \
  "01 Projects/DM UAMI/02 Optimizacion CUDA/"

# etc... (repite para carpetas 03–07 de "03 Projects/")

# Archiva el viejo código de fases
mkdir -p "01 Projects/DM UAMI/ARCHIVE-Phase1-Legacy"
mv "01 Projects/DM UAMI/"{PHASE1*,PHASE2*} "01 Projects/DM UAMI/ARCHIVE-Phase1-Legacy/" 2>/dev/null

# Limpia binarios y builds (los pones en .gitignore, no los subes)
mkdir -p "01 Projects/DM UAMI/03 Builds & Binarios"
mv "01 Projects/DM UAMI"/**/*.o "01 Projects/DM UAMI/03 Builds & Binarios/" 2>/dev/null
mv "01 Projects/DM UAMI"/**/build "01 Projects/DM UAMI/03 Builds & Binarios/" 2>/dev/null
```

**Paso 2.3: Eliminar duplicado en 03 Projects**

```bash
rm -rf "03 Projects/DM UAMI"
```

### Fase 3: Mover Archivos Sueltos (30 min)

**Paso 3.1: Mover CLAUDE.md y GOALS.md a 00 System/**

```bash
mv "CLAUDE.md" "00 System/"
mv "GOALS.md" "00 System/"
```

**Paso 3.2: Mover archivos de coordinación IA a 00 System/Agents/**

```bash
mv "AI-Carrillo-Master-Coordination-Setup.md" "00 System/Agents/"
mv "DM-UAMI-Research-Session-Plan-*.md" "00 System/Agents/" 2>/dev/null
mv "SatanZote-Daily-Audit-Team-Setup.md" "00 System/Agents/"
mv "Hermes-Bot-Team-Mode-Setup.md" "03 Projects/GitHub-Integration/" # o 00 System/Agents si es global
```

**Paso 3.3: Mover 04 Reviews a 03 Operations/**

```bash
rsync -av "04 Reviews/" "03 Operations/" --delete
rm -rf "04 Reviews"
```

**Paso 3.4: Mover Prototipos a 04 Ideas & Drafts/**

```bash
mv "03 Projects/Prototipos" "04 Ideas & Drafts/Prototipos"
```

### Fase 4: Reorganizar Proyectos (1 hora)

**Paso 4.1: Determinar qué es "activo" vs "archivado"**

Proyectos activos (deadline < 6 meses):
- ✅ DM UAMI (trabajo en progreso)
- ✅ Claude Strava (deadline 2026-11-15)
- ✅ Proxmox Infrastructure (mantenimiento continuo)
- ❓ B2-Backup-Strategy (activo pero bajo prioridad)
- ❓ GitHub-Integration (completado? verificar)
- ❓ Infraestructura (deprecado?)

**Paso 4.2: Mover archivados a 10 Archives/**

```bash
# Ejemplo: si Infraestructura está vieja
mv "03 Projects/Infraestructura" "10 Archives/Infraestructura-2026-09-17"
```

**Paso 4.3: Reorganizar 02 Knowledge**

```bash
# De 00 Notes/Books → 02 Knowledge/Libros
mv "00 Notes/Books/"* "02 Knowledge/Libros/" 2>/dev/null
rmdir "00 Notes/Books"

# De 00 Notes/Courses → 02 Knowledge/Cursos
mv "00 Notes/Courses/"* "02 Knowledge/Cursos/" 2>/dev/null
rmdir "00 Notes/Courses"

# Crear Research
mkdir -p "02 Knowledge/Research/IA"
mkdir -p "02 Knowledge/Research/Fisica Molecular"
# (Las notas de investigación las puedes agregar manualmente)
```

### Fase 5: Crear Archivos de Sistema (45 min)

**Paso 5.1: Crear Tags-Taxonomy.md**

```bash
cat > "00 System/Tags-Taxonomy.md" << 'EOF'
---
type: system
status: active
---

# Taxonomía de Tags

## Proyectos
- `gromacs` — Dinámica molecular (DM UAMI)
- `strava` — Entrenamiento y fitness (Claude Strava, L'Étape)
- `proxmox` — Infraestructura de servidor
- `ops` — Operaciones y rutina diaria

## Tecnología
- `cuda` — Optimizaciones CUDA/GPU
- `cpp` — Código C++
- `fortran` — Código Fortran
- `python` — Python scripts
- `bash` — Bash/shell scripts
- `devops` — Deployment, CI/CD

## Tipo de Contenido
- `IA` — Trabajo generado por IA o análisis con IA
- `benchmark` — Mediciones de performance
- `analysis` — Análisis profundo
- `review` — Revisión semanal/mensual
- `decision` — ADR o decisión ejecutiva
- `howto` — Tutorial o guía
- `reference` — Documentación de referencia

## Estado
- `draft` — Work in progress
- `active` — En desarrollo/investigación
- `completed` — Terminado
- `archived` — Archivado pero útil para referencia
- `deprecated` — No usar

## Ejemplos de uso
```
tags: [gromacs, cuda, benchmark, completed]
tags: [strava, review, active]
tags: [proxmox, ops, decision]
```

EOF
```

**Paso 5.2: Crear Templates/**

```bash
cat > "00 System/Templates/Weekly-Review-Template.md" << 'EOF'
---
type: review
project: (llena esto)
priority: high
status: active
tags: [review, weekly]
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Weekly Review — Week of [YYYY-MM-DD]

## What's Working
- [ ] 

## What's Not Working
- [ ] 

## Decisions Made
- [ ]

## Next Week Focus
- [ ]

## Metrics
- Training: X km, Y hours
- DM UAMI: Phase, iteration, blocker
- Other projects: status

EOF
```

**Paso 5.3: Crear README.md en carpetas clave**

```bash
cat > "01 Projects/README.md" << 'EOF'
# Proyectos Activos

Cada carpeta aquí es un proyecto con deadline < 6 meses o entregable visible.

Ver el status actual en:
- Cada carpeta `README.md`
- Metadata en `.base` (Obsidian Base view)
- Revisiones semanales en `03 Operations/Weekly Reviews/`

Proyectos inactivos (> 6 meses sin tocar) se mueven a `10 Archives/`.

EOF

cat > "10 Archives/README.md" << 'EOF'
# Proyectos Archivados

Proyectos completados o pausados.

| Proyecto | Razón | Fecha |
|----------|-------|-------|
| Ejemplo | Completado | 2026-09-17 |

EOF
```

### Fase 6: Agregar Frontmatter a Archivos Críticos (1 hora)

**Paso 6.1: Identificar archivos sin frontmatter**

```bash
# Encuentra todos los .md sin frontmatter
find . -name '*.md' -type f ! -path './.git/*' ! -path './.opencode/*' -exec sh -c '
  if ! head -1 "$1" | grep -q "^---"; then
    echo "NO FM: $1"
  fi
' _ {} \; | head -50
```

**Paso 6.2: Agregar frontmatter mínimo a .md de proyectos activos**

Ejemplo: `01 Projects/DM UAMI/README.md`

Antes:
```markdown
# DM UAMI — Dinámica Molecular

## Resumen
...
```

Después:
```markdown
---
type: project-md
project: DM UAMI
priority: high
status: active
tags: [gromacs, cuda, optimization]
created: 2026-01-15
updated: 2026-09-17
---

# DM UAMI — Dinámica Molecular

## Resumen
...
```

(Puedes hacer esto con un script `sed` si son muchos.)

### Fase 7: Actualizar .gitignore (15 min)

**Paso 7.1: Agregar rutas de binarios y builds**

```bash
cat >> ".gitignore" << 'EOF'

# DM UAMI builds (no subir binarios)
01 Projects/DM UAMI/03 Builds & Binarios/
01 Projects/DM UAMI/**/build/
01 Projects/DM UAMI/**/*.o
01 Projects/DM UAMI/**/*.a
01 Projects/DM UAMI/**/*.so
01 Projects/DM UAMI/**/phase4_energies.txt

# Temporary draft files
04 Ideas & Drafts/Inbox/
04 Ideas & Drafts/Nuevas Ideas/

# Obsidian cache (already excluded)
# .obsidian/cache
# .obsidian/plugins
EOF
```

### Fase 8: Commit y Push (15 min)

**Paso 8.1: Revisar cambios**

```bash
git status
git diff --name-status HEAD | head -50  # Ver qué cambió
```

**Paso 8.2: Commit**

```bash
git add -A
git commit -m "refactor: reorganizar vault structure según auditoría 2026-09-17

Cambios:
- Consolidate DM UAMI (01 Projects + 03 Projects → 01 Projects)
- Move system files: CLAUDE.md, GOALS.md → 00 System/
- Move coordination: AI-Carrillo-* → 00 System/Agents/
- Move reviews: 04 Reviews/ → 03 Operations/
- Move WIP: Prototipos → 04 Ideas & Drafts/
- Remove empty files and malformed directories
- Add Tags-Taxonomy.md and templates
- Add frontmatter to critical .md files
- Update .gitignore for builds and temp files"
```

**Paso 8.3: Push a rama de feature**

```bash
git push origin refactor/vault-reorganization-2026-09-17
```

**Paso 8.4: (Luego) Mergear en main**

Crea un PR, revisa, aprueba, merge.

```bash
git checkout main
git pull
git merge refactor/vault-reorganization-2026-09-17
git push origin main
```

---

## Flujo de Trabajo Diario / Semanal

### Diario (5 min)

1. Abre Obsidian, navega a `03 Operations/Diario/`.
2. Crea o abre `YYYYMMDD.md` (ej: `20260917.md`).
3. Escribe notas libremente (sin frontmatter requerido).
4. Al cerrar el día, mueve notas útiles a sus carpetas respectivas (proyecto, knowledge, idea).

### Semanal (Domingos ~19:00 CDMX)

1. Abre `03 Operations/Weekly Reviews/` y crea `20260917 - Week Review.md` (usa template).
2. Escribe: qué funcionó, qué no, decisiones, métricas.
3. Revisa `GOALS.md` en `00 System/`.
4. **Git:**
   ```bash
   cd /Users/josealejandre/Obsidian/JarvisVault
   git add -A
   git commit -m "Weekly review + vault updates — $(date +%Y-%m-%d)"
   git push origin main
   ```
5. (Rutina automática en CT 109 hace esto también, pero puedes hacerlo manual.)

### Mensual (Primer día del mes)

1. Crea `03 Operations/Monthly Reviews/202609 - September Review.md`.
2. Revisa 4 semanas de reviews semanales.
3. Planifica mes siguiente.
4. Archiva notas viejas de `04 Ideas & Drafts/`.

### Trimestral (Fin del trimestre)

1. Ejecuta auditoría limpia:
   ```bash
   find /Users/josealejandre/Obsidian/JarvisVault/04\ Ideas\ \&\ Drafts -mtime +180 -type f
   ```
2. Mueve cosas viejas a `10 Archives/`.
3. Actualiza `GOALS.md`.
4. Revisa wikilinks rotos.

---

## Resumen de Resultados Esperados

| Métrica | Antes | Después | Mejora |
|---------|-------|---------|--------|
| Fragmentación DM UAMI | 3 ubicaciones | 1 centralizado | ✅ |
| Archivos sin frontmatter | 301/448 (67%) | ~50/448 (11%) | ✅ |
| Archivos en raíz | 11 | 0 | ✅ |
| Directorios con errores | 2 (backslash) | 0 | ✅ |
| Wikilinks rotos | 37 | ~5 (después de refactor) | ✅ |
| Tags centralizados | ❌ No | ✅ Sí (Taxonomy) | ✅ |
| Convencion de nombres | Inconsistente | Consistente | ✅ |

---

## Próximos Pasos (Post-Migración)

1. **Validar:** Abre Obsidian, verifica que todos los links siguen funcionando. Si no, actualiza manualmente.
2. **Documentar:** Escribe una guía rápida ("VAULT-GUIDE.md") sobre cómo usar la nueva estructura.
3. **Automatizar:** Crea un script de limpieza trimestral que busque archivos old/vacíos.
4. **Monitor:** En las próximas 2 semanas, verifica que la rutina semanal de git funciona sin errores.

---

**FIN DEL REPORTE**

Auditoría completada: 17 de septiembre de 2026  
Próxima auditoría recomendada: 17 de diciembre de 2026 (trimestral)

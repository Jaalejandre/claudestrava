# Evaluación de Skills Externos — Web/UX (E20)

**Fecha:** 2026-09-20
**Evaluador:** Equipo Web/UX (E20 Dashboard Manager)
**Fuentes:** emilkowalski/skills (GitHub ★27.7k), agenticskills.io/skills/mcp-builder

---

## Resumen Ejecutivo

Se evaluaron **14 skills** de dos repositorios externos. Recomendación:

| Acción | Cantidad |
|--------|----------|
| Instalar en Hermes | 6 |
| Documentar en vault (referencia) | 3 |
| Derivar a otro equipo | 3 |
| Descartar | 2 |

---

## 1. emilkowalski/skills — Evaluación skill por skill

Repo de Emil Kowalski (ex-Vercel, Linear). Skills de diseño engineering con barra de calidad alta. Las descripciones están en SKILL.md, estructuradas con frontmatter YAML + markdown.

### 1.1 `animate` — ✅ INSTALAR (Web/UX)

**Descripción:** Construye animaciones desde cero con criterio — decide si algo debe animar, con qué propósito, tool, propiedades, curva, duración e interrupción. Escribe la implementación.

**Juicio:** **ALTA relevancia.** Es el skill central de animación web del repo. Se alinea perfectamente con el stack de prototipos. Las reglas son estrictas (nunca `ease-in` en entrances, sub-300ms UI motion, solo `transform`/`opacity`, reduced-motion handling). Complementa a `prototipo-local`.

**Recomendación:** Instalar. Reemplazaría a cualquier skill de animación ad-hoc que tengamos.

**Tags:** `animation`, `css`, `motion`, `framer-motion`

### 1.2 `animation-vocabulary` — ✅ INSTALAR (Web/UX)

**Descripción:** Glosario inverso: de descripción vaga a término exacto ("lo que rebota cuando un popover se abre" → "Pop in").

**Juicio:** **MEDIA-ALTA relevancia.** Skill pequeño pero útil para comunicación interna y con otros agentes. Reduce ambigüedad en prompts de diseño.

**Recomendación:** Instalar. Ocupa espacio mínimo, utilidad alta para especificación precisa.

**Tags:** `glossary`, `terminology`, `vocabulary`

### 1.3 `prototype` — ✅ INSTALAR (Web/UX)

**Descripción:** Construye múltiples versiones genuinamente diferentes de un componente UI, renderizadas detrás de un picker visual para comparar y elegir la mejor.

**Juicio:** **MUY ALTA relevancia.** Es exactamente lo que hacemos con prototipos. La filosofía de divergencia (variantes genuinamente diferentes, no 3 tintes de la misma idea) se alinea con nuestro workflow. Diferente de `prototipo-local`: este es para exploración de variantes de un mismo componente.

**Recomendación:** Instalar. Complementa `prototipo-local` (que es más de harness completo).

**Tags:** `prototyping`, `design-exploration`, `ui-variants`

### 1.4 `pick-ui-library` — ✅ INSTALAR (Web/UX)

**Descripción:** Recomienda la librería correcta para cada tarea frontend de una lista curada: números, OTP inputs, charts, command menus, drag & drop, toasts, estado, estilos, etc.

**Juicio:** **ALTA relevancia.** Lista curada por Emil Kowalski que incluye Sonner (su library), base-ui, Vaul, Virtuoso, etc. Muy útil como checklist rápido al decidir dependencias.

**Recomendación:** Instalar. `disable-model-invocation: true` — solo se invoca explícitamente.

**Tags:** `libraries`, `decision-making`, `frontend-tooling`

### 1.5 `review-animations` — ✅ INSTALAR (Web/UX)

**Descripción:** Revisa código de animación contra estándares altos de craft. Incluye STANDARDS.md con 10 reglas no negociables (easing, duración, spring config, gestures, clip-path, performance, a11y).

**Juicio:** **ALTA relevancia.** Útil como checklist de code review para cualquier PR de UI que incluya motion. Las reglas son transferibles a cualquier framework.

**Recomendación:** Instalar. Usar en code reviews de UI.

**Tags:** `code-review`, `animation-standards`, `quality`

### 1.6 `improve-animations` — 📝 DOCUMENTAR (referencia, no instalar)

**Descripción:** Audita toda una codebase de animaciones y produce hallazgos priorizados + planes de implementación autocontenidos para que otros agentes ejecuten.

**Juicio:** **MEDIA relevancia.** Útil cuando toque hacer overhaul grande de animaciones en un proyecto existente. Pero no tenemos codebases legacy con animaciones que auditar ahora. Skills `animate` + `review-animations` cubren el día a día.

**Recomendación:** No instalar ahora. Documentar en vault como referencia futura. Si un proyecto existente requiere auditoría de motion, se instala en ese momento.

**Tags:** `audit`, `planning`, `refactoring`

### 1.7 `find-animation-opportunities` — 📝 DOCUMENTAR (referencia)

**Descripción:** Busca en una UI lugares que no animan pero deberían (y rechaza los que no deben). Read-only, propone motion con valores exactos.

**Juicio:** **BAJA-MEDIA relevancia.** Útil en fase de diseño inicial, pero nuestros proyectos son pequeños y sabemos dónde poner animaciones.

**Recomendación:** No instalar. Documentar en vault. Si se inicia proyecto greenfield, considerar.

**Tags:** `audit`, `discovery`, `motion-opportunities`

### 1.8 `apple-design` — ✅ INSTALAR (Web/UX)

**Descripción:** Enfoque de Apple para diseño de interfaces y motion físico/fluido, traducido para web. Springs, gesture-driven UI, translucency, tipografía óptica, reduced-motion.

**Juicio:** **ALTA relevancia.** Filosofía de diseño de Apple (WWDC 2018 "Designing Fluid Interfaces") traducida a web. Útil para darle a los prototipos el "feeling native" que buscamos. Complementa `mobile-native`.

**Recomendación:** Instalar.

**Tags:** `apple-hci`, `spring-animations`, `gesture-driven`, `fluid-interfaces`

### 1.9 `emil-design-eng` — ✅ INSTALAR (Web/UX)

**Descripción:** Filosofía completa de Emil Kowalski sobre UI polish, component design, decisiones de animación, y detalles invisibles que hacen que el software se sienta genial.

**Juicio:** **MUY ALTA relevancia.** Es el skill "paraguas" filosófico del repo. Codifica taste, criterio y principios de diseño engineering. Útil como grounding filosófico para cualquier decisión de UI que tome el equipo.

**Recomendación:** Instalar. Usar como skill de referencia para grounding filosófico.

**Tags:** `design-philosophy`, `craft`, `taste`, `ui-polish`

### 1.10 `mobile-native` — ✅ INSTALAR (Web/UX)

**Descripción:** Hace que una web app se sienta nativa en móvil — sticky hover states, tap highlight, 100vh bug, inputs que zoom, pull-to-refresh, notch, safe areas, etc.

**Juicio:** **ALTA relevancia.** Todos nuestros proyectos web deberían correr en mobile. Este skill cubre los detalles de platform layer que marcan la diferencia entre "una web en un browser" y "algo que se siente instalado".

**Recomendación:** Instalar.

**Tags:** `mobile`, `pwa`, `touch`, `responsive`, `native-feel`

### 1.11 `animate-expo` — ➡️ DERIVAR a Mobile Dev (no tenemos)

**Descripción:** Animaciones en React Native / Expo con Reanimated, Gesture Handler, Expo Router.

**Juicio:** **Relevante solo si tuviéramos apps React Native/Expo.** No tenemos proyectos RN/Expo actualmente. Si en el futuro se desarrolla app nativa, instalar entonces.

**Recomendación:** No instalar ahora. Anotar como skill futuro si el equipo se expande a mobile nativo.

**Destino:** Equipo Mobile (no existe actualmente en RUDR9). Documentar en vault para futuro.

### 1.12 `ask-sonner` — ✅ INSTALAR (Web/UX, liviano)

**Descripción:** Guía para Sonner (React toast library de Emil Kowalski) — setup, styling, troubleshooting.

**Juicio:** **MEDIA relevancia.** Sonner es la library de toasts recomendada por `pick-ui-library`. Si usamos React y toasts en algún proyecto, útil tener la guía. Ocupa espacio mínimo.

**Recomendación:** Instalar. Es pequeño y específico pero muy útil cuando se necesita.

**Tags:** `sonner`, `toasts`, `react`

### 1.13 `write-swift` — ➡️ DERIVAR a Desarrollo Apple (no tenemos)

**Descripción:** Cómo escribir Swift moderno — value types, Swift 6 concurrency, protocols, ARC, macros.

**Juicio:** **Cero relevancia para Web/UX.** Swift es para desarrollo Apple nativo.

**Recomendación:** No instalar. Descartar para Web/UX. Si algún día hay desarrollo iOS/macOS se evalúa entonces.

**Destino:** Equipo Apple (no existe). Documentar en vault.

---

## 2. agenticskills.io/skills/mcp-builder

**URL:** https://agenticskills.io/skills/mcp-builder
**Autor:** Anthropic
**Rank:** S-RANK
**Stars:** 176.2k
**Updated:** ~5 months ago

**Descripción:** Guía para crear servidores MCP de alta calidad. Cubre Python (FastMCP), Node/TypeScript (MCP SDK), diseño de tool surface, adaptación de APIs existentes.

**Juicio:** **Relevancia BAJA para Web/UX.** MCP builder es un skill de arquitectura de agentes (para construir tools que LLMs puedan llamar). Pertenece al equipo AI/Agentes (OmniMind) o a Infraestructura. Nosotros (Web/UX) consumimos MCP servers, no los construimos.

**Recomendación:** ❌ No instalar en Web/UX. **Derivar a equipo AI/Agentes (OmniMind)** que maneja la infraestructura OmniRoute y skills Hermes. Ellos pueden decidir si integrarlo.

**Destino:** AI/Agentes (OmniMind, CT 666)

---

## 3. Resumen de Instalación

### Instalar AHORA (6 skills + 1 liviano):

| Skill | Prioridad | Tags |
|-------|-----------|------|
| `emil-design-eng` | 🔴 Crítica | design-philosophy, craft, taste |
| `prototype` | 🔴 Crítica | prototyping, ui-variants |
| `animate` | 🟡 Alta | animation, css, motion |
| `apple-design` | 🟡 Alta | apple-hci, springs, gestures |
| `mobile-native` | 🟡 Alta | mobile, pwa, touch |
| `review-animations` | 🟡 Alta | code-review, standards |
| `pick-ui-library` | 🟢 Media | libraries, tooling |
| `animation-vocabulary` | 🟢 Media | glossary, terminology |
| `ask-sonner` | 🟢 Media/baja | toasts, react |

### Derivar a otros equipos:

| Skill | Equipo destino | Razón |
|-------|----------------|-------|
| `mcp-builder` | AI/Agentes (OmniMind) | Arquitectura de agentes MCP |
| `animate-expo` | (futuro) Mobile Dev | React Native, no aplica ahora |
| `write-swift` | (futuro) Apple Dev | Swift nativo |

### Documentar en vault (no instalar ahora):

| Skill | Cuándo reconsiderar |
|-------|---------------------|
| `improve-animations` | Cuando un proyecto legacy requiera auditoría de motion |
| `find-animation-opportunities` | En proyecto greenfield de UI |

### Descartar:

Ninguno se descarta completamente — todos tienen mérito técnico. Solo `write-swift` y `animate-expo` no aplican a nuestro stack actual.

---

## 4. Nota para el Jefe E20

Los skills de emilkowalski/skills representan la filosofía más refinada de diseño engineering disponible como código de agente. La instalación de `emil-design-eng`, `prototype` y `animate` como trio base le da al equipo Web/UX una capacidad de prototipado + criterio estético que antes no tenía codificada.

Se requiere visto bueno para proceder con la instalación. Los skills viven en `.hermes/skills/` y se activan automáticamente al cargar el perfil.
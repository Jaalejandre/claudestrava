# (C) SKILLS CATALOG WEB/UX — Emil Kowalski Skills

> **Equipo:** Web/UX (jefe E20 Dashboard Manager)
> **Fuente:** https://github.com/emilkowalski/skills
> **Fecha:** 2026-09-20
> **Estado:** 5 core instalados, 6 condicionales documentados (pendientes de instalar)

---

## Instalados (Core) — en `.hermes/skills/`

| Skill | Proposito |
|-------|-----------|
| `emil-design-eng` | Skill base. Filosofia de polish UI de Emil Kowalski: diseno de componentes, decisiones de animacion, detalles invisibles que hacen que el software se sienta bien. |
| `animate` | Construir una animacion desde cero tomando las decisiones en el orden correcto (debe animar?, que proposito, que tool, que propiedades, curva/duracion, interrupcion, salida). Escribe la implementacion. |
| `apple-design` | Enfoque Apple al diseno de interfaces y movimiento fisico, traducido a la web: gestures, springs, drag/swipe/sheet, materiales translucidos, tipografia, reduced-motion. |
| `prototype` | Prototipado rapido de ideas/experiencias. Requiere `PICKER.md` (incluido). |
| `mobile-native` | Hacks para que una web se sienta nativa en movil: hover states, tap highlights, bug 100vh, inputs que hacen zoom, laggy taps, contenido bajo el notch, PWA, bottom sheets, carouseles. |

### Archivos auxiliares
- `prototype/PICKER.md` — incluido con prototype.

---

## Condicionales — documentar, instalar solo cuando aplique

Estos 6 skills NO se instalan aun. Instalar bajo demanda segun el disparador descrito.

| # | Skill | Proposito | Cuando instalar |
|---|-------|-----------|-----------------|
| 6 | `pick-ui-library` | Elegir la biblioteca UI/componentes correcta para un proyecto. | Cuando se inicie un nuevo proyecto frontend y haya que decidir entre librerias de componentes (shadcn, Radix, MUI, etc.). |
| 7 | `review-animations` | Criticar/auditar una animacion existente y dar feedback accionable. | Cuando alguien haya implementado una animacion y pida revision, o al hacer code review de motion. |
| 8 | `improve-animations` | Auditar UN CODIGO BASE ENTERO en busca de oportunidades de mejorar las animaciones/progressive enhancement. | Auditorias de codebase completa (tarea masiva), no piezas sueltas. |
| 9 | `animation-vocabulary` | Vocabulario/terminologia correcta de animacion para comunicarse con precision. | Cuando se necesite describir motion con precision en docs, PRs o comunicacion inter-equipo. |
| 10 | `find-animation-opportunities` | Encontrar oportunidades de animacion en una interfaz/experiencia existente. | Fase de diseno UX: identificar donde una micro-interaccion mejoraria la experiencia. |
| 11 | `ask-sonner` | Integrar sonner (libreria de toasts de Emil Kowalski). | Cuando un proyecto necesite toasts/notificaciones in-app. |

### Regla de instalacion
Instalar con el mismo comando base:
```bash
curl -o /root/.hermes/skills/NOMBRE/SKILL.md \
  https://raw.githubusercontent.com/emilkowalski/skills/main/skills/NOMBRE/SKILL.md
```
Verificar siempre que el frontmatter `---` y `name:` existan (igual que los core).

---

## Asignaciones a otros equipos
- `mcp-builder` (agenticskills.io) → **Equipo AI/Agentes (OmniMind)**. Ver `(C) RECOMENDACION_MCP_BUILDER.md`.

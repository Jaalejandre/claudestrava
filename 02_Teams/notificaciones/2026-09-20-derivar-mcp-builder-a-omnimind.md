# Notificación: Skill MCP Builder para equipo AI/Agentes

**De:** Equipo Web/UX (E20)
**Para:** AI/Agentes (OmniMind)
**Fecha:** 2026-09-20

---

Durante la evaluación de skills externos para el equipo Web/UX, identificamos un skill que pertenece al dominio de AI/Agentes:

## mcp-builder (agenticskills.io)

- **Autor:** Anthropic
- **Rank:** S-RANK
- **Descripción:** Guía para crear servidores MCP de alta calidad en Python (FastMCP) y Node/TypeScript (MCP SDK). Cubre diseño de tool surface, adaptación de APIs, testing.
- **URL:** https://agenticskills.io/skills/mcp-builder
- **Instalación:** `npx skills add anthropics/skills@mcp-builder`

**Por qué va a AI/Agentes:** MCP builder es sobre arquitectura de agentes — construir tools que LLMs puedan llamar vía Model Context Protocol. Web/UX consume MCP servers, no los construye. OmniMind maneja la infraestructura OmniRoute, skills Hermes, y la integración MCP. Este skill les pertenece.

**Recomendación:** Evaluar instalación en perfil de OmniMind/Infraestructura si planean construir más MCP servers caseros (vs. consumir los existentes).

---

*Este documento se archiva en `02_Teams/notificaciones/` como registro de derivación inter-equipo.*
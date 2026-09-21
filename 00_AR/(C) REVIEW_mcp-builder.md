# (C) Review: mcp-builder skill (agenticskills.io)

> Evaluación del skill **mcp-builder** de Anthropic.
> Fuente: https://agenticskills.io/skills/mcp-builder
> Evaluado: 2026-09-20

## Resumen

**mcp-builder** es un skill de Anthropic (143.7K stars en GitHub) para crear
servidores MCP (Model Context Protocol) de alta calidad. Versión evaluada: v1.3.0
(MAY 30 2026).

## ¿Qué ofrece?

Guía completa para crear MCP servers en 4 fases:

1. **Research & Planning** — diseño de herramientas, naming, cobertura API vs. workflows
2. **Implementation** — patrones de transporte (stdio, SSE, streaming), validación
3. **Testing** — test suite con MCP inspector, casos edge
4. **Deployment** — packaging, documentación, ejemplos

Incluye: templates, checklist de calidad, guía de debugging.

## ¿Sirve para SatanZote?

| Necesidad | mcp-builder cubre? |
|-----------|-------------------|
| Crear MCP servers para Hermes | ✅ Sí, guía completa de creación |
| Skills actuales via SKILL.md | ⚠️ Parcial — Hermes usa skills/.md, no MCP servers |
| GPU Orchestrator como MCP | ✅ Podría exponer API del orchestrator como MCP tools |
| OpenViking como MCP | ✅ Podría convertir el RAG en tools MCP |
| OmniRoute tools | ⚠️ Ya existen como MCP tools nativas |

## Recomendación

**Instalar solo si** se planea exponer servicios SatanZote como MCP servers
para consumo desde otros agentes (ej: que Claude Code o Codex accedan al
GPU orchestrator vía MCP en vez de curl).

**No instalar ahora** porque:
1. Hermes ya tiene acceso directo a bash/curl — no necesita bridge MCP para
   tareas actuales
2. Los tools de OmniRoute ya son MCP — duplicaría funcionalidad
3. Agregar otro skill aumenta el baseline de tokens sin beneficio inmediato

**Guardar para referencia.** Si en el futuro se necesita que agentes externos
(Codex, Claude Code en otros CTs) accedan a servicios SatanZote, mcp-builder
es la herramienta correcta.

## Instalación (futura)

```bash
cd /root/.hermes
npx skills add anthropics/mcp-builder
```

Esto instala el skill en `.hermes/skills/mcp-builder/` con templates y guías.
# (C) RECOMENDACION — mcp-builder para el Equipo AI/Agentes (OmniMind)

> **Remitente:** Equipo Web/UX (jefe E20 Dashboard Manager)
> **Destino:** Equipo AI/Agentes (OmniMind)
> **Fuente:** https://agenticskills.io/skills/mcp-builder
> **Fecha:** 2026-09-20
> **Estado:** RECOMENDADO

---

## Que es mcp-builder

`mcp-builder` es un skill de agenticskills.io que agiliza la construccion de **servidores MCP (Model Context Protocol)**. Un servidor MCP expone herramientas, recursos y prompts a agentes de IA (como Hermes) a traves del protocolo estandar de Anthropic. En lugar de escribir cada handler a mano, partiendo de un prompt/descripcion el skill genera el esqueleto del servidor, los tipos, el handler de herramientas y la configuracion de arranque (stdio o HTTP).

---

## Por que le pertenece a AI/Agentes (OmniMind)

1. **Es infraestructura de agentes, no de UI.** mcp-builder crea servidores MCP, que son el tejido que conecta Hermes/agentes con servicios externos. Eso es competencia directa de OmniMind, no de Web/UX.
2. **Encaja con el roadmap del equipo.** OmniMind gestiona el ecosistema de agentes de SatanZote; construir MCP servers para Hermes (conectores a herramientas internas: Proxmox, vault, Gromacs, etc.) es trabajo recurrente.
3. **Reutilizable y multiplataforma.** Un solo skill sirve para generar servidores MCP reutilizables en todo el stack, no solo para un frontend puntual.
4. **Coherencia con la infra existente.** Hermes ya usa MCP (ver carpeta `/root/JarvisVault/00_System/MCP_Servers/`). El equipo AI/Agentes es quien debe mantener y extender ese parque.

---

## Instrucciones de instalacion

```bash
# 1. Crear el directorio del skill
mkdir -p /root/.hermes/skills/mcp-builder

# 2. Descargar el skill
curl -o /root/.hermes/skills/mcp-builder/SKILL.md \
  https://agenticskills.io/skills/mcp-builder/SKILL.md

# 3. Verificar frontmatter valido
head -5 /root/.hermes/skills/mcp-builder/SKILL.md   # debe mostrar '---' y 'name:'
```

> **Nota de verificacion:** confirmar la URL exacta de descarga en agenticskills.io al instalar, ya que el path puede variar. Si el curl directo no resuelve, consultar el skill de install manual del sitio.

---

## Consideraciones
- **Coste:** relevante para el equipo, no para el presupuesto GPU.
- **Prioridad:** recomendado como backlog del equipo AI/Agentes; no bloquea tareas actuales de Web/UX.
- **Duplicidad:** revisar en OmniMind si ya existe algun skill/tool equivalente antes de duplicar.

**Accion solicitada al Equipo AI/Agentes:** aceptar la asignacion, instalar el skill siguiendo las instrucciones y registrar su uso.

# Skill: New Dev Project

Variante de la skill **New Project** específica para proyectos de desarrollo/código. Además de crear la carpeta y el `CLAUDE.md` en el vault, provisiona el espacio de trabajo real en el **contenedor de desarrollo Claude Code** que vive en Proxmox, y ese contenedor es donde ocurre el trabajo de código real (no en el vault local).

## Cuándo usar esta skill (en vez de New Project)

- El usuario dice "nuevo proyecto" y el proyecto implica escribir/mantener código (apps, scripts, APIs, automatizaciones, etc.)
- Si no está claro si es un proyecto de código o uno organizacional (como Claude Strava, que es más bien un plan de entrenamiento), pregúntale directo: "¿este proyecto implica programar?"

## El contenedor de desarrollo

Ya existe un contenedor LXC dedicado a esto, creado con el script `serversathome/ServersatHome/agentic.sh` (Claude Code + Node/Python/Go/Rust + Docker + CloudCLI UI). **Es compartido para todos los proyectos de desarrollo** — cada proyecto nuevo es solo una subcarpeta dentro de `/project` en este mismo contenedor, no un contenedor nuevo cada vez.

| Dato              | Valor                                                                                                                             |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------- |
| Host Proxmox       | `192.168.0.52` (ver skill `proxmox.md`)                                                                                           |
| CT ID              | `109`                                                                                                                              |
| Hostname           | `claude-dev`                                                                                                                      |
| IP (fija, static)  | `192.168.0.64` — configurada como IP estática en `pct` (`net0 ...,ip=192.168.0.64/24,gw=192.168.0.1`), ya no cambia por DHCP      |
| SSH                | `ssh root@192.168.0.64` (llave ya instalada, sin contraseña) — o vía el host: `ssh root@192.168.0.52 "pct exec 109 -- <comando>"` |
| Web UI (CloudCLI)  | `http://192.168.0.64:3001` — crear login la primera vez                                                                           |
| Workspace          | `/project/<nombre-proyecto>/` dentro del contenedor                                                                               |
| Vault (SMB)        | El vault de Obsidian también vive físicamente aquí (`/root/JarvisVault`), montado en el Mac vía SMB en `/Volumes/JarvisVault`     |

## Herramientas disponibles dentro del contenedor

Además del stack base (Node/Python/Go/Rust/Docker/Claude Code), `claude-dev` tiene instalado:

| Herramienta   | Qué es                                                                                          | Cuándo ofrecerla                                                                 |
| ------------- | ------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------- |
| **OmniRoute** | Gateway local de IA (`localhost:20128`) que agrupa proveedores LLM bajo un solo endpoint, incluye un proveedor gratuito (`opencode`) sin API key. Corre en la **Mac**, no en `claude-dev` (ver nota abajo). | Cuando el proyecto necesita llamadas a LLM baratas/gratis desde herramientas externas (Cursor, Cline, scripts propios) sin gastar tu cuota de Claude. |
| **Ruflo**     | Orquestador de agentes/swarms sobre Claude Code (`/project/ruflo/`), con daemon + workers en background (modo local-only por default) y proveedor Anthropic configurado. | Cuando el proyecto es grande/complejo y se beneficia de coordinar múltiples agentes o memoria persistente entre sesiones — no para proyectos simples. |

> **Nota de arquitectura:** OmniRoute vive en tu Mac (`~/.npm-global`), no en `claude-dev` — es aparte del contenedor. Ruflo sí vive dentro de `claude-dev`.

## Cómo funciona

1. Corre la entrevista y el scaffolding normal de **New Project** (`new-project.md`) — esto crea `03 Projects/<Nombre>/` en el vault con su `CLAUDE.md`, `COMMANDS.md`, y estructura de carpetas. Esta parte del vault es para planeación, notas, y contexto — no para el código en sí.
2. **Pregunta qué herramientas usar para este proyecto**, antes de crear nada en el contenedor:
   - "¿Este proyecto necesita orquestación de agentes/swarms (Ruflo), o Claude Code normal es suficiente?"
   - "¿Vas a necesitar llamadas a LLM baratas/gratis vía OmniRoute (para herramientas externas tipo Cursor/Cline), o solo Claude Code?"
   - Si el usuario no está seguro o el proyecto es simple, el default es **solo Claude Code normal**, sin Ruflo ni OmniRoute — no las actives de más.
3. En el contenedor `claude-dev`, crea la carpeta de trabajo real:
   ```bash
   ssh root@192.168.0.64 "mkdir -p /project/<nombre-slug> && cd /project/<nombre-slug> && git init"
   ```
   Si el usuario pidió Ruflo para este proyecto: `ssh root@192.168.0.64 "cd /project/<nombre-slug> && ruflo init"`.
4. Documenta en el `COMMANDS.md` del proyecto (en el vault) cómo conectarse:
   - SSH directo: `ssh root@192.168.0.64`
   - Web UI: `http://192.168.0.64:3001`
   - Ruta del código: `/project/<nombre-slug>/`
   - Si aplica: cómo usar Ruflo (`ruflo status`, `ruflo agent ...`) y/o apuntar a OmniRoute (`http://localhost:20128/v1`)
5. Para cualquier tarea de desarrollo real de este proyecto (escribir código, correr comandos, instalar dependencias, correr tests, usar Claude Code ahí mismo), **conéctate por SSH al contenedor y trabaja ahí** — no repliques el código dentro del vault de Obsidian.
6. Si el usuario pide sincronizar el código a GitHub, hazlo desde dentro del contenedor (ya tiene git, y se le puede configurar su propia llave/remote igual que se hizo con el vault).

## Reglas

- **El vault es para contexto y planeación; el contenedor es para el código.** No dupliques archivos de código dentro de `03 Projects/<Nombre>/` — ahí solo van notas, specs, y el `CLAUDE.md`/`COMMANDS.md` de referencia.
- **Siempre pregunta qué herramientas usar** (Ruflo, OmniRoute) al arrancar un proyecto nuevo — no las actives por default, son opt-in por proyecto.
- **La IP del contenedor ya es fija** (`192.168.0.64`) — si por algún motivo no responde, confirma con `ssh root@192.168.0.52 "pct exec 109 -- hostname -I"` antes de asumir que cambió.
- **Actualizaciones del contenedor son automáticas** (domingos 4am vía `agentic-update`, corre en el propio contenedor) — no hace falta mantenimiento manual salvo que algo falle (`agentic-doctor` para diagnosticar).
- **No crear un contenedor nuevo por proyecto** — todos los proyectos de desarrollo comparten `claude-dev` (CT 109), organizados en subcarpetas bajo `/project/`.

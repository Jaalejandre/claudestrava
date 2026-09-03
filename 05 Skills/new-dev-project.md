# Skill: New Dev Project

Variante de la skill **New Project** específica para proyectos de desarrollo/código. Además de crear la carpeta y el `CLAUDE.md` en el vault, provisiona el espacio de trabajo real en el **contenedor de desarrollo Claude Code** que vive en Proxmox, y ese contenedor es donde ocurre el trabajo de código real (no en el vault local).

## Cuándo usar esta skill (en vez de New Project)

- El usuario dice "nuevo proyecto" y el proyecto implica escribir/mantener código (apps, scripts, APIs, automatizaciones, etc.)
- Si no está claro si es un proyecto de código o uno organizacional (como Claude Strava, que es más bien un plan de entrenamiento), pregúntale directo: "¿este proyecto implica programar?"

## El contenedor de desarrollo

Ya existe un contenedor LXC dedicado a esto, creado con el script `serversathome/ServersatHome/agentic.sh` (Claude Code + Node/Python/Go/Rust + Docker + CloudCLI UI). **Es compartido para todos los proyectos de desarrollo** — cada proyecto nuevo es solo una subcarpeta dentro de `/project` en este mismo contenedor, no un contenedor nuevo cada vez.

| Dato | Valor |
|---|---|
| Host Proxmox | `192.168.0.52` (ver skill `proxmox.md`) |
| CT ID | `109` |
| Hostname | `claude-dev` |
| IP (DHCP, puede cambiar) | `192.168.0.66` — verificar con `pct exec 109 -- hostname -I` si falla la conexión directa |
| SSH | `ssh root@192.168.0.66` (llave ya instalada, sin contraseña) — o vía el host: `ssh root@192.168.0.52 "pct exec 109 -- <comando>"` |
| Web UI (CloudCLI) | `http://192.168.0.66:3001` — crear login la primera vez |
| Workspace | `/project/<nombre-proyecto>/` dentro del contenedor |

## Cómo funciona

1. Corre la entrevista y el scaffolding normal de **New Project** (`new-project.md`) — esto crea `03 Projects/<Nombre>/` en el vault con su `CLAUDE.md`, `COMMANDS.md`, y estructura de carpetas. Esta parte del vault es para planeación, notas, y contexto — no para el código en sí.
2. Además, en el contenedor `claude-dev`, crea la carpeta de trabajo real:
   ```bash
   ssh root@192.168.0.66 "mkdir -p /project/<nombre-slug> && cd /project/<nombre-slug> && git init"
   ```
3. Documenta en el `COMMANDS.md` del proyecto (en el vault) cómo conectarse:
   - SSH directo: `ssh root@192.168.0.66`
   - Web UI: `http://192.168.0.66:3001`
   - Ruta del código: `/project/<nombre-slug>/`
4. Para cualquier tarea de desarrollo real de este proyecto (escribir código, correr comandos, instalar dependencias, correr tests, usar Claude Code ahí mismo), **conéctate por SSH al contenedor y trabaja ahí** — no repliques el código dentro del vault de Obsidian.
5. Si el usuario pide sincronizar el código a GitHub, hazlo desde dentro del contenedor (ya tiene git, y se le puede configurar su propia llave/remote igual que se hizo con el vault).

## Reglas

- **El vault es para contexto y planeación; el contenedor es para el código.** No dupliques archivos de código dentro de `03 Projects/<Nombre>/` — ahí solo van notas, specs, y el `CLAUDE.md`/`COMMANDS.md` de referencia.
- **Verificar la IP del contenedor antes de asumir que cambió** — es DHCP, así que si `192.168.0.66` deja de responder, confirma la IP actual vía el host: `ssh root@192.168.0.52 "pct exec 109 -- hostname -I"`.
- **Actualizaciones del contenedor son automáticas** (domingos 4am vía `agentic-update`, corre en el propio contenedor) — no hace falta mantenimiento manual salvo que algo falle (`agentic-doctor` para diagnosticar).
- **No crear un contenedor nuevo por proyecto** — todos los proyectos de desarrollo comparten `claude-dev` (CT 109), organizados en subcarpetas bajo `/project/`.

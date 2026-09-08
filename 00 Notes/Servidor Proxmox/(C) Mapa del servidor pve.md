---
tipo: referencia-infra
actualizado: 2026-09-07
fuente: barrido en vivo por SSH (ssh root@192.168.0.52)
---

# Mapa del servidor `pve`

Inventario completo del Proxmox VE personal y de qué usa cada proyecto. Complemento de [[proxmox.md]] y [[UPS y energía]]. Chequeos automáticos diarios en [[Chequeos Diarios]]. **Se desactualiza** — verificar en vivo antes de cambios (último barrido manual: ver `actualizado` en el frontmatter).

## Host

| Dato       | Valor                                                                                             |
| ---------- | ------------------------------------------------------------------------------------------------- |
| Nodo       | `pve` — Proxmox VE **9.1.1**, kernel 6.17.2-1-pve, standalone (sin cluster, sin HA)               |
| CPU        | Intel **i5-14600K** — 14 núcleos / 20 hilos                                                       |
| RAM        | **31 GB** (~11 GB en uso) + **8 GB swap (4.4 GB en uso ⚠️)** — hay presión de memoria, ver notas  |
| Disco raíz | `/dev/mapper/pve-root` 94 GB, 20% usado                                                           |
| GPU        | **NVIDIA RTX 5070 Ti 16 GB** (driver 580.105.08) — compartida por passthrough a CT 103, 109 y 901 |
| Red        | bridge único `vmbr0` sobre `nic0`, `192.168.0.52/24`, gw `192.168.0.1`. Wi-Fi `wlp4s0` DOWN.      |
| Tailscale  | `100.85.38.121` (tailscale0 activo en el host)                                                    |
| Acceso     | SSH por llave (`ssh root@192.168.0.52`), dashboard `https://192.168.0.52:8006`                    |

### Storage

| Nombre | Tipo | Tamaño | Uso | Para qué |
|---|---|---|---|---|
| `local` | dir | 94 GB | 18% | ISOs, plantillas, snippets |
| `local-lvm` | lvmthin | 832 GB | 33% | discos de todos los CT/VM |
| `backups` | dir | 3.8 TB | 9.5% (364 GB) | vzdump + `/mnt/backups` (montado en CT 113 rclone) |
| `nvme-fast` | dir | 245 GB | 3% | (casi vacío — disco rápido disponible) |

### Backups

`vzdump` **diario 21:00**, **todos** los guests, `zstd`, modo snapshot, a storage `backups`, con hook `/usr/local/bin/vzdump-hook.sh`. Sin replicación ni HA.

## Guests

Todos con `onboot: 1`. IP `.x` = `192.168.0.x`.

### VMs

| ID | Nombre | IP | vCPU/RAM/disco | Qué es |
|---|---|---|---|---|
| 106 | `haos-17.1` | .103 | 2 / 4 GB / 32 GB | **Home Assistant OS** (domótica) |
| 200 | `debian-brain` | .204 (prob.) | 2 / 4 GB / 32 GB | ⚠️ **sin guest-agent, sin acceso por llave desde el host** — creada 2025-11. Identidad sin confirmar (¿"segundo cerebro" / experimentos LLM?). **Pendiente: entrar y documentar.** |

### Contenedores LXC

| ID | Nombre | IP | vCPU/RAM/disco | Servicios (puerto) |
|---|---|---|---|---|
| 100 | nginxproxymanager | .109 | 1 / 2 GB / 8 GB | **Nginx Proxy Manager** + openresty — reverse proxy :80 / :81 (admin) / :443 |
| 101 | debian | .203 | 1 / 512 MB / 2 GB | Docker: `enlinea-saas` (:8091), `satanzote-studio` (nginx :8085) |
| 102 | uptimekuma | .216 | 1 / 1 GB / 4 GB | **Uptime Kuma** :3001 (monitoreo) |
| 103 | openwebui | .99 | 4 / 8 GB / 50 GB | **Ollama** :11434 + **Open WebUI** :8080 — **usa GPU**. Modelos movidos a `nvme-fast` (`mp0` → `/opt/ollama-models`, `OLLAMA_MODELS` override) el 2026-09-08; disco raíz bajó de 97% a 63%. Modelos: `qwen2.5-coder:14b`, `gpt-oss:latest`, `gemma3`. Usado por el skill `prototipo-local.md`. |
| 104 | adguard | .10 | 1 / 512 MB / 5 GB | **AdGuard Home** — DNS :53 + panel :80 (`adguard.home`) |
| 105 | unbound | .11 | 1 / 512 MB / 2 GB | **Unbound** — resolver DNS recursivo :5335 (upstream de AdGuard) |
| 107 | docker | .61 | 2 / 2 GB / 16 GB | **Portainer CE** :9443 (+ :8000 edge) — gestión de Docker |
| 108 | cloudflared | .12 | 1 / 512 MB / 2 GB | **Cloudflare Tunnel** (por token) — expone `*.satanzote.me` a internet |
| 110 | n8n | .13 | 2 / 2 GB | **n8n** :5678 (automatización de workflows). Detectado 2026-09-08 por el chequeo diario. |
| 109 | **claude-dev** | **.64** | 4 / 10 GB / 60 GB | **el nodo de IA** — ver detalle abajo. **usa GPU** |
| 111 | apps-prod | .20 | 4 / 4 GB / 40 GB | Docker: `mundial-app`+`mundial-db` (Mundial prod :8000), `nextcloud` :8088 (+redis+mariadb), `guacamole` :8090 (+guacd), `mint-portal` :5010, `open-webui` :3000, `portainer-agent`. Nativo: gunicorn :8085, `qr-counter` |
| 112 | app-dev | .21 | 2 / 2 GB / 20 GB | Docker: `mundial-app` dev :8000 (+db), `airbnb-dashboard` :8090, `portainer-agent`. Nativo: gunicorn :8086, `gpu-top` (http :8095/:8091), `qr-counter-dev` |
| 113 | rclone | .32 | 1 / 2 GB / 2 GB | **rclone-web** :3000 — sync a nube; monta `/mnt/backups` |
| 114 | vaultwarden | .30 | 4 / 6 GB / 20 GB | **Vaultwarden** :8000 (`vault.satanzote.me`) — gestor de contraseñas |
| 115 | debmediav2 | .164 | 10 / 12 GB / 60 GB | **stack de media** — ver detalle abajo; monta `/mnt/media` |
| 116 | ntfy | .179 | 1 / 512 MB / 2 GB | **ntfy** :80 — notificaciones push self-hosted |
| 400 | medinotes | .132 | 2 / 4 GB / 40 GB | Docker: `medinotes` (nginx :80/:443, backend :8000, postgres, redis) — SaaS de notas médicas |
| 901 | `ubuntu` | **.230** | **12 / 24 GB / 100 GB** | **GromacsMexicano** — ver detalle abajo. **usa GPU**. tag `lxgpu` |

#### CT 109 `claude-dev` (.64) — nodo de IA

| Servicio | Puerto | Qué hace |
|---|---|---|
| `omniroute.service` | **20128** (0.0.0.0) | **OmniRoute** — gateway LLM, gestión de tokens. Dashboard `http://192.168.0.64:20128` (admin / `11deabril5`). Backend `cc` = suscripción Claude Code OAuth. Internos :20131/:20132. |
| `smbd.service` | 139 / 445 | **Samba** — comparte `[JarvisVault]` = `/root/JarvisVault`. **Aquí vive físicamente el vault SatanZote AI**; la Mac lo monta por SMB. |
| `telegram-bridge.service` | 3001 | Puente **Telegram ↔ Claude Code** (`/project/telegram-bridge/bot.js`) |
| `cloudcli.service` | — | **claudecodeui** — front web para Claude Code (`/project`) |
| `cloudflared` | 20241 (local) | túnel Cloudflare para exponer el UI de Claude Code |
| `docker` + `containerd` | — | instalado, sin contenedores corriendo ahora |

#### CT 115 `debmediav2` (.164) — stack de media (Docker)

Plex `:32400`, Jellyseerr `:5055` (`pedirpeliculas.satanzote.me`), Sonarr `:8989` (`sonarr.home`), Radarr `:7878`, Prowlarr `:9696`, Bazarr `:6767`, Transmission `:9091` (`transmissions.home`), SABnzbd `:8080`, Tdarr `:8265-66`, Tautulli `:8181`, Navidrome `:4533`, Maintainerr `:6246`, Wizarr `:5690`, Flaresolverr `:8191`, Threadfin/xTeVe `:34400-01` (IPTV), Dispatcharr `:9191`, Kima `:3030`, Glances.

#### CT 901 `ubuntu` (.230) — GromacsMexicano

- `/home/alejandre/Programa_DM/` — código Fortran+CUDA de los científicos (**referencia congelada**)
- `/home/alejandre/GromacsMexicano/Programa_DM_cpp/` — reescritura a C++ (CMake), repo git
- `/home/alejandre/Prueba/` — caso de prueba (agua + NaCl); GROMACS 2025.2/2025.3 de referencia compilados en el home
- **Claude Code** (`/usr/bin/claude`) → enruta por OmniRoute (CT 109) → suscripción Claude Code
- **BASE** (`~/.local/bin/base`) — memoria/grafo del rewrite (reemplazó a Ruflo). Ver [[(C) 2026-09-07 BASE para memoria del rewrite C++.md]]
- `gpu-api.service` :5000 (`/usr/local/bin/gpu-api.py`) — API de estado de GPU
- `fail2ban`, `notify_telegram.sh` (script de alertas a Telegram)
- Usuario del trabajo: `alejandre`. GPU RTX 5070 Ti, CUDA 13.0.

## Uso REAL de recursos (medido 2026-09-07, sistema en reposo)

`pvesh get /cluster/resources`. Casi todo está **idle** — la asignación (`maxmem`) es muy generosa comparada con el uso real.

| ID | Guest | CPU | RAM usada / asignada | Disco usado / asignado |
|---|---|---|---|---|
| 100 | nginxproxymanager | ~0% | 0.1 / 2 GB | 2.3 / 7.8 GB |
| 101 | debian | ~0% | 0.1 / 0.5 GB | 1.7 / 1.9 GB (lleno) |
| 102 | uptimekuma | ~0% | 0.1 / 1 GB | 2.3 / 3.9 GB |
| 103 | openwebui | ~0% | 0.4 / 8 GB | **45.5 / 48.9 GB ⚠️ 93%** |
| 104 | adguard | ~0% | 0.1 / 0.5 GB | 2.4 / 4.9 GB |
| 105 | unbound | ~0% | 0.0 / 0.5 GB | 0.8 / 1.9 GB |
| 106 | haos-17.1 (VM) | ~1% | 2.3 / 4 GB | — |
| 107 | docker | ~0% | 0.1 / 2 GB | 1.4 / 15.6 GB |
| 108 | cloudflared | ~0% | 0.1 / 0.5 GB | 1.0 / 1.9 GB |
| 109 | claude-dev | ~0% | 1.2 / 10 GB | 24.6 / 58.9 GB |
| 111 | apps-prod | ~0% | 0.9 / 4 GB | 17.3 / 39.2 GB |
| 112 | app-dev | ~1% | 0.2 / 2 GB | 3.0 / 19.5 GB |
| 113 | rclone | ~0% | 0.0 / 2 GB | 1.2 / 1.9 GB (lleno) |
| 114 | vaultwarden | ~0% | 0.0 / 6 GB | 3.5 / 19.5 GB |
| 115 | debmediav2 | ~1% | 2.2 / 12 GB | **50.7 / 58.8 GB ⚠️ 86%** |
| 116 | ntfy | ~0% | 0.0 / 0.5 GB | 1.0 / 1.9 GB |
| 200 | debian-brain (VM) | ~0% | 1.2 / 4 GB | — |
| 400 | medinotes | ~1% | 0.1 / 4 GB | 7.1 / 39.1 GB |
| 901 | ubuntu | ~0% | 0.3 / 24 GB | 26.6 / 97.9 GB |

**RAM: uso real total ≈ 9.6 GB** · asignada 87.5 GB · host físico 31 GB. **GPU: 0 procesos activos** ahora mismo (Ollama carga bajo demanda; CT 109 y 901 tienen el passthrough pero no lo están usando).

### Lectura

- **El sobrecompromiso de RAM NO es un problema hoy** — corregí la nota anterior. Con todo idle se usan ~10 GB de 31. El swap (4.4 GB) viene de un pico pasado (build de GromacsMexicano, transcoding, o carga de modelo), no de presión sostenida. El riesgo real solo aparece si **coinciden** GromacsMexicano a full (puede pedir varios GB) + Plex transcodificando + un modelo grande en Ollama. Poco probable, pero por eso el `maxmem` de 24 GB en CT 901 conviene bajarlo a ~12 GB (nunca ha pasado de 0.3 GB idle; los picos de MD son de CPU/GPU, no de RAM masiva).
- **Discos que se van a llenar pronto** ⚠️: CT 103 openwebui (93%, los modelos de Ollama), CT 115 media (86%). CT 101 y CT 113 ya están al 100% de su disco raíz de 1.9 GB (funcionan pero sin margen).
- **`nvme-fast` (245 GB, 3% usado)** sigue casi vacío — es el lugar obvio para mover el disco de CT 103 (modelos) o dar scratch a CT 901.

## Exposición a internet

### Nginx Proxy Manager (CT 100) + Cloudflare Tunnel (CT 108)

| Dominio | Destino (inferido) |
|---|---|
| `vault.satanzote.me` | Vaultwarden (CT 114 :8000) |
| `plex.satanzote.me` | Plex (CT 115 :32400) |
| `pedirpeliculas.satanzote.me` | Jellyseerr (CT 115 :5055) |
| `soypirata.satanzote.me` | media (CT 115) |
| `elmundial.satanzote.me` | app Mundial prod (CT 111 :8000) |
| `elinternetqr.satanzote.me` | QR counter / mint-portal (CT 111) |
| `adguard.home` | AdGuard (CT 104) — solo LAN |
| `sonarr.home` | Sonarr (CT 115) — solo LAN |
| `transmissions.home` | Transmission (CT 115) — solo LAN |

Segundo túnel Cloudflare en CT 109 para el UI de Claude Code.

## Qué usa cada proyecto del vault

### SatanZote AI (este vault, antes "Jarvis") — es la raíz, no un proyecto
- **CT 109 claude-dev**: el vault vive en `/root/JarvisVault` (nombre de path sin cambiar), servido por Samba y montado en la Mac.
- **CT 109**: `telegram-bridge` para chatear con Claude desde Telegram.
- **CT 901**: `notify_telegram.sh` para alertas salientes.
- Plugin **Claudian** corre en la Mac (Obsidian).

### GromacsMexicano — `03 Projects/GromacsMexicano/`
- **CT 901 `ubuntu`** (todo el cómputo): código Fortran+CUDA, reescritura C++, RTX 5070 Ti, Claude Code, BASE.
- **CT 109**: OmniRoute como gateway de tokens para el Claude Code de CT 901.
- **CT 112**: `gpu-top` (:8095) y **CT 901** `gpu-api` (:5000) para monitorear la GPU.

### Claude Strava — `03 Projects/Claude Strava/`
- **No usa un contenedor propio.** La revisión semanal corre como **rutina en la nube de Claude** (domingos ~7pm CDMX), lee Strava por MCP y hace push al repo GitHub `Jaalejandre/claudestrava`. No toca el servidor.
- Datos (InBody, GPX, plan) viven en el vault (por tanto en CT 109 vía Samba).

### OmniRoute (infra transversal de IA)
- **CT 109 claude-dev**, `omniroute.service` :20128, systemd, siempre encendido.

## Otras apps / portafolio de builds (no son proyectos del vault)

| App | Dónde | Notas |
|---|---|---|
| Mundial / worldcup | CT 111 (prod) + CT 112 (dev) | `elmundial.satanzote.me` |
| medinotes | CT 400 | SaaS de notas médicas (nginx+FastAPI+postgres+redis) |
| enlinea-saas, satanzote-studio | CT 101 | |
| airbnb-dashboard | CT 112 (dev) | |
| mint-portal, qr-counter | CT 111 | `elinternetqr.satanzote.me` |
| Nextcloud, Guacamole | CT 111 | utilidades |

## Relación entre proyectos y anti-redundancia

### Mapa de dependencias

```
SatanZote AI (vault, CT 109 /root/JarvisVault + Samba)
  ├── es el store de contexto de TODOS los proyectos
  └── Claudian (Mac) ── SMB ──> CT 109

OmniRoute (CT 109 :20128)  ← gateway único de tokens LLM
  ├── Claude Code (CT 901) ──> OmniRoute ──> suscripción Claude
  └── [debería] OpenWebUI + Ollama ──> OmniRoute también

BASE (CT 901)  ← memoria/grafo, SOLO GromacsMexicano por ahora
Telegram: bridge (CT 109 :3001, entrada) + notify_telegram.sh (CT 901, salida)

GromacsMexicano ── CT 901 (Fortran/CUDA/C++, GPU) + OmniRoute + BASE + Telegram
Claude Strava ──── rutina en la nube de Claude (no usa el server) + repo GitHub claudestrava
```

### Redundancias detectadas (qué NO repetir)

| # | Redundancia | Qué hacer |
|---|---|---|
| 1 | **Dos Open WebUI**: CT 103 (nativo, con Ollama + GPU, el bueno) y CT 111 (`open-webui` en Docker, `OPENAI_API_BASE_URL` vacío, medio configurado) | Borrar el de CT 111. Dejar solo CT 103. |
| 2 | **Dos capas de acceso LLM**: Ollama (CT 103, local/GPU) y OmniRoute (CT 109, nube). No son lo mismo pero se solapan. | Poner **OpenWebUI → OmniRoute → {Ollama, Claude}**. Un solo punto de entrada y de conteo de tokens. |
| 3 | **CT 107 existe solo para Portainer** (2 GB / 16 GB para 1 contenedor) | Mover Portainer a un host Docker que ya existe (CT 111 o 115) y apagar CT 107. |
| 4 | **CT 101 `debian`** (512 MB, 2 sitios en Docker) duplica el rol de CT 111 apps-prod | Migrar `enlinea-saas` y `satanzote-studio` a CT 111 y apagar CT 101. |
| 5 | **CT 109 tiene passthrough de GPU pero no la usa** (OmniRoute llama a la nube) | Quitar el passthrough de CT 109 → menos riesgo de pelea de VRAM con GromacsMexicano. Confirmar antes que nada en 109 dependa de CUDA. |
| 6 | **Monitoreo de GPU disperso**: `gpu-api` (CT 901 :5000), `gpu-top` (CT 112 :8095 — ¡y CT 112 ni tiene GPU!), Glances (CT 115) | Quedarse con `gpu-api` en CT 901. Quitar `gpu-top` de CT 112. |
| 7 | **BASE solo en GromacsMexicano** | Cuando arranque Claude Strava, **reusar el mismo BASE** (otro proyecto en el mismo grafo, o BASE en CT 109), no montar otra herramienta de memoria. |

### Regla para no volver a ser redundante

- **Nuevo proyecto de IA (ej. Claude Strava)** → NO crear CT nuevo. Va en **CT 109 claude-dev** (ya tiene Claude Code, Telegram bridge, es el nodo de IA) o como servicio en CT 111. Reusa: OmniRoute (tokens), BASE (memoria), Telegram (bridge + notify), el vault (contexto).
- **Necesitas LLM** → pasa por **OmniRoute**. No agregar otro gateway ni llamar APIs directo.
- **Necesitas notificar** → Telegram (bridge/`notify_telegram.sh`). ntfy (CT 116) ya existe y se usa para alertas de sistema; no mezclar.
- **Necesitas memoria de agente** → BASE. Ruflo quedó retirado.

## Otras notas / pendientes

- ⚠️ **VM 200 `debian-brain`**: sin identificar (creada 2025-11, 1.2 GB RAM en uso, sin guest-agent, sin llave SSH desde el host). Entrar y decidir si sigue.
- **Discos casi llenos**: CT 103 (93%), CT 115 (86%), CT 101 y CT 113 al 100% de sus 1.9 GB. Mover CT 103 a `nvme-fast`.
- **CT 901 `maxmem` 24 GB → bajar a ~12 GB** (uso real 0.3 GB idle; los picos de MD son CPU/GPU).
- **GPU RTX 5070 Ti** compartida a 3 CTs sin particionar. Idle ahora. GromacsMexicano ya verifica `nvidia-smi` libre antes de medir; si se quita el passthrough de CT 109 (redundancia #5) solo compiten 103 y 901.
- Sin HA ni replicación: si muere `local-lvm` se pierden todos los guests entre backups. El `vzdump` 21:00 → `backups` (3.8 TB) + `rclone` offsite (CT 113) es la única red.

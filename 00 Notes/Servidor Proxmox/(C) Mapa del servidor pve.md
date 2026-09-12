---
tipo: referencia-infra
actualizado: 2026-09-11
fuente: barrido en vivo por SSH (ssh root@192.168.0.52)
---

# Mapa del servidor `pve`

Inventario completo del Proxmox VE personal y de qué usa cada proyecto. Complemento de [[proxmox.md]] y [[UPS y energía]]. **Topología visual (Graph View + Mermaid): [[Arquitectura]].** Chequeos automáticos diarios en [[Chequeos Diarios]]. **Se desactualiza** — verificar en vivo antes de cambios (último barrido manual: ver `actualizado` en el frontmatter).

## Host

| Dato       | Valor                                                                                             |
| ---------- | ------------------------------------------------------------------------------------------------- |
| Nodo       | `pve` — Proxmox VE **9.1.1**, kernel 6.17.2-1-pve, standalone (sin cluster, sin HA)               |
| CPU        | Intel **i5-14600K** — 14 núcleos / 20 hilos                                                       |
| RAM        | **31 GB** (~17 GB en uso) + **8 GB swap (0 B en uso)** — `vm.swappiness=10` y límites right-sizeados 2026-09-08 (ver [[#Optimización de memoria 2026-09-08]]) |
| Disco raíz | `/dev/mapper/pve-root` 94 GB, 20% usado                                                           |
| GPU        | **NVIDIA RTX 5070 Ti 16 GB** (driver 580.105.08) — compartida por passthrough a CT 103 y 901 |
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
| 200 | ~~`debian-brain`~~ **ELIMINADA 2026-09-11** | — | — | Cerebro de automatización precursora (Debian 13, nov-2025): n8n, telegram bots PVE, airbnb-dashboard, Strava/triathlon, backups SSH. Inactiva desde ~abr-2026; tubería de backup al CT 901 muerta. **Destruida con `qm destroy 200 --purge`** — disco liberado. Backup final: `backup/vzdump-qemu-200-2026_09_10-21_16_59.vma.zst` (recuperable con `qmrestore`). |

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
| 109 | **claude-dev** | **.64** | 4 / 6 GB / 60 GB | **el nodo de IA** — ver detalle abajo. ~~usa GPU~~ (passthrough quitado 2026-09-11, pendiente restart) |
| 111 | apps-prod | .20 | 4 / 4 GB / 40 GB | Docker: `mundial-app`+`mundial-db` (Mundial prod :8000), `nextcloud` :8088 (+redis+mariadb), `guacamole` :8090 (+guacd), `mint-portal` :5010, `open-webui` :3000, `portainer-agent`. Nativo: gunicorn :8085, `qr-counter` |
| 112 | app-dev | .21 | 2 / 2 GB / 20 GB | Docker: `mundial-app` dev :8000 (+db), `airbnb-dashboard` :8090, `portainer-agent`. Nativo: gunicorn :8086, `gpu-top` (http :8095/:8091), `qr-counter-dev` |
| 113 | rclone | .32 | 1 / 2 GB / 2 GB | **rclone-web** :3000 — sync a nube; monta `/mnt/backups` |
| 114 | vaultwarden | .30 | 4 / 2 GB / 20 GB | **Vaultwarden** :8000 (`vault.satanzote.me`) — gestor de contraseñas |
| 115 | debmediav2 | .164 | 10 / 6 GB / 60 GB | **stack de media** — ver detalle abajo; monta `/mnt/media` |
| 116 | ntfy | .179 | 1 / 512 MB / 2 GB | **ntfy** :80 — notificaciones push self-hosted |
| 117 | `difybot` | .14 (dhcp) | 2 / 4 GB / 4 GB | ⚠️ **NUEVO 2026-09-11 12:39, sin confirmar** — Ubuntu 24.04 + docker vacío, sin `onboot`, nada corriendo. ¿Creado por el usuario o un agente? Ver [[(C) Mapa de red LAN]]. |
| 400 | medinotes | .132 | 2 / 4 GB / 40 GB | Docker: `medinotes` (nginx :80/:443, backend :8000, postgres, redis) — SaaS de notas médicas |
| 901 | `ubuntu` (Ubuntu 24.04.4 LTS) | **.230** | **12 / 12 GB / 100 GB** | **GromacsMexicano** — ver detalle abajo. **usa GPU**. tag `lxgpu` |

#### CT 109 `claude-dev` (.64) — nodo de IA

| Servicio                        | Puerto                                                                          | Qué hace                                                                                                                                                                                                       |
| ------------------------------- | ------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `omniroute.service`             | **20128** (0.0.0.0)                                                             | **OmniRoute** — gateway LLM, gestión de tokens. Dashboard `http://192.168.0.64:20128` (admin / `11deabril5`). Backend `cc` = suscripción Claude Code OAuth. Todos sus componentes viven en `/root/.omniroute`. |
| └─ servicios internos OmniRoute | 20131 / 20132 / 3456 (`dario`) / 8080 (`bifrost` v1.6.3) / 8317 (`cliproxyapi`) | componentes del gateway: API interna, proxy node (`dario`), proxy HTTP (`bifrost`), proxy CLI (`cliproxyapi`). Descubiertos en barrido 2026-09-08, ver [[(C) Tecnologías y proyectos por contenedor]].         |
| `smbd.service`                  | 139 / 445                                                                       | **Samba** — comparte `[JarvisVault]` = `/root/JarvisVault`. **Aquí vive físicamente el vault SatanZote AI**; la Mac lo monta por SMB.                                                                          |
| `telegram-bridge.service`       | 3001                                                                            | Puente **Telegram ↔ Claude Code** (`/project/telegram-bridge/bot.js`)                                                                                                                                          |
| `cloudcli.service`              | —                                                                               | **claudecodeui** — front web para Claude Code (`/project`)                                                                                                                                                     |
| `cloudflared`                   | 20241 (local)                                                                   | túnel Cloudflare para exponer el UI de Claude Code                                                                                                                                                             |
| `docker` + `containerd`         | —                                                                               | instalado, sin contenedores corriendo ahora                                                                                                                                                                    |

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
| 103 | openwebui | ~0% | 3.2 / 8 GB | **45.5 / 48.9 GB ⚠️ 93%** |
| 104 | adguard | ~0% | 0.1 / 0.5 GB | 2.4 / 4.9 GB |
| 105 | unbound | ~0% | 0.0 / 0.5 GB | 0.8 / 1.9 GB |
| 106 | haos-17.1 (VM) | ~1% | 2.3 / 4 GB | — |
| 107 | docker | ~0% | 0.1 / 2 GB | 1.4 / 15.6 GB |
| 108 | cloudflared | ~0% | 0.1 / 0.5 GB | 1.0 / 1.9 GB |
| 109 | claude-dev | ~0% | 2.5 / 6 GB | 24.6 / 58.9 GB |
| 111 | apps-prod | ~0% | 0.9 / 4 GB | 17.3 / 39.2 GB |
| 112 | app-dev | ~1% | 0.2 / 2 GB | 3.0 / 19.5 GB |
| 113 | rclone | ~0% | 0.0 / 2 GB | 1.2 / 1.9 GB (lleno) |
| 114 | vaultwarden | ~0% | 0.1 / 2 GB | 3.5 / 19.5 GB |
| 115 | debmediav2 | ~0% | 4.7 / 6 GB | **50.7 / 58.8 GB ⚠️ 86%** |
| 116 | ntfy | ~0% | 0.0 / 0.5 GB | 1.0 / 1.9 GB |
| 400 | medinotes | ~1% | 0.1 / 4 GB | 7.1 / 39.1 GB |
| 901 | ubuntu | ~0% | 0.5 / 12 GB | 26.6 / 97.9 GB |

**RAM: uso real total ≈ 12 GB** · asignada ~58 GB · host físico 31 GB. **GPU: 0 procesos activos** ahora mismo (Ollama carga bajo demanda; CT 103 y 901 tienen el passthrough).

### Lectura

- **El sobrecompromiso de RAM estaba controlándose con swap proactivo** — el 2026-09-08 se resolvió: `vm.swappiness=60 → 10`, swap drenado a 0, y 5 CTs right-sizeados (~87 GB → ~58 GB asignados). CT 103 se revertió a 8 GB el mismo día (carga de `qwen2.5-coder:14b`). Ver [[#Optimización de memoria 2026-09-08]]. Vigilar CT 115 (4.7/6 GB): si pega su límite, subir o mover el servicio.
- **Discos que se van a llenar pronto** ⚠️: CT 101 debian (94%, 1.9 GB de disco), CT 115 media (92%). CT 103 ya bajó a 63% tras mover modelos a `nvme-fast` el 2026-09-08 (dejó de ser problema). CT 113 al 68% — ya no está al 100% (se limpió).
- **`nvme-fast` (245 GB, 13% usado)** sigue casi vacío — es el lugar obvio para mover el disco de CT 103 (modelos) o dar scratch a CT 901.

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
| 5 | ✅ **Resuelto 2026-09-11** — passthrough de GPU quitado de CT 109 (staged en config; **reinicio automático programado para 2026-09-12 03:00 CST** vía `ct109-reboot-gpu.timer`). Se confirmó **cero dependencias CUDA** en 109: chequeo diario y benchmark consultan GPU vía SSH a CT 901. Config respaldada en `/root/lxc-109.conf.bak-20260911` en el host. Queda pendiente decidir si también se quita `lxc.apparmor.profile: unconfined`. |
| 6 | **Monitoreo de GPU disperso**: `gpu-api` (CT 901 :5000), `gpu-top` (CT 112 :8095 — ¡y CT 112 ni tiene GPU!), Glances (CT 115) | Quedarse con `gpu-api` en CT 901. Quitar `gpu-top` de CT 112. |
| 7 | **BASE solo en GromacsMexicano** | Cuando arranque Claude Strava, **reusar el mismo BASE** (otro proyecto en el mismo grafo, o BASE en CT 109), no montar otra herramienta de memoria. |

### Regla para no volver a ser redundante

- **Nuevo proyecto de IA (ej. Claude Strava)** → NO crear CT nuevo. Va en **CT 109 claude-dev** (ya tiene Claude Code, Telegram bridge, es el nodo de IA) o como servicio en CT 111. Reusa: OmniRoute (tokens), BASE (memoria), Telegram (bridge + notify), el vault (contexto).
- **Necesitas LLM** → pasa por **OmniRoute**. No agregar otro gateway ni llamar APIs directo.
- **Necesitas notificar** → Telegram (bridge/`notify_telegram.sh`). ntfy (CT 116) ya existe y se usa para alertas de sistema; no mezclar.
- **Necesitas memoria de agente** → BASE. Ruflo quedó retirado.

## Otras notas / pendientes

- ✅ **VM 200 `debian-brain`** — **IDENTIFICADA y ELIMINADA 2026-09-11**: precursora de automatización, inactiva desde ~abr-26, duplicaba funciones ya migradas (n8n→CT 110, airbnb→CT 112, strava→nube). `qm destroy 200 --purge` con backup final en `backups` (09-10). Disk LVM liberado.
- **Discos casi llenos**: CT 103 (93%), CT 115 (86%), CT 101 y CT 113 al 100% de sus 1.9 GB. Mover CT 103 a `nvme-fast`.
- **CT 901 `maxmem` 24 GB → bajar a ~12 GB** (uso real 0.3 GB idle; los picos de MD son CPU/GPU).
- **GPU RTX 5070 Ti** compartida a **2 CTs (103 y 901)** desde 2026-09-11 (se quitó el passthrough de CT 109). GromacsMexicano ya verifica `nvidia-smi` libre antes de medir.
- Sin HA ni replicación: si muere `local-lvm` se pierden todos los guests entre backups. El `vzdump` 21:00 → `backups` (3.8 TB) + `rclone` offsite (CT 113) es la única red.

## Optimización de memoria 2026-09-08

Aplicado en vivo por SSH (sin downtime, sin reinicios) para resolver swap alto (4.4 / 8 GB) y sobre-asignación de RAM (~87 GB asignados en 31 GB físicos).

| Cambio | Valor |
|---|---|
| `vm.swappiness` | 60 (default) → **10**, persistido en `/etc/sysctl.d/99-swappiness.conf` |
| Swap drenado | `swapoff -a && swapon -a` → **0 B** (estaba 4.4 GB viciado, sin thrashing activo) |
| CT 103 openwebui | 8 GB → 4 GB → **8 GB** (revertido el mismo día: cargar `qwen2.5-coder:14b` de 8.4 GiB necesita RAM; con 4 GB quedaba en 805 MB libres y dependía 100% de VRAM) |
| CT 109 claude-dev | 10 GB → **6 GB** (usual ~2.5 GB) |
| CT 114 vaultwarden | 6 GB → **2 GB** (usa ~0.1 GB) |
| CT 115 debmediav2 | 12 GB → **6 GB** (usa ~4.7 GB — monitorear, va justo) |
| CT 901 ubuntu | 24 GB → **12 GB** (usa ~0.5 GB idle) |

Asignación total: ~87 GB → ~58 GB (CT 103 revertido a 8 GB el mismo día por la carga de `qwen2.5-coder:14b`). Aplicado con `sysctl -w` y `pct set` (cgroup en vivo). Con swappiness 10 el kernel ya no envía páginas a swap proactivamente si hay RAM disponible; si un CT pega su límite se niega memoria dentro del CT (potencial OOM interno) en vez de llenar swap global.

**Seguimiento:** vigilar CT 115 (usa 4.7/6 GB tras el right-size). Si pega el tope, subir límite o mover el servicio a otro CT. CT 103 quedó en 8 GB (necesario para cargar `qwen2.5-coder:14b`).

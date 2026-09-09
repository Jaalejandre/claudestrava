---
tipo: referencia-infra
actualizado: 2026-09-08
fuente: barrido en vivo por SSH (ssh root@192.168.0.52) — systemctl, docker ps, ss, dpkg en cada CT
complementa: "(C) Mapa del servidor pve"
---

# Tecnologías y proyectos por contenedor

Inventario detallado de qué tecnología hay instalada y qué proyectos vive en cada CT/VM del servidor `pve`. Complementa el [[(C) Mapa del servidor pve]] (recursos, IPs, exposición a internet). **Se desactualiza** — verificar en vivo antes de cambios (barrido: `actualizado` en el frontmatter).

## Resumen por contenedor

| CT | Nombre | SO | Tecnologías instaladas | Proyectos / apps que corren ahí | Puertos clave |
|---|---|---|---|---|---|
| 100 | nginxproxymanager | Debian 13 | Nginx Proxy Manager (npm) + openresty, nodejs, certbot | reverse proxy de `*.satanzote.me` | 80, 81, 443, 3000 |
| 101 | debian | Debian 13 | Docker CE + compose, nginx | `enlinea-saas` (Docker), `satanzote-studio` (nginx:alpine) | 8085, 8091 |
| 102 | uptimekuma | Debian 13 | Uptime Kuma (node) | monitoreo de servicios | 3001 |
| 103 | openwebui | Debian 13 | Ollama + Open WebUI, CUDA toolkit, ffmpeg | LLM local con GPU: `qwen2.5-coder:14b`, `gpt-oss`, `gemma3` | 8080, 11434 |
| 104 | adguard | Debian 13 | AdGuard Home | DNS + panel LAN | 53, 80 |
| 105 | unbound | Debian 13 | Unbound | resolver DNS recursivo (upstream de AdGuard) | 5335 |
| 107 | docker | Debian 13 | Portainer CE, Docker | gestión de Docker por web | 9443, 8000 |
| 108 | cloudflared | Debian 13 | Cloudflare Tunnel (por token) | expone `*.satanzote.me` a internet | 20241 |
| 109 | **claude-dev** | Debian 13 | OmniRoute + servicios internos, Samba, Docker, CUDA 13, node, python 3.14, JDK 25, Claude Code | **vault SatanZote AI** (`/root/JarvisVault`), OmniRoute, telegram-bridge, claudecodeui, `airbnb-admin` (proto) | 445 (SMB), 3001, 8877, 20128 |
| 110 | n8n | Debian 13 | n8n (node) | automatización de workflows | 5678, 5679 |
| 111 | apps-prod | Debian 13 | Docker CE + compose, nginx, gunicorn, python | Mundial prod, Nextcloud (+redis+mariadb), Guacamole, mint-portal, qr-counter, open-webui (redundante ⚠️) | 3000, 5010, 8000, 8085, 8088, 8090 |
| 112 | app-dev | Debian 13 | Docker CE + compose, gunicorn, python | Mundial dev, airbnb-dashboard, qr-counter-dev, gpu-top | 8000, 8086, 8090, 8095 |
| 113 | rclone | Debian 13 | rclone-web | sync a nube; monta `/mnt/backups` | 3000 |
| 114 | vaultwarden | Debian 13 | Vaultwarden | gestor de contraseñas (`vault.satanzote.me`) | 8000 |
| 115 | debmediav2 | Debian 13 | Docker CE + compose, ~20 servicios | stack de media completo (Plex, *arr, descargas, IPTV…) | 32400, 5055, 8989, 7878, 9696, 6767, 9091, 8080, 8265-66, 8181, 4533, 6246, 5690, 8191, 34400-01, 9191, 3030 |
| 116 | ntfy | Debian 13 | ntfy | alertas de sistema (`pve-alerts`) | 80 |
| 400 | medinotes | Debian 13 | Docker CE + compose, nginx, FastAPI, postgres:16, redis:7 | SaaS de notas médicas (4 contenedores) | 80, 443, 8000 |
| 901 | **ubuntu** | Ubuntu 24.04.4 LTS | GROMACS 2025.2/2025.3, CUDA, NVIDIA driver 580, gcc/g++, Claude Code, BASE | **GromacsMexicano**: Fortran+CUDA referencia + reescritura C++ | — (SSH) |

## Detalle por contenedor

### CT 109 `claude-dev` (.64) — el nodo de IA (el más cargado)

Servicios systemd corriendo: `omniroute`, `smbd`, `telegram-bridge`, `cloudcli`, `proto-airbnb-admin`, `docker`+`containerd` (sin contenedores activos ahora).

| Puertos | Proceso | Qué es |
|---|---|---|
| 20128 | OmniRoute | gateway LLM principal (token manager) |
| 20130-20132 | OmniRoute | servicios internos del gateway |
| 3456 | `dario` (node) | proxy interno de **OmniRoute** (nuevo, no estaba documentado) |
| 8080 | `bifrost` v1.6.3 | componente interno de **OmniRoute** (nuevo, no estaba documentado) |
| 8317 | `cliproxyapi` | proxy CLI de **OmniRoute** (nuevo, no estaba documentado) |
| 3001 | telegram-bridge | puente Telegram ↔ Claude Code |
| 8877 | `uvicorn` | **airbnb-admin** — dashboard prototipo (`proto-airbnb-admin.service`) |
| 139/445 | Samba | comparte `[JarvisVault]` = `/root/JarvisVault` |
| 53 | systemd-resolve | DNS local del CT (irrelevante) |

Proyectos:
- `/root/JarvisVault` — **el vault SatanZote AI** (aquí vive físicamente, montado por SMB en la Mac)
- `/root/.omniroute` — gateway OmniRoute + sus servicios (`dario`, `bifrost`, `cliproxy`, configs)
- `/project/` — `telegram-bridge`, `prototipos/` (harness.py), `ruflo` (retirado)
- `/root/go` — workspace de Go

Tecnologías destacadas: CUDA toolkit 13 completo, Docker CE, nodejs, python 3.14, OpenJDK 25, postgresql-client, `/usr/bin/claude` (Claude Code enruta por OmniRoute).

### Stack de media — CT 115 `debmediav2` (.164)

Todos en Docker (`/opt/media-stack`), ~20 contenedores: Plex, Jellyseerr, Sonarr, Radarr, Prowlarr, Bazarr, Transmission, SABnzbd, Tdarr, Tautulli, Navidrome, Maintainerr, Wizarr, Flaresolverr, Threadfin/xTeVe, Dispatcharr, Kima, Glances.

### GromacsMexicano — CT 901 `ubuntu` (.230)

- `/home/alejandre/Programa_DM/` — código Fortran+CUDA de los científicos (**referencia, congelada**)
- `/home/alejandre/GromacsMexicano/` — reescritura a C++ (CMake, repo git)
- `/home/alejandre/gromacs-2025.2/` y `gromacs-2025.3/` — GROMACS de referencia compilados
- `/home/alejandre/Prueba/` — caso de prueba (agua + NaCl); también `DM_NPT_gmx_v2`, `gmx-test`, `Sistemas`
- `claude` en `/usr/bin`, **BASE** en `~/.local/bin/base` (memoria del rewrite)
- GPU: RTX 5070 Ti 16 GB vía passthrough, driver 580.105.08, `cuda-test` en home

## VMs

| VM | Nombre | Estado | Qué es |
|---|---|---|---|
| 106 | haos-17.1 | running | **Home Assistant OS** (4 GB / 32 GB) |
| 200 | debian-brain | running | **sin identificar** ⚠️ — creada 2025-11, sin guest-agent, sin llave SSH desde el host. Pendiente entrar y decidir. |

## Hallazgos del barrido (2026-09-08)

- **CT 109**: OmniRoute tiene 3 servicios internos que no estaban documentados (`dario` :3456, `bifrost` :8080, `cliproxyapi` :8317) — todo bajo `/root/.omniroute`. No son proyectos nuevos, son componentes del gateway.
- **CT 100** escucha también en :3000 (proceso node) — es el UI de Nginx Proxy Manager, no un servicio extra.
- **CT 110 n8n** también escucha en :5679 (probablemente webhook/proxy interno de n8n).
- **CT 111** tiene `open-webui` en Docker además del nativo de CT 103 — redundancia ya detectada en el mapa del servidor (ver [[(C) Mapa del servidor pve#Redundancias detectadas]]).
- **CT 103** tiene `libmariadb` y `ffmpeg` instalados — restos de setup, no están en uso por Ollama.
- Todos los CTs corren `postfix` (por defecto de la plantilla Debian de PVE) — sin remitente configurado; es ruido de la plantilla, no un servicio intencional.
- ○ `postfix` → ignorar en inventarios futuros; es parte de la plantilla.

## Cómo re-barridar rápido

```bash
# pasada 1 — tecnologías (systemd + docker + puertos)
for id in <CTs>; do pct exec $id -- bash -c 'echo "== $id"; systemctl list-units --type=service --state=running --no-legend | awk "{print \$1}"; command -v docker >/dev/null && docker ps --format "{{.Names}}"; ss -tln | awk "NR>1{print \$4}" | sed "s/.*://" | sort -un'; done
```
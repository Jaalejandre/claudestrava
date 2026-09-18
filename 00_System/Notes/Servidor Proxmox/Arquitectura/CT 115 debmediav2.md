---
contenedor: 115
nombre: debmediav2
ip: 192.168.0.164
so: Debian 13 (trixie)
servicios: Docker CE + compose (~20 contenedores)
puertos: 32400, 5055, 8989, 7878, 9696, 6767, 9091, 8080, 8265-66, 8181, 4533, 6246, 5690, 8191, 34400-01, 9191, 3030
proyectos: stack de media completo
actualizado: 2026-09-08
---

# CT 115 — debmediav2 (.164) — stack de media

**Stack de media completo** en Docker (`/opt/media-stack`).

## Qué corre (Docker, ~20 contenedores)
| Categoría | Contenedores |
|---|---|
| **Servidor** | Plex :32400 (`plex.satanzote.me`), Jellyseerr :5055 (`pedirpeliculas.satanzote.me`) |
| **Gestión de descargas** | Sonarr :8989, Radarr :7878, Prowlarr :9696, Bazarr :6767, Flaresolverr :8191 |
| **Descargas** | Transmission :9091, SABnzbd :8080 |
| **Reproductor** | Navidrome :4533 (música), Threadfin/xTeVe :34400-01 (IPTV) |
| **Transcodificación** | Tdarr :8265-66 |
| **Estadísticas** | Tautulli :8181 (Plex), Glances |
| **Otros** | Maintainerr :6246, Wizarr :5690, Dispatcharr :9191, Kima :3030 |

## Conexiones
- **Exposición**: [[CT 100 nginxproxymanager]] (`plex`, `pedirpeliculas`, `soypirata`)
- **Dominios LAN**: `sonarr.home`, `transmissions.home`

## Notas
- ⚠️ Disco 86% y creciendo (media) — candidato a `nvme-fast` o limpieza.
- Vigilar RAM (4.7/6 GB): si pega su límite, subir o mover.
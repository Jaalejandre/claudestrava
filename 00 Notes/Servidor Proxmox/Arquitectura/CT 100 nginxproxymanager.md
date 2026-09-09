---
contenedor: 100
nombre: nginxproxymanager
ip: 192.168.0.109
so: Debian 13 (trixie)
servicios: NPM + openresty, certbot
puertos: 80, 81, 443, 3000
proyectos: reverse proxy *.satanzote.me
actualizado: 2026-09-08
---

# CT 100 — nginxproxymanager

**Reverse proxy** de todos los dominios → servicios internos.

## Qué corre
- **Nginx Proxy Manager** — admin en :81, proxy :80/:443
- Proceso node en :3000 (UI de NPM, no es servicio extra)
- certbot para TLS

## Puertos
| Puerto | Uso |
|---|---|
| 80 / 443 | proxy HTTP/HTTPS de `*.satanzote.me` |
| 81 | panel de admin de NPM |
| 3000 | UI/node interno de NPM |

## Conexiones
- Recibe del túnel [[CT 108 cloudflared]]
- Enruta a: [[CT 114 vaultwarden]] (`vault.satanzote.me`), [[CT 111 apps-prod]] (`elmundial.satanzote.me`), [[CT 115 debmediav2]] (`plex`, `pedirpeliculas`, `soypirata`), [[CT 400 medinotes]], [[CT 109 claude-dev]]
- Dominios completos: ver [[(C) Mapa del servidor pve]]

## Notas
- Directorios: `/opt/nginxproxymanager`, `/opt/certbot`
- Detalle tecnológico: [[(C) Tecnologías y proyectos por contenedor]]
---
contenedor: 108
nombre: cloudflared
ip: 192.168.0.12
so: Debian 13 (trixie)
servicios: Cloudflare Tunnel
puertos: 20241
proyectos: exposición a internet
actualizado: 2026-09-08
---

# CT 108 — cloudflared

**Cloudflare Tunnel** — expone `*.satanzote.me` a internet.

## Qué corre
| Servicio | Puerto |
|---|---|
| **cloudflared** (por token) | :20241 |

## Conexiones
- Recibe tráfico de Cloudflare → lo pasa a [[CT 100 nginxproxymanager]] :80/:443
- Ruta: `Internet → Cloudflare → CT 108 → CT 100 → servicio destino`

## Notas
- Config por token (nube, no archivo local)
- Existe un segundo túnel en [[CT 109 claude-dev]] para el UI de Claude Code
---
contenedor: 111
nombre: apps-prod
ip: 192.168.0.20
so: Debian 13 (trixie)
servicios: Docker CE + compose, nginx, gunicorn, python
puertos: 3000, 5010, 8000, 8085, 8088, 8090
proyectos: mundial (prod), nextcloud, guacamole, mint-portal, qr-counter, open-webui
actualizado: 2026-09-08
---

# CT 111 — apps-prod (.20) — producción

**Apps en producción.** El par productivo de [[CT 112 app-dev]].

## Qué corre (Docker)
| Contenedor | Imagen | Puerto |
|---|---|---|
| `mundial-app` + `mundial-db` | worldcup-prod + postgres:16 | :8000 |
| `nextcloud` + `nextcloud-redis` + `nextcloud-db` | nextcloud + redis:7 + mariadb:10.11 | :8088 |
| `guacamole` + `guacd` | guacamole | :8090 |
| `mint-portal` | mint-portal | :5010 |
| `open-webui` | ghcr.io/open-webui | :3000 ⚠️ |
| `portainer-agent` | portainer/agent | :9001 |

## Qué corre (nativo)
- `qr-counter` (systemd) + gunicorn :8085
- nginx, python

## Proyectos / rutas
- `/opt/worldcup-prod/` — **mundial** (`elmundial.satanzote.me`)
- `/opt/apps/nextcloud`, `/opt/guacamole`, `/opt/mint-portal/`, `/opt/qr-counter/`, `/opt/apps-prod`

## Conexiones
- **Exposición**: [[CT 100 nginxproxymanager]] (`elmundial.satanzote.me`, `elinternetqr.satanzote.me`)
- **Par dev**: [[CT 112 app-dev]]
- **Gestión**: agente de [[CT 107 docker]]
- **Backups**: [[CT 113 rclone]]

## Notas
- ⚠️ Redundancia #1 del mapa: el `open-webui` Docker de aquí duplica a [[CT 103 openwebui]] — borrarlo.
- Vigilar RAM (4.7/6 GB en el último chequeo).
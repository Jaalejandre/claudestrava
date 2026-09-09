---
contenedor: 112
nombre: app-dev
ip: 192.168.0.21
so: Debian 13 (trixie)
servicios: Docker CE + compose, gunicorn, python
puertos: 8000, 8086, 8090, 8095
proyectos: mundial (dev), airbnb-dashboard, qr-counter-dev, gpu-top
actualizado: 2026-09-08
---

# CT 112 — app-dev (.21) — desarrollo/test

**Apps en desarrollo/pruebas.** El par de desarrollo de [[CT 111 apps-prod]].

## Qué corre (Docker)
| Contenedor | Imagen | Puerto |
|---|---|---|
| `mundial-app` + `mundial-db` | worldcup-dev + postgres:16 | :8000 |
| `airbnb-dashboard` | airbnb-dashboard | :8090 |
| `portainer-agent` | portainer/agent | :9001 |

## Qué corre (nativo)
- `qr-counter-dev` (systemd)
- `gpu-top` (systemd) :8095 — monitoreo GPU
- gunicorn :8086

## Proyectos / rutas
- `/opt/worldcup-dev/` — mundial dev
- `/opt/airbnb-dashboard/` — dashboard limpieza/inventario (hermano del `airbnb-admin` proto en CT 109)
- `/opt/qr-counter-dev/`, `/opt/gpu-top/`, `/opt/backups`

## Conexiones
- **Par prod**: [[CT 111 apps-prod]] (mundial y qr-counter tienen ambas versiones)
- **Gestión**: agente de [[CT 107 docker]]
- **Origen del código**: desarrollos de [[CT 109 claude-dev]]

## Notas
- ⚠️ `gpu-top` monitorea la GPU pero **este CT no tiene GPU** — redundancia #6, quedarse con `gpu-api` de [[CT 901 ubuntu]] y quitar este.
- Es el entorno natural de **test** para el flujo dev → test → prod.
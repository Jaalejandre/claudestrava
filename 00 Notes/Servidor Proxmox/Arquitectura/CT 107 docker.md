---
contenedor: 107
nombre: docker
ip: 192.168.0.61
so: Debian 13 (trixie)
servicios: Portainer CE
puertos: 9443, 8000
proyectos: gestión Docker
actualizado: 2026-09-08
---

# CT 107 — docker

**Portainer CE** — gestión web del ecosistema Docker.

## Qué corre
| Servicio | Puerto | Nota |
|---|---|---|
| **Portainer CE** | :9443 | panel web |
| edge agent | :8000 | conexión de agentes remotos |

## Conexiones
- Agentes `portainer-agent` instalados en [[CT 111 apps-prod]] y [[CT 112 app-dev]] (puerto :9001) — gestión desde aquí

## Notas
- Directorios: `/opt/containers`, `/opt/containerd`
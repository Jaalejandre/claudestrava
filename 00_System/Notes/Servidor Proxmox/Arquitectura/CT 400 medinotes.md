---
contenedor: 400
nombre: medinotes
ip: 192.168.0.132
so: Debian 13 (trixie)
servicios: Docker CE + compose
puertos: 80, 443, 8000
proyectos: medinotes (SaaS notas médicas)
actualizado: 2026-09-08
---

# CT 400 — medinotes (.132)

**SaaS de notas médicas** — stack completo en Docker.

## Qué corre (Docker)
| Contenedor | Imagen | Puerto |
|---|---|---|
| `medinotes_nginx` | nginx:alpine | :80/:443 |
| `medinotes_backend` | medinotes-backend | :8000 |
| `medinotes_postgres` | postgres:16-alpine | :5432 (interno) |
| `medinotes_redis` | redis:7-alpine | interno |

## Qué hace
- Backend: FastAPI
- BD: postgres:16, caché: redis:7
- Nginx como proxy de entrada

## Proyectos / rutas
- `/opt/medinotes/` (compose + código)

## Conexiones
- **Exposición**: [[CT 100 nginxproxymanager]]
- Sin conexión documentada con otros CTs (servicio independiente)

## Notas
- 7.1 / 39.1 GB de disco usado en el último chequeo.
---
contenedor: 101
nombre: debian
ip: 192.168.0.203
so: Debian 13 (trixie)
servicios: Docker CE + compose
puertos: 8085, 8091
proyectos: enlinea-saas, satanzote-studio
actualizado: 2026-09-08
---

# CT 101 — debian

**Docker apps legacy** — duplica en parte el rol de [[CT 111 apps-prod]].

## Qué corre (Docker)
| Contenedor | Imagen | Puerto |
|---|---|---|
| `enlinea-saas` | enlinea-saas | :8091 |
| `satanzote-studio` | nginx:alpine | :8085 |

## Conexiones
- Proyectos en `/opt/enlinea-saas/app`, `/opt/satanzote-studio`
- ⚠️ Redundancia detectada: su rol lo cubre mejor [[CT 111 apps-prod]] — candidato a migrar y apagar (ver [[(C) Mapa del servidor pve]])

## Notas
- Con 512 MB / 2 GB de disco, al 100% — sin margen.
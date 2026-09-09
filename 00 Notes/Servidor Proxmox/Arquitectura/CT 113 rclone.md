---
contenedor: 113
nombre: rclone
ip: 192.168.0.32
so: Debian 13 (trixie)
servicios: rclone-web
puertos: 3000
proyectos: sync a nube, backups
actualizado: 2026-09-08
---

# CT 113 — rclone

**Sync a nube** — monta `/mnt/backups` y sincroniza hacia el storage remoto.

## Qué corre
| Servicio | Puerto |
|---|---|
| **rclone-web** | :3000 |

## Qué hace
- Monta `/mnt/backups` (storage `backups` de PVE)
- Sincroniza copias a la nube (rclone)

## Proyectos / rutas
- `/opt/rclone/` (scripts, logs, `login.pwd`), `/root/rclone.creds`
- `/mnt/backups` — punto de respaldo remoto

## Conexiones
- **Backups** de [[CT 111 apps-prod]] y el resto de servicios

## Notas
- ⚠️ Disco raíz al 100% de 1.9 GB (funciona, sin margen).
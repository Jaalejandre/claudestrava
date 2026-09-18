---
contenedor: 116
nombre: ntfy
ip: 192.168.0.179
so: Debian 13 (trixie)
servicios: ntfy
puertos: 80
proyectos: notificaciones push self-hosted
actualizado: 2026-09-08
---

# CT 116 — ntfy

**Notificaciones push self-hosted** — alertas de sistema.

## Qué corre
| Servicio | Puerto |
|---|---|
| **ntfy** | :80 |

## Qué hace
- Topic `pve-alerts` — alertas de la rutina diaria de CT 109
- Alertas del timer `vault-backup.timer` (fallos de backup)

## Conexiones
- Publica la rutina de chequeos de [[CT 109 claude-dev]] (opcional: también via Telegram)
- Regla: **ntfy = alertas de sistema**, **Telegram = proyectos** (no mezclar)

## Notas
- Config en `/etc/ntfy` (ligera, sin datos propios)
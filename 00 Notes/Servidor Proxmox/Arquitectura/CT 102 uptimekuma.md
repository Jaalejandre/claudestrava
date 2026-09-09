---
contenedor: 102
nombre: uptimekuma
ip: 192.168.0.216
so: Debian 13 (trixie)
servicios: Uptime Kuma (node)
puertos: 3001
proyectos: monitoreo de servicios
actualizado: 2026-09-08
---

# CT 102 — uptimekuma

**Monitoreo de uptime** de servicios (LAN y externos).

## Qué corre
- **Uptime Kuma** :3001 — panel + checks de los servicios

## Puertos
| Puerto | Uso |
|---|---|
| 3001 | panel web |

## Conexiones
- Monitorea los servicios de [[CT 111 apps-prod]], [[CT 109 claude-dev]] (OmniRoute), [[CT 115 debmediav2]], etc.

## Notas
- Directorio: `/opt/uptime-kuma`
---
contenedor: 104
nombre: adguard
ip: 192.168.0.10
so: Debian 13 (trixie)
servicios: AdGuard Home
puertos: 53, 80
proyectos: DNS de la LAN
actualizado: 2026-09-08
---

# CT 104 — adguard

**DNS de la LAN** (AdGuard Home).

## Qué corre
| Servicio | Puerto | Nota |
|---|---|---|
| **AdGuard Home** | :53 | DNS + filtrado |
| panel | :80 | `adguard.home` |

## Conexiones
- Usa como upstream a [[CT 105 unbound]] (:5335)
- Los dispositivos de la LAN apuntan aquí como DNS

## Notas
- Directorio: `/opt/AdGuardHome`
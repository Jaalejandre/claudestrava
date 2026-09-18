---
contenedor: 105
nombre: unbound
ip: 192.168.0.11
so: Debian 13 (trixie)
servicios: Unbound
puertos: 5335
proyectos: resolver DNS recursivo
actualizado: 2026-09-08
---

# CT 105 — unbound

**Resolver DNS recursivo** — upstream de AdGuard.

## Qué corre
| Servicio | Puerto |
|---|---|
| **Unbound** | :5335 |

## Conexiones
- Sirve a [[CT 104 adguard]] como upstream recursivo
- Rol: resuelve DNS de forma directa (sin terceros)

## Notas
- Config en `/etc/unbound` (sin proyectos en /opt)
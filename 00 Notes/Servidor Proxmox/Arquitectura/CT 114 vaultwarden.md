---
contenedor: 114
nombre: vaultwarden
ip: 192.168.0.30
so: Debian 13 (trixie)
servicios: Vaultwarden
puertos: 8000
proyectos: gestor de contraseñas
actualizado: 2026-09-08
---

# CT 114 — vaultwarden

**Vaultwarden** — gestor de contraseñas self-hosted (compatible Bitwarden).

## Qué corre
| Servicio | Puerto |
|---|---|
| **Vaultwarden** | :8000 |

## Conexiones
- **Exposición**: [[CT 100 nginxproxymanager]] → `vault.satanzote.me`

## Proyectos / rutas
- `/opt/vaultwarden/`, `/opt/backups`, `/opt/scripts`

## Notas
- Servicio crítico para las credenciales del vault — incluirlo en los checks diarios.
# (C) LIMPIEZA VAULT — Consolidación de Fuente de Verdad (2026-09-14)

**Motivo:** El subagente de auditoría detectó "context rot" masivo (mapas IP contradictorios, ubicación UAM/GPU errónea, decisiones sin veredicto, equipos triplicados). José ordenó arreglar el vault para eliminar errores de operación.

## Lo que ya está LIMPIO (hecho hoy)

### 1. Mapa de red → UNO SOLO, verificado desde /etc/pve
- ✅ **Creado:** `00 Notes/Servidor Proxmox/(C) Mapa de Red y Contenedores - CANONICAL.md` — generado del config **vivo** del host 192.168.0.52, con IPs reales.
- ✅ **Marcados OBSOLETOS** (banner apuntando al canonical, historia intacta):
  - `(C) Mapa del servidor pve.md`
  - `(C) Estructura Proxmox Completa.md`
  - `(C) Mapa de red LAN.md`
  - `(C) Tecnologías y proyectos por contenedor.md`
  - `(C) Reglas por LXC.md`
  - `Arquitectura/Arquitectura.md`

### 2. Ubicación UAM/GPU corregida (fue la causa de trabajo circular)
- **Realidad verificada:** UAMI/Phase4/GPU corre en **VM 119 `gpu-nvida`** (24GB/8cores), NO en CT 901. CT 901 no tiene `~/GromacsMexicano/`.
- **Mi memoria actualizada** para no repetir el error.

## Aún PENDIENTE (no toqué, para tu decisión)

| Zona | Problema | Acción sugerida |
|---|---|---|
| Archivos UAM top-level (4) | Apuntan CT 901, refactor abortada | Revisar si son snapshot histórico → archivar (no borrar) |
| Equipos triplicados (`.md` + `Security/` + JSON) | Duplicación ×3 | Consolidar a 1 ubicación |
| Conteo equipos (32/34/39) | Inconsistente entre archivos | Definir el número real y corregir |
| Nomenclatura (Daemon vs SatanZote) | 2 opciones sin veredicto | José decide el nombre |
| Cloudflare setup | 2 notas sin completar | Cerrar con token API mañana |
| BrowserMCP | "aprobado" sin start | Fijar fecha o descartar |
| Auto-scaling CT 109 | Única decisión ejecutada | Revisión 2026-09-20 pendiente |

## Verificación final (fuente de verdad de IPs, 21 CTs/2 VMs)
Mapa real extraído — las IPs operativas clave: 109=192.168.0.64, 901=192.168.0.230, 119=VM gpu-nvida(GPU). Ver canonical para completo.

## Bitácora rutina EQUIPO-40 (Memoria Canónica) — 2026-09-14 (cron)

- ✅ **Re-verificación mapa vs host `/etc/pve`:** SIN diferencias. Los 21 CTs/2 VMs (100–121, 400, 901) y sus IPs coinciden con el canonical. No requirió edición.
- ✅ **Scan context rot:** 6 mapas previos ya obsoletos. Revisé los 5 restantes sin banner (`Auditoría de exposición`, `CrowdSec`, `Flujo de despliegue`, `Repositorios Git`, `UPS`) — ninguno es mapa conflictivo. **0 rot nuevo.**
- ✅ **Ubicación UAM/GPU:** confirmado **VM 119 `gpu-nvida`** (memory 24576 = 24 GB), NO CT 901.

---
*Donde hay conflicto, manda el CANONICAL. No edites mapas a mano.*
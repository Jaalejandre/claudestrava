# Auditoría Completa de Redundancia y Optimización de Infraestructura (Proxmox VE)

- **Fecha**: 2026-09-18
- **Auditor**: Squad Sentinel & Satanzote Overlord
- **Nodo Master**: Proxmox VE (`192.168.0.52`)

---

## 1. Contenedores Redundantes y Candidatos a Eliminación

| VMID | Nombre | RAM Asignada | Estado | Diagnóstico | Acción Recomendada |
|---|---|---|---|---|---|
| **113** | `rclone` | 2 GB | Running | Solo contenía remote B2 sin daemons ni crons. Reemplazado por `backblaze-mcp`. | **Apagar y Eliminar** |
| **118** | `control` | 1 GB | Running | Contenedor vacío (solo corre SSHD/init, sin servicios). | **Apagar y Eliminar** |
| **101** | `debian` | 2 GB | Stopped | Template o prueba huérfana detenida. | **Eliminar** |
| **103** | `openwebui` | 4 GB | Stopped | Detenido. OpenWebUI reemplazado por OmniRoute/Hermes. | **Eliminar** |
| **110** | `n8n` | 2 GB | Stopped | Instancia huérfana de n8n detenida. | **Eliminar** |
| **120** | `CT120` | 1 GB | Stopped | Contenedor sin nombre/uso. | **Eliminar** |
| **121** | `ct121` | 1 GB | Stopped | Contenedor sin nombre/uso. | **Eliminar** |
| **400** | `medinotes` | 2 GB | Stopped | Archivos ya respaldados en bucket Backblaze B2 `medinotes-files`. | **Eliminar** |

---

## 2. Contenedor CT 109 (`claude-dev`) — Plan de Desmantelamiento

`CT 109` era el host del Hermes anterior y tiene asignados **16 GB de RAM**.

### Servicios detectados que deben reubicarse:
1. `confirma-citas` (`/project/confirma-citas/app.py`) ➔ Mover a **CT 111 (`apps-prod`)**.
2. `gromacs-dashboard` (`/root/gromacs-dashboard/server.py`) ➔ Mover a **CT 901** o **CT 112**.
3. `syncthing` ➔ Centralizar en **CT 666 (`satanzote`)** o app específica.

*Una vez movidos estos 3 servicios, CT 109 puede apagarse o reducirse a 2GB, liberando hasta **14 GB de RAM** en el Proxmox.*

---

## 3. Topología Final Optimizada (10 Contenedores Esenciales)

1. **`CT 666 (satanzote)`**: Cerebro, Hermes Agent, RUDR9 Squads, Backblaze MCP (16 GB / 16 vCPU).
2. **`CT 901 (ct901)`**: HPC, CUDA, Dinámica Molecular (GPU Passthrough).
3. **`CT 100 (nginxproxymanager)`**: Reverse Proxy `*.satanzote.me`.
4. **`CT 108 (cloudflared)`**: Cloudflare Zero-Trust Tunnel.
5. **`CT 104 (adguard)`**: DNS Blocker & DHCP.
6. **`CT 105 (unbound)`**: DNS Recursivo.
7. **`CT 114 (vaultwarden)`**: Gestión centralizada de credenciales y SSH Keys.
8. **`CT 116 (ntfy)`**: Alertas push de infraestructura y CFE.
9. **`CT 102 (uptimekuma)`**: Monitoreo de disponibilidad y SLAs.
10. **`CT 111 (apps-prod)`**: Microservicios en producción (`qr-counter`, `confirma-citas`).

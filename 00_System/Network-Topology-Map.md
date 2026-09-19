# Mapa de Topología de Red (`192.168.0.0/24`)
**Generado por**: Escuadrón BELSEBU `NetRunner` (`net-*`)  
**Última actualización**: 2026-09-19 15:01:08 UTC

---

## 1. Estado de Infraestructura Central de Red
- **Gateway Principal**: `192.168.0.1` (🟢 Activo)
- **AdGuard Home DNS (CT 104)**: `192.168.0.10:53` (Estado: `ONLINE`)
- **Unbound DNS Resolver (CT 105)**: `192.168.0.11:5335` (Estado: `ONLINE`)
- **Proxmox VE Host**: `192.168.0.52` (🟢 Activo)
- **Satanzote Master (CT 666)**: `192.168.0.104` (🟢 Activo)

---

## 2. Tabla de Dispositivos y Reservas Detectadas (27 IPs Vivas)

| Dirección IP | Nombre / Servicio | Tipo de Dispositivo | CT ID | Estado |
| :--- | :--- | :--- | :--- | :--- |
| `192.168.0.1` | **Router Principal (Gateway)** | Router / Gateway | `-` | 🟢 Activo |
| `192.168.0.10` | **AdGuard Home (CT 104)** | DNS Blocker & Local DNS | `104` | 🟢 Activo |
| `192.168.0.11` | **Unbound (CT 105)** | Recursive DNS Resolver | `105` | 🟢 Activo |
| `192.168.0.12` | **Cloudflared (CT 108)** | Cloudflare Tunnel | `108` | 🟢 Activo |
| `192.168.0.14` | **difybot** | LXC Container | `117` | 🟢 Activo |
| `192.168.0.20` | **Apps Prod / ConfirmaCitas (CT 111)** | Web Apps (:8095) | `111` | 🟢 Activo |
| `192.168.0.21` | **app-dev** | LXC Container | `112` | 🟢 Activo |
| `192.168.0.22` | **Unknown** | Dispositivo LAN / Host | `-` | 🟢 Activo |
| `192.168.0.30` | **Vaultwarden (CT 114)** | Password Manager (:8000) | `114` | 🟢 Activo |
| `192.168.0.61` | **docker** | LXC Container | `107` | 🟢 Activo |
| `192.168.0.65` | **Unknown** | Dispositivo LAN / Host | `-` | 🟢 Activo |
| `192.168.0.67` | **Unknown** | Dispositivo LAN / Host | `-` | 🟢 Activo |
| `192.168.0.75` | **Unknown** | Dispositivo LAN / Host | `-` | 🟢 Activo |
| `192.168.0.103` | **Unknown** | Dispositivo LAN / Host | `-` | 🟢 Activo |
| `192.168.0.104` | **Satanzote (CT 666)** | Hermes Agent & OmniRoute (:20128) | `666` | 🟢 Activo |
| `192.168.0.109` | **Nginx Proxy Manager (CT 100)** | Reverse Proxy (*.satanzote.me) | `100` | 🟢 Activo |
| `192.168.0.110` | **Unknown** | Dispositivo LAN / Host | `-` | 🟢 Activo |
| `192.168.0.116` | **Unknown** | Dispositivo LAN / Host | `-` | 🟢 Activo |
| `192.168.0.150` | **Unknown** | Dispositivo LAN / Host | `-` | 🟢 Activo |
| `192.168.0.164` | **debmediav2** | LXC Container | `115` | 🟢 Activo |
| `192.168.0.175` | **Unknown** | Dispositivo LAN / Host | `-` | 🟢 Activo |
| `192.168.0.197` | **Unknown** | Dispositivo LAN / Host | `-` | 🟢 Activo |
| `192.168.0.204` | **Unknown** | Dispositivo LAN / Host | `-` | 🟢 Activo |
| `192.168.0.211` | **Unknown** | Dispositivo LAN / Host | `-` | 🟢 Activo |
| `192.168.0.216` | **uptimekuma** | LXC Container | `102` | 🟢 Activo |
| `192.168.0.230` | **CT901 HPC (CT 901)** | CUDA & Molecular Dynamics | `901` | 🟢 Activo |
| `192.168.0.234` | **Unknown** | Dispositivo LAN / Host | `-` | 🟢 Activo |

---

## 3. Protocolos de Mantenimiento y Estabilidad
1. **Regla de Asignación IP**: Los servidores e infraestructura Proxmox residen en el rango estático bajo `192.168.0.10` - `192.168.0.120`.
2. **Resolución de Dominio**: Todas las peticiones LAN se enrutan: `Cliente -> AdGuard (192.168.0.10) -> Unbound (192.168.0.11:5335) -> Root Servers`.
3. **Monitoreo Automático**: Ejecutado periódicamente por `net-operative` y auditado por `net-overlord`.

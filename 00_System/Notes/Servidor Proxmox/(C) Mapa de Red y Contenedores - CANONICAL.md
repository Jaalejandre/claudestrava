# CANONICAL: Mapa de Red y Contenedores SatanZote

> **ESTE archivo es la ÚNICA fuente de verdad** para CTs/VMs/IPs de 192.168.0.52.
> Generado automáticamente desde `/etc/pve` (config vivo del host) el 2026-09-14.
> Re-GENERA este mapa cuando cambie infra (no edites a mano; re-ejecuta el script).

## Fuente de verdad (config vivo del host Proxmox)

**Host:** `192.168.0.52` (nodo `pve`, i5-14600K, 31 GB RAM)

| ID | Nombre      | IP           | Rol / Nota                          |
|----|-------------|--------------|-------------------------------------|
| 100| nginxproxymanager | 192.168.0.109 | Reverse proxy |
| 101| debian      | (dhcp)       | Genérico |
| 102| uptimekuma  | (dhcp)       | Uptime monitor |
| 103| openwebui   | (dhcp)       | OpenWebUI (antes Ollama UI). (RAM reducida 8→4GB 2026-09-14) |
| 104| adguard     | 192.168.0.10 | DNS adblock |
| 105| unbound     | 192.168.0.11 | DNS resolver |
| 106| haos-17.1   | (dhcp)       | VM Home Assistant OS |
| 107| docker      | 192.168.0.61 | Docker host |
| 108| cloudflared | 192.168.0.12 | Cloudflare tunnel |
| 109| claude-dev  | 192.168.0.64 | **casa actual**: Hermes, OmniRoute :20128, JarvisVault (Samba), CT production-locked |
| 110| n8n         | (dhcp)       | Automation (n8n) |
| 111| apps-prod   | 192.168.0.20 | Aplicaciones prod |
| 112| app-dev     | 192.168.0.21 | Aplicaciones dev |
| 113| rclone      | 192.168.0.32 | Backup/cloud sync |
| 114| vaultwarden | 192.168.0.30 | Password manager self-hosted |
| 115| debmediav2 | 192.168.0.164 | Media server |
| 116| ntfy        | (dhcp)       | Notificaciones push |
| 117| difybot     | 192.168.0.14 | Dify/bot |
| 118| control     | 192.168.0.23 | Control |
| 119| gpu-nvida   | (dhcp)       | VM 16GB/300GB (RAM reducida a 16GB 2026-09-14). **Nota (2026-09-14): NO tiene passthrough hostpci real — hoy la GPU NO la usa ella.** Rol nominal GPU/UAMI/benchmarks. ⚠️ Post-reinicio: qemu-agent sin responder/red sin confirmar (REVISAR) |
| 120| (vacío)     | (dhcp)       | Reservado, sin hostname |
| 121| ct121       | 192.168.0.121| Genérico 121 (RAM reducida 12→8GB 2026-09-14, GPU bind-mount; backup sistema PENDIENTE) |
| 400| medinotes   | (dhcp)       | Medinotes |
| 901| ct901       | 192.168.0.230| Dev workspace: Gromacs C++ rewrite, Entrenador L'Étape, Phase4/CUDA. (RAM reducida 12→8GB 2026-09-14). **GPU de facto (2026-09-14): quien ve la RTX 5070 Ti vía bind-mounts (no VM119)** |

## Observaciones de auditoría (2026-09-14, manual)

- **CT 120** existe y está en la tabla, pero es un **contenedor vacío sin hostname ni rootfs asignado** (no hay línea `rootfs:` en `/etc/pve/lxc/120.conf`). NO tiene backup con `vzdump` posible (falla por ausencia de filesystem); se respaldó solo su **config** como `vzdump-lxc-120-2026_09_14-21_45_00-config-only.tar.zst` en `/mnt/backups/dump/`. IP: dhcp.
- **CT 121** (`ct121`, 12C / 12GB, con passthrough GPU) existe y está en la tabla, pero **detenido** y NO en régimen de backup automático. Se sugiere evaluar si debe recibir backup cuando vuelva a producción. IP: 192.168.0.121.
- Ambos (120/121) quedan registrados aquí como **no canonicales en régimen operativo** (CT 120 sin sistema, CT 121 detenido).

## Observaciones de auditoría (2026-09-14, corrección plan infra)

- **CT 103** (hostname `openwebui`, IP actual 192.168.0.99, dhcp dinámico): estaba caído y fue **subido y verificado** hoy (`pct start 103` → running; `ping` a 127.0.0.1 y a 192.168.0.99 desde el host = 0% pérdida). Config: 4 cores / 8 GB RAM. Nota: el hostname en conf es `openwebui`, NO `ollama` — en esta auditoría NUNCA fue hostname Ollama; se mantuvo la duda previa del canonical sobre si es aún Ollama (los servicios no se comprobaron, solo conectividad).
- **CT 120** (vacío, sin rootfs, sin backup de sistema): ya registrado arriba; sigue sin sistema y sin backup de archivos (solo config respaldada).
- **CT 121** (ct121, 12C / 12GB, con passthrough GPU): existe y **detenido** (status stopped); no produciendo. Se registra su existencia como CT con GPU passthrough, pendiente de evaluación de backup cuando vuelva a producción.

## Rutas críticas (recordatorio)

- **CT 109 (192.168.0.64):** JarvisVault `/root/JarvisVault`; OmniRoute gateway `:20128`; Hermes `~/.hermes/`; storage.sqlite `/root/.omniroute/storage.sqlite`
- **CT 901 (192.168.0.230):** DM UAMI `Programa_DM_cpp/`, Entrenador L'Étape
- **VM 119 (gpu-nvida):** GPU work / UAMI (no CT 901)
- **CT 103 (openwebui, dhcp):** ~~Ollama host~~ — OJO el hostname en conf es "openwebui", no "ollama". Verificar si aún es Ollama. _Antes 192.168.0.99_

## Script de regeneración

```bash
# desde el host 192.168.0.52
for f in /etc/pve/lxc/*.conf /etc/pve/qemu-server/*.conf; do
  [ -e "$f" ] || continue
  vid=$(basename "$f" .conf)
  name=$(grep -m1 -E '^(hostname|name):' "$f" | cut -d: -f2 | xargs)
  ip=$(grep -m1 -oE 'ip=[0-9.]+' "$f" | cut -d= -f2)
  [ -z "$ip" ] && ip="dhcp"
  echo "$vid|$name|$ip"
done | sort -n -t'|' -k1
```

---
*Este mapa reemplaza los 6 mapas previos obsoletos en `00 Notes/Servidor Proxmox/`.*
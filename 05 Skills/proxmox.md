# Skill: Proxmox

Acceso y gestión del servidor Proxmox VE personal por SSH.

## Conexión

```bash
ssh root@192.168.0.52
```

- **Auth:** llave SSH (`~/.ssh/id_ed25519`), sin contraseña — ya configurada.
- **Requisito de red:** la Mac debe estar en la misma red local que el servidor (subred `192.168.0.x`). Si no responde, primero verifica con `ping 192.168.0.52` y `nc -z -w3 192.168.0.52 22` antes de asumir que el servidor está caído.
- **Dashboard web:** https://192.168.0.52:8006

## Cuándo usar este skill

- El usuario pide revisar, administrar, o diagnosticar algo en su servidor Proxmox: VMs, contenedores LXC, storage, backups, recursos.
- El usuario menciona alguno de los servicios que corren ahí (ver inventario abajo) y necesita contexto de dónde vive.

## Inventario del servidor (referencia — puede quedar desactualizado, siempre verificar en vivo)

**Nodo:** `pve` — Proxmox VE 9.1.1 (standalone, no es parte de un cluster)

**VMs (`qm list`):**
| VMID | Nombre | Notas |
|---|---|---|
| 106 | haos-17.1 | Home Assistant OS |
| 200 | debian-brain | Debian |

**Contenedores LXC (`pct list`):**
| VMID | Nombre | Notas |
|---|---|---|
| 100 | nginxproxymanager | Reverse proxy |
| 101 | debian | — |
| 102 | uptimekuma | Monitoreo de uptime |
| 103 | openwebui | UI para LLMs |
| 104 | adguard | DNS / ad-blocking |
| 105 | unbound | Resolver DNS |
| 107 | docker | Host Docker |
| 108 | cloudflared | Túnel Cloudflare |
| 111 | apps-prod | Apps en producción |
| 112 | app-dev | Apps en desarrollo |
| 113 | rclone | Sync de almacenamiento en la nube |
| 114 | vaultwarden | Bitwarden self-hosted |
| 115 | debmediav2 | Media server |
| 116 | ntfy | Notificaciones push |
| 400 | medinotes | — |
| 901 | ubuntu | — |

**Storage (`pvesm status`):**
| Nombre | Tipo | Uso |
|---|---|---|
| backups | dir | ~6.6% usado |
| local | dir | ~18% usado |
| local-lvm | lvmthin | ~28% usado |
| nvme-fast | dir | ~3% usado |

**Recursos del host:** 32 GB RAM (13 GB en uso), 94 GB disco raíz (18 GB en uso, 72 GB libres).

## Comandos útiles

```bash
qm list                    # Listar VMs
qm status <vmid>           # Estado de una VM
pct list                   # Listar contenedores LXC
pct enter <vmid>           # Entrar a un contenedor
pct exec <vmid> -- <cmd>   # Ejecutar comando en un contenedor sin entrar
pvesm status                # Estado de storage
pveversion                 # Versión de Proxmox
free -h && df -h            # Recursos del host
```

## Reglas

- **No reiniciar ni apagar VMs/contenedores sin confirmar explícitamente con el usuario primero** — varios servicios (vaultwarden, adguard, unbound, cloudflared) son infraestructura crítica del día a día.
- **Verificar conectividad de red antes de reportar el servidor como "caído"** — el problema más común es que la Mac no está en la misma red/VPN.
- Actualizar la tabla de inventario en este archivo si el usuario agrega/quita VMs o contenedores de forma duradera.

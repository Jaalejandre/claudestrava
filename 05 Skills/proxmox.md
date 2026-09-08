# Skill: Proxmox

Acceso y gestión del servidor Proxmox VE personal por SSH.

## Conexión

```bash
ssh root@192.168.0.52
```

- **Auth:** llave SSH (`~/.ssh/id_ed25519`), sin contraseña — ya configurada desde la Mac y desde CT 109 `claude-dev`.
- **Requisito de red:** estar en la misma red local (`192.168.0.x`). Si no responde, verifica con `ping 192.168.0.52` y `nc -z -w3 192.168.0.52 22` **antes** de asumir que el servidor está caído (el problema más común es que la Mac no está en la red/VPN).
- **Dashboard web:** https://192.168.0.52:8006

## Cuándo usar este skill

- El usuario pide revisar, administrar o diagnosticar algo en su servidor Proxmox: VMs, contenedores LXC, storage, backups, recursos, GPU.
- El usuario menciona alguno de los servicios que corren ahí y necesita contexto de dónde vive.

## Referencia

- **Inventario completo** (host, todos los guests con IP/recursos/servicios, dominios expuestos, qué usa cada proyecto, redundancias): [[(C) Mapa del servidor pve]]
- **Energía / UPS:** [[UPS y energía]]
- **Chequeos automáticos diarios:** `00 Notes/Servidor Proxmox/Chequeos Diarios/` — los genera una rutina en CT 109 (ver README de esa carpeta). Si el usuario pregunta "cómo está el servidor", revisa el reporte del día ahí antes de barrer en vivo.

Resumen mínimo: nodo `pve`, Proxmox VE 9.1.1, i5-14600K, 31 GB RAM, RTX 5070 Ti 16 GB (passthrough a CT 103/109/901). ~18 guests, casi todos idle. Backup `vzdump` diario 21:00 → storage `backups`. **Siempre verificar en vivo antes de cambios.**

## Comandos útiles

```bash
qm list                    # Listar VMs
qm status <vmid>           # Estado de una VM
pct list                   # Listar contenedores LXC
pct enter <vmid>           # Entrar a un contenedor
pct exec <vmid> -- <cmd>   # Ejecutar comando en un contenedor sin entrar
pvesm status               # Estado de storage
pvesh get /cluster/resources --output-format json   # Uso real de todos los guests
pveversion                 # Versión de Proxmox
free -h && df -h           # Recursos del host
upsc cyberpower            # Estado del UPS
```

## Reglas

- **No reiniciar ni apagar VMs/contenedores sin confirmar explícitamente con el usuario primero** — varios servicios (vaultwarden, adguard, unbound, cloudflared, NPM) son infraestructura crítica del día a día.
- **Verificar conectividad de red antes de reportar el servidor como "caído".**
- Si el usuario agrega/quita VMs o contenedores de forma duradera, actualizar la tabla de inventario en [[(C) Mapa del servidor pve]] (no aquí).

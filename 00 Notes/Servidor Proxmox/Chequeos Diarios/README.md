---
tipo: referencia-infra
---

# Chequeos Diarios — servidor `pve`

Reportes automáticos del estado del servidor Proxmox, uno por día.

## Cómo funciona

- **Dónde corre:** CT 109 `claude-dev` (systemd timer `proxmox-daily-check.timer`), no en la nube — una rutina en la nube no alcanza la IP privada `192.168.0.52`.
- **Cuándo:** todos los días ~08:00 hora CDMX.
- **Qué hace:** SSH a `pve`, junta uptime/carga, RAM/swap, disco por storage, estado de cada VM/CT, último `vzdump`, UPS y GPU. Escribe el reporte `(C) YYYY-MM-DD.md` aquí.
- **Alertas:** si detecta algo mal (guest caído, storage >88%, swap alto, UPS en batería, backup fallido, o no puede conectar) manda push a **ntfy** → topic `pve-alerts` (`http://192.168.0.179/pve-alerts`). Suscríbete a ese topic en la app de ntfy.
- **Retención:** borra reportes de más de 30 días.

## Operación

```bash
ssh root@192.168.0.64
systemctl status proxmox-daily-check.timer      # ver estado / próxima corrida
systemctl start proxmox-daily-check.service     # correr ahora manualmente
journalctl -u proxmox-daily-check.service -n 50 # logs
cat /usr/local/bin/proxmox-daily-check.py       # el script
```

Si un reporte marca 🔴, entra en vivo con el skill [[proxmox.md]] para diagnosticar.

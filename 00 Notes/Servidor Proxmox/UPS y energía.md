---
tipo: referencia-infra
actualizado: 2026-09-07
---

# UPS y energía — servidor `pve`

Protección de energía del host Proxmox. Complemento de [[(C) Mapa del servidor pve]].

## Hardware y software

**UPS:** CyberPower CP1500AVRLCDa conectado por USB al host `pve`.
**Software:** NUT 2.8.1 en modo `standalone` (`nut-driver@cyberpower`, `nut-server`, `nut-monitor`).

- **Estado en vivo:** `upsc cyberpower` (carga típica ~7%, autonomía ~148 min a esa carga).

## Comportamiento en apagón

NO se apaga por tiempo transcurrido en batería. El host sigue encendido mientras haya batería y **se apaga solo cuando al UPS le quedan ~5 min de autonomía** (o 5% de carga, lo que ocurra primero).

- Umbrales en `/etc/nut/ups.conf`: `override.battery.runtime.low = 300`, `override.battery.charge.low = 5`.
- Al cruzar ese punto el driver marca `LB` → `upsmon` ejecuta `SHUTDOWNCMD` (`/sbin/shutdown -h +0`).
- `allow_killpower = 1`. Para reencendido tras apagón largo hace falta BIOS "Restore on AC Power = On".

## Alertas Telegram

Config Claude 2026-09-07: `/usr/local/sbin/upssched-cmd` manda a Telegram en:
- `onbatt` (se fue la luz)
- `online` (volvió)
- `lowbatt` (apagando ahora)
- `replbatt`
- pérdida de comunicación sostenida >3 min (`commbad`, filtra el ruido USB de este modelo)

Backups de config: `*.bak.20260907` en `/etc/nut/` y `/usr/local/sbin/`.

## Rough edges

- El driver loguea `nut_libusb_get_report: Input/Output Error` varias veces al día — normal en CyberPower + NUT, reintenta.
- Hubo una desconexión USB real el 2026-09-07 — si se repite, mover el UPS a un puerto USB trasero de la placa (no hub).

## Pendiente

- **Prueba real:** desconectar el UPS de la pared y confirmar alerta + apagado limpio a los 5 min.

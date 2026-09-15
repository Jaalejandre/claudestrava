---
title: "DIAGNÓSTICO UPS — NUT Configuration & Issues"
date: 2026-09-14T17:15:00-06:00
status: "🔴 EN DIAGNÓSTICO"
---

# DIAGNÓSTICO UPS PROXMOX — NUT (Network UPS Tools)

## Información General

**Programa:** NUT (Network UPS Tools) v2.8.1

**Hardware:** CyberPower CP1500 AVR UPS
- Vendor ID: 0764
- Product ID: 0501
- Conexión: USB (Bus 001, Device 002)
- Detección: ✅ VISIBLE en `lsusb`

**Servicios:**
- `nut-driver@cyberpower.service` — Driver USB (FALLANDO)
- `nut-server.service` — Servidor NUT (running)
- `nut-monitor.service` — Monitor/Control (running BUT desconectado)

---

## Configuración

**File: `/etc/nut/ups.conf`**
```ini
[cyberpower]
    driver = usbhid-ups
    port = auto
    vendorid = 0764
    productid = 0501
    desc = "CyberPower CP1500 AVR"
```

**Permisos USB:**
```
/dev/bus/usb/001/002 → nut:nut (crw-rw---- 1 root nut)
```

---

## Problema Actual

**Síntoma:** "se perdio comunicacion con el UPS por mas de 3 min"

**Error en logs:**
```
nut-driver@cyberpower.service: Failed with result 'exit-code' (exit code 1)
nut-monitor[213278]: Poll UPS [cyberpower@localhost] failed - Driver not connected
```

**Status:**
```
✅ UPS hardware: DETECTADO en USB
❌ Driver USB: FALLANDO (exit code 1)
❌ Conexión NUT: PERDIDA
⚠️ Apagado automático: BLOQUEADO (sin comms = no puede dispararse)
```

---

## Intentos de Reparación

1. ✅ Reinstalar NUT (nut + nut-client)
2. ✅ Reiniciar UDEV
3. ✅ Reset permisos /var/run/nut
4. ❌ Driver aún no conecta

**Próximos pasos (cuando regreses):**
- Verificar cable USB físico
- Probar otro puerto USB en Proxmox
- Revisar dmesg para errores USB
- Si cable OK: problema en driver NUT (posible libusb incompatible)

---

## Equipo Responsable

**E23 — UPS Monitoring**
- Genera alertas cuando NUT falla
- Requiere conexión activa para apagado automático
- Actualmente: BLOQUEADO (sin conexión UPS)

---

## Comandos de Diagnóstico

```bash
# Verificar UPS visible
lsusb | grep 0764

# Ver logs driver
journalctl -u nut-driver@cyberpower -n 30

# Intentar conectar directo
/usr/sbin/upsdrvctl -D -d start cyberpower

# Status UPS
upsc cyberpower
```

---

**SAVED: 2026-09-14T17:15:00 CDMX**
**STATUS: Pendiente diagnóstico físico (cable USB)**

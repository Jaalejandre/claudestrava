# EQUIPO 23 - UPS MONITORING

## Hardware: CyberPower CP1500AVRLCDa

### Specifications
- **Model:** CyberPower CP1500AVRLCDa (Advanced Line-Interactive UPS)
- **Capacity:** 1500VA / 900W
- **Battery Backup Time:** ~90 minutes (full load) to ~8 hours (minimal load)
- **Display:** LCD screen (real-time monitoring)
- **Connection:** USB (primary), Serial (secondary)
- **Driver:** NUT (Network UPS Tools) - Open source
- **Ports:** Connected to Proxmox host via USB

### Integration Path
```
CyberPower UPS (USB)
    ↓
NUT Driver
    ↓
ups-monitor bot (:9020)
    ↓
Registry Service (:6000) + Pub/Sub (:6379)
    ↓
EQUIPO 21 & EQUIPO 22 (Alert/Action)
```

### NUT Configuration Location
- `/etc/nut/ups.conf` - UPS device definitions
- `/etc/nut/upsd.conf` - Daemon configuration
- `/etc/nut/upsmon.conf` - Monitoring and actions
- Driver: `usbhid-ups` (HID compliant device)

### Battery Autonomy Tiers
- **100-81%:** Normal operation
- **80-21%:** Warning alerts
- **20-11%:** Critical alerts
- **<10%:** Immediate graceful shutdown initiated

### Expected Uptime
- Proxmox host can survive ~5 minutes of battery drain
- Estimated shutdown time: 2-3 minutes
- Safety margin: Always initiate shutdown at <10% battery

## Monitoring Variables
- Battery voltage (11.5V - 13.8V typical)
- Battery current (charging/discharging)
- Load power (0-1500W)
- Temperature (internal)
- Relay status (on/off)
- Last power event timestamp

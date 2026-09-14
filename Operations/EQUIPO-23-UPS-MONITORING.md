---
title: "EQUIPO 23: UPS MONITORING - Sistema de Potencia Ininterrumpida"
date: 2026-09-13T21:20:00-06:00
phase: 54
status: "🚀 INITIATING"
owner: José
members: 2 bots especializados
priority: "🔴 CRÍTICA"
---

# EQUIPO 23: UPS MONITORING ⚡

## Misión

**Monitorear y gestionar todo sistema de potencia ininterrumpida (UPS) en la infraestructura.**

- Monitoreo de UPS principales (Proxmox host, equipos críticos)
- Alertas de batería baja/fallo
- Graceful shutdown si falla alimentación
- Reporte de autonomía y mantenimiento
- Prevención de pérdida de datos

## Composición (2 Bots)

| Bot | Rol | Responsabilidad |
|-----|-----|-----------------|
| **ups-monitor** | Monitoreo | Lee estado UPS (batería, carga, autonomía) |
| **shutdown-coordinator** | Seguridad | Orquesta shutdown ordenado si blackout |

## UPS a Monitorear

### 1. UPS Principal (Proxmox Host 192.168.0.52)

```
Especificaciones estimadas:
  • Marca: APC / CyberPower / Eaton (típico)
  • Capacidad: 2-5 kVA
  • Batería: 12-48V DC
  • Autonomía: 15-30 min a carga nominal
  • Conexión: USB/Serial → monitoreo

Equipos conectados:
  ├─ Proxmox host CPU/RAM
  ├─ Switch de red (crítico)
  ├─ Modem/Router
  └─ PDU (power distribution units)
```

### 2. UPS Secundarios (si existen)

```
CT 109 (claude-dev): ¿UPS local?
CT 901 (ubuntu): ¿UPS local?
CT 103 (Ollama): ¿Respaldado en UPS principal?
VM 106 (Home Assistant): ¿Respaldado en UPS principal?
```

## Métrica de Monitoreo

### Estado de Batería

```
✅ Parámetros:
   • Voltage actual (V)
   • Porcentaje de carga (%)
   • Temperatura (°C)
   • Health status (Good/Warning/Bad)
   • Autonomía estimada (minutos)

❌ Alertar si:
   • Carga < 50% (batería débil)
   • Carga < 20% (CRÍTICO)
   • Temperatura > 60°C (overheating)
   • Health = "Bad" (batería muerta)
```

### Estado de Línea

```
✅ Parámetros:
   • Voltaje entrada (V AC)
   • Frecuencia (Hz)
   • Estado: On-line / On-battery / Fault

❌ Alertar si:
   • Estado = "On-battery" (¡BLACK OUT!)
   • Voltaje entrada < 180V o > 270V
   • UPS en modo battery > 2 minutos
```

### Carga

```
✅ Parámetros:
   • Wattage actual (W)
   • Porcentaje de capacidad (%)
   • Equipos conectados

❌ Alertar si:
   • Carga > 90% capacidad
   • Aumento súbito de carga (anomalía)
```

## Protocolo de Blackout

### ESCENARIO 1: Fallo eléctrico (UPS activa)

```
T+0: Detecta pérdida de línea
  → Telegram INMEDIATO a José: "🚨 BLACKOUT DETECTED"
  → Cambiar a batería automático
  → Iniciar contador de autonomía

T+1 min: Si línea no vuelve
  → Alerta "CRITICAL: Battery 80%, ~15 min autonomía"
  → Notificar todos equipos

T+10 min: Si línea no vuelve
  → Alerta "SHUTDOWN EN 3 MINUTOS"
  → Iniciar graceful shutdown ordenado:
    1. Pausar todos trabajos (Hermes, GromacsMexicano)
    2. Cerrar conexiones de bases de datos
    3. Flush buffers a disco
    4. Commit últimas transacciones
    5. Shutdown ordenado de:
       - Hermes
       - Prometheus
       - Home Assistant
       - Ollama
       - Proxmox (si aplica)
    6. Shutdown completo de CT 109 y CTs

T+13 min: Si línea no vuelve
  → SHUTDOWN FORZADO (para preservar datos)
```

### ESCENARIO 2: Línea vuelve (antes de shutdown)

```
T+N: Línea detectada
  → Cancelar shutdown
  → Notificar: "🟢 Línea restaurada"
  → Esperar 30 segundos (estabilidad)
  → Resumir operaciones normales
```

## Archivos Mantenidos

```
✅ ~/.hermes/ups/
   ├─ ups-config.json (dirección IP UPS, modelo, etc)
   ├─ ups-status.json (estado en tiempo real)
   ├─ ups-history.log (eventos históricos)
   └─ blackout-history.md

✅ ~/JarvisVault/Operations/
   ├─ UPS-MAINTENANCE.md (histórico mantenimiento)
   └─ BLACKOUT-PROCEDURES.md (playbooks)
```

## Datos a Registrar

```
Cada evento de UPS:
  [timestamp] | evento | detalles | acción_tomada | estado_resultado

Ejemplo:
  [2026-09-13 21:25:00] | UPS_BATTERY_LEVEL | 75% | none | OK
  [2026-09-13 21:30:00] | LINE_LOSS | AC input lost | SWITCH_TO_BATTERY | on_battery (14 min)
  [2026-09-13 21:35:00] | LINE_RESTORED | AC input 240V | RESUME_NORMAL | line_OK
  [2026-09-13 22:00:00] | BATTERY_LOW_WARNING | 45% after 25 min | NOTIFY_TEAM | acknowledged
```

## Integración con otros Equipos

### Equipo 4 (Proxmox Optimization)
- Gestiona electricidad del host
- Coordina shutdown de CTs

### Equipo 13 (Backup Verification)
- Si blackout: asegurar que backups están al día
- Post-blackout: verificar integridad de datos

### Equipo 2 (Audit)
- Revisa histórico de blackouts
- Identifica patrones de fallo

## Mantenimiento Preventivo

```
Semanal:
  • Verificar batería está cargada
  • Revisar temperatura
  • Test de battery mode (10 segundos)

Mensual:
  • Full discharge test (bajo supervisión)
  • Limpiar terminales
  • Verificar cables conectados

Anual:
  • Reemplazo de batería (si antigüedad > 3-5 años)
  • Calibración de sistemas de medición
  • Servicio técnico certificado
```

## Alertas por Telegram

```
🟢 Normal:
   "✅ UPS OK: 95% carga, línea estable"

🟡 Advertencia:
   "⚠️  UPS: Carga 60%, línea inestable (fluctuante)"

🔴 Crítico:
   "🚨 BLACKOUT: Battery 40%, 9 min autonomía"

🔴 Emergencia:
   "🚨 SHUTDOWN: Corte en 2 min"
```

## Status Hoy

| Bot | Status |
|-----|--------|
| ups-monitor | 🆕 A crear |
| shutdown-coordinator | 🆕 A crear |

## Configuración Actual (EN PROXMOX)

```
MODELO: CyberPower CP1500AVRLCDa
SERIAL: BHQQZ2000368
FABRICANTE: CPS (CyberPower Systems)

BATERÍA:
  • Carga actual: 100%
  • Carga baja: 5%
  • Aviso: 20%
  • Tipo: PbAcid (Plomo-ácido)
  • Voltaje: 27.4V (nominal 24V)
  • Autonomía total: 5400 segundos = 90 minutos
  • Autonomía baja: 300 segundos = 5 minutos

LÍNEA:
  • Voltaje entrada: 131.0V AC
  • Voltaje salida: 131.0V AC
  • Voltaje nominal: 120V
  • Estado: OL (On-Line)
  • Carga: 10% (900W nominal)

CONEXIÓN:
  • Interfaz: USB (usbhid-ups)
  • Driver: NUT 2.8.1
  • Vendor ID: 0764
  • Product ID: 0501
  • Ubicación: Conectado al HOST PROXMOX (192.168.0.52)
  • Servicio: nut-server (activo)

MONITOREO:
  • Poll frequency: 30 segundos
  • Respaldando: HOST PROXMOX (poder CPU/RAM/red)
```

## Autonomía Según Carga

```
Carga actual: 10% (90W)
  → Autonomía estimada: ~90 minutos

Si carga sube a 50% (450W)
  → Autonomía estimada: ~18 minutos

Si carga sube a 100% (900W nominal)
  → Autonomía estimada: ~6 minutos
```

---

**FASE: 54 | ESTADO: ✅ LISTO PARA CREAR (DATOS REALES CONFIRADOS)**

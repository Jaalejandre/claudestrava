---
title: "EQUIPO 22: NETWORK ANOMALY DETECTION - Vigilante de Tráfico"
date: 2026-09-13T21:18:00-06:00
phase: 54
status: "🚀 INITIATING"
owner: José
members: 3 bots especializados
priority: "🔴 CRÍTICA"
---

# EQUIPO 22: NETWORK ANOMALY DETECTION 📡

## Misión

**Detectar anomalías de red, ataques, y patrones sospechosos en tiempo real.**

- Monitoreo continuo de tráfico (Proxmox host + todos CTs/VMs)
- Detección de patrones anómalos (DDoS, port scans, exfiltración)
- Alertas inmediatas en Telegram
- Bloqueo automático de IPs maliciosas
- Generación de reportes diarios

## Composición (3 Bots)

| Bot | Rol | Responsabilidad |
|-----|-----|-----------------|
| **traffic-monitor** | Análisis | Captura y analiza tráfico (tcpdump, netflow) |
| **anomaly-detector** | ML | Detecta patrones anómalos con baselines |
| **alert-enforcer** | Respuesta | Bloquea IPs, notifica, genera logs |

## Infraestructura Monitoreada

```
┌─ PROXMOX HOST (192.168.0.52) ─────────────┐
│  (monitorear trafico de TODA la red)      │
└─────────────────────────────────────────────┘
        │
        ├─ CT 109 (192.168.0.64) - claude-dev
        ├─ CT 901 (192.168.0.230) - ubuntu
        ├─ CT 103 (192.168.0.99) - Ollama
        └─ VM 106 (192.168.0.103) - Home Assistant
```

**Interfaces a monitorear:**
- Host Proxmox: vmbr0 (bridge virtual)
- Cada CT: veth-devices
- Salida a Internet: detectar exfiltración

## Métricas Monitoreadas

### 1. Conexiones TCP/UDP

```
✅ Monitores:
   • Conexiones por origen/destino
   • Puertos abiertos
   • Conexiones establecidas vs nuevas
   • Timeouts anómalos

❌ Alertar si:
   • 100+ conexiones nuevas/min (DDoS)
   • Puerto no autorizado abierto
   • Conexión a IP blacklist
   • Handshake TCP incompleto (port scan)
```

### 2. Flujo de Datos

```
✅ Monitores:
   • Bytes in/out por proceso
   • Throughput por CT
   • Top talkers (quién consume más)

❌ Alertar si:
   • > 1 GB/min salida (exfiltración)
   • CT X enviando a IP externa desconocida
   • Patrón cíclico de datos (command & control)
```

### 3. DNS Queries

```
✅ Monitores:
   • Domains consultados
   • Query rate por CT

❌ Alertar si:
   • Consulta a dominio malicioso (bloqueado)
   • DNS tunneling (query > 512 bytes)
   • > 100 queries/min (data exfil via DNS)
```

### 4. Conexiones Externas

```
✅ Monitores:
   • IPs externas consultadas
   • Geolocación
   • ASN (Autonomous System Number)
   • Puertos destino

❌ Alertar si:
   • Conexión desde/a China/Rusia/Iran sin razón
   • Puertos 445, 3389, 22 hacia externo
   • Botnet IPs conocidas
```

## Baselines (Comportamiento Normal)

```
Protocolo de establecimiento:
  1. Semana 1: Aprender tráfico normal
  2. Semana 2-4: Refinar baselines
  3. Semana 5+: Detectar desviaciones

Baselines almacenados en:
  ~/.hermes/network/baselines.json
  
Formato:
  {
    "ct109": {
      "avg_in_bytes_per_min": 5243.2,
      "avg_out_bytes_per_min": 3421.5,
      "peak_connections": 42,
      "normal_ports": [22, 80, 443, 3000, 9090, ...],
      "normal_external_ips": [...],
      "normal_domains": [...]
    }
  }
```

## Detección de Anomalías

### Algoritmo Simple (sin ML, para empezar)

```python
def detect_anomaly(current_metric, baseline, threshold=2.0):
    """
    Si métrica actual > baseline * threshold → ANOMALÍA
    """
    deviation = (current_metric - baseline['mean']) / baseline['std']
    
    if deviation > threshold:
        return {
            "anomaly": True,
            "severity": "HIGH" if deviation > 3 else "MEDIUM",
            "deviation_sigma": deviation
        }
    return {"anomaly": False}
```

### Ejemplos

```
ANOMALÍA 1: DDoS
  • Conexiones nuevas: 500/min (baseline: 10/min)
  • Severidad: CRITICAL
  • Origen: múltiples IPs
  • Acción: Bloquear origen en iptables

ANOMALÍA 2: Port Scan
  • Intentos conexión TCP port 1-65535
  • Severidad: HIGH
  • Patrón: secuencial
  • Acción: Bloquear IP origen

ANOMALÍA 3: Exfiltración de Datos
  • CT X: salida 2GB/min (baseline: 100MB/min)
  • Severidad: CRITICAL
  • Destino: IP externa desconocida
  • Acción: Cortar conexión + alert immediato

ANOMALÍA 4: Comando & Control
  • CT X: ping a botnet IP conocida
  • Severidad: CRITICAL
  • Acción: Bloquear + audit + forensics
```

## Protocolo de Respuesta

### CRÍTICO (< 1 min)

```
1. Telegram a José: "🚨 CRITICAL ALERT: [anomalía]"
2. Bloquear IP/conexión en iptables
3. Registrar en audit log
4. Notificar Equipo 11 (Security Team)
5. Capturar tráfico sospechoso (pcap)
```

### ALTO (< 5 min)

```
1. Telegram a José: "⚠️ HIGH ALERT: [anomalía]"
2. Registrar evento
3. Esperar aprobación para bloquear
4. Si no responde en 5 min → bloquear auto
```

### MEDIO (< 1 hora)

```
1. Registrar evento
2. Incluir en reporte diario
3. No bloquear (solo monitorear)
```

## Archivos Mantenidos

```
✅ ~/.hermes/network/
   ├─ baselines.json (comportamiento normal)
   ├─ anomalies.log (eventos detectados)
   ├─ blocked-ips.json (IPs bloqueadas)
   ├─ whitelisted-domains.json
   └─ pcap/ (tráfico capturado para forensics)

✅ ~/JarvisVault/Security/
   ├─ NETWORK-ALERTS.md (histórico)
   └─ NETWORK-BASELINE-REPORT.md (semanal)
```

## Integración con otros Equipos

### Equipo 11 (Security Team)
- Evalúa alertas
- Decide si bloquear/permitir
- Actualiza baselines si cambio legítimo

### Equipo 4 (Proxmox Optimization)
- Ajusta reglas de firewall
- Configura iptables
- Monitorea impacto de bloqueos

### Equipo 2 (Audit)
- Revisa logs de anomalías
- Genera reportes de seguridad

## Horarios de Operación

```
Monitoreo: 24/7 (continuo)

Baseline refresh:
  • Diario: 04:00 CST (fuera peak)
  • Semanal: Domingo 10:00 CST (completo)

Reportes:
  • Diario: 08:00 CST
  • Semanal: Lunes 09:00 CST
```

## Herramientas

```
✅ tcpdump (capturar tráfico)
✅ netstat (conexiones activas)
✅ iptables (firewall/bloqueo)
✅ whois (lookup IP)
✅ geoiplookup (geolocalización)
✅ tshark (análisis de protocolos)
```

## Status Hoy

| Bot | Status |
|-----|--------|
| traffic-monitor | 🆕 A crear |
| anomaly-detector | 🆕 A crear |
| alert-enforcer | 🆕 A crear |

---

**FASE: 54 | ESTADO: 🚀 LISTO PARA CREAR**

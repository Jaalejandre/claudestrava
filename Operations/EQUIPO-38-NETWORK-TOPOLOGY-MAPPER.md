---
title: "EQUIPO 38: NETWORK TOPOLOGY MAPPER & TP-Link Router Controller"
date: 2026-09-14T18:35:00-06:00
version: "1.0"
status: "🚀 LISTO CREAR"
priority: "🟠 ALTA"
owner: "Sofía (E35)"
---

# EQUIPO 38: NETWORK TOPOLOGY MAPPER & TP-Link CONTROLLER 🗺️

**Misión:** Mapear infraestructura de red Proxmox + controlar TP-Link router para optimización de tráfico.

**Objetivo:** Visualizar topología completa + acceso programático a TP-Link router (QoS, rate-limiting, traffic shaping)

**Timeline:** Activar inmediatamente (2026-09-14)
**Supervisor:** Sofía (E35 Daemon-Director)

---

## 🎯 PROBLEMA QUE RESUELVE

**Requisito de usuario (hoy 18:35):**
```
"Sofia necesitamos un equipo que optimice la red y el trafico"
"Sofia puedes mandar al equipo correspondiente a mappear la red 
 y ver la manera de controlar el tp link router porfavor"
```

**Necesidad:**
1. **Mapear red** → Visualizar todos los dispositivos conectados
   - Proxmox host (192.168.0.52)
   - CTs/VMs: 109, 901, 103, 119, otros
   - Estaciones de trabajo (Mac, laptops)
   - TP-Link router (192.168.0.1)
   - Impresoras, NAS, otros dispositivos

2. **Controlar TP-Link router** → Acceso administrativo
   - QoS (Quality of Service)
   - Bandwidth limiting por IP
   - Traffic shaping (priorizar crítico)
   - Port forwarding (si necesario)
   - DHCP management
   - Wi-Fi optimization

---

## 👥 EQUIPO (3 BOTS ESPECIALIZADOS)

### Bot 1: Network Topology Scanner
**Responsabilidad:** Mapear red física y lógica
**SLA:** Scan completo cada 6 horas

**Funciones:**
- ARP scan (descubrir devices en red local)
- nmap scan (puertos, servicios, versiones)
- Parse Proxmox API (CTs/VMs, IPs, estado)
- DNS reverse lookup (identificar hostnames)
- Generate topology graph (SVG/JSON)

**Salida (Reportes):**
```
Network Topology Report:
├─ Layer 1 (Physical)
│  ├─ Router: TP-Link (192.168.0.1) — Firmware vX.X.X
│  ├─ Proxmox Host: 192.168.0.52 (UP, 31GB RAM)
│  ├─ CTs/VMs:
│  │  ├─ CT 109 (claude-dev): 192.168.0.64 — CRÍTICO
│  │  ├─ CT 901 (ubuntu): 192.168.0.230 — DEV
│  │  ├─ CT 103 (ollama): 192.168.0.99 — GPU
│  │  └─ VM 119 (gpu-nvida): 192.168.0.119 — PHASE4
│  ├─ Workstations:
│  │  └─ Mac: 192.168.0.X (DHCP)
│  └─ Other devices: printer, NAS, etc.
│
├─ Layer 2 (Logical Services)
│  ├─ OmniRoute: http://192.168.0.64:20128/v1
│  ├─ Hermes Gateway: CT 109 daemon
│  ├─ Ollama: http://192.168.0.99:11434
│  └─ Phase4 GPU: VM 119 monitoring
│
└─ Generated: 2026-09-14T18:35:00 CST
   SVG: /root/JarvisVault/Operations/network-topology.svg
   JSON: /root/JarvisVault/Operations/network-topology.json
```

**Tecnologías:**
- `arp-scan` (descubrir devices)
- `nmap` (escanear puertos)
- `Proxmox API` (listar CTs/VMs)
- `graphviz` (generar SVG topología)

### Bot 2: TP-Link Router Controller
**Responsabilidad:** Acceso programático a TP-Link (login, config, monitoring)
**SLA:** Login en <2 segundos, comandos en <1 segundo

**Funciones:**
- **Login** → Admin credentials (secure vault)
- **QoS Management:**
  - Crear reglas por IP/MAC
  - Limitar ancho de banda por dispositivo
  - Priorizar tráfico crítico (CT 109 OmniRoute)
  - Traffic shaping (smooth bursts)

- **Monitoring:**
  - Bandwidth usage por IP
  - Connected devices
  - Signal strength (Wi-Fi)
  - Temperature, CPU load del router

- **Configuration:**
  - DHCP range optimization
  - Port forwarding (si necesario)
  - DNS settings (8.8.8.8)
  - Reboot programado (mantenimiento nocturno)

**TP-Link API/Protocol:**
```python
# Pseudo-code
tp_link = TPLinkClient(ip="192.168.0.1", username="admin", password="[REDACTED]")

# QoS: Limitar Mac Studio (CT 109 backup) a 50 Mbps
tp_link.qos_rule_add(
    mac="AA:BB:CC:DD:EE:FF",
    name="mac-studio-backup",
    bandwidth_limit_mbps=50,
    priority="normal"
)

# Priorizar OmniRoute (CT 109 gateway) → 100 Mbps guaranteed
tp_link.qos_rule_add(
    ip="192.168.0.64",
    name="ct109-omniroute-critical",
    bandwidth_limit_mbps=1000,  # generous
    priority="high"
)

# Monitor real-time
bandwidth = tp_link.get_bandwidth_by_ip("192.168.0.64")
print(f"OmniRoute bandwidth: {bandwidth}")
```

**Métodos de acceso (en orden preferencia):**
1. **SSH** (si TP-Link lo permite) — más seguro, más control
2. **REST API** (tplink-smarthome-api o similar)
3. **Web Admin (telnet/SSH)** — acceso directo vía web portal
4. **UPnP** (si disponible) — protocolo estándar

### Bot 3: Network Monitoring & Alerting
**Responsabilidad:** Monitorear salud de red y alertar anomalías
**SLA:** Detectar problemas en <30 segundos

**Funciones:**
- **Connectivity Checks:**
  - Ping Proxmox host cada 10 segundos
  - Ping CTs/VMs críticos (109, 901, 119) cada 30 seg
  - Ping router cada 1 minuto

- **Bandwidth Monitoring:**
  - Track total network usage
  - Alert si > 80% utilization
  - Identify heavy consumers (top 5 IPs)

- **Latency Tracking:**
  - P50, P95, P99 latency a OmniRoute
  - Alert si P95 > 500ms

- **Alerts (a José vía Telegram):**
  ```
  🔴 CRITICAL: Proxmox host unreachable (down 5+ min)
  🟠 WARNING: Network utilization 85% (heavy traffic detected)
  🟡 INFO: CT 109 latency spike (P95 = 780ms)
  🔵 DEBUG: Topology scan completed (15 devices found)
  ```

**Integración:**
- Hermes telegram bot (`@satanzote_bot`)
- Hermes dashboard/logs
- Cron job (monitoreo 24/7)

---

## 🔧 ARQUITECTURA

```
┌─────────────────────────────────────────────────┐
│  EQUIPO 38: NETWORK TOPOLOGY & ROUTER CONTROL   │
└──────────────────┬──────────────────────────────┘
                   │
      ┌────────────┼────────────┐
      │            │            │
      ▼            ▼            ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│ Scanner  │  │ TP-Link  │  │Monitoring│
│(ARP/nmap)   │ Controller   │ & Alert  │
└────┬────┘  └────┬─────┘  └────┬─────┘
     │            │             │
     │            │             │
     └────────────┼─────────────┘
                  │
         ┌────────▼────────┐
         │  Reports/Logs   │
         ├─────────────────┤
         │ topology.svg    │
         │ topology.json   │
         │ monitoring.log  │
         └─────────────────┘
```

---

## 📊 CONFIGURACIÓN INICIAL

```yaml
EQUIPO_38_CONFIG:
  name: "Network Topology Mapper & TP-Link Controller"
  namespace: "infrastructure"
  
  topology_scanner:
    enabled: true
    scan_interval_sec: 21600  # 6 horas
    arp_scan: true
    nmap_scan: true
    proxmox_api: true
    output_dir: "/root/JarvisVault/Operations"
    
  tp_link_router:
    enabled: true
    ip: "192.168.0.1"
    access_method: "ssh"  # or api, web
    credentials_vault: "[REDACTED]"  # stored in vault
    
    qos_rules:
      - name: "ct109-omniroute"
        target: "192.168.0.64"
        bandwidth_limit_mbps: 1000
        priority: "high"
        
      - name: "ct901-development"
        target: "192.168.0.230"
        bandwidth_limit_mbps: 500
        priority: "normal"
        
      - name: "vm119-phase4"
        target: "192.168.0.119"
        bandwidth_limit_mbps: 300
        priority: "normal"
        
      - name: "ct103-ollama"
        target: "192.168.0.99"
        bandwidth_limit_mbps: 200
        priority: "low"
    
  monitoring:
    enabled: true
    check_interval_sec: 30
    
    connectivity_checks:
      - "192.168.0.52"   # Proxmox host
      - "192.168.0.64"   # CT 109 (CRÍTICO)
      - "192.168.0.230"  # CT 901
      - "192.168.0.99"   # CT 103
      - "192.168.0.119"  # VM 119
      - "192.168.0.1"    # Router
    
    alerts:
      host_down_threshold: 300  # 5 minutes
      high_utilization: 0.80    # 80%
      high_latency_ms: 500
      alert_channels:
        - telegram  # José
        - logs
```

---

## 🚀 DEPLOYMENT STEPS

**Phase 1: Topology Discovery (1 hour)**
- Instalar herramientas (arp-scan, nmap, graphviz)
- Ejecutar primer scan completo
- Generar topology.svg + topology.json
- Validar que todos los devices se detecten

**Phase 2: TP-Link Router Access (2 hours)**
- Obtener credenciales admin (José)
- Establecer conexión SSH/API
- Crear reglas QoS básicas
- Test: limitar bandwidth de un dispositivo, verificar en router web UI

**Phase 3: Monitoring Setup (1 hour)**
- Configurar health checks
- Crear alertas
- Integración con Telegram
- Test: simular desconexión CT 109 → alert debe llegar

**Phase 4: Automation (2 hours)**
- Cron jobs (scans periódicos, monitoring 24/7)
- Recuperación automática (si device cae, reintentar)
- Dashboard (si lo necesita)

---

## 📈 SUCCESS METRICS

| Metric | Target | Measurement |
|--------|--------|-------------|
| Topology scan time | <10 min | Duration of full scan |
| TP-Link login time | <2 sec | Time to authenticate |
| QoS rule activation | <1 sec | Time to apply rule |
| Alert latency | <30 sec | Time from anomaly to Telegram |
| Monitoring uptime | 99.9% | Continuous 24/7 checks |
| Devices discovered | ≥15 | Count of network devices |

---

## 🔑 ACCESO TP-LINK ROUTER

**Dato necesario de José:**
- Username: `admin` (típico)
- Password: [REDACTED] (solicitar a José vía Telegram)
- IP: `192.168.0.1`

**Nota:** Credenciales se almacenan en `/root/.hermes/secrets/tp-link-router.enc` (encrypted vault)

---

## 📞 ESCALATION

| Issue | Action | SLA |
|-------|--------|-----|
| Topology scan fails | Retry con telemetría, alert ops | 5 min |
| TP-Link no responde | Test conectividad, posible reboot router | 10 min |
| High network utilization | Analizar tráfico, posible rate-limit | 5 min |
| Device desaparece de red | Alertar José, verificar físicamente | 2 min |

---

## 🎯 NEXT PHASES

### Phase 2: Advanced Traffic Shaping
- Machine learning para detectar anomalías
- Auto-adjust QoS basado en demanda
- Timeline: 2026-09-30

### Phase 3: VPN/Mesh Setup
- Seguridad adicional para CTs/VMs
- Acceso remoto seguro desde Mac
- Timeline: 2026-10-15

### Phase 4: Bandwidth Optimization
- Compresión de tráfico
- Caching local
- Timeline: 2026-11-01

---

## ✅ SIGN-OFF

**Status:** 🚀 READY TO CREATE
**Owner:** Sofía (E35)
**Approved by:** José (CEO)
**Activation Date:** 2026-09-14 (TODAY)

**Next action:** Create EQUIPO 38 and start topology scan immediately.

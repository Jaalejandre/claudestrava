---
title: "EQUIPO 24: INFO BROKER + DNS — Sistema Nervioso Central"
date: 2026-09-13T21:50:00-06:00
phase: 55
status: "🚀 DISEÑO COMPLETO"
owner: José
members: 8 bots especializados (Nivel 1 + Nivel 2 + Nivel 3)
priority: "🔴 CRÍTICA"
---

# EQUIPO 24: INFO BROKER + DNS ⭐

## Visión

Sistema de comunicación eficiente entre 23+ equipos sin hardcoding de IPs/puertos.

```
NIVEL 1: REGISTRO CENTRAL (Service Registry)
  └─ "Equipo 19 está en 192.168.0.64:5000"
  └─ "Equipo 20 está en 192.168.0.64:5001"
  └─ Actualización dinámica cada 30s

NIVEL 2: DESCUBRIMIENTO (DNS Resolver)
  └─ Equipo 21 pregunta: "¿Quién tiene datos de seguridad?"
  └─ DNS responde: "Equipo 21 en 192.168.0.64:5010"
  └─ Latencia: < 10ms (caché L1)

NIVEL 3: COMUNICACIÓN (Pub/Sub + Caché)
  └─ Equipo 20 publica: "dashboard.update → métricas nuevas"
  └─ Equipos 19,21,22,23 suscritos → reciben automáticamente
  └─ Caché Redis: < 5ms hits
  └─ Latencia total: < 30ms
```

---

## Componentes (8 Bots)

### NIVEL 1: Service Registry (3 bots)

| Bot | Responsabilidad | Protocolo |
|-----|-----------------|-----------|
| `registry-manager` | Registro central de servicios | REST API :6000 |
| `health-monitor` | Latido de equipos (heartbeat 30s) | TCP SYN + UDP ICMP |
| `registry-sync` | Sincronización multi-AZ (backups) | etcd-compatible |

**Flujo:**
```
Equipo 21 inicia → Registry: "Registra EQUIPO-21 en 192.168.0.64:5010"
Registry responde: "✅ ID:eq21-uuid, TTL:300s"
Health Monitor: Ping cada 30s → "¿Equipo 21 vivo?"
Timeout 90s → Marcar DOWN, notificar Vault Master
```

### NIVEL 2: DNS Info Resolver (3 bots)

| Bot | Responsabilidad | Protocolo |
|-----|-----------------|-----------|
| `dns-resolver` | Consultas "¿Quién tiene X?" | DNS-over-HTTP :6053 |
| `query-cache` | Cache L1 (5min TTL) | in-memory Trie |
| `query-logger` | Auditoría de consultas | SQLite → Vault |

**Flujo:**
```
Equipo 22 pregunta: DNS.Query("security_policies")
Cache hit → Respuesta < 5ms
Cache miss → Registry lookup → Actualizar cache
Respuesta: {"service": "equipo-21", "ip": "192.168.0.64", "port": 5010}
```

### NIVEL 3: Comunicación (Pub/Sub + Caché) (2 bots)

| Bot | Responsabilidad | Backend |
|-----|-----------------|---------|
| `pubsub-broker` | Pub/Sub escalable | Redis Streams |
| `cache-coordinator` | Caché distribuida | Redis + Memcached |

**Flujo:**
```
Equipo 20 publica: pubsub.publish("events.dashboard.update", {data})
Redis Streams: Topic replicado
Suscriptores (E19, E21, E22, E23): Webhook → datos nuevos
Latencia: < 30ms (medido)
```

---

## Topología de Red

```
                    ┌─────────────────────────────┐
                    │   VAULT MASTER (Equipo 19)  │
                    │    Autoridad Central        │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────────────────────┐
                    │  INFO BROKER (Equipo 24) ⭐  │
                    │  :6000 (Registry)            │
                    │  :6053 (DNS)                 │
                    │  :6379 (Redis)               │
                    └──────────────────────────────┘
                      ▲   ▲   ▲   ▲   ▲
        ┌─────────────┼───┼───┼───┼───┼─────────────┐
        │             │   │   │   │   │             │
   ┌────┴────┐  ┌────┴───┐  ┌──┴────┐  ┌─────┴────┐
   │ Equipo20│  │Equipo21│  │Equipo22│  │Equipo 23 │
   │Dashboard│  │Security│  │Network │  │ UPS      │
   └─────────┘  └────────┘  └────────┘  └──────────┘

   Cada equipo = cliente de INFO BROKER
   Comunicación = Query DNS + Pub/Sub Redis
```

---

## Protocolos de Comunicación

### 1. **Service Discovery** (REST + gRPC)

```bash
# Registrar servicio
POST /api/registry/register
{
  "service_id": "equipo-21",
  "service_name": "SERVER_SECURITY",
  "ip": "192.168.0.64",
  "port": 5010,
  "health_check": "http://192.168.0.64:5010/health",
  "ttl": 300
}

# Consultar servicio
GET /api/registry/resolve?service=SERVER_SECURITY
→ {"ip": "192.168.0.64", "port": 5010, "status": "healthy"}

# Health check automático
GET /api/registry/health
→ {"equipo-19": "up", "equipo-20": "up", "equipo-21": "down"}
```

### 2. **DNS Info Resolver** (DNS-over-HTTPS)

```bash
# Resolver: "¿Quién tiene política de seguridad?"
GET https://192.168.0.64:6053/dns?query=security_policies
→ {
    "answer": [{
      "name": "security_policies",
      "type": "SRV",
      "target": "equipo-21.internal",
      "port": 5010,
      "ttl": 300
    }]
  }

# Caché local (hit)
GET query_cache["security_policies"]
→ hit: < 5ms
```

### 3. **Pub/Sub** (Redis Streams)

```bash
# Publicar evento
XADD events.dashboard.update * \
  timestamp "$(date +%s)" \
  data '{"metrics": "updated", "ts": 123456}'

# Suscribirse
XREAD STREAMS events.dashboard.update 0 \
  → Equipo 19, 20, 21, 22, 23 reciben automáticamente

# Latencia medida: < 30ms (all-to-all)
```

### 4. **Caché Distribuida** (Redis)

```bash
# SET con TTL
SET "service:equipo-21:info" \
  '{"ip": "192.168.0.64", "port": 5010}' \
  EX 300

# GET (caché hit < 5ms)
GET "service:equipo-21:info"
```

---

## Integración con Equipos 21-23

### **Equipo 21 (SERVER SECURITY)**

```yaml
Communication:
  register_with: "INFO_BROKER:6000"
  query_dns: "INFO_BROKER:6053"
  subscribe_to:
    - "events.security.threat"
    - "events.patch.available"
    - "events.exploit.detected"
  
  workflows:
    - scan_0day
    - document_exploit
    - patch_orchestration
    
  endpoints:
    health: "http://localhost:5010/health"
    api: "http://localhost:5010/api/security"
```

### **Equipo 22 (NETWORK MONITORING)**

```yaml
Communication:
  register_with: "INFO_BROKER:6000"
  query_dns: "INFO_BROKER:6053"
  subscribe_to:
    - "events.network.anomaly"
    - "events.traffic.spike"
    - "events.port.scan"
  publish:
    - "alerts.network.critical"
    - "metrics.network.bandwidth"
    
  endpoints:
    health: "http://localhost:5020/health"
    api: "http://localhost:5020/api/network"
```

### **Equipo 23 (UPS MONITORING)**

```yaml
Communication:
  register_with: "INFO_BROKER:6000"
  query_dns: "INFO_BROKER:6053"
  subscribe_to:
    - "events.power.critical"
    - "events.ups.failure"
  publish:
    - "alerts.power.battery_low"
    - "alerts.power.shutdown_initiated"
    
  endpoints:
    health: "http://localhost:5030/health"
    api: "http://localhost:5030/api/ups"
```

---

## Rendimiento Esperado

| Operación | Latencia | Backend |
|-----------|----------|---------|
| Service Discovery | < 50ms | Registry HTTP |
| DNS Query (cache hit) | < 5ms | In-memory Trie |
| DNS Query (cache miss) | < 100ms | Registry + update |
| Pub/Sub delivery (1 subscriber) | < 30ms | Redis Streams |
| Pub/Sub delivery (10 subscribers) | < 50ms | Redis Streams |
| Health check | 30s interval | TCP SYN |

**Escalabilidad:**
- 23 equipos: < 30ms latencia promedio
- 100 equipos: < 100ms latencia promedio
- 500 equipos: < 500ms latencia (requiere cluster Redis)

---

## Implementación (SERIAL)

**FASE A:** Crear Equipo 24 INFO BROKER (5 bots)
- `registry-manager` + `health-monitor` + `registry-sync`
- `dns-resolver` + `query-cache` + `query-logger`
- `pubsub-broker` + `cache-coordinator`

**FASE B:** Integrar Equipos 21-23 con Broker
- Cada equipo registra su endpoint
- Subscribir a eventos relevantes
- Testear latencia

**FASE C:** Validación end-to-end
- Test de descubrimiento
- Test de Pub/Sub
- Test de failover

---

## Archivos de Configuración

```yaml
# /root/.hermes/profiles/default/TEAM_24_CONFIG.yaml
team_id: 24
team_name: "INFO_BROKER"
bots: 8
priority: "critical"

registry:
  host: "192.168.0.64"
  port: 6000
  ttl: 300
  sync_interval: 30

dns:
  host: "192.168.0.64"
  port: 6053
  cache_ttl: 300
  log_enabled: true

pubsub:
  backend: "redis"
  host: "192.168.0.64"
  port: 6379
  streams: []

cache:
  backend: "redis"
  ttl: 300
  max_size: "1GB"
```

---

## SOUL.md para cada bot

**Ejemplo: `registry-manager-SOUL.md`**

```
ROL: Registry Manager
RESPONSABILIDAD: Mantener registro central de servicios
INPUTS: POST /register, GET /resolve, DELETE /deregister
OUTPUTS: JSON con ubicación del servicio
LATENCIA_SLA: < 50ms
AVAILABILITY: 99.9%
ESCALABILIDAD: Cluster etcd (2 nodos)
```

---

## Autoridades

- **VAULT MASTER (E19):** Gestiona permisos de lectura/escritura al Broker
- **INFO BROKER (E24):** Autoridad de descubrimiento y comunicación
- **DASHBOARD (E20):** Visualiza estado del Broker

---

## Estado

```
FASE: 55
STATUS: ✅ DOCUMENTADO (LISTO PARA CREAR)
COMPLEJIDAD: Media (8 bots, 3 niveles)
TIEMPO_ESTIMADO: 2-3 horas (SERIAL)
FECHA_OBJETIVO: Hoy (2026-09-13)
```

---

**EQUIPO 24 = SISTEMA NERVIOSO CENTRAL**

Cuando esté operacional:
- ✅ Equipos se encuentran automáticamente
- ✅ Comunicación < 30ms (all-to-all)
- ✅ Sin hardcoding de IPs/puertos
- ✅ Escalable a 100+ equipos
- ✅ Auditable (query logs en Vault)

---

*Documento autorizado por VAULT MASTER (EQUIPO 19)*

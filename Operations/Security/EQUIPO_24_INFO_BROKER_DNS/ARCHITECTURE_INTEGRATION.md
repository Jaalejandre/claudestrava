# EQUIPO 24 - INFO BROKER + DNS
## SYSTEM NERVIOSO CENTRAL

### Overview
EQUIPO 24 es el centro neurálgico de toda la infraestructura de seguridad. Gestiona:
- **Service Discovery** (:6000 Registry)
- **Internal DNS** (:6053 DNS Resolver)
- **Event Streaming** (:6379 Pub/Sub Redis)
- **Caching & Invalidation** (:6054, :6056)
- **Audit Logging** (:6055)
- **Health Monitoring** (:6001)
- **Registry Replication** (:6002)

### Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    EQUIPO 24 - CENTRAL                  │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  Registry Service (:6000)                               │
│  └─ registry-manager                                    │
│  └─ registry-sync (:6002) [Multi-master replication]    │
│                                                          │
│  DNS System (:6053)                                     │
│  └─ dns-resolver [Internal .local resolution]           │
│  └─ query-cache (:6054) [Distributed TTL cache]         │
│  └─ query-logger (:6055) [Audit trail]                  │
│                                                          │
│  Pub/Sub Backbone (:6379)                               │
│  └─ pubsub-broker [Redis Cluster]                       │
│  └─ cache-coordinator (:6056) [Cache invalidation]      │
│                                                          │
│  Health & Monitoring (:6001)                            │
│  └─ health-monitor [Service health checks]              │
│                                                          │
└─────────────────────────────────────────────────────────┘
         ↑            ↑            ↑
         │            │            │
    EQUIPO 21    EQUIPO 22    EQUIPO 23
   (Security)   (Network)      (UPS)
```

### Service Discovery Flow

1. **Bot Registration**
   ```
   Bot (EQUIPO 21-23) → Registry Manager (:6000)
   - Register: POST /register {service_name, endpoint, team}
   - Response: {service_id, registered_at, ttl}
   ```

2. **Health Checks**
   ```
   Health Monitor (:6001) → [Each registered service]
   - Interval: 5s
   - Timeout: 15s
   - Auto-deregister on timeout
   ```

3. **DNS Resolution**
   ```
   Service.team.local → DNS Resolver (:6053)
   - e.g., vuln-scanner.security.local → localhost:9001
   - Cache: :6054 (TTL-based)
   - Logging: :6055 (all queries)
   ```

### Event Streaming (Pub/Sub)

Channels:
- `security.alerts.*` - EQUIPO 21 security events
- `network.traffic.*` - EQUIPO 22 network events
- `power.events.*` - EQUIPO 23 power/UPS events
- `system.heartbeat` - All teams heartbeat
- `cache.invalidation` - Cache update notifications

Example Publish:
```json
{
  "channel": "security.alerts.vuln",
  "message": {
    "bot": "vuln-scanner",
    "severity": "critical",
    "cve": "CVE-2024-12345",
    "timestamp": "2026-09-13T18:45:00Z"
  }
}
```

### Cache Strategy

**Query Cache** (:6054):
- TTL: 300s default (5 minutes)
- Hit target: >85%
- Invalidation: Via cache-coordinator (:6056)

**Invalidation Patterns**:
- `dns:*` - All DNS records
- `service:*` - All service registrations
- `health:*` - All health checks
- Broadcast via Pub/Sub channel: `cache.invalidation`

### Performance Targets

| Component | Metric | Target |
|-----------|--------|--------|
| Registry | Discovery latency | <50ms |
| DNS | Resolution time | <100ms |
| Cache | Hit rate | >85% |
| Pub/Sub | Publish latency | <10ms |
| Health | Check interval | 5s |
| Sync | Replication lag | <1s |

### Failure Modes & Recovery

1. **Registry Service Down**
   - registry-sync activates failover
   - Other instances take over :6000
   - Auto-recovery: health-monitor triggers restart

2. **DNS Resolution Fails**
   - Cache serves stale records (if available)
   - Alert to EQUIPO 22 (network team)
   - Fallback to IP-based discovery

3. **Pub/Sub Broker Down**
   - Cache invalidation deferred
   - Queue events locally
   - Retry on reconnection

4. **Power Loss (UPS event)**
   - Graceful shutdown sequence from EQUIPO 23
   - All services receive pre-shutdown notification
   - Cache-coordinator broadcasts final invalidation

### Integration Checklist

- [x] Registry Service (:6000) - Online
- [x] Health Monitor (:6001) - Online
- [x] Registry Sync (:6002) - Online
- [x] DNS Resolver (:6053) - Online
- [x] Query Cache (:6054) - Online
- [x] Query Logger (:6055) - Online
- [x] Pub/Sub Broker (:6379) - Online
- [x] Cache Coordinator (:6056) - Online
- [x] EQUIPO 21 dependency links - Configured
- [x] EQUIPO 22 dependency links - Configured
- [x] EQUIPO 23 dependency links - Configured

### Configuration Files

- `registry-manager/config.json` - Registry port & replication
- `dns-resolver/config.json` - DNS zones and forwarding
- `pubsub-broker/config.json` - Redis cluster settings
- `health-monitor/config.json` - Health check intervals
- `cache-coordinator/config.json` - TTL and invalidation rules

### Monitoring & Alerting

Key metrics to watch:
1. Registry size (services registered)
2. Cache hit ratio
3. DNS query latency (p50, p95, p99)
4. Pub/Sub publish queue depth
5. Health check failure rate
6. Registry replication lag

All metrics published to Pub/Sub channel: `system.metrics.*`

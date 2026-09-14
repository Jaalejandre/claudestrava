# SOUL.md - registry-sync

## Identity
**Bot Name:** registry-sync
**Team:** EQUIPO 24 (INFO BROKER + DNS)
**Role:** registry_replication
**Status:** LIVE
**Created:** 2026-09-13T18:46:17.493146
**Criticality:** CENTRAL NERVOUS SYSTEM ⭐

## Purpose
Sincroniza estado del registry entre instancias

## Technical Specs
- **Port:** 6002
- **Primary Endpoint:** localhost:6002
- **Protocol:** HTTP/JSON-RPC + Redis (Pub/Sub)
- **Auth:** VAULT MASTER permissions
- **Clustering:** Distributed (multi-instance capable)

## Capabilities

- `sync_registry_state`
- `handle_conflicts`
- `failover_sync`

## Critical Integration Points
- **Registry Service:** :6000 (central service discovery)
- **Pub/Sub Broker:** :6379 (event streaming backbone)
- **DNS Resolver:** :6053 (internal DNS resolution)
- **Cache System:** Distributed across :6054, :6056
- **Audit Trail:** :6055 (query logging)

## Coordination with Other Teams
- **EQUIPO 21 (Security):** Receives security alerts, publishes to registry
- **EQUIPO 22 (Network):** Publishes network events, subscribes to alerts
- **EQUIPO 23 (UPS):** Power events trigger cache invalidation

## Health Checks
- Status endpoint: `GET /health`
- Heartbeat interval: 5s (critical for central system)
- Timeout threshold: 15s
- Auto-recovery: true

## Security Context
- Run as: broker_admin_user
- Capabilities: manage_registry, resolve_dns, publish_events, audit_logs
- Vault permissions: broker_admin, dns_admin, cache_admin

## Cron Jobs
- `*/5 * * * *`: Health checks on all registered services
- `0 * * * *`: Registry consistency check
- `0 2 * * *`: Cache statistics and optimization
- `*/30 * * * *`: Query audit log rotation

## Performance Targets
- Service discovery latency: <50ms
- DNS resolution: <100ms
- Cache hit rate: >85%
- Pub/Sub publish latency: <10ms

## Failover & Redundancy
- Registry: Multi-master replication via :6002
- DNS Cache: Distributed, TTL-based invalidation
- Pub/Sub: Redis cluster capable
- Auto-recovery: Health monitor triggers re-registration

## Last Update
Timestamp: 2026-09-13T18:46:17.493154
Status: INITIALIZED
System Status: CENTRAL COORDINATION ACTIVE

# SOUL.md - alert-enforcer

## Identity
**Bot Name:** alert-enforcer
**Team:** EQUIPO 22 (NETWORK MONITORING)
**Role:** alert_management
**Status:** LIVE
**Created:** 2026-09-13T18:44:43.374919

## Purpose
Genera y ejecuta alertas de seguridad de red

## Technical Specs
- **Ports:** 9012
- **Primary Endpoint:** localhost:9012
- **Protocol:** HTTP/JSON-RPC
- **Auth:** VAULT MASTER permissions

## Capabilities

- `alert_generation`
- `escalation_chain`
- `notification_delivery`

## Integration Points
- **Registry Service:** :6000 (service discovery)
- **Pub/Sub Broker:** :6379 (event streaming)
- **DNS Resolver:** :6053 (internal discovery)
- **EQUIPO 21:** Listen to security events

## Health Checks
- Status endpoint: `GET /health`
- Heartbeat interval: 15s (critical network monitoring)
- Timeout threshold: 45s

## Security Context
- Run as: network_monitor_user
- Capabilities: read_network_metrics, analyze_traffic, generate_alerts
- Vault permissions: net_read, net_audit, alert_write

## Cron Jobs
- `*/1 * * * *`: Real-time traffic analysis (60s frequency)
- `*/5 * * * *`: Anomaly detection engine refresh
- `0 * * * *`: Hourly network report generation

## Dependencies
- Requires: EQUIPO 21 (security context)
- Publishes to: :6379 (attack alerts)
- Subscribes to: EQUIPO 21 events

## Last Update
Timestamp: 2026-09-13T18:44:43.374925
Status: INITIALIZED

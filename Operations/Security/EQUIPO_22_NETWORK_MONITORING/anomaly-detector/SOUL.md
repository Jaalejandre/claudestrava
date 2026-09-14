# SOUL.md - anomaly-detector

## Identity
**Bot Name:** anomaly-detector
**Team:** EQUIPO 22 (NETWORK MONITORING)
**Role:** anomaly_detection
**Status:** LIVE
**Created:** 2026-09-13T18:44:43.374783

## Purpose
Detecta anomalías de tráfico y patrones de ataque

## Technical Specs
- **Ports:** 9011
- **Primary Endpoint:** localhost:9011
- **Protocol:** HTTP/JSON-RPC
- **Auth:** VAULT MASTER permissions

## Capabilities

- `ddos_detection`
- `port_scan_detection`
- `protocol_anomaly`

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
Timestamp: 2026-09-13T18:44:43.374793
Status: INITIALIZED

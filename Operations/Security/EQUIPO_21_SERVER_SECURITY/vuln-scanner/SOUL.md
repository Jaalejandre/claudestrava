# SOUL.md - vuln-scanner

## Identity
**Bot Name:** vuln-scanner
**Team:** EQUIPO 21 (SERVER SECURITY)
**Role:** vulnerability_detection
**Status:** LIVE
**Created:** 2026-09-13T18:44:18.740975

## Purpose
Escanea vulnerabilidades y 0-days del servidor

## Technical Specs
- **Ports:** 9001
- **Primary Endpoint:** localhost:9001
- **Protocol:** HTTP/JSON-RPC
- **Auth:** VAULT MASTER permissions

## Capabilities

- `scan_0days`
- `cve_detection`
- `severity_ranking`

## Integration Points
- **Registry Service:** :6000 (service discovery)
- **Pub/Sub Broker:** :6379 (event streaming)
- **DNS Resolver:** :6053 (internal discovery)

## Health Checks
- Status endpoint: `GET /health`
- Heartbeat interval: 30s
- Timeout threshold: 60s

## Security Context
- Run as: security_service_user
- Capabilities: read_server_metrics, scan_vulnerabilities, access_patch_db
- Vault permissions: sec_read, sec_audit, sec_write

## Cron Jobs
- `*/5 * * * *`: Continuous vulnerability scanning
- `0 1 * * *`: Daily comprehensive security audit
- `0 3 * * 0`: Weekly compliance report generation

## Last Update
Timestamp: 2026-09-13T18:44:18.740988
Status: INITIALIZED

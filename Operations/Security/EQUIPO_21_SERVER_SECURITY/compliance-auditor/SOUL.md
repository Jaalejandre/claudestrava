# SOUL.md - compliance-auditor

## Identity
**Bot Name:** compliance-auditor
**Team:** EQUIPO 21 (SERVER SECURITY)
**Role:** compliance_check
**Status:** LIVE
**Created:** 2026-09-13T18:44:18.741433

## Purpose
Auditoría de cumplimiento de seguridad

## Technical Specs
- **Ports:** 9004
- **Primary Endpoint:** localhost:9004
- **Protocol:** HTTP/JSON-RPC
- **Auth:** VAULT MASTER permissions

## Capabilities

- `compliance_scan`
- `policy_verification`
- `report_generation`

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
Timestamp: 2026-09-13T18:44:18.741439
Status: INITIALIZED

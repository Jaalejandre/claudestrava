# SOUL.md - ups-monitor

## Identity
**Bot Name:** ups-monitor
**Team:** EQUIPO 23 (UPS MONITORING)
**Role:** ups_status_monitoring
**Status:** LIVE
**Created:** 2026-09-13T18:45:24.015067

## Purpose
Monitorea estado en tiempo real del UPS CyberPower CP1500AVRLCDa

## Hardware Integration
- **Device:** CyberPower CP1500AVRLCDa (USB via NUT driver)
- **Battery Capacity:** 90 min autonomy
- **Connection:** USB (NUT driver enabled)
- **API Protocol:** NUT (Network UPS Tools)

## Technical Specs
- **Ports:** 9020
- **Primary Endpoint:** localhost:9020
- **Protocol:** HTTP/JSON-RPC + NUT driver
- **Auth:** VAULT MASTER permissions

## Capabilities

- `battery_status_read`
- `voltage_monitoring`
- `load_check`

## Integration Points
- **Registry Service:** :6000 (service discovery)
- **Pub/Sub Broker:** :6379 (power event streaming)
- **DNS Resolver:** :6053 (internal discovery)
- **EQUIPO 21 & 22:** Alert integration for power events

## Health Checks
- Status endpoint: `GET /health`
- Battery polling: 10s intervals
- Critical threshold: 15 min battery remaining
- Shutdown trigger: <5 min battery or grid loss

## Security Context
- Run as: power_admin_user
- Capabilities: read_ups_metrics, trigger_shutdown, manage_services
- Vault permissions: power_read, power_write, shutdown_execute

## Cron Jobs
- `*/10 * * * *`: Battery status polling (every 10 seconds via daemon)
- `0 */1 * * *`: Hourly power report (uptime, load, battery health)
- `0 2 * * *`: Daily battery calibration check

## Critical Thresholds
- Battery < 20%: Generate warning alert
- Battery < 10%: Initiate graceful shutdown
- Power loss detected: Immediate notification to EQUIPO 22
- Grid recovery: Resume normal operations

## Last Update
Timestamp: 2026-09-13T18:45:24.015079
Status: INITIALIZED
Hardware Status: AWAITING CONNECTION

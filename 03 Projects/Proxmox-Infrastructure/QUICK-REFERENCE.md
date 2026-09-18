# ProxmoxVE Community Scripts — Quick Reference for José

## Immediately Useful Scripts (CT deployment)

### Monitoring Stack (Recommended for Phase 4 + L'Étape tracking)
```bash
# Prometheus (metrics collection)
bash /root/proxmox-community-scripts/ct/prometheus.sh

# Grafana (visualization — dashboards for GPU, training metrics)
bash /root/proxmox-community-scripts/ct/grafana.sh

# InfluxDB (time-series database — for Phase 4 convergence trends)
bash /root/proxmox-community-scripts/ct/influxdb.sh
```

### Database (for Phase 4 results archive)
```bash
# PostgreSQL (structured data — convergence logs, timing reports)
bash /root/proxmox-community-scripts/ct/postgresql.sh

# Redis (cache — fast lookups for recent simulations)
bash /root/proxmox-community-scripts/ct/redis.sh
```

### CI/CD (for automated Phase 4 testing + L'Étape sync)
```bash
# Gitea (lightweight Git server — backup for DM UAMI)
bash /root/proxmox-community-scripts/ct/gitea.sh

# Drone CI (lightweight CI/CD — auto-test Phase 4 PRs)
bash /root/proxmox-community-scripts/ct/drone.sh
```

## Deployment Recipe Template

```bash
#!/bin/bash
# 03-monitoring-stack.recipe (store in vault)

set -e

echo "=== Phase 4 Monitoring Stack Setup ==="

# Step 1: Prometheus (CT 120)
echo "Installing Prometheus..."
bash /root/proxmox-community-scripts/ct/prometheus.sh

# Step 2: InfluxDB (CT 121)
echo "Installing InfluxDB..."
bash /root/proxmox-community-scripts/ct/influxdb.sh

# Step 3: Grafana (CT 122)
echo "Installing Grafana..."
bash /root/proxmox-community-scripts/ct/grafana.sh

# Step 4: Configure data sources
echo "Configuring Grafana data sources..."
pct exec 122 -- curl -X POST http://localhost:3000/api/datasources \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Prometheus",
    "type":"prometheus",
    "url":"http://192.168.0.120:9090",
    "access":"proxy",
    "isDefault":true
  }'

echo "✅ Monitoring stack deployed"
echo "Access Grafana at: http://192.168.0.X:3000"
```

## Safety Checklist

- [ ] **Review script** (check for hardcoded values)
- [ ] **Snapshot Proxmox** (before execution)
- [ ] **Allocate resources** (CPU, RAM, disk explicitly)
- [ ] **Run script** (background or foreground?)
- [ ] **Verify service** (health checks, systemctl status)
- [ ] **Document CT ID** (in vault, label in Proxmox)
- [ ] **Setup monitoring** (add to Prometheus/Grafana)
- [ ] **Configure backup** (if stateful service)

## Integration with Hermes

proxmoxve-community-scripts skill triggers:
- `deploy container` → choose script → pre-flight checks → execute
- `setup monitoring` → Prometheus + Grafana stack
- `ci/cd pipeline` → Gitea + Drone stack

## Next Steps

1. **Phase 4 Monitoring** (Prometheus + Grafana for GPU trends)
2. **L'Étape Sync** (InfluxDB time-series for weekly training review)
3. **Git Backup** (Gitea for DM UAMI + EntrenadorL'Étape repos)
4. **CI Testing** (Drone for automated Phase 4 PR validation)


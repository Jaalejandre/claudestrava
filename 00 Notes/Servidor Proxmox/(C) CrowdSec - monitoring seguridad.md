---
tipo: referencia-infra
actualizado: 2026-09-09
proyecto: seguridad-red
---

# CrowdSec — monitoring de seguridad

Instalación y configuración completa de CrowdSec para detección y bloqueo de ataques (SSH brute-force, escaneos, etc.) en el servidor `pve` y CT 109.

## Resumen de despliegue

| Componente                    | Dónde            | Puerto LAPI      | Estado   |
| ----------------------------- | ---------------- | ---------------- | -------- |
| **CrowdSec Agent (host PVE)** | Proxmox VE (pve) | 127.0.0.1:8080   | ✅ active |
| **CrowdSec Agent (CT 109)**   | claude-dev       | 127.0.0.1:8083   | ✅ active |
| **Firewall Bouncer (host)**   | pve              | iptables / ipset | ✅ active |
| **Firewall Bouncer (CT 109)** | claude-dev       | iptables / ipset | ✅ active |

## Whitelist (anti-lockout) — CRÍTICO

En **ambos** nodos hay whitelist que impide banear la LAN local + Mac admin:

```yaml
# /etc/crowdsec/parsers/s02-enrich/whitelists/whitelist-lan.yaml
name: crowdsecurity/whitelist-lan
whitelist:
  reason: "IP local / admin"
  ip:
    - "127.0.0.1"
    - "::1"
  cidr:
    - "192.168.0.0/24"   # incluye Mac (192.168.0.228)
```

> **Nunca borrar/deshabilitar esto** — evita que te bloquees tú mismo del panel Proxmox y del SSH.

## Qué monitorea cada nodo

### Host PVE (pve)
- **fuente**: `journalctl` del servicio `ssh.service`
- **parsers**: `sshd-logs`, `sshd-success-logs`, `syslog-logs`
- **escenarios SSH**: `ssh-bf`, `ssh-bf_user-enum`, `ssh-slow-bf`, `ssh-time-based-bf` (y variantes)
- **firewall**: `CROWDSEC_CHAIN` en iptables + ipset `crowdsec-blacklists-0` (convive con PVEFW)

### CT 109 (claude-dev)
- **fuente**: `/var/log/auth.log` (propio CT) + logs de Samba y postfix
- **parsers**: `sshd-logs`, `smb-logs`, `postfix-logs`, `syslog-logs`
- **escenarios SSH**: mismos + `ssh-time-based-bf`
- **firewall**: `CROWDSEC_CHAIN` en iptables + ipset `crowdsec-blacklists-0`

## Comandos útiles (correr en cada nodo)

```bash
# Estado
systemctl is-active crowdsec crowdsec-firewall-bouncer

# Ver alertas y decisiones activas
cscli alerts list
cscli decisions list

# Ver bouncers registrados
cscli bouncers list

# Métricas de procesamiento
cscli metrics

# Probar un log sin escribir en disco
echo "Sep 9 04:50:01 pve sshd-session[12345]: Failed password for invalid user admin from 198.51.100.42 port 55555 ssh2" | cscli explain --type syslog

# Añadir ban manual (para test)
cscli decisions add --ip 203.0.113.99 --reason "test-manual" --duration 5m
cscli decisions delete --id <id>

# Ver ipset y reglas de firewall
ipset list crowdsec-blacklists-0
iptables -L CROWDSEC_CHAIN -n
```

## Configuración clave

| Archivo | Qué hace |
|---|---|
| `/etc/crowdsec/config.yaml` | LAPI server, trusted_ips, Prometheus |
| `/etc/crowdsec/acquis.yaml` | Fuentes de logs (journald en host, files en CT 109) |
| `/etc/crowdsec/local_api_credentials.yaml` | API key del watcher local |
| `/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml` | API key del bouncer + URL LAPI |
| `/etc/crowdsec/parsers/s02-enrich/whitelists/whitelist-lan.yaml` | **Whitelist LAN** — nunca tocar |

## Puertos LAPI (no confundir)

| Nodo | Puerto | Proceso |
|---|---|---|
| **pve (host)** | 8080 | CrowdSec LAPI + bouncer |
| **CT 109** | 8083 | CrowdSec LAPI + bouncer (movido de 8080 por conflicto con `bifrost` de OmniRoute) |

## Consola web (opcional, gratis)

Dashboard visual en `https://app.crowdsec.net`:

```bash
# En cualquier nodo
cscli console enroll <token>
```

Requiere crear cuenta en crowdsec.net y pegar el token.

## Verificación end-to-end

Probado en ambos nodos:

1. **Inyección de 8 intentos fallidos SSH** → alerta `crowdsecurity/ssh-bf` → decisión ban 4h
2. **Ban manual vía cscli** → ipset creado → DROP en `CROWDSEC_CHAIN`
3. **Whitelist probada**: IP `192.168.0.228` (Mac) + `192.168.0.0/24` nunca se banea

## Pendientes / Mejoras

- [ ] Consola web (`app.crowdsec.net`) — enrollar token
- [ ] Parser de nginx para CT 100 (NPM) — detectar escaneos web
- [ ] Alertas por ntfy/Telegram cuando CrowdSec banea algo
- [ ] Revisar parsers de Docker (para CT 111/112/115/400)
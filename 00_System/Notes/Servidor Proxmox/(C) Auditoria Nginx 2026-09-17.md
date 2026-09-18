# 🔍 Auditoría Nginx — SatanZote AI

**Fecha:** 2026-09-17 12:31  
**Estado General:** ⚠️ PARCIALMENTE CONTROLADO (hay redundancia no documentada, necesita limpieza)

---

## 1. INFRAESTRUCTURA ACTUAL

### Nginx Corriendo (CT 109 — Proxmox Host)
- **Versión:** `nginx/1.26.3` (Sistema Debian)
- **Estado:** `active (running)` — 1 día 9 horas
- **Usuarios:** `www-data` (workers)
- **Memoria:** 16.5 MB actual, pico 42.7 MB
- **Worker Processes:** `auto` (detecta CPU cores)
- **Worker Connections:** 768 (por defecto, bajo para producción)

### Procesos Nginx Activos
```
Master (root, PID 3312144) → 1 worker
Master (www-data, PID 2169...) → ~20 workers (OpenResty fantasma o legacy?)
Master (www-data, PID 17267) → ~20 workers (Duplicado)
```

**PROBLEMA CRÍTICO:** 2+ maestros Nginx con múltiples workers compartiendo los mismos puertos. Esto causa:
- Contención de puerto (ambos escuchan :80, :20128)
- Comportamiento impredecible en failover
- Consumo de memoria duplicado
- Conflicto en recargas (`nginx -s reload` puede afectar múltiples procesos)

---

## 2. CONFIGURACIÓN

### Sitio 1: `default` (Puerto 80)
**Propósito:** Proxy reverso general  
**Upstream:** `http://127.0.0.1:8000`

```nginx
server {
    listen 80;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
    }
}
```

**Estado:** ✅ Bien configurado (headers proxy correctos, reuso de conexión)  
**Faltante:** Sin timeout, sin retry logic, sin rate limit

### Sitio 2: `omniroute-proxy` (Puerto 20128)
**Propósito:** Proxy hacia OmniRoute (gateway LLM)  
**Upstream:** `http://192.168.0.64:20128` (Tailscale + LAN)

```nginx
upstream omniroute_backend {
    server 192.168.0.64:20128;
}

server {
    listen 100.85.38.121:20128;  # Tailscale IP
    server_name omniroute.tailscale;
    location / {
        proxy_pass http://omniroute_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto http;
    }
}

server {
    listen 192.168.0.52:20128;   # LAN directo
    server_name omniroute.local;
    location / {
        proxy_pass http://omniroute_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**Estado:** ✅ Funcional (OmniRoute responde `/dashboard`)  
**Faltante:** Inconsistencia en headers (Tailscale incluye Proto, LAN no), sin health check, sin retry en CT 109

---

## 3. DIAGNÓSTICO DETALLADO

| Dimensión | Estado | Nota |
| --- | --- | --- |
| **Versión** | ✅ Moderna | 1.26.3 (2026-09 release) |
| **Startup** | ✅ Systemd | `nginx.service` enabled, auto-start OK |
| **SSL/TLS** | ✅ Correcto | TLS 1.2/1.3 configurado, SSLv3/TLS 1.0 deshabilitado |
| **Compresión** | ✅ Activo | gzip on (pero sin `gzip_types` — usa default) |
| **Seguridad** | ✅ Decente | `server_tokens off`, HTTPS headers presente |
| **Múltiples Maestros** | ❌ CRÍTICO | 2+ procesos master escuchando mismo puerto |
| **Worker Connections** | ⚠️ Bajo | 768 = ~15k conexiones máximo (OK para laboratorio, insuficiente para prod) |
| **Logging** | ⚠️ Genérico | Access/error logs en archivo, sin rotación visible, sin structured logging |
| **Rate Limiting** | ❌ Ausente | Sin `limit_req`, expuesto a brute-force en endpoints |
| **Health Checks** | ❌ Ausente | Sin `proxy_cache`, sin validación de upstream activo |
| **Timeouts** | ❌ Ausente | Sin `proxy_connect_timeout`, `proxy_read_timeout` |
| **Caching** | ❌ Ausente | Sin directivas `proxy_cache_*`, cada request toca el backend |

---

## 4. NGINX vs CLOUDFLARE: MATRIZ DE DECISIÓN

| Criterio | Nginx (On-Prem) | Cloudflare | Juicio |
| --- | --- | --- | --- |
| **Costo** | ~$0 (ya instalado) | $0 (free) o $20-200/mes (plan) | **TIE** (free ambos, pero Nginx =0 marginal) |
| **Control** | 100% (tu máquina) | ~70% (API limitada, policy dependiente) | **Nginx** ✅ |
| **Latencia** | ~5-10ms local LAN | ~50-100ms (redrección global) | **Nginx** ✅ (LAN es crítico) |
| **DDoS Protection** | Manual (fail2ban, iptables) | Automático (gestión de tráfico) | **Cloudflare** ✅ |
| **SSL/TLS** | Manual (Let's Encrypt) | Automático + renewals | **Cloudflare** ✅ |
| **WAF** | No (nginx solo proxy) | Sí (rules, rate limit, bot protect) | **Cloudflare** ✅ |
| **DNS** | No (usa OS resolver) | Sí (Cloudflare nameserver) | **Cloudflare** ✅ |
| **Uptime** | Depende de CT 109 | 99.99% SLA | **Cloudflare** ✅ |
| **Complejidad Ops** | Alta (config manual) | Baja (dashboard) | **Cloudflare** ✅ |
| **Para GromacsMexicano** | N/A (CT 901, CUDA) | N/A (no es web) | — |
| **Para Claude Strava** | ✅ OK (interno) | ⚠️ Posible (solo web) | **Nginx** ✅ |
| **Para airbnb-admin** | ✅ Bueno | ✅ Mejor (WAF + bot block) | **Depende spec** |

---

## 5. RECOMENDACIÓN INMEDIATA

### Paso 1: Limpiar Redundancia (URGENTE)
```bash
# Identificar qué maestro es "real"
ps aux | grep nginx | grep master

# Matar todos salvo el de systemd
killall nginx  # O kill -9 <PID de maestros legacy>
systemctl restart nginx
systemctl status nginx
```

### Paso 2: Reforzar Configuración
Editar `/etc/nginx/nginx.conf` + `/etc/nginx/sites-available/*`:

```nginx
# http block
worker_connections 4096;  # Aumentar para más concurrencia

# Dentro de server blocks
# Agregar timeouts
proxy_connect_timeout 10s;
proxy_read_timeout 30s;
proxy_send_timeout 30s;

# Rate limiting (por IP)
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
location /api/ {
    limit_req zone=api_limit burst=20;
    proxy_pass http://backend;
}

# Health check para upstream
upstream backend {
    server 127.0.0.1:8000 max_fails=3 fail_timeout=30s;
}
```

### Paso 3: Decidir Nginx vs Cloudflare
- **Mantener Nginx si:** Control total, latencia LAN es crítica, no necesitas DDoS global
- **Migrar a Cloudflare si:** Necesitas WAF + DDoS + SSL management automático (y DNS apunta a CF)

**Para tu caso (SatanZote):**
- **OmniRoute (LAN):** Mantener Nginx (local, bajo latency)
- **airbnb-admin (HTTP público):** Considerar Cloudflare (WAF, bot protection, uptime)
- **Claude Strava (interno):** Nginx es suficiente

---

## 6. CHECKLIST DE ORDEN

- [ ] Limpiar procesos Nginx duplicados → `killall nginx && systemctl restart nginx`
- [ ] Validar único master corriendo → `ps aux | grep -E "nginx: master"`
- [ ] Aumentar `worker_connections` a 4096 (mínimo prod)
- [ ] Agregar `proxy_*_timeout` a ambos sitios
- [ ] Documentar backend upstreams en nota (¿qué es 8000, 20128?)
- [ ] Configurar log rotation (logrotate)
- [ ] Monitorear error.log por anomalías
- [ ] Backup config a git (si no lo está)
- [ ] Decidir: Cloudflare solo para DNS + origen en Nginx, o dejar todo Nginx

---

## 7. ARCHIVOS A REVISAR / CREAR

```
CT 109:/etc/nginx/
├── nginx.conf                    ← Base (OK)
├── conf.d/                       ← Vacío (OK)
├── sites-available/
│   ├── default                   ← Puerto 80, upstream :8000
│   └── omniroute-proxy           ← Puerto 20128, upstream 192.168.0.64
└── sites-enabled/
    ├── default (→ sites-available/default)
    └── omniroute-proxy (→ sites-available/omniroute-proxy)
```

**Siguiente paso:** ¿Crear `(C) Nginx Config v2` con mejoras aplicadas? ¿O primero decidimos Cloudflare?


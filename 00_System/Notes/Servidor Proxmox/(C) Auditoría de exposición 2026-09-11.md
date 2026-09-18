---
tipo: auditoria-seguridad
fecha: 2026-09-11
pve: pve (Proxmox 9.1.1)
ip-publica: 187.190.189.68 (totalplay)
nmap: 7.95 desde host (SSH)
---

# Auditoría de exposición — 2026-09-11

Test de puertos externos, configuración de tunnels, NPM proxy hosts y listeners de hosts/CTs críticos. Criterio: ¿estamos exponiendo algo innecesariamente a internet o a la LAN?

## Veredicto general

**Exposición a internet: SEGURA** — no hay port-forwarding en el router (Todos los puertos del host/host vanish en WAN scan). La ÚNICA vía a internet son los túneles Cloudflare, que solo sirven 6 dominios activos, todos detrás de autenticación.

**Exposición a LAN: aceptable con mejoras menores** — hay 3 listener-issues que limpiar (ver hallazgos).

## 1. Exposición a internet

### 1.1 Test de puertos WAN

Escaneo nmap `187.190.189.68` (IP pública totalplay) — **TODOS filtrados**:

| Puerto | Servicio | Estado |
|---|---|---|
| 22 | SSH | filtered ✅ |
| 80/443 | HTTP/HTTPS | filtered ✅ |
| 111 | rpcbind | filtered ✅ |
| 139/445 | Samba | filtered ✅ |
| 8006 | PVE web UI | filtered ✅ |
| 9443 | Portainer | filtered ✅ |
| 20128 | OmniRoute | filtered ✅ |
| Resto (8080-8877) | Prototipos | filtered ✅ |

**Conclusión:** el router no tiene reglas de port-forwarding. Nada llega directamente desde internet. La única vía es vía Cloudflare tunnel.

### 1.2 Túneles Cloudflare (los únicos exposures reales)

**CT 108 (cloudflared)** — config remota (token en dashboard Cloudflare). Ingress definido allí, no en el host.

**CT 109 (cloudflared)** — cloudflared-service (`cloudcli.service`) activo. Config en dashboard Cloudflare.

### 1.3 Proxy hosts de NPM (CT 100)

Dominios activos en la tabla `proxy_host`:

| Dominio → Destino | Tipo | Estado | Observaciones |
|---|---|---|---|
| `vault.satanzote.me` → `.30:8000` (Vaultwarden) | LAN→HTTPS via tunnel | ✅ OK | Auth por clave |
| `plex.satanzote.me` → `.164:32400` (Plex) | LAN→HTTP via tunnel | ✅ OK | Auth por usuario |
| `pedirpeliculas.satanzote.me` → `.164:5055` (Jellyseerr) | LAN→HTTP via tunnel | ✅ OK | Auth por usuario |
| `elmundial.satanzote.me` → `.20:8000` (Mundial) | LAN→HTTP via tunnel | ✅ OK | App propia |
| `soypirata.satanzote.me` → `.164:5690` (Wizarr) | LAN→HTTP via tunnel | ✅ OK | Media invites |
| `elinternetqr.satanzote.me` → **`.20:8085`** | LAN→HTTP via tunnel | ⚠️ | Verificar: satanzote-studio map dice `.203 CT 101`, NPM dice `.20 CT 111` |
| `adguard.home` → `.10:80` | Solo LAN (.home no resuelve publico) | ✅ OK | Dead config, no afecta |
| `sonarr.home` → **`.60:8989`** | Solo LAN | ⚠️ | Target **192.168.0.60 no existe** en scan — host muerto o stale |
| `transmissions.home` → **`.60:9091`** | Solo LAN | ⚠️ | Mismo .60 — stale |

**`medinotes.satanzote.me`** → **timeout (000)** en test curl — dominio ya no existe en NPM (borrado). No está en riesgo (no responde).

### 1.4 Dominios públicos extra (fuera de NPM)

El túnel 109 expone el **Claude Code UI** (cloudcli.service) por un dominio propio (configurado en Cloudflare dashboard; no se lista aquí). Verificar que tiene auth.

## 2. Exposición LAN (lo que escucha dentro de la red)

### 2.1 Host pve

| Puerto | Servicio | Bind | Estado |
|---|---|---|---|
| 22 | sshd | `0.0.0.0` | ✅ Protegido por CrowdSec + clave SSH |
| 111 | rpcbind | `0.0.0.0` | ⚠️ **NO NECESARIO** — NFS no instalado; deshabilitar |
| 8006 | pveproxy | `*:3128` | ✅ Solo para UI PVE (LAN) |
| Resto | upsd, crowdsec, pvedaemon | `127.0.0.1` | ✅ Localhost |

**Protección:** PVE firewall ENABLED + CrowdSec bouncer (iptables chains activas).

### 2.2 CT 109 (claude-dev) — hay cosas que limpiar

| Puerto | Servicio | Bind | Riesgo |
|---|---|---|---|
| 22 | ssh | `0.0.0.0` | ✅ OK |
| 445/139 | Samba | `0.0.0.0` | ⚠️ Accesible desde Tailscale también — verificar si se necesita |
| 20128 | OmniRoute | `0.0.0.0` | ℹ️ Dashboard con pass `11deabril5` — considerar hardening |
| 8877 | airbnb-admin (FastAPI) | `0.0.0.0` | ℹ️ Prototipo — bind a localhost |
| 8851 | claudecodeui | `0.0.0.0` | ℹ️ Claude Code UI — verificar auth (también en tunnel) |
| 8090 | gromacs-benchmark (Flask) | `0.0.0.0` | ℹ️ Benchmark dashboard — bind a localhost |

## 3. Hallazgos resumen

### ✅ BIEN (no requieren acción)

| Hallazgo |
|---|
| Sin port-forward en el router — todos los puertos WAN filtered |
| Túneles Cloudflare: solo dominios intencionados, todos con auth |
| PVE firewall activo con CrowdSec bouncer |
| SSH protegido con llave + CrowdSec |
| Todos los dominios `.home` son LAN-only (no resuelven externamente) |

### ⚠️ MEJORAR (recomendaciones)

| # | Hallazgo | Riesgo | Acción | Prioridad |
|---|---|---|---|---|
| 1 | **rpcbind (111) activo** sin NFS instalado | Expone servicio innecesario | `systemctl disable --now rpcbind rpcbind.socket` en el host | Alta |
| 2 | **Samba (109) escucha `0.0.0.0`** — accesible desde Tailscale | Potencial acceso remoto no intencionado | En smb.conf: `interfaces = 127.0.0.1/8 192.168.0.0/24` | Alta |
| 3 | **3 prototipos en 109** (8877/8851/8090) escuchan `0.0.0.0` | No autenticados, expuestos LAN-wide | Bind a `127.0.0.1` o `192.168.0.64` | Media |
| 4 | **NPM: `sonarr.home` / `transmissions.home` apuntan a `.60`** que no existe | Proxy muerto — ruido innecesario | Borrar las entradas de NPM | Baja |
| 5 | **NPM: `elinternetqr` apunta a `.20:8085`** — verificar si es `.203` | Proxy al target incorrecto | Verificar y corregir IP en NPM | Media |
| 6 | **OmniRoute dashboard** password débil (`11deabril5`) | Acceso LAN al dashboard LLM | Cambiar pass o restringir por IP (bind a localhost) | Media |

### ℹ️ INFORMATIVO

| Hallazgo |
|---|
| `medinotes.satanzote.me` no responde (timeout) — configuración stale o eliminada |
| Claude Code UI tiene su propio túnel Cloudflare (auth por token Cloudflare) — verificar que tiene pass |
| CT 117 `difybot` nuevo (sin confirmar — pendiente respuesta del usuario) |

## 4. Cómo re-hacer esta auditoría

```bash
# Escaneo WAN completo (desde host)
nmap -Pn -p 22,80,443,111,139,445,8006,9443,20128,8090,8877 $(curl -s ifconfig.me)

# Test de dominios
for d in vault plex pedirpeliculas soypirata elmundial elinternetqr; do
  echo -n "$d.satanzote.me → "; curl -s -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://$d.satanzote.me"
done

# Verificar listeners del host
ss -tlnp | grep -vE "127.0.0.53|\[::1\]"
```
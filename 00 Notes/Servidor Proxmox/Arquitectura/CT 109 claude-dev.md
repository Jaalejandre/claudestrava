---
contenedor: 109
nombre: claude-dev
ip: 192.168.0.64
so: Debian 13 (trixie)
servicios: OmniRoute, Samba, telegram-bridge, cloudcli, proto-airbnb-admin, Docker
puertos: 20128, 20130-32, 3456, 8080, 8317, 3001, 8877, 139/445
proyectos: vault SatanZote AI, OmniRoute, prototipos
gpu: RTX 5070 Ti (passthrough, no usada)
actualizado: 2026-09-08
---

# CT 109 — claude-dev (.64) — nodo de IA

**El nodo de IA.** Aquí vive físicamente el vault [[SatanZote AI]] (`/root/JarvisVault`), OmniRoute y los puentes de comunicaciones.

## Qué corre
| Servicio | Puerto | Qué hace |
|---|---|---|
| `omniroute.service` | **20128** | **OmniRoute** — gateway LLM, tokens. Internos :20131/:20132 |
| └ `dario` (node) | 3456 | proxy interno de OmniRoute |
| └ `bifrost` v1.6.3 | 8080 | proxy HTTP interno de OmniRoute |
| └ `cliproxyapi` | 8317 | proxy CLI de OmniRoute |
| `smbd.service` | 139/445 | Samba — comparte `[JarvisVault]` |
| `telegram-bridge.service` | 3001 | puente Telegram ↔ Claude Code |
| `cloudcli.service` | — | claudecodeui (front web) |
| `proto-airbnb-admin.service` | 8877 | dashboard prototipo `airbnb-admin` (uvicorn) |
| `docker` + `containerd` | — | instalado, sin contenedores activos |
| `crowdsec` | 8083 (LAPI) | **CrowdSec agent** — monitoring SSH/Samba/postfix |
| `crowdsec-firewall-bouncer` | — | bouncer iptables → `CROWDSEC_CHAIN` + ipset `crowdsec-blacklists-0` |

## Proyectos / rutas
- `/root/JarvisVault` — **el vault** (montado por SMB en la Mac)
- `/root/.omniroute` — gateway + servicios (`dario`, `bifrost`, `cliproxy`, configs)
- `/project/` — `telegram-bridge`, `prototipos/` (harness.py), `ruflo` (retirado)
- `/root/go` — workspace Go

## Conexiones
- **Samba** → la Mac monta el vault
- **tokens LLM**: [[CT 901 ubuntu]] (Claude Code) y [[CT 103 openwebui]] enrutan por OmniRoute
- **Telegram**: canal de entrada para proyectos
- **NPM**: [[CT 100 nginxproxymanager]] expone el UI de Claude Code (túnel propio en :20241)
- **GPU**: passthrough RTX 5070 Ti asignado pero **sin uso real** (candidato a quitarse)

## Notas
- Redundancia #5 del mapa: quitar passthrough GPU de aquí (no depende de CUDA).
- Todos los componentes de OmniRoute viven en `/root/.omniroute`.

## Seguridad (CrowdSec)
- **Agent**: LAPI en 127.0.0.1:8083 (movido de 8080 por conflicto con `bifrost`)
- **Bouncer**: iptables + ipset `crowdsec-blacklists-0` → `CROWDSEC_CHAIN`
- **Whitelist**: `192.168.0.0/24` + localhost — anti-lockout para Mac y LAN
- **Monitorea**: SSH (auth.log), Samba, postfix
- **Ver**: [[(C) CrowdSec - monitoring seguridad]]
# (C) Reglas por LXC — el lugar de cada cosa

> Definido: 2026-09-12 · resultado de la auditoría en vivo del mismo día.
> Complementa [[(C) Mapa del servidor pve]] y [[(C) OmniRoute - arquitectura y routing]].
> **Regla de oro:** todo servicio/credencial/script tiene UN solo lugar. Si algo no cumple, se mueve.

## Principios

1. **Un LXC = un rol.** No mezclar roles; si hay conflicto, se crea contenedor o se mueve el servicio.
2. **El tráfico LLM pasa por OmniRoute (CT 109).** Nadie llama un provider directo.
3. **Las credenciales viven en VaultWarden (CT 114).** Los `.env` dispersos se consolidan ahí (con backup local en cada CT).
4. **Un contenedor controlador (`CT 118 control`) gobierna todo el stack** vía SSH keys — sin entrar a cada CT manualmente.
5. **El vault es el mapa.** El mapa del servidor se actualiza en cada cambio.
6. **Nada se instala suelto:** systemd o Docker Compose, siempre versionado en el vault.

## Tabla de reglas por LXC

| CT | Nombre | Rol (UNO) | Qué vive aquí | Qué NO vive aquí (mover) | IP |
|---|---|---|---|---|---|
| 100 | nginxproxymanager | Reverse proxy | NPM :80/:81/:443 | Nada más | .109 |
| 101 | debian | Apps Docker legacy | `enlinea-saas` :8091, `satanzote-studio` :8085 | — | .203 |
| 102 | uptimekuma | Monitoreo uptime | Uptime Kuma :3001 | — | .216 |
| 103 | openwebui | **LLM local (GPU)** | Ollama :11434 + OpenWebUI :8080; modelos en `nvme-fast` | Nada de cloud | .99 |
| 104 | adguard | DNS LAN | AdGuard :53/:80 | — | .10 |
| 105 | unbound | Resolver recursivo | Unbound :5335 | — | .11 |
| 107 | docker | Portainer (gestión Docker) | Portainer CE :9443 | — | .61 |
| 108 | cloudflared | Túnel a internet | Cloudflare Tunnel | — | .12 |
| 109 | claude-dev | **Nodo IA / gateway** | Vault (Samba), OmniRoute :20128, Hermes, telegram-bridge, cloudcli | ❌ airbnb-admin, confirma-citas, gromacs-benchmark → **mover a CT 112** | .64 |
| 110 | n8n | Automatización workflows | n8n :5678 | — | .13 |
| 111 | apps-prod | Apps en producción | mundial, nextcloud, guacamole, mint-portal, qr-counter | ❌ airbnb-admin-app :8877 → **coordinar con CT 109/112** (3 instancias!) | .20 |
| 112 | app-dev | Apps desarrollo/test | airbnb-admin (única instancia, :8097), airbnb-dashboard, gpu-top | ❌ gpu-top (CT 112 no tiene GPU) → **eliminar** | .21 |
| 113 | rclone | Backup offsite | rclone-web :3000, monta `/mnt/backups` | — | .32 |
| 114 | vaultwarden | **Gestor de contraseñas** | Vaultwarden HTTPS :8000 | — | .30 |
| 115 | debmediav2 | Stack de media | 19 contenedores Docker (Plex/arr/…) | — | .164 |
| 116 | ntfy | Alertas de sistema | ntfy :80 | — | .179 |
| 117 | difybot | ⚠️ **Dify (agente LLM)** | Dify 1.17.1 (nginx :80/:443, api, web, agent, postgres) | ⚠️ sin IP fija, sin onboot — **regularizar** | .14 (dhcp) |
| 400 | medinotes | SaaS notas médicas | medinotes (nginx/backend/postgres/redis) | — | .132 |
| 901 | ubuntu | **GromacsMexicano (GPU)** | Programa_DM (ref congelada), rewrite C++, BASE, gpu-api :5000 | ❌ uvicorn :8877 no documentado → **identificar** | .230 |
| 118 | control | **Controlador (NUEVO)** | SSH keys → todo el stack, scripts deploy | — | .?? |

## Discrepancias detectadas en la auditoría (2026-09-12)

### 1. Triple instancia de airbnb-admin ❌
- CT 109: `airbnb-admin.service` systemd :8877 (vivo, con auto-sync)
- CT 111: `airbnb-admin-app` Docker :8877
- CT 112: `airbnb-admin-app` Docker :8097
**Decisión:** la instancia canónica vive en **CT 109** (la más completa: auto-sync, CLEANING_LOG, DIAS_SEMANA — verificada el 11-sep). Las otras dos son herederas del piloto CT 112 / prod CT 111. **Se elige CT 109 como única** y se apagan CT 111/112 (o se deja la de CT 112 como nueva canónica post-migración — decidir con el usuario).

### 2. CT 117 `difybot` — ✅ REGULARIZADO 2026-09-12
- IP fija `.14` + `onboot 1` (antes DHCP sin onboot — hubiera muerto en reinicio). Dify 1.17.1 con 15 contenedores funcionando (HTTP 200).
- Pendiente: confirmar propósito con el usuario (¿lo creó él o un agente?).

### 3. Swap alto otra vez ⚠️
- 7.1/8.1 GB en uso. Diagnóstico 2026-09-12: por cgroup → **CT 115 (2.0 GB)** — media con 19 contenedores en 6 GB; **CT 109 (1.26 GB)** — OmniRoute/Hermes; **CT 103 (511 MB)** — Ollama en reposo. El resto trivial.
- **Decisión:** mantener (swappiness 10 evita thrashing). Si CT 115 empeora → +1 GB RAM. Documentado.

### 4. uvicorn :8877 en CT 901 — ✅ IDENTIFICADO 2026-09-12
- Es **EntrenadorLEtape** (`src.plan_api:app`, `/home/alejandre/EntrenadorLEtape/`) — API del entrenador de la L'Étape. Legítimo, documentado en el mapa.

### 5. `gpu-top` en CT 112 — ✅ ELIMINADO 2026-09-12
- Desactivado (`systemctl disable --now gpu-top.service`), puerto :8095 libre. Código queda en `/opt/gpu-top` (backup). `gpu-api` CT 901 es el único canónico.

### 6. CT 114 VaultWarden sin consolidar
- Las credenciales yacen en `.env` dispersos: CT 109 (omniroute, hermes, telegram-bridge), CT 111 (worldcup-prod, airbnb-admin), CT 901 (EntrenadorLEtape), CT 103 (/root/.env), CT 114 (vaultwarden propio).
- **Decisión:** crear cuenta/items en VaultWarden por servicio, con referencia en el vault. Los `.env` se quedan (necesarios para runtime) pero centralizados en el controlador para backup.

## Flujo de cambio

1. Detectar algo fuera de su lugar → nota temporal.
2. Actualizar esta tabla + [[(C) Mapa del servidor pve]].
3. Mover con script del controlador ([[CT 118 control]]), verificar servicio, actualizar mapa.
4. Lo viejo se apaga (nunca se borra sin backup).

## Pendientes con el usuario

- [ ] **VaultWarden**: el ADMIN_TOKEN está vacío — pedir credenciales de cuenta (o que el usuario genere token) para crear la colección "Servidor" y subir items. Contenido preparado: OmniRoute (gateway key), Hermes, airbnb-admin, Gromacs/gpu-api, EntrenadorLEtape, telegram-bridge, mundo-prod, medinotes, vaultwarden propio.
- [ ] ¿CT 117 Dify: propósito? (regularizado, se queda)
- [ ] airbnb-admin: mergear fix Starlette de CT 112 (`db1f0fbc`) en CT 109 canónica (`182353d9`) — tarea del pipeline de prototipos (spec v4 pendiente).
- [ ] Documentar CT 118 en el chequeo diario / mapa de red LAN.
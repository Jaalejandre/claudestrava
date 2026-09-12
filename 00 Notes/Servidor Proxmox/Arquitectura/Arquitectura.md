---
tipo: moc
tema: arquitectura-servidor
actualizado: 2026-09-09
fuente: barrido en vivo por SSH 2026-09-08 + "(C) Mapa del servidor pve"
---

# Arquitectura del servidor `pve`

Mapa de contenido (MOC) de la topología: qué corre en cada CT/VM y cómo se conectan. Cada nodo es una nota — **abre el Graph View filtrado a esta carpeta para ver la topología como grafo**.

- Datos a nivel host: [[(C) Mapa del servidor pve]]
- **Topología de la red LAN (todos los dispositivos)**: [[(C) Mapa de red LAN]]
- Detalle de tecnologías: [[(C) Tecnologías y proyectos por contenedor]]
- **Seguridad (CrowdSec)**: [[(C) CrowdSec - monitoring seguridad]]

## Topología general

```mermaid
flowchart LR
    subgraph Internet
        CF[Cloudflare]
    end
    subgraph "Proxmox pve (192.168.0.52)"
        subgraph "Capa entrada"
            T[CT 108 <br/>cloudflared<br/>:20241]
            NPM[CT 100 <br/>Nginx Proxy Manager<br/>:80/:81/:443]
            DNS[CT 104 <br/>AdGuard :53]
            R[CT 105 <br/>Unbound :5335]
        end
        subgraph "Nodo IA"
            IA[CT 109 <br/>claude-dev<br/>OmniRoute Samba Claude]
            CS1[CT 109 <br/>CrowdSec :8083<br/>Bouncer iptables]
        end
        subgraph "Host PVE"
            CS0[pve <br/>CrowdSec :8080<br/>Bouncer iptables]
        end
        subgraph "Apps prod"
            P[CT 111 <br/>apps-prod<br/>mundial nextcloud guac]
        end
        subgraph "Apps dev"
            D[CT 112 <br/>app-dev<br/>mundial-dev airbnb]
        end
        subgraph "Media"
            M[CT 115 <br/>debmediav2<br/>Plex + arr]
        end
        subgraph "Otros servicios"
            VW[CT 114 vaultwarden]
            K[CT 102 uptime-kuma]
            N8[CT 110 n8n]
            NTF[CT 116 ntfy]
            MD[CT 400 medinotes]
            RCL[CT 113 rclone]
            PT[CT 107 portainer]
            OW[CT 103 openwebui<br/>Ollama GPU]
            GX[CT 901 ubuntu<br/>GromacsMexicano GPU]
        end
    end
    CF -->|tunnel| T
    T --> NPM
    NPM -->|vault.satanzote.me| VW
    NPM -->|elmundial.satanzote.me| P
    NPM -->|plex / pedirpeliculas| M
    NPM -->|medinotes| MD
    DNS --> R
    IA -->|tokens LLM| NPM
    GX -->|Claude Code / OmniRoute| IA
    OW -.->|LLM local| IA
    PT -.->|docker API| P
    PT -.->|docker API| D
    RCL -.->|backups| P
    CS1 -->|monitorea auth.log| IA
    CS0 -.->|monitorea ssh.service| CS1
```

## Tabla de nodos

| CT | Nota | IP | Rol |
|---|---|---|---|
| 100 | [[CT 100 nginxproxymanager]] | .109 | Reverse proxy |
| 101 | [[CT 101 debian]] | .203 | Docker apps legacy |
| 102 | [[CT 102 uptimekuma]] | .216 | Monitoreo |
| 103 | [[CT 103 openwebui]] | .99 | LLM local (GPU) |
| 104 | [[CT 104 adguard]] | .10 | DNS LAN |
| 105 | [[CT 105 unbound]] | .11 | Resolver recursivo |
| 107 | [[CT 107 docker]] | .61 | Portainer |
| 108 | [[CT 108 cloudflared]] | .12 | Tunnel a internet |
| 109 | [[CT 109 claude-dev]] | .64 | Nodo de IA (vault, OmniRoute) |
| 110 | [[CT 110 n8n]] | .13 | Automatización |
| 111 | [[CT 111 apps-prod]] | .20 | Apps producción |
| 112 | [[CT 112 app-dev]] | .21 | Apps desarrollo/test |
| 113 | [[CT 113 rclone]] | .32 | Sync a nube |
| — | [[(C) CrowdSec - monitoring seguridad]] | — | Seguridad (host + CT 109) |
| 114 | [[CT 114 vaultwarden]] | .30 | Gestor de contraseñas |
| 115 | [[CT 115 debmediav2]] | .164 | Stack de media |
| 116 | [[CT 116 ntfy]] | .179 | Alertas sistema |
| 400 | [[CT 400 medinotes]] | .132 | SaaS notas médicas |
| 901 | [[CT 901 ubuntu]] | .230 | GromacsMexicano (GPU) |

VM:

| VM | Nota | Rol |
|---|---|---|
| 106 | [[VM 106 haos]] | Home Assistant |
| 200 | [[VM 200 debian-brain]] | Sin identificar ⚠️ |

## Fechas de verificación

- **2026-09-08** — barrido en vivo completo (systemd + docker + puertos + carpetas en todos los CTs). Datos volcados en [[(C) Tecnologías y proyectos por contenedor]].
- Se desactualiza — antes de operaciones, verificar en vivo vía `ssh root@192.168.0.52`.
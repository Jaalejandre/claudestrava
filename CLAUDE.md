# SatanZote AI — Operational Journal

This file is the operational hub for SatanZote AI. It tracks infrastructure status, Kanban state, and daily TODOs. 

## 1. Governance & Protocol
- **Identity & Directives:** Permanently defined in `/root/.hermes/SOUL.md`.
- **Identity-Config Segregation Principle:** IT IS FORBIDDEN to mingle identity directives with infrastructure/config data. SOUL.md is ONLY for personality/identity; operational state resides exclusively here in CLAUDE.md, 00_Infra/config files, and ACP manifests.
- **Sources of Truth (Infra):** All configuration (MCPs, plugins, variables, routing protocols) MUST reside in `/root/JarvisVault/00_Infra/(C) mcp_manifest.json` and reflect in `/root/.hermes/acp_config.json`.
- **Operating Philosophy:**
    - Any infrastructure change (MCPs/Plugins/etc.) must be codified in the manifest first.
    - If it's not codified, it doesn't exist.

## 2. Infrastructure Map
```text
SatanZote AI/   (vault — físicamente /root/JarvisVault en CT 109, montado en la Mac)
├── CLAUDE.md              ← You are here
├── GOALS.md               ← Goals, progress, master plan (vacío — pendiente)
├── 00 Notes/
│   └── Servidor Proxmox/  ← mapa del server, UPS, chequeos diarios automáticos
├── 03 Projects/           ← Proyectos individuales
│   ├── Claude Strava/
│   └── DM UAMI/
├── 04 Reviews/            ← Monthly / Quarterly / Yearly / Weekly
└── 05 Skills/             ← brain-setup, new-project, new-dev-project, proxmox, weekly-update
```

## 3. Active Protocols
- **NetRunner:** Network hygiene & firewalls (strict whitelisting).
- **Briefing Protocol:** Auto-runs daily at 09:00 (`/root/scripts/daily_briefing.py`).
- **SRE Audits:** Daily check (`/root/scripts/nightly_sre_audit.sh` + `hermes config check`).

## 4. Current Tasks & Projects
[See Kanban Board at /root/.hermes/kanban.db]
1. **GromacsMexicano:** Status: C++/CUDA Port (CT 901) - Active.
2. **Claude Strava:** Status: Maintenance (Weekly review).
3. **Satanzote Infra:** Migration to clean LXC - Operational.

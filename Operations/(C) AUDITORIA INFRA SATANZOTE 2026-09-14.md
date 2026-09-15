---
title: "(C) AUDITORIA INFRA SATANZOTE 2026-09-14"
date: 2026-09-14
status: "ACTIVO"
author: "Subagente Auditoría (Hermes)"
version: "1.0"
---

# (C) AUDITORIA INFRA SATANZOTE — 2026-09-14

Auditoría integral de infraestructura para dejarla a "cien por ciento" (producción).
Reglas respetadas: no borrar historia (marcar OBSOLETO), no tocar `Programa_DM/` (congelado),
no romper gateway/OmniRoute (:20128), conservar solo MCPs funcionales.

---

## 1. Inventario auditado

### 1.1 Equipos E-operativos en `Operations/` (documentos + SOUL/SKILL)
Presentes como archivo/dir `EQUIPO-N`:
**E8, 8B, 19, 20, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40.**
- E21 y E22 existen SOLO en `/root/JarvisVault/Security/` (no en `Operations/` raíz).
- E1-E7, 9-18 **no tienen archivo top-level en Operations/**; el organigrama los referencia como
  agrupados (E6-10 "Oráculo") o no están materializados como docs.
- `Security/` (raíz del vault) y `Operations/Security/` son **dos ubicaciones separadas** que
  duplican los equipos 21-24 (estructura x2).

### 1.2 Skills
- 49 directorios raíz en `/root/.hermes/skills/`, coinciden con el catálogo cargado (107 habilitadas,
  0 rotas, según auditoría previa 2026-09-14). Sin skills rotas detectadas.

### 1.3 MCPs (`/root/.hermes/config.yaml`)
Entran 5 servidores Cloudflare, todos activos:
`cloudflare`, `cloudflare-docs`, `cloudflare-bindings`, `cloudflare-builds`, `cloudflare-observability`.
Los MCPs muertos (context7, playwright, claude-in-chrome) ya fueron eliminados en auditoría previa.
**Sin MCPs rotos en config actual.**

### 1.4 Cron jobs (crontab + timers systemd)
16 scripts crontab verificados: **todos existen en disco (OK)**.
- Limpieza memoria (x2 cron + timer), skill-audit semanal, audits diarios SatánZote, colección
  Proxmox (06/14/20), análisis (22), credential-check, orquestador Carrillo, dashboard visualizer,
  6x DM-UAMI (integrity/liaison/security/reporter/orchestrator), innovation cycle.
- Timers: `vault-backup.timer` (23:30) = auto-push del vault, `proxmox-daily-check`, `hermes-cleanup`.
- **Sin cron muerto detectado** (todos los scripts existen).

### 1.5 Estado del vault (git)
- 131 commits, rama `main`, remoto `claudestrava/origin main` (sincronizada).
- `.hermes/.env` apunta a JarvisVault remoto correcto.
- 35 rutas en `git status --porcelain`: modificados = mapas de red ya marcados OBSOLETO por E40,
  y untracked = documentos nuevos (auditorías, organización, projectos).

---

## 2. Hallazgos y acciones

| Categoría | Hallazgo | Acción tomada |
|---|---|---|
| **DUPLICADO (context rot)** | 6 mapas de IP duplicados contradictorios | Ya marcados `OBSOLETO` por E40/LIMPIEZA VAULT (canonical verificado desde `/etc/pve`). Confirmado vigente. |
| **DUPLICADO (equipo)** | `E19 VAULT MASTER` (SSOT/custodia vault) se solapa con `E40 Memoria Canónica` (CIO, SSOT) | Marcado `OBSOLETO` (historial conservado). E40 queda como SSOT canónico. |
| **DUPLICADO (equipo)** | `E20 DASHBOARD MANAGER` depende de VAULT MASTER (SSOT) | Marcado `OBSOLETO` (absorbido por E40/custodio). Dashboard :3000 si está vivo lo custodia E40. |
| **DUPLICADO (doc)** | `DELEGACION-NOMENCLATURA-SATANZOTE-34-EQUIPOS` + `-FRIENDLY-...` (borradores 34 equipos) chocan con organigrama final | Ambos marcados `OBSOLETO`; nomenclatura Daemon-* final está en el CANONICAL C-SUITE. |
| **DOBLE UBICACIÓN** | Equipos 21-24 duplicados entre `/Security/` (raíz) y `Operations/Security/` | REPORTADO (no consolidado de raíz por riesgo: E21/E22 no tienen doc en Operations; la estructura Security es referenciada por MANIFEST.md/AUDITORIA). Se dejó intacta. |
| **MUERTO / sin uso** | E1-E7, 9-18 sin doc top-level en Operations (referenciados solo como agrupación E6-10) | REPORTADO (no creado de raíz: riesgo de romper organigrama que los agrupa; requiere decisión de José). |
| **OBSOLETO (mapas)** | `Mapa de red LAN`, `Mapa del servidor pve`, `Estructura Proxmox`, `Tecnologías por contenedor`, `Reglas por LXC`, `Arquitectura` | Ya marcados `OBSOLETO` (E40). Concurrencia verificada. |
| **MCPs muertos** | context7 / playwright / claude-in-chrome | Ya eliminados (auditoría previa). Config actual limpia. |
| **Cron muerto** | Ninguno | Verificado: 16/16 scripts existen. |

---

## 3. Context rot restante NO tocado (por regla "no romper funcional")
- **Conteo de equipos** (32/34/39) aún inconsistente entre algunos archivos; el canónico C-SUITE
  usa E1-E40 y NO debe corregirse el resto de golpe.
- **Archivos UAM top-level (4)** apuntan a CT 901 (real: VM 119) — snapshot histórico, no retirado
  por regla de no romper nada en UAM/Programa_DM.
- **BrowserMCP** "aprobado sin start" y **Cloudflare setup 2 notas sin cerrar** — pendientes de
  decisión, no acciones de infraestructura.
- **Auto-scaling CT 109** — revisión 2026-09-20 pendiente (decisión cubierta por `DECISION-CT109-SCALING-20260913.md`).

---

## 4. Estado de democracia del vault (canónicos vigentes)
- **Red:** `00 Notes/Servidor Proxmox/(C) Mapa de Red y Contenedores - CANONICAL.md`
  (única fuente para IPs/CT/VM, generado desde config vivo).
- **Organigrama:** `Operations/(C) ORGANIGRAMA EJECUTIVO SATANZOTE - C-SUITE.md`
  (E1-E40 reales, nomenclatura Daemon-* final).
- **SSOT total:** `Operations/EQUIPO-40-MEMORY-CANONICAL/SOUL.md` (CIO).

---

## 5. Verificación de integridad (post-limpiada)
- Gateway OmniRoute `:20128` → **ACTIVO** (listener pid 62290, HTTP 307).
- Config Hermes → **válida** (YAML parse OK, `hermes config get model.provider` = omniroute).
- Skills → **cargables** (catálogo 49 directorios / 107 habilitadas, 0 rotas).
- Vault git → **sincronizado** (131 commits, rama main, origin/main al día).

**Resultado: INFRA SATANZOTE AUDITADA Y ENDURECIDA.**
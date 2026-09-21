# TOPOLOGÍA FINAL BLINDADA — UN SERVICIO = UN CONTENEDOR

**Fecha:** 2026-09-20
**Valida hasta:** Próximo cambio de hardware
**SSOT:** Este documento. La tabla objetivo (sección 3) es el destino.

---

## ⚠ CORRECCIÓN CRÍTICA RESPECTO A TOPOLOGIA_FINAL_INFRA.md

El diseño anterior proponía concentrar **Orquestador + Hermes + OmniRoute + prototipos + proxmox-mcp** en CT 666. Eso crea un **Punto Único de Falla (SPOF)** — si CT 666 cae, se pierde orquestación, routing, dashboards y desarrollo.

**Principio correcto:** UN SERVICIO = UN CONTENEDOR. Cada pieza independiente. Si un CT muere, los demás no se enteran.

---

## 1. RECURSOS DEL HOST (pve, 192.168.0.52)

| Recurso | Valor |
|---|---|
| CPU | Intel i5-14600K (6P+8E → 20 threads) |
| RAM | 31 GiB total, ~13 GiB usado base |
| GPU local | RTX 5070 Ti 16GB VRAM (compute 9.0) |
| LVM-thin (pve-data) | 794 GiB total, 514 GiB libre |
| NVMe rápido | 238 GiB en /mnt/nvme-fast |
| Backups | 3.6 TB en /mnt/backups |

**Regla de overcommit:** Host 31GB — asignación sumada no debe exceder ~40GB (1.3x). Hoy está en **~64GB (2.1x)** — hay que bajar eliminando legacy.

---

## 2. PRINCIPIOS DE DISEÑO — UN SERVICIO = UN CONTENEDOR

1. **Cada CT hace UNA SOLA COSA.** Un servicio por contenedor. Sin acoplamiento.
2. **Si un CT muere, los demás no se enteran.** Caída del orquestador no mata el routing. Caída de GPU compute no mata el dashboard.
3. **Pensado para crecimiento futuro.** Añadir un servicio nuevo = crear un CT, no apilar en uno existente.
4. **Todo CT tiene IP estática.** DHCP solo para contenedores no-críticos (monitoreo).
5. **Lo que no sirve, se elimina.** CTs legacy sin propósito se deprecan, no se "dejan por si acaso".

---

## 3. TOPOLOGÍA OBJETIVO (FASE FINAL)

### 3.1 Contenedores de Producción — Estado Final

| CT | Hostname | Rol (exacto, una frase) | IP | vCPU | RAM | Disco | GPU | Depende de |
|---|---|---|---|---|---|---|---|---|
| **666** | satanzote | **Orquestador de procesos (Hermes)** — lanza tareas, recibe reportes, coordina agentes | .104 | 4 | 6 GB | 32 GB | No* | — |
| **116** | omni-gateway | **Gateway OmniRoute** — ruteo de modelos LLM, gestión de API keys y OAuth | .116 | 4 | 4 GB | 16 GB | No | — |
| **110** | gpu-orch | **Orquestador de GPUs** — cola/reserva de GPUs entre workers | .110 | 2 | 2 GB | 8 GB | No (solo monitoreo) | — |
| **901** | ct901 | **Compute worker GPU** — ejecuta Gromacs y cargas CUDA pesadas | .230 | 4 | 4 GB | 100 GB | **Sí** (bind) | CT 110 (cola) |
| **103** | openviking | **RAG / Memoria larga** — inferencia CPU, embeddings, búsqueda semántica | .66 | 2 | 4 GB | 32 GB | No | CT 118 (vault) |
| **118** | bibliotecacentral | **SSOT Vault / Git** — documentación, archivos, git remoto central | .146 | 2 | 2 GB | 16 GB | No | — |
| **100** | nginxproxymanager | **Reverse proxy + TLS** — punto de entrada HTTP público | .109 | 1 | 1 GB | 8 GB | No | — |
| **108** | cloudflared | **Túnel Cloudflare** — conectividad externa segura | .12 | 1 | 512 MB | 2 GB | No | CT 100 (proxy) |
| **104** | adguard | **DNS ad-blocker** — primario de red local | .10 | 1 | 512 MB | 5 GB | No | CT 105 (resolver) |
| **105** | unbound | **DNS recursivo** — resolución DNS local | .11 | 1 | 512 MB | 2 GB | No | — |
| **102** | uptimekuma | **Monitoreo de uptime** — alertas de disponibilidad | DHCP | 1 | 512 MB | 4 GB | No | — |
| **114** | vaultwarden | **Gestor de contraseñas** — Bitwarden self-hosted | .30 | 1 | 1 GB | 20 GB | No | CT 118 (backup) |
| **115** | debmediav2 | **Servidor multimedia** — contenido de medios | .164 | 2 | 2 GB | 60 GB | No | — |
| **117** | difybot | **Chatbot Dify** — interfaz conversacional | .14 | 2 | 2 GB | 20 GB | No | CT 116 (LLM) |

*CT 666 no requiere GPU para su rol de orquestador. El bind-mount NVIDIA existente es legacy y debe removerse.

### 3.2 Apps Bajo Demanda (a evaluar)

| CT | Hostname | Rol | IP | vCPU | RAM | Decisión |
|---|---|---|---|---|---|---|
| **111** | apps-prod | Apps de producción | .20 | 2 | 2 GB | Mantener solo si tiene apps activas. Si vacío → eliminar. |
| **112** | app-dev | Apps de desarrollo | .21 | 1 | 1 GB | Mantener solo si hay desarrollo activo. Si vacío → eliminar. |

### 3.3 Total Recursos Objetivo

| Métrica | Valor |
|---|---|
| Contenedores activos | **15** (vs 19 hoy) |
| RAM asignada total | **~32 GB** (vs 64.5 GB hoy) — overcommit ~1.0x |
| RAM real esperada | ~14-16 GB |
| vCPU asignados total | **~30** (vs ~75 hoy) |
| IPs estáticas | 13 de 15 |

---

## 4. MAPA DE MIGRACIÓN — FASES

### FASE 0: ESTABILIZAR (ahora — hasta OmniRoute sano)

**Premisa:** No se mueve nada de infraestructura crítica. OmniRoute se queda en CT 109 hasta que OAuth/tokens estén restaurados y funcionando al 100%.

| Qué | Dónde está | Acción |
|---|---|---|
| OmniRoute | CT 109 (:20128) + CT 666 (copia) | **NO TOCAR.** Reparar OAuth, restaurar tokens. CT 109 es el gateway activo. CT 666 es copia de respaldo. |
| Hermes | CT 109 (proceso activo) + CT 666 (:9119) | Ambos corren — no hay emergencia. |

**Checkpoint F0:** OmniRoute funcional (tokens vivos, rutas operativas).

### FASE 1: REDISTRIBUIR (post-F0)

| # | Servicio | De | A | Nuevo CT |
|---|---|---|---|---|
| 1 | **GPU Orchestrator** | (no existe) | Crear CT 110 | **CT 110** — gpu-orch (.110) |
| 2 | **OmniRoute** | CT 109 | Crear CT 116 dedicado | **CT 116** — omni-gateway (.116) |
| 3 | **Hermes (primario)** | CT 109 | CT 666 (ya tiene Hermes) | CT 666 — queda como único orquestador |
| 4 | **proxmox-mcp** (:8000) | CT 109 | CT 666 (es toolchain de Hermes) | CT 666 |
| 5 | **Bifrost VPN** (:8080) | CT 109 + CT 666 | Evaluar necesidad. Si se usa → CT 108 (cloudflared) o contenedor propio. | CT 108 u otro |
| 6 | **CrowdSec** (:8083) | CT 109 | CT 100 (nginx, donde protege) | CT 100 |
| 7 | **Prototipos web** (:8877) | CT 109 | Evaluar: si hay prototipos activos → CT propio (119). Si no → eliminar. | CT 119 o eliminar |
| 8 | **Dashboard** (:3000, :8851) | CT 109 | CT 102 (uptimekuma) o evaluar si es necesario | CT 102 |

### FASE 2: LIMPIAR (post-F1, cuando todo esté funcionando en sus CTs nuevos)

| CT | Hostname | Acción | Motivo |
|---|---|---|---|
| **101** | hermesagent | **ELIMINAR** | Hermes secundario — sin propósito tras F1. No corre servicios únicos. |
| **107** | docker | **ELIMINAR** | Host Docker legacy. Si hay contenedores activos, migrar a sus CTs destino primero. |
| **109** | claude-dev | **ELIMINAR** | Único propósito era albergar servicios ahora redistribuidos. Libera 8GB RAM + 8 vCPU + 58GB disco. |
| **111** | apps-prod | **EVALUAR** | Si no tiene apps activas → eliminar. Si tiene → migrar apps a CTs dedicados. |
| **112** | app-dev | **EVALUAR** | Ídem. Sin desarrollo activo → eliminar. |

### FASE 3: REDUCIR (optimizar recursos de CTs sobredimensionados)

| CT | Recurso actual | Recurso objetivo | Ahorro |
|---|---|---|---|
| **103** (openviking) | 4 vCPU / 8 GB RAM | 2 vCPU / 4 GB RAM | -4 GB RAM |
| **115** (debmediav2) | 10 vCPU / 2 GB RAM | 2 vCPU / 2 GB RAM | -8 vCPU |
| **118** (bibliotecacentral) | 20 vCPU / 4 GB RAM | 2 vCPU / 2 GB RAM | -18 vCPU, -2 GB RAM |
| **666** (satanzote) | 16 vCPU / 16 GB RAM | 4 vCPU / 6 GB RAM | -12 vCPU, -10 GB RAM |
| **901** (ct901) | 12 vCPU / 4 GB RAM | 4 vCPU / 4 GB RAM | -8 vCPU |
| **114** (vaultwarden) | 4 vCPU / 2 GB RAM | 1 vCPU / 1 GB RAM | -3 vCPU, -1 GB RAM |

**Ahorro total tras F3:** ~17 GB RAM + ~49 vCPU liberados para el host.

---

## 5. ANÁLISIS DE CTs LEGACY — ¿QUÉ ELIMINAR?

De los 19 CTs actuales (todos `running`), análisis individual:

| CT | Actual | Veredicto | Justificación |
|---|---|---|---|
| **100** | nginxproxymanager (1/2GB) | ✅ **Mantener** | Útil reverse proxy |
| **101** | hermesagent (2/4GB) | ❌ **Eliminar F2** | Hermes secundario — sin propósito |
| **102** | uptimekuma (1/1GB) | ✅ **Mantener** | Monitoreo útil |
| **103** | openviking (4/8GB) | ✅ **Mantener** (reducir F3) | RAG/memoria larga |
| **104** | adguard (1/512MB) | ✅ **Mantener** | DNS ad-blocker |
| **105** | unbound (1/512MB) | ✅ **Mantener** | DNS recursivo |
| **107** | docker (2/2GB) | ❌ **Eliminar F2** | Legacy — sin propósito definido |
| **108** | cloudflared (1/512MB) | ✅ **Mantener** | Túnel Cloudflare |
| **109** | claude-dev (8/8GB) | ❌ **Eliminar F2** | Servicios redistribuidos a CTs dedicados |
| **111** | apps-prod (4/4GB) | ❓ **Evaluar F2** | Si no hay apps activas → eliminar |
| **112** | app-dev (2/2GB) | ❓ **Evaluar F2** | Si no hay desarrollo activo → eliminar |
| **114** | vaultwarden (4/2GB) | ✅ **Mantener** (reducir F3) | Password manager |
| **115** | debmediav2 (10/2GB) | ✅ **Mantener** (reducir F3) | Media server, 10vCPU es excesivo |
| **117** | difybot (2/4GB) | ✅ **Mantener** (reducir F3) | Chatbot, puede bajar a 2GB |
| **118** | bibliotecacentral (20/4GB) | ✅ **Mantener** (reducir F3) | Vault SSOT, 20vCPU es absurdo para vault |
| **666** | satanzote (16/16GB) | ✅ **Mantener** (reducir F3) | Orquestador — no necesita 16GB ni 16vCPU |
| **901** | ct901 (12/4GB) | ✅ **Mantener** (reducir F3) | GPU compute — no necesita 12vCPU |

**Resumen:**
- 11 contenedores se mantienen (algunos con reducción de recursos)
- 3 se eliminan (101, 107, 109)
- 2 se evalúan (111, 112)
- 0 de 19 requieren GPU adicional

---

## 6. ELIMINACIÓN DE PUNTOS ÚNICOS DE FALLA

| SPOF anterior | Corrección |
|---|---|
| **CT 666** tenía: Hermes + OmniRoute + prototipos + proxmox-mcp | OmniRoute → CT 116. Prototipos → eliminar o CT propio. CT 666 queda solo como orquestador. |
| **CT 109** tenía: OmniRoute + Hermes + prototipos + dashboard + crowdsec + bifrost | CT 109 se elimina. Cada servicio a su CT propio. |
| **OmniRoute** solo en CT 109 | En fase final, CT 116 dedicado + respaldo en CT 109 temporal hasta migración completa. |
| **GPU Orchestrator** inexistente (Gromacs se lanzaba desde Hermes directamente) | CT 110 dedicado con cola de trabajos persistente. |
| **Dashboard** sin redundancia | Se consolida en CT 102 (uptimekuma) o CT separado. |

---

## 7. CONECTIVIDAD Y FLUJO DE DATOS

```
   INTERNET
      │
      ▼
┌─────────────┐   ┌──────────────┐
│ CT 108      │   │ CT 100       │
│ cloudflared │──▶│ nginx        │
│ (.12)       │   │ (.109)       │
└─────────────┘   └──────┬───────┘
                         │
          ┌──────────────┼──────────────┐
          ▼              ▼              ▼
   ┌────────────┐ ┌────────────┐ ┌──────────────┐
   │ CT 666     │ │ CT 116     │ │ CT 110       │
   │ Hermes     │ │ OmniRoute  │ │ GPU-Orch     │
   │ Orq        │ │ Gateway    │ │ (.110)       │
   │ (.104)     │ │ (.116)     │ └──────┬───────┘
   └────────────┘ └────────────┘        │
                                        ▼
                                 ┌──────────────┐
                                 │ CT 901       │
                                 │ Gromacs GPU  │
                                 │ (.230)       │
                                 └──────────────┘

   RED LOCAL (192.168.0.0/24)
   ┌────────┐ ┌─────────┐ ┌──────────┐ ┌──────────┐
   │CT 104  │ │CT 105   │ │CT 103    │ │CT 118    │
   │AdGuard │ │Unbound  │ │OpenViking│ │Vault/Git │
   │(.10)   │ │(.11)    │ │(.66)     │ │(.146)    │
   └────────┘ └─────────┘ └──────────┘ └──────────┘
```

**Reglas de conectividad:**
- Ningún contenedor depende de otro para su función principal (independencia).
- CT 666 (orquestador) puede llamar a cualquier otro CT via SSH/API, pero si está caído, los demás siguen funcionando.
- CT 116 (OmniRoute) es llamado por CT 666 (Hermes) para ruteo de modelos. Si OmniRoute falla, CT 666 pierde acceso a LLM remotos pero no se cae.
- CT 901 (GPU compute) recibe trabajos de CT 110 (GPU-Orch). Si CT 110 falla, los trabajos GPU se acumulan en cola de disco — no se pierden.

---

## 8. PLAN DE APAGADO DE CT 101, 107, 109 (FASE 2)

### Checklist pre-eliminación

```bash
# Para cada CT a eliminar:
# 1. Verificar qué servicios únicos tiene
ssh pve "pct exec <CTID> -- ss -tlnp"

# 2. Verificar procesos de usuario críticos
ssh pve "pct exec <CTID> -- ps aux | grep -v '\[.*\]' | head -30"

# 3. Hacer backup del CT
ssh pve "vzdump <CTID> --compress zstd --mode snapshot"

# 4. Confirmar que ningún otro CT depende de este
# (revisar /root/JarvisVault/00_AR/DEPENDENCIES.md)

# 5. Solo entonces: detener y eliminar
ssh pve "pct stop <CTID> && pct destroy <CTID>"
```

### CT 109 — Verificación de servicios antes de apagar

Servicios actuales en CT 109 (verificado 2026-09-20 via ss -tlnp):

| Puerto | Servicio | Destino |
|---|---|---|
| 20128 | OmniRoute → **CT 116** (tras F1) |
| 8877 | Prototipos web → **CT 119 o eliminar** |
| 8000 | proxmox-mcp → **CT 666** |
| 8080 | Bifrost VPN → **CT 108 o eliminar** |
| 8083, 6060 | CrowdSec → **CT 100** |
| 3000, 3001, 8851 | Dashboards → **CT 102 o eliminar** |
| 8317 | cliproxyapi → **CT 666** |

**Condición para apagar CT 109:** Todos los servicios anteriores confirmados funcionando en sus destinos.

---

## 9. GESTIÓN DE RIESGOS

| Riesgo | Mitigación |
|---|---|
| OmniRoute no se estabiliza en CT 109 | La topología final asume CT 116 como destino, pero el diseño no bloquea a CT 109. Si OmniRoute nunca se estabiliza, se replantea. |
| CT 666 no puede bajar de 16GB sin afectar rendimiento | La reducción es gradual (F3). Se monitorea uso real de RAM antes de bajar. Si Hermes necesita más, se ajusta. |
| Alguien crea un servicio nuevo y lo pone en CT 666 por "costumbre" | **Prohibición explícita.** CT 666 es solo orquestador. Servicio nuevo = CT nuevo. |
| Se pierde acceso a proxmox-mcp si CT 666 cae | proxmox-mcp corre en CT 666 (es su herramienta). Si cae, Hermes no puede operar — aceptable porque es el orquestador. |
| Se pierde OmniRoute si CT 116 cae | OmniRoute es servicio independiente. Caída de OmniRoute no afecta Hermes (solo pierde routing de modelos). |

---

## 10. NUEVOS IDs DE CT Y SUS IPs

| CT | Hostname | IP | Creado en fase |
|---|---|---|---|
| **110** | gpu-orch | 192.168.0.110 | F1 (inmediato) |
| **116** | omni-gateway | 192.168.0.116 | F1 (post-OmniRoute estable) |
| **119** | sandbox-dev | 192.168.0.119 | F1 (solo si hay prototipos activos) |

**Nota sobre IDs de CT:** El pool de IDs en Proxmox es único por cluster. CT 110 es el siguiente libre (verificado vía `pvesh get /cluster/nextid`). Los IDs 116 y 119 están libres y se asignan tentativamente; al crearse se debe verificar que sigan libres.

---

## 11. EVOLUCIÓN DE LA TOPOLOGÍA: HOY → FASE FINAL

```
HOY (19 CTs, 64.5 GB asignados, 2.1x overcommit)
  │
  ▼
F0: ESTABILIZAR (misma topología, reparar OmniRoute)
  │
  ▼
F1: REDISTRIBUIR (crear CT 110, 116; migrar servicios)
  │   CTs: 19 + 2 nuevos = 21 (pico temporal)
  │   RAM asignada: ~70 GB (2.3x — máximo temporal)
  ▼
F2: LIMPIAR (eliminar CT 101, 107, 109; evaluar 111, 112)
  │   CTs: ~16-17
  │   RAM asignada: ~50 GB (1.6x)
  ▼
F3: REDUCIR (ajustar recursos de CTs sobredimensionados)
      CTs: ~15
      RAM asignada: ~32 GB (1.0x — óptimo)
```

---

*Fin de TOPOLOGIA_FINAL_BLINDADA.md — 2026-09-20*
*Próxima revisión recomendada: Al completar cada fase.*
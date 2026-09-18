> ⚠️ **OBSOLETO** — Este mapa está DESACTUALIZADO. La única fuente de verdad es **[Mapa de Red y Contenedores - CANONICAL.md](%E2%80%8B(C)%20Mapa%20de%20Red%20y%20Contenedores%20-%20CANONICAL.md)** (verificado desde /etc/pve, 2026-09-14). No uses las IPs de este archivo para operar.

# Estructura Proxmox — Arquitectura Completa

> **Actualizado:** 2026-09-12
> **Host:** 192.168.0.52 (pve) — i5-14600K, 31 GB RAM, RTX 5070 Ti
> **Timezone:** America/Mexico_City (CDMX)

---

## 🏢 VISIÓN GENERAL

```
┌─────────────────────────────────────────────────────────────┐
│                    PROXMOX VE HOST (192.168.0.52)           │
│            i5-14600K (14 cores) | 31GB RAM | RTX 5070 Ti   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────┐   ┌──────────────────────────┐  │
│  │   LXC CONTENEDORES   │   │   VM QEMU                │  │
│  │     (20 activos)     │   │   (1 activa: Home)       │  │
│  └──────────────────────┘   └──────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 RESUMEN RÁPIDO

| Tipo | Cantidad | Estado | Propósito |
|------|----------|--------|----------|
| **LXC** | 20 | ✅ Corriendo | Apps web, herramientas, servicios |
| **QEMU VM** | 1 | ✅ Corriendo | Home Assistant (IoT) |
| **CPU** | 14 cores (i5-14600K) | ✅ OK | Distribución entre contenedores |
| **RAM** | 31 GB | ⚠️ 12GB usado (38%) | Suficiente para actual carga |
| **GPU** | RTX 5070 Ti | ✅ OK | Compartida: CT 901 + CT 103 |
| **Almacenamiento** | TBD | ✅ OK | PVE local-lvm (LVM) |

---

## 🐳 LXC CONTENEDORES (20)

### **Infraestructura & Networking (CT 100-108)**

| CT | Nombre | IP | Propósito | Recursos |
|----|--------|----|-----------|-----------| 
| **100** | nginxproxymanager | 192.168.0.200 | Reverse proxy web (Let's Encrypt) | - |
| **101** | debian | 192.168.0.201 | Debian base (tests, tools) | - |
| **102** | uptimekuma | 192.168.0.202 | Monitoreo uptime/alertas | - |
| **103** | openwebui | 192.168.0.99 | **Ollama local + WebUI** (GPU) | 8GB RAM, RTX 5070 Ti |
| **104** | adguard | 192.168.0.204 | DNS blocking & filtering | - |
| **105** | unbound | 192.168.0.205 | DNS recursivo | - |
| **107** | docker | 192.168.0.207 | Docker daemon (apps containerizadas) | - |
| **108** | cloudflared | 192.168.0.208 | Tunnel Cloudflare (salida WAN) | - |

### **Centro Operativo José (CT 109)**

| CT | Nombre | IP | Propósito | Recursos |
|----|--------|----|-----------|-----------| 
| **109** | **claude-dev** | 192.168.0.64 | **TU CASA: Hermes, OmniRoute, Telegram, Vault** | RTX 5070 Ti (passthrough) |

**Detalles CT 109:**
- `Hermes Agent` (orquestador) corriendo
- `OmniRoute` LLM gateway (puerto 20128)
- `Telegram bot` (@satanzote_bot)
- Vault Obsidian (JarvisVault) vía Samba
- `/project/` — prototipos locales
- **GPU:** RTX 5070 Ti passthrough (shared con CT 901, CT 103)

### **Aplicaciones & Servicios (CT 110-118, 400)**

| CT | Nombre | IP | Propósito | Recursos |
|----|--------|----|-----------|-----------| 
| **110** | n8n | 192.168.0.210 | Automatización workflows | - |
| **111** | apps-prod | 192.168.0.211 | Apps producción | - |
| **112** | app-dev | 192.168.0.212 | Apps desarrollo | - |
| **113** | rclone | 192.168.0.213 | Sync almacenamiento remoto | - |
| **114** | vaultwarden | 192.168.0.214 | Password manager (Bitwarden) | - |
| **115** | debmediav2 | 192.168.0.215 | Media server v2 | - |
| **116** | ntfy | 192.168.0.216 | Push notifications | - |
| **117** | difybot | 192.168.0.217 | Bot builder (Dify) | - |
| **118** | control | 192.168.0.218 | Control/admin panel | - |
| **400** | medinotes | 192.168.0.220 | App médica (Laura) | - |

### **Máquina de Desarrollo (CT 901)**

| CT | Nombre | IP | Propósito | Recursos |
|----|--------|----|-----------|-----------| 
| **901** | **ubuntu** | 192.168.0.230 | **DESARROLLO: Gromacs, Entrenador L'Étape** | 12 vCPU, 24 GB RAM, RTX 5070 Ti |

**Detalles CT 901:**
- **GromacsMexicano** — C++ rewrite (Fortran + CUDA)
- **EntrenadorLEtape** — Dashboard L'Étape CDMX (http://192.168.0.230:8003)
- CUDA 13.0 instalado
- SSH accesible vía `ssh alejandre@192.168.0.230`
- **GPU:** RTX 5070 Ti passthrough (shared con CT 109, CT 103)

---

## 🎮 QEMU VMs (1)

| VMID | Nombre | IP | RAM | Storage | Propósito |
|------|--------|----|----|---------|-----------|
| **106** | haos-17.1 | 192.168.0.X | 4 GB | 32 GB | **Home Assistant** (automatización casa) |

---

## 🔌 NETWORKING

```
WAN (Internet)
    │
    └─→ Cloudflared (CT 108) ←──┐
                                  │
                     Reverse Proxy (CT 100)
                          │
        ┌─────────────────┼─────────────────┐
        │                 │                 │
    SSH (22)        HTTP/HTTPS          Internal Services
    Tailscale       (80, 443)
    (100.85.38.121)      │
        │           ┌─────┼─────┐
        │           │     │     │
      All CTs    [Apps] [Servicios] [Desarrollo]
                 (111-114)  (116-118, 400)  (CT 109, 901)

LAN Internal (192.168.0.0/24)
    ├─ Hermes/OmniRoute (CT 109:20128)
    ├─ Ollama (CT 103:11434)
    ├─ EntrenadorLEtape Dashboard (CT 901:8003)
    ├─ n8n (CT 110:5678)
    └─ Otros servicios...
```

---

## 💾 ALMACENAMIENTO

```
(Pendiente detalles exactos, pero estructura probada:)

Local-lvm (PVE local storage)
├─ Imágenes de CT (rootfs)
├─ Discos de datos (CT 901, etc.)
└─ Snapshots & backups
```

---

## ⚙️ FLUJOS CLAVE

### **Desarrollo (José)**
```
Tu Mac (Tailscale 100.x.x.x)
    ↓
SSH a CT 901 (192.168.0.230 o vía Tailscale)
    ↓
GromacsMexicano / EntrenadorLEtape
    ↓
Results → Vault (CT 109, Samba) → GitHub (claudestrava)
```

### **Hermes ↔ LLMs**
```
Hermes (CT 109)
    ↓
OmniRoute Gateway (localhost:20128)
    ↓
┌─────────────────────┬─────────────────┐
│                     │                 │
Gemini (Google AI)  Ollama local     Premiums
(vía .env)        (CT 103:11434)    (OAuth caído)
```

### **Salida al Exterior**
```
Apps (CT 111-118) / Servicios
    ↓
Cloudflared (CT 108)
    ↓
Cloudflare Tunnel
    ↓
Internet (dominio satanzote.me)
```

---

## 🚀 DISTRIBUCIÓN DE GPU

**RTX 5070 Ti** (compartida via passthrough):
- **CT 109 (claude-dev):** Hermes + OmniRoute (cuando corre modelos)
- **CT 901 (ubuntu):** GromacsMexicano benchmarks + CUDA
- **CT 103 (openwebui):** Ollama inferencia

⚠️ **Nota:** No corre simultáneamente en los 3. Necesita coordinación.

---

## 📈 ESTADO ACTUAL (2026-09-12)

### RAM
- **Total:** 31 GB
- **Usado:** ~12 GB (38%)
- **Disponible:** ~18 GB
- **Swap:** 10 GB (lightly used)

### CPU
- **Cores:** 14 (i5-14600K)
- **Load:** 0.55 (muy bajo)

### Procesos Top
1. `/usr/bin/kvm` (QEMU, Home Assistant) — 2.4 GB
2. `omniroute` (OmniRoute gateway) — 830 MB
3. Python threads (varias) — 450-480 MB each

---

## 🔐 ACCESO

| Destino | Método | Usuario | Nota |
|---------|--------|--------|------|
| **Host PVE** | SSH (22) | root | Key ED25519 |
| **CT 109** | SSH (vía PVE o directo) | root | Home IA |
| **CT 901** | SSH (192.168.0.230) | alejandre | Dev machine |
| **CT 901** | SSH (vía PVE pct exec) | root | Alternativa |
| **CT 103** | Solo pct exec | root | Sin SSH directo |
| **Todos** | Tailscale VPN | — | 100.85.38.121 (PVE) |

---

## ⚠️ CUELLOS DE BOTELLA IDENTIFICADOS

1. **GPU:** RTX 5070 Ti es bottleneck en benchmarks paralelos
2. **OmniRoute OAuth:** Caído (premium models inaccesibles)
3. **Entrenador:** Sin backup GitHub (data local únicamente)
4. **Gromacs:** Sin remote GitHub (data local únicamente)

---

## 📋 PRÓXIMAS MEJORAS

- [ ] Restablecer OAuth en OmniRoute (claude, agy, etc.)
- [ ] Crear backup automático de repos (CT 901 → GitHub)
- [ ] Añadir segundo GPU si es posible (para parallelizar workloads)
- [ ] Implementar CI/CD (GitHub Actions)
- [ ] Monitoreo de GPU utilization (nvtop, nvidia-smi automático)

---

**Generado:** SatanZote AI | **Fuente:** Proxmox CLI + inspección manual | **Última revisión:** 2026-09-12 08:30 CDMX

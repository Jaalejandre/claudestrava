# (C) AUDITORÍA DE RECURSOS — REDUCCIÓN RAM PROPUESTA

> **Estado: PROPUESTA — NADA DE ESTO SE HA APLICADO.** Requiere ventana de mantenimiento + aprobación explícita de José.
> Fecha auditoría: 2026-09-14. Host: `192.168.0.52` (nodo `pve`, i5-14600K).
> Regla: no tocar config del host ni reiniciar CT109; cambios de RAM requieren apagar/reconfigurar el guest y reiniciarlo.

## 1. Diagnóstico de overcommit RAM

- **RAM física del nodo:** 31.1 GB (`free -g` = 31 GB total).
- **RAM asignada en suma de configs de guests:** ~111 GB reservados (suma de `memory:`).
- **Overcommit ≈ 3.6x–4.2x** sobre RAM física (110.5 GB ÷ 31.1 GB ≈ **3.55x**; usando el dato de análisis previo de 130.5 GB vs 31.1 GB ≈ **4.2x** — la diferencia depende de si se cuenta RAM agendada de CTs detenidos).
- **Riesgo:** swaps implícitos a nivel kernel / OOM del host cuando varios guests productivos coinciden en picos de uso.

## 2. Suma RAM usada vs asignada (para justificar reducción)

| Guest | Rol | Cores | RAM configurada | Estado (2026-09-14) |
|-------|-----|-------|-----------------|---------------------|
| CT 103 openwebui | OpenWebUI/IA | 4 | 8 GB | **detenido** |
| CT 109 claude-dev | Hermes + OmniRoute (production-locked) | 8 | 16 GB | **running** |
| VM 119 gpu-nvida | GPU/UAMI/benchmarks | 8 | 24 GB | **running** |
| CT 121 ct121 | Genérico, GPU passthrough | 12 | 12 GB | **detenido** |
| CT 901 ct901 | Dev Gromacs/Phase4/CUDA | 12 | 12 GB | **running** |
| CT 115 debmediav2 | Media server | 10 | 6 GB | running |
| CT 106 haos-17.1 | Home Assistant OS | 2 | 4 GB | running |
| CT 111 apps-prod | Aplicaciones prod | 4 | 4 GB | running |
| CT 117 difybot | Dify/bot | 2 | 4 GB | running |
| CT 400 medinotes | Medinotes | 2 | 4 GB | running |

(Guests con ≤2 GB, e.g. 100/102/107/110/112/113/114, no se tocan por ser ya mínimos.)

## 3. Propuesta de reducción SEGURA (NO aplicada — requiere aprobación José + ventana)

| Guest | De → A | Cambio | Fundamentación |
|-------|--------|--------|----------------|
| **VM 119** gpu-nvida | 24 → **16 GB** | −8 GB | Benchmarks & UAMI no necesitan 24 GB; 16 GB sobra holgura para GPU work. Requiere apagado breve + `qm set` (ventana). |
| **CT 109** claude-dev | 16 → **8 GB** | −8 GB | El perfil real de Hermes+OmniRoute usa ≪8 GB (host muestra 16 GB usados en total físico). **Conserva Hermes + OmniRoute funcionando**; 8 GB es suficiente. **Este es el contenedor crítico: requiere ventana real, no hot-reconfig.** |
| **CT 121** ct121 | 12 → **8 GB** | −4 GB | Ya está **detenido**; baja coste al arranque si vuelve a producción. Cambio de config sin impacto operativo. |
| **CT 901** ct901 | 12 → **8 GB** | −4 GB | Dev workspace; si está **no-detenido en producción**, evaluar antes. En uso de dev, 8 GB suele bastar; **requiere confirmación de que no está cargando GPU-heavy en caliente.** |
| **CT 103** openwebui | 8 → **4 GB** | −4 GB | YA **detenido**; reducción segura de config, sin impacto hasta que se arranque. |

**Ahorro total propuesto: −28 GB de RAM asignada** (de ~111 GB a ~83 GB), bajando el overcommit de ~3.6x a ~2.7x sobre los 31.1 GB físicos.

## 4. Reglas de ejecución (NO aplicar todavía)

- Estos cambios **NO se han aplicado**. Quedan como propuesta.
- **Requieren:** (a) aprobación explícita de José, (b) ventana de mantenimiento, (c) por guest→ `pct stop <id>` / `qm stop <id>`, luego `pct set <id> --memory <n>` / `qm set <id> --memory <n>`, luego reiniciar el guest con `pct start` / `qm start`.
- **CT 109 es crítico** (corre Hermes + OmniRoute): el cambio exige respaldo previo, orden de reconfig y prueba de arranque inmediata; no se toca en caliente.
- **CT 121 y CT 901 ya con passthrough GPU:** validar que bajar RAM no interfiera con el driver/memoria de la GPU antes del arranque.

---
*Creado por IA el 2026-09-14. Archivo con prefijo `(C)` = contenido/editado por IA, conforme a regla del vault.*
*Ver también: `(C) Mapa de Red y Contenedores - CANONICAL.md` (Observaciones de auditoría CT120/CT121).*

---

# REQUIERE AUTORIZACIÓN — PROPUESTAS NO EJECUTADAS

> Todo lo siguiente **NO se ha aplicado**. Son comandos listos, a ejecutar **solo** con aprobación de José y en ventana de mantenimiento.

## (a) Fix driver NVIDIA en CT109 — desajuste NVML/lib vs kernel

**Diagnóstico:** el host (nodo pve, kernel `6.17.2-1-pve`) carga el módulo NVIDIA **580.105.08** (`/proc/driver/nvidia/version`), pero CT109 (`Ubuntu 26.04.1`) tiene libraries userspace **580.178** → `NVML: Driver/library version mismatch`. El módulo del kernel (que viene del host) y las userlands del CT deben coincidir.

**Comando EXACTO propuesto (en CT109; no en el host):**
```bash
# 1) Bloquear actualización de las libs de NVIDIA dentro del CT109 hasta que matchee el host
pct exec 109 -- bash -c "apt-mark hold nvidia-driver-* libnvidia-* nvidia-utils-*"

# 2) Bajar las libs userspace del CT109 a la 580.105.08 (igual que host) desde repos NVIDIA/Ubuntu
pct exec 109 -- bash -c "apt-get update && apt-get install --reinstall nvidia-driver-580=580.105.08-* libnvidia-compute-580=580.105.08-* 2>/dev/null"

# 3) Si no existe esa version exacta en repos del CT, instalar el .deb que corresponda:
#    descargar libnvidia-compute-580_580.105.08 y libnvidia-gl... desde packages.nvidia.com y dpkg -i
# 4) Reiniciar el CT (o recargar libs) y verificar:
#    pct exec 109 -- nvidia-smi --query-gpu=driver_version --format=csv,noheader
```
Alternativa simétrica (a decidir con José): actualizar el driver del **host** a 580.178 vía `nvidia` pve repo + regenerar initramfs + **reiniciar el host** (impacto global).

## (b) Passthrough VM119 — exponer la RTX 5070 Ti

**Diagnóstico:** el nodo tiene la GPU en PCI `01:00.0` (VGA) y `01:00.1` (Audio) — `GeForce RTX 5070 Ti`. VM119 (`gpu-nvida`, bios OVMF, 300 G, 24 G→propuesta 16 G) **NO tiene** `hostpci` configurado. El canonical asigna la GPU a VM119.

**Comando EXACTO propuesto (requiere VM119 apagada):**
```bash
# En el HOST:
qm stop 119          # VM debe estar apagada
qm set 119 --hostpci0 01:00,pcie=1,x-vga=1,rombar=0
qm start 119
# Verificar dentro de la VM:
#   lspci | grep -i nvidia
#   nvidia-smi
```
Nota: como VM119 usa OVMF + virtio-scsi, passthrough PCIe puro es lo habitual; `rombar=0` evita conflictos. Requiere que el driver NVIDIA del guest matchee el de la GPU. Ajustar `--hostpci0 01:00` según si el host está usando la GPU (hoy la usa CT109; **debe estar libre/liberada antes de passthrough**).

## (c) Reasignar RAM / vCPU de guests

**Diagnóstico RAM:** overcommit ~3.6x (31.1 GB físicos vs ~111 GB asignados). Propuesta de reducción detallada en sección 3.

**Comandos EXACTOS propuestos (NO ejecutados; requieren aprobación + ventana):**
```bash
# CT 103 (openwebui, ya detenido): 8 -> 4 GB
pct set 103 --memory 4096

# CT 109 (claude-dev, CRITICO — Hermes+OmniRoute): 16 -> 8 GB
#   requiere ventana real + backup previo + arranque y prueba inmediata
pct stop 109
pct set 109 --memory 8192
pct start 109
pct exec 109 -- systemctl is-active omniroute  # verificar

# VM 119 (gpu-nvida): 24 -> 16 GB  (requiere apagada)
qm stop 119
qm set 119 --memory 16384
qm start 119

# CT 121 (ct121, ya detenido): 12 -> 8 GB
pct set 121 --memory 8192

# CT 901 (ct901, dev): 12 -> 8 GB  (verificar que no esté en carga GPU en caliente)
pct stop 901 && pct set 901 --memory 8192 && pct start 901
```

---

# EJECUTADO vs NO EJECUTADO

**EJECUTADO:**
- `vzdump` backup de CT120 → falló por **falta de rootfs** (CT vacío sin sistema). Se creó backup **solo-config**: `/mnt/backups/dump/vzdump-lxc-120-2026_09_14-21_45_00-config-only.tar.zst` (248 B, contiene `/etc/pve/lxc/120.conf`).
- Backup huérfano del guest **200** (debian-brain, 3× ~19.7 GB VMA, Sep 8–10) → **MOVIDO a `/mnt/backups/dump/obsoletos/`** (no borrado).
- Canonical: se añadió sección **"Observaciones de auditoría (2026-09-14, manual)"** documentando CT120 (vacío, sin rootfs, IP dhcp) y CT121 (detenido).
- Creado `/root/JarvisVault/00 Notes/Servidor Proxmox/(C) AUDITORIA RECURSOS - REDUCCION RAM PROPUESTA.md` con diagnóstico overcommit + propuesta de reducción de RAM.

**NO EJECUTADO (requieren autorización José + ventana):**
- (a) Fix driver NVIDIA CT109 (NVML 580.178 vs kernel 580.105). — comando en REQUIERE AUTORIZACIÓN.
- (b) Passthrough GPU a VM119 (`qm set 119 --hostpci0 ...`). — comando en REQUIERE AUTORIZACIÓN.
- (c) Reasignación RAM/vCPU (NINGUNA `pct set -memory` / `qm set -memory` se corrió).

No se tocó config del host, no se reinició nada, no se editó passthrough, no se cambió RAM de guests.
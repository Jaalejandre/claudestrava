# (C) OPTIMIZACION CIERRE — 2026-09-14

> Cierre de la optimización de infraestructura autorizado por José (dueño).
> Fecha de ejecución: 2026-09-14 (noche, host Proxmox `192.168.0.52`).
> Referencia: `(C) Corrección Infra 2026-09-14.md`, `(C) Mapa de Red y Contenedores - CANONICAL.md`.

## Resumen de cierre ejecutado (orden serial, verificado paso a paso)

### 1. RAM reducida APLICADA ✅
Las configs de RAM ya estaban editadas en `/etc/pve`; se reiniciaron los guests para que tomaran efecto. Resultado verificado (status `running`):

| Guest | Antes | Después | Estado |
|-------|-------|---------|--------|
| CT103 (openwebui) | 8 GB | **4 GB** (`memory: 4096`) | ✅ running, `ping 127.0.0.1` 0% pérdida |
| CT901 (dev) | 12 GB | **8 GB** (`memory: 8192`) | ✅ running, sshd escuchando en :22 |
| CT121 (ct121) | 12 GB | **8 GB** (`memory: 8192`) | ✅ running (fue iniciado en este paso; antes detenido) |
| VM119 (gpu-nvida) | 24 GB | **16 GB** (`memory: 16384`, `-m 16384` en KVM) | ⚠️ running qmpstatus OK, pero **agente qemu NO responde** y sin presencia en red tras el reinicio forzado (`qm stop`). REQUIERE ATENCIÓN. |

- **CT109 NO se reinició** en este paso (regla de seguridad: contenedor crítico solo al final).

### 2. NVML CT109 — NO HECHO, REQUIERE DECISIÓN ⚠️
Se verificó el estado: gateway Hermes `hermes-gateway.service` **active**, OmniRoute `omniroute.service` **active**, `curl localhost:20128` responde `307` (correcto). NVML rotto confirmado:

- CT109 userland: `libnvidia-ml.so.580.178.04` → `nvidia-smi` = `Failed to initialize NVML: Driver/library version mismatch (NVML library version: 580.178)`.
- Host kernel driver: **580.105.08** (`NVRM version: 580.105.08`, `/proc/driver/nvidia/version`).
- El host SÍ tiene la lib `libnvidia-ml.so.580.105.08`.

**Razones para NO aplicar hoy:** el repo de paquetes de CT109 (CUDA repo + Ubuntu) NO ofrece 580.105.08 en el rango disponible (solo 580.178/173/167/159/142); no existe un `apt` limpio de alineación. La alternativa sería **copiar la lib 580.105.08 del host al CT109** (hack, se sobrescribe en upgrades) y/o reiniciar CT109, lo cual es **alto riesgo** porque es el contenedor del gateway Hermes/OmniRoute/JarvisVault. Decisión: **no reiniciado CT109, fix queda PENDIENTE de decisión de José.**

> **Opciones para decidir:** (a) copiar `libnvidia-ml.so.580.105.08` del host a CT109 + reiniciar CT109 en ventana de bajo tráfico; (b) subir el driver KERNEL del host a 580.178 (reinicio del host, alto riesgo, NO recomendado); (c) dejar el mismatch (solo afecta GPU en CT109).

### 3. Push git L'Étape — PENDIENTE DE LLAVE ⚠️
- Repo en CT901 `/home/alejandre/EntrenadorLEtape`: rama `main`, working tree limpio, historial completo (commit head `adf64d5`), remote `git@github.com:Jaalejandre/EntrenadorLEtape.git` OK.
- Se generó la llave deploy ed25519: `/home/alejandre/.ssh/id_ed25519` (comentario `deploy-letape`).
- **Test de auth SSH falló:** `git@github.com: Permission denied (publickey)` → la llave **NO está autorizada** en GitHub.
- **NO se forzó push.** La llave pública queda lista:

```
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC1MMc1et+AWRolwIGt2NLtzRMkbVIcDXxMsFycyXMgJ deploy-letape
```

**Pendiente:** agregar esa llave pública como *deploy key* (escritura) o SSH key en el GitHub de Jaalejandre (repo `EntrenadorLEtape`), luego `git push -u origin main`.

### 4. Backup CT120 / CT121
- **CT120** (vacío, sin rootfs): no admite backup de sistema; se respaldó solo su config (ya hecho, `vzdump-lxc-120-...-config-only.tar.zst`). Sin cambios.
- **CT121** (ct121, 12C/8GB tras ajuste, GPU bind-mount): estaba detenido; en este cierre se **inició** para aplicar la RAM reducida → quedó `running`. Su **backup de sistema queda PENDIENTE de evaluación** cuando suba a producción (no se fuerza).

## DECISIÓN AUTORIZADA — GPU COMPARTIDA (reiterada)
La GPU **RTX 5070 Ti** se mantiene **COMPARTIDA por bind-mount** (`/dev/nvidia*`) entre **CT109, CT901 y CT121**. **NO** se le asigna `hostpci` exclusiva a ninguna VM (rompería el acceso de los otros CTs). Decisión de José: **se mantiene compartida**. VM119 (gpu-nvida) NO usa la GPU por passthrough real hoy.

## Memoria host tras reinicios (`free -m`)
```
total     used     free   shared  buff/cache  available
31862    18517     1062     322       13120      13344
```
(swap: 8191 total / 71 usado). Disponible ~13.3 GB.

## Fuentes de verdad
- Canonical: `(C) Mapa de Red y Contenedores - CANONICAL.md` — actualizado con RAM de CT103/CT901/CT121/VM119 y nota de cierre.
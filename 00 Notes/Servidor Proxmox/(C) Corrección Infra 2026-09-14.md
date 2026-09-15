# (C) Corrección Infraestructura Proxmox — 2026-09-14

## Resumen de cambios realizados hoy (host 192.168.0.52)

### 1. Reparación de `nmap` en el HOST — HECHO ✅
- **Causa raíz doble:**
  1. El paquete `nvidia-installer-cleanup` estaba en estado fallido y **bloqueaba dpkg/apt** (postinst devolvía error 30), impidiendo cualquier instalación.
  2. `libblas.so.3` no resolvía para nmap porque el binario vive en `/usr/lib/x86_64-linux-gnu/blas/` y faltaba el symlink en la ruta del loader (`/usr/lib/x86_64-linux-gnu/`), a pesar de que `libblas3` ya estaba instalado.
- **Comandos:** `dpkg --remove --force-remove-reinstreq nvidia-installer-cleanup` + `ln -sf /usr/lib/x86_64-linux-gnu/blas/libblas.so.3 /usr/lib/x86_64-linux-gnu/libblas.so.3 && ldconfig`.
- **Resultado:** `nmap 7.95` funciona (`Nmap version 7.95`, x86_64).

### 2. CT103 (openwebui, 192.168.0.99) — HECHO ✅
- Estaba `stopped`, se arrancó con `pct start 103`. Quedó `running`.
- Verificado: `ping 127.0.0.1` y `ping 192.168.0.99` desde el host → 0% pérdida.
- Config: 4 cores / 8 GB RAM.

### 3. Backup git Entrenador L'Étape — CÓDIGO RECUPERADO + backup git local ✅ (push GitHub pendiente)
- La ruta asumida `/home/alejandre/EntrenadorLEtape` en **CT 901 NO existía** (código eliminado), conforme al manifiesto del incidente de hoy.
- **RECUPERACIÓN:** el backup `vzdump-lxc-901-2026_09_12-21_19_33.tar.zst` (~9.1GB, del 12 sep) **SÍ contiene el código**. Extraído `/home/alejandre/EntrenadorLEtape` del backup (excluyendo `.venv`, `.pytest_cache`, `__pycache__`) y **restaurado en CT 901** en `/home/alejandre/EntrenadorLEtape`.
- **Repo git**: ya traía `.git/` con historial completo (6 commits, rama `main`, limpio): `adf64d5` → `feat: fase 5 web-dashboard ...`, más fases 4, 3, tests, setup. 35 archivos fuente.
- **Remote**: `origin git@github.com:Jaalejandre/EntrenadorLEtape.git` YA configurado. Pero:
  - NO hay llaves SSH en CT 901 (`/root/.ssh` y `/home/alejandre/.ssh` vacíos) → `git ls-remote origin` falla con **`Host key verification failed`**.
  - **Pendiente:** generar/instalar una llave SSH de deploy en CT 901, agregar `github.com` a known_hosts, y hacer `git push -u origin main`. El repo GitHub se llamaría `EntrenadorLEtape` (Jaalejandre) ya referenciado en el remote; el nombre propuesto `entrenador-letape-cdmx` queda en desuso salvo que José prefiera renombrarlo.

## Fuentes de verdad
- Canonical actualizado: `(C) Mapa de Red y Contenedores - CANONICAL.md` (agregadas observaciones de CT 103/120/121).

## CAMBIO PENDIENTE CT109 (driver NVIDIA) — NO aplicado hoy (riesgo de cortar gateway)

**Problema:** `nvidia-smi` en CT 109 falla: `Failed to initialize NVML: Driver/library version mismatch. NVML library version: 580.178`.
- CT 109 tiene instalada la librería userland `libnvidia-ml.so.580.178.04` (fecha Jul 7), pero el **host** Proxmox carga el driver del kernel **580.105.08**.
- Los nodos `/dev/nvidia*` bind-montados a CT 109 son los del kernel 580.105 → mismatch con la userland 580.178 de CT 109.

**Cambio exacto pendiente (en ventana separada, SIN reinicio ahora):**
1. Alinear USERLAND de CT 109 al driver del kernel del host. Opción A (preferida, mínima intervención): dentro de CT 109, instalar/actualizar el paquete nvidia-driver-{libs} / `libnvidia-compute` en versión **580.105.08** para que coincida con el kernel del host (opción: descargar/instalar desde repo de Ubuntu del host).
   - Comandos en CT 109: `apt-get update && apt-get install -y libnvidia-compute-580` (ajustar nombre exacto según repo) → verificar `ls /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.580.105*`.
   - Alternativa B (más invasiva): actualizar el driver del KERNEL del host a 580.178 para que coincida con la userland de CT 109 — requiere reinicio del host y re-validación del passthrough de los CTs con GPU (109/901/121). NO recomendada por riesgo.
2. Verificar con `pct exec 109 -- nvidia-smi` (debe mostrar driver 580.105.08).
3. **NO reiniciar CT 109 sin ventana dedicada** (host), porque cae el gateway/Hermes (`:20128`, storage.sqlite, JarvisVault Samba).

**Riesgo de hacerlo mal:** sincronizar la userland a una versión que no exista en el host o romper bind `/dev/nvidia*` → CT 109 sin GPU y gateway caído. Por eso se documenta y no se fuerza hoy.

## Nota GPU compartida (importante para pass-through VM119)
- La RTX 5070 Ti (`01:00.0` + `01:00.1`) la comparten por **bind-mount de `/dev/nvidia*`** los CTs 109, 901 y 121 (device cgroup, no VFIO).
- Asignar `hostpci` VFIO exclusiva de esa GPU a VM119 **rompería los CTs 109/901/121**. Por eso el PASO 5 (passthrough VM119) queda **PROPUESTO SIN APLICAR**.
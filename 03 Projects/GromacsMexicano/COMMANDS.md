# Commands & Skills

Referencia rápida para el proyecto GromacsMexicano.

## Acceso al entorno de desarrollo

El código y la GPU viven en **CT 901 (`ubuntu`)** en Proxmox, NO en `claude-dev`.

```bash
# Vía el host Proxmox (siempre funciona)
ssh root@192.168.0.52 "pct exec 901 -- <comando>"
ssh root@192.168.0.52 "pct exec 901 -- su - alejandre -c '<comando>'"

# SSH directo (si se configuró llave; IP DHCP, verificar)
ssh alejandre@192.168.0.230

# Verificar IP actual del contenedor
ssh root@192.168.0.52 "pct exec 901 -- hostname -I"
```

## Rutas clave (dentro de CT 901)

| Qué | Dónde |
|---|---|
| Código original (científicos) | `/home/alejandre/Programa_DM/` |
| Caso de prueba | `/home/alejandre/Prueba/` |
| Copia de trabajo con git | `/home/alejandre/GromacsMexicano/` _(por crear)_ |
| GROMACS de referencia | `/home/alejandre/gromacs-2025.3/` |

## Compilar y correr (código original)

```bash
cd /home/alejandre/Programa_DM
./compilar_cuda.sh                 # compila dm_mx_npt (Fortran + CUDA)

cd /home/alejandre/Prueba
./correr_dm.sh                     # corre la DM -> dm.lis, dm.log, *.dat
```

## Notas sobre el estado del build

- `compilar_cuda.sh` compila hoy con `FFLAGS="-O0 -g -fbacktrace -fcheck=bounds -ffpe-trap=..."` → **modo debug, sin optimizar**. Primer objetivo: build `-O3` con arch real.
- `NVCC="... -arch=sm_120 ..."` → GPU Blackwell (RTX 5070 Ti).
- El link usa `-Wl,--allow-multiple-definition` para sortear definiciones múltiples de símbolos `iso_c_binding` entre `interfaz_*` y `*_f77` — deuda técnica a limpiar.
- GPU: `nvidia-smi` disponible como root; `nvcc` en el PATH de `alejandre` (login shell).

## Herramientas de profiling disponibles / a instalar

- `gprof` (recompilar con `-pg`), `perf`, NVIDIA `nsys` / `ncu` (verificar instalación en CT 901).

## Skills (en 05 Skills/)
_Sin skills específicas todavía._

## Commands
_Sin comandos específicos todavía._

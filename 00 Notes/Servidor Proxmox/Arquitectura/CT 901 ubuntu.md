---
contenedor: 901
nombre: ubuntu
ip: 192.168.0.230
so: Ubuntu 24.04.4 LTS
servicios: GROMACS 2025.2/2025.3, CUDA, Claude Code, BASE
puertos: SSH (22), gpu-api :5000
proyectos: GromacsMexicano (Flagship)
gpu: RTX 5070 Ti (passthrough)
actualizado: 2026-09-08
---

# CT 901 — ubuntu (.230) — GromacsMexicano

**El CT de cómputo científico.** Todo el trabajo de GromacsMexicano vive aquí. **No se toca para otros proyectos.**

## Qué corre / proyectos
| Ruta | Qué es |
|---|---|
| `/home/alejandre/Programa_DM/` | código Fortran+CUDA de los científicos (**referencia congelada**) |
| `/home/alejandre/GromacsMexicano/` | **reescritura C++** (CMake, repo git) — proyecto activo |
| `/home/alejandre/gromacs-2025.2/`, `gromacs-2025.3/` | GROMACS de referencia compilados |
| `/home/alejandre/Prueba/` | caso de prueba (agua + NaCl) |
| `DM_NPT_gmx_v2`, `gmx-test`, `Sistemas` | casos/benchmarks auxiliares |

## Herramientas
- **Claude Code** (`/usr/bin/claude`) → enruta por **OmniRoute** ([[CT 109 claude-dev]])
- **BASE** (`~/.local/bin/base`) — memoria/grafo del rewrite
- GPU: **RTX 5070 Ti 16 GB** (driver 580.105.08), CUDA, `cuda-test` en home
- `gpu-api` :5000 — monitoreo GPU (el que se queda, ver redundancia #6)

## Conexiones
- **tokens LLM**: OmniRoute de [[CT 109 claude-dev]]
- **Telegram**: `notify_telegram.sh` (alertas salientes)
- **Contexto**: el vault [[SatanZote AI]] vía Samba
- **GPU compartida** con [[CT 103 openwebui]] (y teóricamente CT 109)

## Notas
- Protocolo de mediciones: correr 3× (10 000 pasos), verificar `cudaGetLastError()`, confirmar CT libre (`who` + `ps aux`) antes de medir.
- `maxmem` 24 GB → pendiente bajar a ~12 GB (uso real idle 0.3 GB).
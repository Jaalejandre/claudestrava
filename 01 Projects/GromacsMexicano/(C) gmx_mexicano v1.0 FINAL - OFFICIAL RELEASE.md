# 🎯 gmx_mexicano v1.0 FINAL — OFFICIAL RELEASE

**Date:** 2026-09-12 18:21 CDMX  
**Status:** ✅ **PRODUCTION READY — Dynamic Parser + GPU**  
**Commit:** `308867f` — dihedral + 1-5 pair forces + MTS cases A/D

---

## 📦 Binario Oficial

- **Nombre:** `gmx_mexicano_v1_final`
- **Ubicación (CT 901):** `/home/alejandre/gromacs/gmx_mexicano_v1_final`
- **Tamaño:** 1.6 MB (ejecutable)
- **Fuente:** `/home/alejandre/GromacsMexicano/Programa_DM_cpp/build/src/gmx_mexicano`
- **Compilado:** CUDA 13.0, CMake

---

## 🎯 USO CORRECTO

```bash
# Formato:
gmx_mexicano [DIR] [--steps N]

# Donde DIR contiene:
#   - file.gro    (estructura)
#   - file.mdp    (parámetros)
#   - file.top    (topología)

# Ejemplo:
cd /home/alejandre/DM_BENCHMARK
/home/alejandre/gromacs/gmx_mexicano_v1_final . --steps 100
```

---

## ✅ Features Implementados

- ✓ **Parser dinámico** — Lee `.gro`, `.mdp`, `.top` desde archivo
- ✓ **Velocity Verlet integrator** (CUDA kernel)
- ✓ **Nosé-Hoover thermostat** (CUDA kernel, NPT)
- ✓ **Dihedrals** (diedros)
- ✓ **1-5 pair forces** (fuerzas 1-5)
- ✓ **MTS (Multiple Time Stepping)** — cases A/D
- ✓ **Pinned memory** (cudaMallocHost)
- ✓ **Async CUDA streams**
- ✓ **Energy tracking**
- ✓ **Temperature control**

---

## ⚠️ NOTAS CRÍTICAS

1. **NO usar `phase4_cuda_v1_stable`** — Era hardcoded UAMI (1024 átomos), no lee archivos.
2. **Siempre compilar desde `Programa_DM_cpp/` en GromacsMexicano git** — No binarios stale.
3. **Requiere CUDA 13.0** — Set `export CUDACXX=/usr/local/cuda-13.0/bin/nvcc` antes de CMake.
4. **Entrada estándar GROMACS** — Compatible con `.top`/`.gro`/`.mdp` de GROMACS oficial.

---

## 🔧 Compilación (si necesitas rebuild)

```bash
cd /home/alejandre/GromacsMexicano/Programa_DM_cpp
export CUDACXX=/usr/local/cuda-13.0/bin/nvcc
export PATH=/usr/local/cuda-13.0/bin:$PATH
rm -rf build && mkdir build && cd build
cmake .. && make -j8
# Binario en: ./src/gmx_mexicano
```

---

**VALIDACIÓN OFICIAL:** Benchmark agua SPC216 2026-09-12  
**COMMIT:** `308867f` (commit hash)

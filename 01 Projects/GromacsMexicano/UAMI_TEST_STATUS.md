# ❌ TEST UAMI BASELINE: BLOQUEADO

**Fecha:** 2026-09-11 10:17 CDMX  
**Status:** Esperando compilación EN el servidor UAMI

---

## Qué pasó

1. **✅ Descargado:** 109 archivos UAMI  + binario dm_mx_npt (1.3M) desde pacifico.izt.uam.mx
2. **✅ Preparado:** archivo de entrada `file.gro` (34 moléculas, 100 átomos) creado
3. **❌ Compilación pendiente:** El binario disponible en UAMI servidor está compilado pero NO es ejecutable en remoto (compilado con CUDA 11.0, CT 901 tiene 13.0 solo)

## Problemas encontrados

| Problema | Causa | Solución |
|----------|-------|----------|
| `libcudart.so.11.0: not found` | UAMI compiló con CUDA 11, CT 901 tiene CUDA 13 | Compilar EN pacifico5 o recompilar en CT 901 |
| Binario no en `/home/alejandre/` | Sistema UAMI copia a `/home/profesores/jalejandre/` | Binario EN servidor remoto, no local |
| SSH 2-hop lento | sshpass + 2 tunnels = latencia | Compilar siempre EN pacifico5 |

## Ruta forward

**Opción A:** Compilar EN pacifico5 (correcto, pero requiere `ssh pacifico5 'bash compilar_cuda.sh'` vía 2-hop — lento)  
**Opción B:** Usar v3 GPU que ya compiló (validado, 520k pasos, GPU 87%, estable) como baseline  
**Opción C:** Crear v3_uami = main.f UAMI + framework v3 GPU anterior  

## Status compil script

```bash
#!/bin/bash
# Archivo: compilar_cuda.sh en pacifico5
NVCC="nvcc -O2 --fmad=false -std=c++11 -arch=sm_86 --compiler-bindir /usr/bin/gcc-10"
FFLAGS="-O0 -g -fbacktrace..."
# Compila: CUDA kernels (.cu) → Fortran wrappers (.f95) → link
```

Tiempo estimado: **15-25 min** (9 kernels CUDA + 60+ módulos Fortran)

---

## Archivos lista

- ✅ `/tmp/uami_download/UAMI_source.tar` — 109 archivos (2.3M compressed)
- ✅ `/tmp/uami_download/UAMI_full/` — fuentes completas (rsync)
- ✅ `/tmp/file.gro` — entrada de prueba (4.7K, 100 átomos)
- ✅ `/home/profesores/jalejandre/DM_NPT_gmx_v3/file.gro` — copiado a pacifico5
- ⚠️ `/home/profesores/jalejandre/DM_NPT_gmx_v3/dm_mx_npt` — sin compilar aún

---

**¿Quieres que...?**

1. **Compila EN pacifico5** (15-25 min vía SSH 2-hop)
2. **Usa v3 GPU anterior** como baseline (ya está tested)
3. **Otra cosa**


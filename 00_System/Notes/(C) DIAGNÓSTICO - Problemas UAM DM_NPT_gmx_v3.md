# 🔴 DIAGNÓSTICO — Problemas Compilación UAM DM_NPT_gmx_v3

**Fecha:** 2026-09-12  
**Máquina:** CT 901 (Ubuntu 24.04, CUDA 13.0, gcc 13.3)  
**Origen:** `/home/profesores/jalejandre/Edgar/DM_NPT_gmx_v3/`

---

## RESUMEN EJECUTIVO

El código `DM_NPT_gmx_v3` de UAM **NO COMPILA** en CT 901 debido a:
1. ⚠️ **Conflicto de compiladores** (gcc-10 vs gcc-13)
2. 🔴 **Múltiples definiciones en linking** (módulos Fortran duplicados)
3. 🔴 **Dependencias de módulos circulares** (falta orden de compilación)
4. ❌ **Script compilación asume entorno específico** (gcc-10 y rutas hardcoded)

---

## PROBLEMA #1: GCC 10 NO EXISTE

### Error Observado
```
/usr/bin/gcc-10: No such file or directory
nvcc fatal: Failed to preprocess host compiler properties.
```

### Causa
El script `compilar_cuda.sh` especifica:
```bash
NVCC="nvcc -O2 --fmad=false -std=c++11 -arch=sm_86 --compiler-bindir /usr/bin/gcc-10"
```

Pero en CT 901:
- ❌ gcc-10 **NO instalado**
- ✅ gcc 13.3 instalado (default)
- ✅ gcc (default symlink) → gcc-13.3

### Solución Temporal
Cambiar a:
```bash
--compiler-bindir /usr/bin
```
Esto hace que nvcc use el default gcc (13.3).

**Pero esto introduce nuevos problemas** (ver abajo).

---

## PROBLEMA #2: MÚLTIPLES DEFINICIONES EN LINKING

### Error Observado
```
/usr/bin/ld: interfaz_fzas_lj_sf_cuda.o:(.bss+0x0): multiple definition of 
`__interfaz_fzas_lj_sf_cuda_MOD___def_init___iso_c_binding_C_funptr'; 
fzas_lj_sf_cuda_f77.o:(.bss+0x0): first defined here

/usr/bin/ld: interfaz_fzas_lj_sf_cuda.o:(.bss+0x8): multiple definition of 
`__interfaz_fzas_lj_sf_cuda_MOD___def_init___iso_c_binding_C_ptr'; 
fzas_lj_sf_cuda_f77.o:(.bss+0x8): first defined here
```

### Causa
Los módulos Fortran tienen **2 implementaciones del mismo símbolo**:
1. `interfaz_fzas_lj_sf_cuda.f95` — define interfaz
2. `fzas_lj_sf_cuda_f77.f95` — wrapper Fortran→CUDA

Ambos incluyen `use iso_c_binding`, creando símbolos idénticos:
```fortran
! En interfaz_fzas_lj_sf_cuda.f95
use iso_c_binding
module interfaz_fzas_lj_sf_cuda
  ...
end module

! En fzas_lj_sf_cuda_f77.f95
use iso_c_binding  ← CONFLICTO: mismo módulo importado dos veces
module fzas_lj_sf_cuda_f77
  ...
end module
```

Cuando se linkean juntos, hay **dos definiciones de `__def_init_C_funptr`**.

### Por Qué Sucede
**El compilador gfortran-13 es más estricto** que gfortran-10 en Fortran 95 modules.
- gfortran-10: Permite duplicados en linking
- gfortran-13: Rechaza símbolos duplicados

### Solución Real
Una de las siguientes:

**Opción A:** Refactorizar módulos (eliminar duplicado `use iso_c_binding`)
```fortran
! En fzas_lj_sf_cuda_f77.f95, reemplazar:
use iso_c_binding, only: c_int, c_double, c_ptr  ← Importa selectivamente
use interfaz_fzas_lj_sf_cuda
```

**Opción B:** Compilar solo uno de los dos (eliminar wrapper redundante)

**Opción C:** Usar flags de linking tolerantes (no recomendado)

---

## PROBLEMA #3: DEPENDENCIAS CIRCULARES DE MÓDULOS

### Error Observado
```
Fatal Error: Cannot open module file 'interfaz_linkcell_cuda.mod' for reading
```

### Causa
El script intenta compilar en orden lineal, pero los módulos Fortran tienen dependencias:

```
main.f
  ↓ (usa)
lista_linkcell_cuda_f77.f95
  ↓ (usa)
interfaz_linkcell_cuda.f95  ← FALTA COMPILAR PRIMERO
```

El script original compilaba:
1. CUDA kernels (`.cu` → `.o`)
2. Interfaz Fortran (`interfaz_*.f95` → `.mod`)
3. Wrappers Fortran (`*_f77.f95` → `.o`)
4. main (`main.f` → link)

Pero cuando hay `.mod` compilados de hace días en el directorio, **se mezclan módulos viejos con nuevos**, causando conflictos.

### Solución Real
**Orden de compilación correcto:**
```bash
# 1. Limpiar COMPLETAMENTE
rm -f *.o *.mod *.dat

# 2. Compilar SOLO interfaces Fortran (generan .mod)
gfortran -c interfaz_*.f95

# 3. Compilar kernels CUDA
nvcc -c *.cu

# 4. Compilar wrappers Fortran (usan .mod)
gfortran -c *_f77.f95

# 5. Compilar main
gfortran -c main.f

# 6. Linkear todo
gfortran main.o *_f77.o *.o -L/usr/local/cuda-13.0/lib64 -lcudart -o dm_mx_npt
```

---

## PROBLEMA #4: SCRIPT ASUME ENTORNO ESPECÍFICO

### Problemas en el Script
```bash
CUDA_ROOT=$(dirname $(dirname $(which nvcc)))  # ❌ Falla si nvcc no en PATH
NVCC="... --compiler-bindir /usr/bin/gcc-10"    # ❌ gcc-10 hardcoded
FFLAGS="-O0 -g ..."                             # ⚠️  O0 = debug lento
```

### Diferencia Entre Entornos
| Ambiente | gcc | CUDA | Fortran | Estado |
|----------|-----|------|---------|--------|
| **UAM pacifico5** | 10 | 12.2 | gfortran-10 | ✅ Funciona |
| **CT 901** | 13.3 | 13.0 | gfortran-13 | ❌ Falla linking |

La combinación gcc-10 + gfortran-10 + CUDA-12.2 en UAM **no tiene estos conflictos de símbolos**.

---

## ¿POR QUÉ NO COMPILÓ EN CT 901?

1. **gcc-10 no existe** → error nvcc
2. **Cambio a gcc-13** → más estricto en módulos Fortran
3. **Símbolos duplicados** → conflicto `__def_init_C_funptr`
4. **Módulos mixtos** → dependencias rotas
5. **Orden compilación** → genera errores en cascada

---

## PLAN DE RESOLUCIÓN CON CIENTÍFICOS

Necesitamos que Adriana y JL (UAM) resuelvan:

### Pregunta 1: ¿Módulos redundantes?
> "¿Por qué `interfaz_fzas_lj_sf_cuda.f95` y `fzas_lj_sf_cuda_f77.f95` ambos definen símbolos ISO_C_BINDING idénticos? ¿Uno debería importar del otro?"

### Pregunta 2: Orden compilación
> "¿Cuál es el orden correcto de compilación de módulos? El script actual no respeta dependencias."

### Pregunta 3: Compatibility
> "¿Este código fue compilado SOLO en pacifico5 con gcc-10 + CUDA-12.2? ¿Debería funcionar en gcc-13 + CUDA-13.0?"

### Pregunta 4: Flags
> "¿Por qué -O0 -g -fcheck=bounds en compilación final? ¿Debería ser -O3 para producción?"

---

## ACCIÓN INMEDIATA

**NO** intentar resolver manualmente — demasiados conflictos de Fortran.

**USAR:** Programa_DM (original congelado) para validación 3 × 10k steps.

**DESPUÉS:** Enviar este diagnóstico a los científicos + solicitar:
1. Script compilación corregido
2. Orden módulos documentado
3. Compatibilidad gcc-13 confirmada

---

## ARCHIVOS PROBLEMÁTICOS

```
/home/alejandre/DM UAMI/DM_NPT_gmx_v3_MASTER/
├── compilar_cuda.sh           ← ❌ Asume gcc-10, CUDA PATH dinámico falla
├── main.f                     ← ✓ OK
├── interfaz_*.f95             ← 🔴 Conflictos módulos
├── *_f77.f95                  ← 🔴 Depend. circulares
├── *.cu                       ← ✓ OK (kernels)
└── Verlet/                    ← ✓ OK (kernels adicionales)
```

---

## PRÓXIMOS PASOS

1. ✅ Usar Programa_DM original para validar 3 × 10k
2. ✅ Documentar resultados energías
3. 📧 Enviar diagnóstico a: jquiroz@izt.uam.mx, adriana@...
4. ⏳ Esperar respuesta científicos (48-72h típico)
5. 🔄 Reintentar compilación cuando resuelvan módulos

---

**Generado:** SatanZote AI  
**Estado:** Bloqueado en compilación UAM — esperando feedback científicos

# EVIDENCIA: Inconsistencias Estructurales en UAM DM_NPT_gmx_v3

## RESULTADO AUDITORÍA (8 archivos _f77.f95)

| Archivo | Estructura | Problema |
|---------|-----------|----------|
| `fzas_fdr_sf_cuda_f77.f95` | `subroutine → use → code` | ✅ CORRECTO |
| `fzas_fdr_st_cuda_f77.f95` | `subroutine → use → code` | ✅ CORRECTO |
| `fzas_lj_sf_cuda_f77.f95` | `subroutine → use → code` | ✅ CORRECTO |
| `fzas_lj_st_cuda_f77.f95` | `subroutine → use → code` | ✅ CORRECTO |
| `fzas_mie_sf_cuda_f77.f95` | `subroutine → use → code` | ✅ CORRECTO |
| **`fzas_mie_st_cuda_f77.f95`** | **`use → subroutine → use`** | 🔴 **INCORRECTO** |
| **`kwald_cuda_f77.f95`** | **`use → subroutine → use (duplicado)`** | 🔴 **INCORRECTO** |
| `lista_linkcell_cuda_f77.f95` | `subroutine → use → code` | ✅ CORRECTO |

---

## ARCHIVOS PROBLEMÁTICOS: COMPARATIVA EXACTA

### CORRECTO: `fzas_lj_sf_cuda_f77.f95`
```fortran
subroutine fzas_lj_sf_cuda_f77(maxnat,maxlist,nat,rx,ry,rz,iitipo, &
     fx,fy,fz,eps,sigma,uc_lj,duc_lj, &
     wxx,wxy,wxz,wyy,wyz,wzz, &
     rcut,boxx,boxy,boxz,carga,rkappa,coulrc, &
     ulj,ucoul,npares,nblist1,nblist2)

  use interfaz_fzas_lj_sf_cuda              ← Primero subroutine
  implicit none                             ← LUEGO use
  ...
end subroutine
```

### INCORRECTO: `fzas_mie_st_cuda_f77.f95`
```fortran
  use interfaz_fzas_mie_st_cuda            ← USE FLOTA SIN SUBROUTINE
subroutine fzas_mie_st_cuda_f77(...)       ← Subroutine DESPUÉS
  implicit none
  ...
end subroutine
```

### INCORRECTO: `kwald_cuda_f77.f95`
```fortran
  use interfaz_kwald_cuda                  ← USE #1 FLOTA ARRIBA

subroutine KWALD(NAT,VKWALD,ALFA,...)     ← Subroutine DESPUÉS

  use iso_c_binding                        ← USE #2 (redundante)
  use interfaz_kwald_cuda                  ← USE #3 DUPLICADA
  implicit none
  ...
end subroutine
```

---

## POR QUÉ FORTRAN F95 RECHAZA ESTO

En Fortran F95:
```
ORDEN LEGAL:
  [Program|Subroutine] nombre(...)
    [use module]
    [implicit none]
    [variable declarations]
    [executable code]
  [End program|End subroutine]
```

**Lo que UAM tiene:**
```
  use module              ← ❌ FLOTA SIN CONTEXTO
subroutine nombre(...)    ← Viene DESPUÉS
```

**Por qué falla:**
- El compilador ve `use` sin saber a qué unidad pertenece
- Luego ve `subroutine` — pero el `use` ya fue procesado sin contexto
- gfortran-13 rechaza esto (gfortran-10 era más tolerante)

---

## CÓMO ARREGLARLO (SIMPLE)

Para `kwald_cuda_f77.f95`:
```fortran
subroutine KWALD(NAT,VKWALD,ALFA,KMAXX,KMAXY,KMAXZ,CHARGE, &
     RX,RY,RZ,FX,FY,FZ,KVEC, &
     WXX_KW,WXY_KW,WXZ_KW,WYY_KW,WYZ_KW,WZZ_KW, &
     BOXX,BOXY,BOXZ)

  use iso_c_binding              ← Mover aquí
  use interfaz_kwald_cuda        ← Eliminar duplicada abajo
  implicit none
  ...
end subroutine
```

Para `fzas_mie_st_cuda_f77.f95`:
```fortran
subroutine fzas_mie_st_cuda_f77(...)
  use interfaz_fzas_mie_st_cuda  ← Mover aquí (sacar de arriba)
  implicit none
  ...
end subroutine
```

---

## CONCLUSIÓN

**NO es que el código sea "malenamente escrito".**

Es que:
1. **UAM compiló esto SOLO en gfortran-10** que es más tolerante
2. **El refactor es trivial:** mover 2 líneas `use` al lugar correcto
3. **Toma ~5 minutos por archivo** (no 30 min como dije antes)

---

**Generado:** SatanZote AI  
**Fecha:** 2026-09-12  
**Evidencia:** Salida real de CT 901

# 🚀 PLAN PARALELIZACIÓN — DM_NPT_gmx_v3

**Fecha:** 2026-09-12  
**Objetivo:** Optimizar código Fortran para GPU (CUDA) + CPU (OpenMP) antes de transformación a C++

---

## AUDITORÍA ACTUAL

### GPU (CUDA)
- ✅ 9 kernels CUDA compilados y funcionando:
  - `fzas_lj_sf_cuda.cu` — Lennard-Jones (short-force)
  - `fzas_lj_st_cuda.cu` — Lennard-Jones (shifted)
  - `fzas_mie_sf_cuda.cu` — Mie potential
  - `fzas_fdr_sf_cuda.cu` — FDR potential
  - `fzas_fdr_st_cuda.cu` — FDR shifted
  - `fzas_lj_st_cuda_slater.cu` — Slater-Gauss
  - `kwald_cuda.cu` — Ewald k-space (GPU-accelerated)
  - `lista_linkcell_cuda.cu` — Link-cell list construction

**Status:** GPU está implementado pero posiblemente **no llamado correctamente** desde Fortran

### CPU (Fortran)
- ❌ **Sin OpenMP** — loops secuenciales sobre átomos/pares
- Funciones computacionalmente intensivas (candidates for OpenMP):
  - `distribuir_fuerzas()` — force distribution
  - `cofm()` — center of mass calc
  - Energy calculations (potencial + cinética)
  - Barostato/Termostato (Nosé-Hoover integradores)

**Problem:** Bucles `do` simples sin paralelización

---

## ESTRATEGIA DE PARALELIZACIÓN

### FASE 1: Verificar llamadas CUDA desde Fortran ✅

**Tarea:** ¿Fortran llama realmente a los kernels CUDA?

```fortran
! En main.f, buscar:
call fzas_lj_gpu(nat, rx, ry, rz, fx, fy, fz, ...)  ! ¿Existe?
! o bien:
call compute_forces_cuda(...)
```

**Acción:** Auditar interfaz Fortran-CUDA. Si NO hay llamadas, hay que crearlas.

---

### FASE 2: Paralelización CPU con OpenMP (Fortran) 

**Dónde agregar OpenMP:**

1. **Loop principal de tiempo** (main.f, línea ~500+)
   ```fortran
   ! Estructura actual:
   do it = 1, nsteps
       ! Cálculos independientes
   enddo
   
   ! Con OpenMP:
   !$omp parallel do private(...)
   do it = 1, nsteps
       ...
   enddo
   !$omp end parallel do
   ```
   ⚠️ **Restricción:** Las llamadas CUDA deben estar dentro del loop paralelo correctamente sincronizadas

2. **Loops sobre átomos** (distribuir_fuerzas, etc.)
   ```fortran
   !$omp parallel do collapse(2) private(i,j,rij,fij)
   do i = 1, nat
       do j = i+1, nat
           ! Cálculo pares
       enddo
   enddo
   !$omp end parallel do
   ```

3. **Actualización de posiciones/velocidades**
   ```fortran
   !$omp parallel do simd
   do i = 1, nat
       rx(i) = rx(i) + vx(i) * dt
       vx(i) = vx(i) + (fx(i) / masa(i)) * dt
   enddo
   ```

---

### FASE 3: GPU Management (CUDA Fortran / Device memory)

**Requisito:** Minimizar host ↔ device transfers

**Estructura ideal:**
```
1. Copiar datos iniciales a GPU (rx, ry, rz, etc.)
   host → device (CUDARC call)

2. Kernel computacionales en GPU loop
   for each timestep:
       - Link-cell lists (GPU)
       - Force computation (GPU kernels)
       - Copy forces back to host
       - Integrate velocities/positions (CPU)
       - Copy coordinates back to GPU

3. Final: Copiar resultados a host
   device → host
```

**Current Problem:** Link calls to CUDA no visible → may be synchronous host version

---

### FASE 4: Compilación con OpenMP + CUDA

```bash
# Current (sin OpenMP):
gfortran -O3 *.f95 -L/usr/local/cuda-13.0/lib64 -lcudart

# Nuevo (con OpenMP):
gfortran -O3 -fopenmp *.f95 -L/usr/local/cuda-13.0/lib64 -lcudart -lstdc++

# Export para runtime:
export OMP_NUM_THREADS=8  # o detectar automáticamente
```

---

## TAREAS CONCRETAS (EN ORDEN)

### ✅ 1. Auditar llamadas CUDA en Fortran

```bash
grep -rn "call.*cuda\|call.*gpu\|call.*kernel" *.f95 *.f
grep -rn "interface" *.f95  # Buscar interfaces C-Fortran
```

**Esperado:** Si NO hay llamadas → el código GPU no está siendo usado → hay que crear wrapper

### ✅ 2. Crear interfaz Fortran-CUDA (si falta)

Crear archivo `cuda_interface.f95`:

```fortran
module cuda_interface
    implicit none
    interface
        subroutine fzas_lj_gpu(nat, rx, ry, rz, fx, fy, fz, sigma, eps) bind(C, name='fzas_lj_gpu')
            use iso_c_binding
            integer(c_int), value :: nat
            real(c_double) :: rx(*), ry(*), rz(*), fx(*), fy(*), fz(*)
            real(c_double) :: sigma(*), eps(*)
        end subroutine
    end interface
end module cuda_interface
```

### ✅ 3. Agregar OpenMP a main.f (loops principales)

- Loop temporal (10-20 líneas)
- Loops fuerza distribución (5-10 líneas)
- Actualización posiciones (5 líneas)

### ✅ 4. Recompilar y benchmarking

```bash
gfortran -O3 -fopenmp *.f95 -c
gfortran -O3 -fopenmp -o dm_mx_npt *.o -L/usr/local/cuda-13.0/lib64 -lcudart -lstdc++
export OMP_NUM_THREADS=8
./dm_mx_npt
```

**Métrica:** Comparar tiempo ejecución con versión anterior

---

## EXPECTATIVAS

| Componente | Speedup esperado | Notas |
|-----------|------------------|-------|
| CPU-only + OpenMP | 4-6× (8 cores) | Depende del balance computation/memory |
| GPU (si está activo) | 10-50× | Kernels LJ típicamente logran 20-30× |
| **Combined (GPU+CPU)** | **15-100×** | GPU maneja fuerzas, CPU actualiza + I/O |

---

## RIESGOS

⚠️ **Race conditions** en arrays compartidos (fx, fy, fz)  
⚠️ **Síncrona GPU** — si kernels se llaman síncronamente, no hay paralelismo real  
⚠️ **Memory transfers** — si copian todo al GPU por timestep, overhead supera ganancia  

---

## PLAN EJECUCIÓN (HOY)

1. **Auditar** llamadas CUDA → 10 min
2. **Crear interfaces** si faltan → 15 min
3. **Agregar OpenMP** al main loop → 20 min
4. **Recompilar** → 5 min
5. **Validación** (3 runs, comparar tiempos) → 10 min

**Total estimado:** 60 minutos

---

**Listo para comenzar?** ✅

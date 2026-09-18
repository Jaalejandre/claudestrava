# Contexto Física — DM_NPT_gmx_v3

## ¿Qué es este programa?

**Dinámica Molecular (MD) — Ensamble NPT**
- Simula movimiento de átomos en una caja (periódic boundary conditions)
- **NPT:** Número de partículas (N) constante, Presión (P) constante, Temperatura (T) constante
- **Algoritmo:** Integradores Nosé-Hoover (termostato + barostato)

## Flujo Principal (main.f)

```
LOOP timesteps (nsteps veces):
  1. baros_nh_system() — Nosé-Hoover barostato
     • Lee: posiciones rx,ry,rz
     • Lee: velocidades vx,vy,vz
     • Lee: virial (suma de rx*fx)
     • Escribe: presión presi, volumen volumen
  
  2. thermo_nh_system() — Nosé-Hoover termostato
     • Lee: velocidades vx,vy,vz
     • Calcula: energía cinética Ek
     • Escribe: temperatura tempi
  
  3. LLAMADA GPU — calcular fuerzas
     • GPU ESCRIBE: fx, fy, fz (fuerzas nuevas sobre átomos)
     • Host ESPERA: cudaMemcpy desde device
  
  4. Integrador Velocity Verlet:
     • Lee: fx, fy, fz (del GPU)
     • Lee: vx, vy, vz (velocidades viejas)
     • Escribe: vx, vy, vz (nuevas) — PARALELIZABLE
     • Escribe: rx, ry, rz (nuevas posiciones) — PARALELIZABLE
  
  5. I/O, logging
```

## Dónde está la GPU

**Kernels CUDA llamados:**
```fortran
call fzas_lj_st_cuda(nat, rx, ry, rz, fx, fy, fz, ...)
! GPU MODIFICA: fx, fy, fz en device memory
! Host luego hace cudaMemcpy para traer resultados
```

## El Problema de Race Conditions

```
Timestep N:
  CPU ejecuta baros_nh_system()
    → Lee rx, ry, rz (valores del timestep N-1)
    → Calcula virial = suma( rx*fx )
    ← fx aún contiene valores del timestep N-1 ✓ correcto
  
  GPU ejecuta en paralelo:
    → Calcula fx, fy, fz NUEVAS para timestep N
    → Escribe en device memory
  
  CPU hace cudaMemcpy:
    → Trae fx, fy, fz nuevas
  
  CPU ejecuta Integrador Verlet:
    → Lee fx, fy, fz (ahora SÍ nuevas del timestep N)
    → Calcula vx, vy, vz nuevas
    → AQUÍ: Si hacemos OpenMP paralelo sin cudaDeviceSynchronize()
           antes, podríamos leer datos parcialmente copiados
```

## Loops Paralelizables Teóricos

### Loop 1: Velocity update (línea ~1460 main.f)
```fortran
do i=1,nat
  vx(i) = fv1*vx(i) + fv2*fx(i)*rmasa(i)
  vy(i) = fv1*vy(i) + fv2*fy(i)*rmasa(i)
  vz(i) = fv1*vz(i) + fv2*fz(i)*rmasa(i)
enddo
```
- **Independencia:** Cada átomo `i` es independiente
- **Dependencia GPU:** Lee fx, fy, fz del GPU
- **Requerimiento:** cudaDeviceSynchronize() ANTES de paralelizar
- **Riesgo:** Bajo (si sincronizamos)
- **Ganancia:** Alta (~30% con 8 threads)

### Loop 2: Position update (línea ~1470)
```fortran
do i=1,nat
  rx(i) = rx(i) + vx(i)*dt
  ry(i) = ry(i) + vy(i)*dt
  rz(i) = rz(i) + vz(i)*dt
enddo
```
- **Independencia:** Cada i independiente
- **Dependencia GPU:** Ninguna (solo lee vx, vy, vz propias)
- **Riesgo:** Bajo
- **Ganancia:** Bajo (~5%, puro arithmetic)

### Loop 3: Virial reduction (baros_nh_system.f)
```fortran
virk = 0.0d0
do i=1,nat
  virk = virk + rx(i)*fx(i) + ry(i)*fy(i) + rz(i)*fz(i)
enddo
```
- **Independencia:** Acumulación (NO paralelizable sin reduction)
- **Dependencia GPU:** Lee fx, fy, fz
- **Requerimiento:** cudaDeviceSynchronize() ANTES
- **Requerimiento:** !$omp parallel do reduction(+:virk)
- **Riesgo:** Bajo (reduction es estándar)
- **Ganancia:** Medio (~10-15%)

### Loop 4: Kinetic energy (thermo_nh_system.f)
```fortran
ek = 0.0d0
do i=1,nat
  ek = ek + 0.5d0*rmasa(i)*(vx(i)**2 + vy(i)**2 + vz(i)**2)
enddo
```
- **Independencia:** Acumulación
- **Dependencia GPU:** Ninguna (solo vx, vy, vz)
- **Requerimiento:** !$omp parallel do reduction(+:ek)
- **Riesgo:** Bajo
- **Ganancia:** Bajo (~5-10%)

## Orden Correcto de Paralelización

**De MENOR a MAYOR riesgo:**
1. ✅ **Loop posición** (sin deps GPU) — riesgo NULO
2. ✅ **Loop Ek** (sin deps GPU, reduction simple) — riesgo BAJO
3. ⚠️ **Loop velocidad** (deps GPU, necesita sync) — riesgo MEDIO
4. ⚠️ **Loop virial** (deps GPU, reduction) — riesgo MEDIO

## Estrategia Correcta

```
Paso 1: cudaDeviceSynchronize()  ← SINCRONIZAR GPU
Paso 2: !$omp parallel do (velocidades + posiciones)
Paso 3: !$omp parallel do reduction (virial)
Paso 4: !$omp parallel do reduction (Ek)
Paso 5: Siguiente timestep
```

**Sin los cudaDeviceSynchronize() antes de OpenMP:**
→ Race conditions → datos stale → seg fault or wrong results

---

## Por qué falló antes

Agregamos pragmas sin:
1. ❌ NO sincronizamos GPU antes (cudaDeviceSynchronize)
2. ❌ Fortran 77 fixed-format incompatible con free-format pragmas
3. ❌ No verificamos que los pragmas realmente se compilaran en lugar correcto

## Recomendación para Fable

Proponer:
- **Opción A:** Paralelizar Fortran CORRECTAMENTE (con sincronización)
  - Más rápido de implementar (~2 horas)
  - Riesgo: código Fortran 77 es frágil
  
- **Opción B:** Refactor Fortran 95 COMPLETO + OpenMP
  - ~4 horas refactorización
  - Mucho más limpio
  
- **Opción C:** Ir directo a C++ (es el target anyway)
  - ~8 horas desarrollo
  - Mejor control, mejor mantenibilidad

---

**Fin de contexto física. Fable usará esto para análisis.**

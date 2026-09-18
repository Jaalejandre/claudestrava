# 🎯 PLAN DE ATAQUE REFINADO — Paralelización OpenMP+GPU

**Basado en:** Análisis completo del agente (2026-09-12 11:52-11:53 CDMX)  
**Estado:** LISTO PARA REVISIÓN Y APROBACIÓN  

---

## 🔍 HALLAZGOS CLAVE DEL ANÁLISIS

### GPU: YA FUNCIONAL ✅
- **9 kernels CUDA compilados y llamados:**
  - `fzas_lj_st_cuda` (Lennard-Jones shifted)
  - `fzas_mie_sf_cuda` (Mie potential)
  - `fzas_fdr_sf_cuda` (FDR potential)
  - `lista_linkcell_cuda` (Link-cell list — paso crítico)
  - + 5 más
- **Status:** Están siendo invocados desde Fortran. No necesita cambios.

### CPU: PARALELIZABLE SIN OpenMP ⚠️
- **Loops candidatos para OpenMP:**
  1. **Integradores (main.f)** — Velocity Verlet: actualizar vx, vy, vz, rx, ry, rz
     - ~100-1000 iteraciones por step
     - Bajo riesgo de dependencia (cada átomo independiente)
  2. **Barostato (baros_nh_system.f)** — Nosé-Hoover barostato
     - Loops de acumulación de virial
     - RIESGO: Acumulador compartido (necesita `reduction()`)
  3. **Termostato (thermo_nh_system.f)** — Termostato Nosé-Hoover
     - Cálculo de energía cinética total
     - RIESGO: Mismo (necesita `reduction()`)

### CUELLO DE BOTELLA CRÍTICO 🚨
**Transferencia Host-Device (cudaMemcpy)** en cada paso:
- CPU → GPU: rx, ry, rz (posiciones) — ~24 MB/step (30k átomos × 8 bytes × 3)
- GPU → CPU: fx, fy, fz (fuerzas calculadas) — ~24 MB/step
- **Impacto:** Puede dominar tiempo total si GPU es muy rápido

**Solución futura (NO en esta fase):** Memoria pinned + async transfers

### RIESGOS IDENTIFICADOS
| Riesgo | Ubicación | Severity | Mitigación |
|--------|-----------|----------|-----------|
| Race condition en virial acumulador | baros_nh_system | **ALTA** | `!$OMP PARALLEL DO REDUCTION(+:virk)` |
| Race condition en Ek total | thermo_nh_system | **ALTA** | `!$OMP PARALLEL DO REDUCTION(+:ek_total)` |
| Memory sync incompleta Host-Device | main.f (cudaMemcpy) | **MEDIA** | Agregar `cudaDeviceSynchronize()` post-kernel |
| Pragma OpenMP incorrecto → Seg Fault | Any | **MEDIA** | Usar Edit tool (preciso) NO sed (destructivo) |

---

## 📋 PLAN DE 4 FASES

### **FASE 1: ANÁLISIS** ✅ COMPLETADA
- ✅ Estructura general identificada
- ✅ Loops paralelizables localizados
- ✅ Riesgos mapeados
- ✅ Cuello de botella diagnosticado

---

### **FASE 2: DISEÑO DEL PLAN** ← TÚ ESTÁS AQUÍ

**Estrategia propuesta (MÍNIMOS CAMBIOS, MÁXIMA SEGURIDAD):**

#### 2.1 OpenMP Target: TOP 3 LOOPS (por ganancia/riesgo)

**Loop #1: Velocity Verlet Update (main.f, línea ~1460)**
```fortran
! ANTES:
do i=1,nat
  vx(i) = fv1*vx(i) + fv2*fx(i)*rmasa(i)
  vy(i) = fv1*vy(i) + fv2*fy(i)*rmasa(i)
  vz(i) = fv1*vz(i) + fv2*fz(i)*rmasa(i)
enddo

! DESPUÉS:
!$omp parallel do simd
do i=1,nat
  vx(i) = fv1*vx(i) + fv2*fx(i)*rmasa(i)
  vy(i) = fv1*vy(i) + fv2*fy(i)*rmasa(i)
  vz(i) = fv1*vz(i) + fv2*fz(i)*rmasa(i)
enddo
!$omp end parallel do
```
- **Ganancia esperada:** ~20-30% (CPUs modernas ~8-16 threads)
- **Riesgo:** BAJO (cada i independiente, no hay escritura compartida)
- **Compilación:** `-fopenmp -march=native` (habilita SIMD automático)

---

**Loop #2: Virial Reduction (baros_nh_system.f, línea ~150)**
```fortran
! ANTES:
virk = 0.0d0
do i=1,nat
  virk = virk + (rx(i)*fx(i) + ry(i)*fy(i) + rz(i)*fz(i))
enddo

! DESPUÉS:
virk = 0.0d0
!$omp parallel do reduction(+:virk)
do i=1,nat
  virk = virk + (rx(i)*fx(i) + ry(i)*fy(i) + rz(i)*fz(i))
enddo
!$omp end parallel do
```
- **Ganancia esperada:** ~10-15% (menos paralelizable: acumulador)
- **Riesgo:** BAJO (reduction() maneja correctly)
- **Compilación:** `-fopenmp`

---

**Loop #3: Kinetic Energy Sum (thermo_nh_system.f, línea ~200)**
```fortran
! ANTES:
ek_total = 0.0d0
do i=1,nat
  ek_total = ek_total + 0.5d0 * rmasa(i) * (vx(i)**2 + vy(i)**2 + vz(i)**2)
enddo

! DESPUÉS:
ek_total = 0.0d0
!$omp parallel do reduction(+:ek_total)
do i=1,nat
  ek_total = ek_total + 0.5d0 * rmasa(i) * (vx(i)**2 + vy(i)**2 + vz(i)**2)
enddo
!$omp end parallel do
```
- **Ganancia esperada:** ~5-10%
- **Riesgo:** BAJO
- **Compilación:** `-fopenmp`

---

#### 2.2 GPU Optimization (FUTURA, NO ESTA FASE)
- ✋ Mantener kernels CUDA como están (funcionales)
- 📌 Future: Usar CUDA streams (async transfers) para ocultar latencia

---

### **FASE 3: IMPLEMENTACIÓN** (Delegada a agente especializado)

**Agente de Código recibe:**
1. Este plan (estructura + líneas exactas)
2. Main files a editar: `main.f`, `baros_nh_system.f`, `thermo_nh_system.f`
3. Instrucciones: Usar Edit tool, NO sed
4. Compilar: `gfortran -O3 -march=native -cpp -fopenmp ...`
5. Link: `gfortran -O3 -fopenmp -o dm_mx_npt *.o -L/usr/local/cuda-13.0/lib64 -lcudart -lstdc++ -lgomp`

**Si compila:**
→ Agente 2 (Validación) ejecuta framework

**Si crash:**
→ Parar, reportar, NO continuar

---

### **FASE 4: VALIDACIÓN** (Agente de Validación)

**Criteria:**
✅ Compilación exitosa (sin warnings sobre race conditions)  
✅ Quick test (1 run × 1000 pasos) en <30 seg, sin seg fault  
✅ 3 full runs × 1000 pasos: energías reproducibles (Δ < 0.1%)  
✅ Wall time comparado vs baseline (esperar mejora o explicar)  

**Output:** Reporte con tiempos, energías, y conclusión de aceleración

---

## ⏱️ TIMELINE ESTIMADO

| Fase | Duración | Responsable |
|------|----------|-------------|
| 1. Análisis | 100s | ✅ Agente (completo) |
| 2. Diseño Plan | 10 min | 👤 TÚ (ahora) |
| 3. Implementación | 20-30 min | 🤖 Agente 2 |
| 4. Validación | 15 min | 🤖 Agente 3 |
| **TOTAL** | **60-75 min** | — |

---

## 🚨 CRITERIOS DE ABORTO (Rollback immediato)

❌ **Fase 3 falla:** Seg fault tras 1 intento → Revert main.f, parar  
❌ **Fase 4 falla:** Energías divergen >1% vs baseline → Parar, investigar  
❌ **No compila:** Tras 2 intentos fix → Abortar  

→ Documento lección aprendida + rollback a main.f.pre_openmp

---

## ✅ CRITERIOS DE ÉXITO

✅ **Ejecutable compila** sin errores (-fopenmp -march=native)  
✅ **No seg faults** en quick test  
✅ **Reproducibilidad** (3 runs, Δ energía < 0.1%)  
✅ **Aceleración medible** (ideal: >10%, aceptable: >5%)  
✅ **GPU sigue funcionando** (kernels CUDA active)  

---

## 🎬 PRÓXIMO PASO

**TÚ revisar este plan:**
- ¿Loops identificados son correctos?
- ¿Riesgos mitigation OK?
- ¿Compilación flags correctos?
- ¿Timeline aceptable?

**Si apruebas:** → Delegar Fase 3-4 a agentes especializados

**Si hay cambios:** → Editar este plan + re-iterar

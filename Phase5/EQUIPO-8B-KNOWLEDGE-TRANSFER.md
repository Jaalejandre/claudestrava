---
date: 2026-09-13T23:05:00-06:00
source: EQUIPO 8B Knowledge Transfer Session
status: pending_confirmation
---

# INFORMACIÓN TRANSFERIDA A EQUIPO 8B

## 1. EQUIPO 8B CREADO ✅

```
EQUIPO 8B: MD EXPERT
├─ Especialista en Dinámica Molecular
├─ 3 bots (md-algorithms-expert, potentials-specialist, performance-analyzer)
└─ Integración con EQUIPO 8 (DM UAMI Coordination)
```

**Documento:** `/root/JarvisVault/Phase5/EQUIPO-8B-MD-EXPERT.md`

---

## 2. CONOCIMIENTO BASE TRANSFERIDO

### A. Arquitectura del Programa Fortran

```
UBICACIÓN: /home/alejandre/DM UAMI/Programa_DM/
├─ programa.f95         (Main loop)
├─ lista.f95           (Neighbor list - O(N))
├─ fuerzas.f95         (Force computation - 7 casos)
├─ kwald.f95           (Ewald summation)
└─ integ.f95           (Integration - Verlet/Nosé-Hoover/NPT)

BASELINE:
  • Performance: 942 st/s (GPU CT 109)
  • Wall time: 1,000,000 steps = 10.6 seconds
```

### B. Potenciales Implementados

```
✅ Lennard-Jones (LJ)           → ε, σ
✅ Mie                          → n, m coefficients
✅ Fluctuating Dipole (FDR)     → polarizability α
✅ Ewald Summation              → short-range erfc + FFT
✅ Nosé-Hoover Thermostat       → NVT ensemble
✅ NPT Barostat                 → isobaric-isothermal
```

### C. Phase 5 CUDA Kernels (Target)

```
KERNEL 1: LISTA (Neighbor List)
  ├─ Current: Fortran loop (30% wall time)
  ├─ Parallelization: Grid-cell search (CUDA)
  ├─ Expected: 5-10× speedup
  └─ Implementation: 128 blocks × 256 threads

KERNEL 2: FUERZAS (Force Computation)
  ├─ Current: Fortran casos 1-7 (50% wall time)
  ├─ Parallelization: Thread per pair
  ├─ Expected: 10-20× speedup
  └─ Implementation: 256 blocks × 256 threads

KERNEL 3: KWALD (Ewald Summation)
  ├─ Current: FFT + real-space (20% wall time)
  ├─ Parallelization: cuFFT + CUDA real-space
  ├─ Expected: 8-15× speedup
  └─ Implementation: Variable (FFT library)

TARGET: ≥ 1200 st/s (+27% from 942 st/s)
```

### D. Algoritmos Críticos

**Verlet/Velocity Verlet integración:**
```
x(t+dt) = 2*x(t) - x(t-dt) + f(t)/m * dt²
v(t) = (x(t+dt) - x(t-dt)) / 2*dt
```

**Neighbor List (O(N) culling):**
```
For i = 1..N:
  For j = i+1..N:
    If distance(i,j) < rc + skin:
      Add j to list[i]
```

**Lennard-Jones potential:**
```
U_LJ = 4ε[(σ/r)¹² - (σ/r)⁶]
F = -dU/dr = 24ε[2(σ/r)¹³ - (σ/r)⁷]
```

**Ewald Summation:**
```
E = E_real_space + E_fourier_space + E_self
Real: Σ erfc(αr)/r for r < r_cut
Fourier: FFT of charge density * kernel
```

---

## 3. CONFIGURACIÓN DE CORRIDA LARGA (2026-09-13)

### archivo.mdp - Control nstxyz=0

```mdp
; DM UAMI Long Run (nstxyz=0)
integrator              = md
dt                      = 0.001      ; 1 fs
nsteps                  = 1000000    ; 1 ns total

; *** OUTPUT CONTROL ***
nstxyz                  = 0          ; ← NO escribir movie.gro (ahorro ~1.5 GB)
nstvout                 = 1000       ; Velocidades cada 1 ps
nstfout                 = 1000       ; Fuerzas cada 1 ps
nstlog                  = 100        ; Log cada 100 fs
nstenergy               = 100        ; Energía cada 100 fs

; NEIGHBOR SEARCH
nstlist                 = 10
ns_type                 = grid
rlist                   = 1.0

; CUTOFFS
rcoulomb                = 1.0
rvdw                    = 1.0

; TEMPERATURE COUPLING
tcoupl                  = Nosé-Hoover
tau-t                   = 1.0
ref-t                   = 300        ; 300 K

; PRESSURE COUPLING
pcoupl                  = Berendsen
pcoupltype              = isotropic
tau-p                   = 1.0
ref-p                   = 1.0
compressibility         = 4.5e-5

; EWALD
fourierspacing          = 0.16
ewald-rtol              = 1e-5
pme-order               = 4

pbc                     = xyz
```

### Parámetros de Ejecución

```
Simulation Time:    1000 ps (1 nanosecond)
Timestep:           1 fs (0.001 ps)
Total Steps:        1,000,000
Expected Runtime:   ~18 minutos (con GPU a 942 st/s)

Output Files:
  ✅ archivo.edr     (energía, cada 100 fs)
  ✅ archivo.trr     (velocidades, cada 1 ps)
  ✅ archivo.frc     (fuerzas, cada 1 ps)
  ✅ archivo.log     (completo)
  ❌ archivo.gro     (NO - ahorro de I/O)

Disk Space Saved:
  Without nstxyz=0:  ~3-5 GB (movie.gro cada 100 fs)
  With nstxyz=0:     ~0.5 GB (solo energía + log)
  Net saving:        ~3-4.5 GB
```

---

## 4. PRÓXIMOS PASOS PARA EQUIPO 8B

### Acción Inmediata

```
TODO PARA EQUIPO 8B:

1. Localizar Programa_DM en CT 901
   └─ Verificar si está en /home/alejandre/DM UAMI/
   └─ Si no, revisar /root, /opt, o crear link simbólico

2. Copiar archivo.mdp al directorio correcto
   └─ nstxyz=0 (no movie.gro)
   └─ Configuración optimizada para corrida 1 ns

3. Compilar Programa_DM
   └─ make clean && make
   └─ Verificar binary programa.exe

4. Ejecutar corrida larga (serial)
   └─ ./programa.exe < archivo.mdp > archivo.log 2>&1 &
   └─ Monitorear con tail -f archivo.log

5. Recopilar resultados
   └─ archivo.edr (energético)
   └─ archivo.log (trazas)
   └─ archivo.trr (trayectoria velocidades)
```

### Validación

```
CHECKS DESPUÉS DE CORRIDA:

Energy Conservation:
  └─ ΔE/E_initial < 0.1% (ideal)
  └─ Ver en archivo.log (last frame)

Trajectory Stability:
  └─ archivo.trr debe existir (velocidades)
  └─ Size: ~50-100 MB (nstxyz=0)

Force Consistency:
  └─ archivo.frc debe existir (fuerzas)
  └─ Verificar F = -dU/dr analíticamente en primeros pasos
```

### Para Phase 5

```
KERNEL OPTIMIZATION GUIDANCE:

LISTA parallelization:
  • Use CUDA grid-stride loops para O(N)
  • Atomic operations para lista acumulativa
  • Benchmark: compare vs CPU lista.f95

FUERZAS parallelization:
  • One thread per neighbor pair
  • Branch prediction: considerar casos 1-7
  • Warp divergence: major bottleneck aquí

KWALD parallelization:
  • Use cuFFT (state-of-art)
  • Real-space: CUDA kernel estándar
  • Memory bandwidth: critical (FFT-bound)
```

---

## 5. DOCUMENTOS ENTREGADOS

```
📄 /root/JarvisVault/Phase5/EQUIPO-8B-MD-EXPERT.md
   └─ Full knowledge base para MD specialist
   └─ Algoritmos, potenciales, CUDA optimization
   └─ SOUL.md templates para 3 bots

📄 /root/JarvisVault/Phase5/archivo.mdp
   └─ Configuración para corrida larga (1 ns)
   └─ nstxyz=0 (sin movie.gro)
   └─ Optimizado para GPU
```

---

## 6. STATUS

```
✅ EQUIPO 8B CREADO
✅ Conocimiento transferido
✅ Configuración de corrida larga lista
⏳ BLOQUEADO: Ubicación exacta de Programa_DM en CT 901
⏳ BLOQUEADO: SSH access a CT 901 (alejandre@192.168.0.230)

PRÓXIMO:
  José confirma ubicación de Programa_DM en CT 901
  → EQUIPO 8B prepara y ejecuta corrida larga
  → Resultados en 18 minutos (GPU)
```

---

*Transferencia completa de información científica a EQUIPO 8B*
*Timestamp: 2026-09-13 23:10 CST*
*Esperando confirmación de José sobre ubicación real del código*

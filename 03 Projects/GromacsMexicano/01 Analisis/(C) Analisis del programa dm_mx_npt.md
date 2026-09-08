# (C) Análisis del programa `dm_mx_npt`

> Documento generado por Claude a partir de la lectura del código en
> `CT 901:/home/alejandre/Programa_DM/` (copia de trabajo con git en
> `/home/alejandre/GromacsMexicano/`).
> Fecha: 2026-09-03. Commit base: original de los científicos, sin modificar.

---

## 1. Qué es

`dm_mx_npt` es un programa de **dinámica molecular (DM)** escrito por un grupo de
científicos, en **Fortran 77 / 90 / 95** con **kernels CUDA** para las partes
caras. Simula un sistema de partículas (átomos agrupados en moléculas) en el
ensamble **NPT** (número de partículas, presión y temperatura constantes) usando:

- Integrador **velocity-Verlet** (`md-vv`) con **multiple-time-step (MTS / RESPA)**:
  fuerzas rápidas (enlaces) se integran más seguido que las lentas (Ewald recíproco).
- Termostato **Nosé–Hoover en cadena** (`nh-chain-length = 3`).
- Barostato **MTTK** isotrópico (Martyna–Tobias–Klein) para NPT.
- Electrostática por **suma de Ewald** (espacio real truncado + espacio recíproco).
- Varios potenciales de van der Waals seleccionables: **Lennard-Jones, Mie, y FDR**
  (un potencial "suave" con parámetro `soft`), cada uno en variante
  **shifted-force (SF)** o **truncada (ST)**.
- Correcciones de largo alcance (LRC) opcionales para energía y presión.

El programa está diseñado para ser **compatible con los archivos de entrada de
GROMACS** (`file.mdp`, `file.top`, `file.gro`) — de ahí el nombre del proyecto.
Renglones extra que GROMACS ignora (p. ej. `dm-skin`) llevan parámetros propios
de la DM.

### Entrada / Salida

| Entra | Sale |
|---|---|
| `file.gro` — configuración inicial (coordenadas + velocidades + caja) | `dm.log` / `dm.lis` — log detallado paso a paso |
| `file.top` — topología (tipos de átomo, σ/ε, cargas, enlaces, ángulos, diedros, `nbfunc`) | `energy.dat` — tabla de 27 columnas por paso (energías, tensor de presión, caja, T, P) |
| `file.mdp` — parámetros de la corrida (dt, nsteps, rcut, termostato, barostato, Ewald) | `movie.gro` — trayectoria para VMD |
| | `error.dat` — deriva de energía `ΔE` |
| | `energia_*.dat`, `temperatura.dat`, `presion.dat`, `densidad.dat` |

`nbfunc` (en `[defaults]` de `file.top`) selecciona el potencial:
`1`=LJ-SF, `2`=Mie-SF, `3`=FDR-SF, `4`=LJ-ST, `5`=Mie-ST, `6`=FDR-ST.
El caso de prueba usa **`nbfunc=4` (LJ truncado)** aunque el archivo declara `1`
(el comentario `; dm_nbfunc 4` es el que manda para la DM).

---

## 2. Arquitectura del código

~2200 líneas en `main.f` + **69 archivos `.f`** + **28 archivos `.f95`** + **8 kernels `.cu`**.

### Patrón Fortran ↔ CUDA (3 capas)

```
main.f  ──►  fzas_lj_st.f          (wrapper Fortran fino, "elige ruta")
             └─► fzas_lj_st_cuda_f77.f95   (interfaz ISO_C_BINDING)
                 └─► fzas_lj_st_cuda.cu     (host C + __global__ kernel)
```

Para cada potencial hay **dos implementaciones que se ejecutan y comparan**:
- `*_f77` → versión CPU serial de referencia.
- `* ` (sin sufijo) → versión que llama a CUDA.

`escribe_error_fzas` imprime la diferencia CPU-GPU en fuerzas/energía y el
cociente de tiempos. Esto es un **arnés de validación**, no código de producción:
en cada arranque corre ambas versiones (por eso el log dice
`Tiempo CPU/GPU = 26.5`, `Error fuerzas CPU-GPU = 1.1e-9`).

### Inventario de rutinas por función

| Grupo | Archivos | Qué hace |
|---|---|---|
| **Driver** | `main.f` | lee entrada, inicializa, corre el bucle de DM, escribe salida |
| **Lectura entrada** | `gro0.f`, `top_gmx.f95`, `mdp.f`, `top_f77.f`, `top_sfmie*.f` | parsea `.gro` / `.top` / `.mdp` estilo GROMACS |
| **Distribución de topología** | `distribuir_de/angulos/diedros/15/tipos/masas/cargas.f`, `inicio_molecula.f` | expande parámetros por-especie a arreglos por-átomo |
| **Lista de vecinos** | `lista.f` → `lista_linkcell_cuda_f77.f95` → `lista_linkcell_cuda.cu`, `check.f` | link-cell en GPU; `check` decide cuándo reconstruir (criterio `4·dr_max² > skin²`) |
| **Fuerzas intramoleculares** | `fzas_de.f` (enlaces), `fzas_angulo.f`, `fzas_diedro.f`, `fzas_15.f` (pares 1-5) | CPU serial |
| **Fuerzas no enlazadas (vdW+Coulomb real)** | `fzas_{lj,mie,fdr}_{sf,st}.f` + `_f77` + `.cu` | **el corazón del costo**; ruta GPU |
| **Ewald recíproco** | `kwald_cuda.cu`, `kwald_cuda_f77.f95`, `intra.f` (auto-término), `setup2.f`, `compute_kmax_ewald.f`, `kappa_coulomb.f` | espacio-k en GPU |
| **Termostato** | `thermo_nh_system.f`, `nosint.f`, `nosinit.f`, `ini_etas_system.f`, `energy_thermo_system.f` | Nosé–Hoover en cadena |
| **Barostato** | `baros_nh_system.f`, `ini_xis_system.f`, `factores.f`, `energy_baros_system.f` | MTTK NPT |
| **LRC** | `setup_lrc_{lj,mie,fdr}_st.f95`, `lrc_lj_st.f95` | correcciones de dispersión |
| **Centro de masa / PBC** | `cofm.f`, `xyz_cofm.f`, `shift_cofm.f`, `remove_vcofm.f` | recentra moléculas, quita momento del CM |
| **Promedios / salida** | `sumas_gmx.f`, `promedios_gmx.f95`, `iniciar_variables_gmx.f`, `gro_write.f`, `grof.f`, `escribe_error_fzas.f95` | acumula ⟨X⟩ y ⟨X²⟩, escribe archivos |
| **Utilería** | `gauss.f`, `ranf0.f` (RNG), `save.f`, `io_dm.f95` (unidad de log) | |

---

## 3. Flujo de ejecución

### Inicialización (una vez)
1. Abre `dm.log`, `energy.dat` y ~12 archivos `.dat`.
2. `gro0` lee la configuración inicial → `rx,ry,rz`, `vx,vy,vz`, caja.
3. `top_gmx` lee la topología → σ, ε, cargas, enlaces, ángulos, diedros, `nbfunc`.
4. `mdp` lee parámetros de la corrida.
5. Configura LRC según `DispCorr`.
6. `distribuir_*` expande la topología por-especie a arreglos planos por-átomo.
7. `remove_vcofm`, `shift_cofm`, `cofm` — limpia el estado inicial.
8. Inicializa termostato (`ini_etas_system`) y, si NPT, barostato (`ini_xis_system`).
9. Construye la primera **lista de vecinos** (`lista` → link-cell CUDA).
10. Si Ewald: `compute_kmax_ewald` + `setup2` (vectores recíprocos `KVEC`).
11. **Cálculo de fuerzas inicial** (todos los términos) — aquí corre el arnés
    de validación CPU vs GPU.

### Bucle de DM (`do istep = 1, nsteps`)  ← 10 000 iteraciones en la prueba
Para cada paso, y dentro un sub-bucle MTS `do k = 1, nmts`:

```
barostato (medio paso)  ──►  termostato (medio paso)
  para k = 1..nmts:
     v ← v + ½·dt·F/m            (patada con F(t))
     r ← r + dt·v                (deriva; si NPT, escala la caja)
     aplica PBC
     check()  → si hace falta, lista()   (reconstruir vecinos)
     fzas_de + fzas_angulo + fzas_diedro + fzas_15   (F rápidas, CPU)
     si mod(k,nts1)==0:  fzas_<nbfunc>()             (F vdW+Coulomb real, GPU)   ← CARO
     si mod(k,nts2)==0:  INTRA + cofm + KWALD()      (F Ewald recíproco, GPU)    ← CARO
     F = F1 + nts1·F2 + nts2·F3
     v ← v + ½·dt·F/m            (patada con F(t+dt))
     acumula tensor de presión
  termostato (medio paso)  ──►  barostato (medio paso)
  sumas_gmx()   (acumula promedios)
  cada nstlog:    escribe bloque a dm.log
  cada nstenergy: escribe fila a energy.dat
  cada nstxout:   escribe frame a movie.gro
```

Al final: `promedios_gmx` imprime ⟨energías⟩, ⟨T⟩, ⟨P⟩, ⟨ρ⟩ con su desviación.

---

## 4. Estado de la paralelización (hoy)

| Parte | Dónde corre | Comentario |
|---|---|---|
| Fuerzas no enlazadas vdW + Coulomb real | **GPU** (1 hilo por par) | kernel correcto, resultado validado a 1e-9 |
| Lista de vecinos (link-cell) | **GPU** | 2 kernels: asignar celdas + construir pares |
| Ewald recíproco (`KWALD`) | **GPU** | 4 kernels |
| Fuerzas de enlace / ángulo / diedro / 1-5 | CPU serial | baratas para este sistema |
| Integración, termostato, barostato, PBC, promedios | CPU serial | bucles `do i=1,nat` sin vectorizar/paralelizar |
| Versión `*_f77` de cada fuerza | CPU serial | **se ejecuta también** en el arranque (validación) |

La corrida de referencia usó **99 % de UN core de CPU durante 3:00 min**. Es decir:
aunque los kernels CUDA existen y son correctos, **el programa está dominado por
overhead de CPU y de transferencia CPU↔GPU**, no por cómputo de GPU.

---

## 5. Cuellos de botella identificados (orden de impacto esperado)

### 🔴 A. Cada llamada de fuerza re-hace TODA la gestión de memoria GPU
En `fzas_lj_st_cuda.cu` (y sus 7 hermanos), la función host hace **por cada paso de DM**:
- ~20 `cudaMalloc`
- ~8 `cudaMemcpy` Host→Device (posiciones, tipos, cargas, σ/ε, listas)
- lanzar kernel + `cudaDeviceSynchronize`
- ~11 `cudaMemcpy` Device→Host
- ~20 `cudaFree` (al final del archivo)

Para 2544 átomos y 10 000 pasos esto es **decenas de miles de malloc/free y
copias completas de arreglos** cuya latencia supera por mucho el tiempo del
kernel. **Arreglo:** asignar los buffers GPU **una sola vez** al inicio, mantener
posiciones/fuerzas residentes en device, subir sólo lo que cambió (posiciones,
y la lista sólo cuando se reconstruye), y bajar sólo lo necesario. Este es
probablemente el 80 % del problema.

### 🔴 B. Compilado sin optimizar
`compilar_cuda.sh` usa `FFLAGS="-O0 -g -fbacktrace -fcheck=bounds -ffpe-trap=invalid,zero,overflow"`.
Eso es un build de **depuración**: sin optimización, con chequeo de límites de
arreglo en cada acceso y trampas de FPE. `NVCC` además lleva `--fmad=false`.
**Arreglo:** build de release `-O3 -march=native -funroll-loops` (Fortran) y
quitar `--fmad=false` salvo que la validación lo requiera. Ganancia grande y casi
gratis; mantener el build debug como opción aparte.

### 🟠 C. `atomicAdd` de doble precisión sobre 8 escalares globales
El kernel hace `atomicAdd(ulj,…)`, `atomicAdd(ucoul,…)` y 6 `atomicAdd` al
tensor de presión — **todos los hilos golpean las mismas 8 direcciones**. En GPU
eso serializa. **Arreglo:** reducción por bloque (shared memory) + un solo
atomicAdd por bloque, o reducción en un segundo kernel.

### 🟠 D. `atomicAdd` a `fx[i]`, `fx[j]` por cada par
Colisión de escritura cuando varios pares comparten átomo. **Arreglo típico en
MD-GPU:** kernel por **átomo i** que recorre sus vecinos y acumula en registro
(sin atomics), usando lista de vecinos completa (no "half"). Requiere cambiar el
formato de la lista.

### 🟡 E. Matemática del kernel
`pow(sigmaij/rij, 6.0)` en vez de multiplicaciones (`s2=s*s; s6=s2*s2*s2`);
`erfc`/`exp`/`sqrt` por par. Tolerable, pero `pow` con exponente real es caro.

### 🟡 F. Arnés de validación en el bucle caliente del arranque
Correr `*_f77` (CPU serial) además de la versión GPU dobla el costo del cálculo
de fuerzas inicial. Debería ser un modo (`--validate`) desactivable.

### 🟡 G. Bucles de CPU sin paralelizar (OpenMP)
Integración velocity-Verlet, PBC (`dnint`), acumulación del tensor de presión,
`virk`, `check` (busca `dr_max`) — todos `do i=1,nat` triviales de paralelizar
con `!$omp parallel do` / reducción. Con 12 vCPU disponibles.

### 🟡 H. Deuda técnica del enlace
El link necesita `-Wl,--allow-multiple-definition` porque los módulos
`interfaz_*_cuda` y los wrappers `*_cuda_f77` **definen ambos** los símbolos de
`iso_c_binding`. Señal de que hay interfaces duplicadas (un `module` y un
`subroutine` suelto para lo mismo). Limpiar reduce riesgo de bugs sutiles.

### 🟢 I. Sub-bucle MTS llama fuerzas rápidas siempre
`fzas_de/angulo/diedro/15` se calculan en cada `k` del MTS aunque el beneficio
del MTS es no recalcular las lentas. Correcto, pero son CPU serial (ver G).

---

## 6. Física de referencia (NO debe cambiar al optimizar)

Corrida base: agua SPC/E (800 mol) + 72 Na + 72 Cl = **2544 átomos**, `nbfunc=4`
(LJ-ST), Ewald, Nosé–Hoover + MTTK, `dt=0.2 fs`, `nsteps=10000`.

| Cantidad | Valor de referencia | σ |
|---|---|---|
| Potential (kJ/mol/mol) | −98.874 | 0.214 |
| Kinetic | 10.002 | 0.167 |
| Total (conservada) | −89.058 | 0.012 |
| ΔE (deriva) | 0.00013 | 0.00009 |
| Density (kg/m³) | 1162.96 | 7.34 |
| Temperature (K) | 297.60 | 4.96 |
| Pressure (bar) | 2.20 | 791.9 |

Criterio de aceptación de cualquier optimización: estas cantidades deben
reproducirse **dentro de ~1σ**, y `ΔE` (conservación de la energía extendida) no
debe empeorar.

> Nota: la corrida es corta (2 ps) y la presión tiene una barra de error enorme
> (±792 bar) — normal en sistemas pequeños. Para benchmarks serios de física
> conviene una corrida más larga como caso canónico (TODO en el CLAUDE.md).

---

## 7. Plan de ataque propuesto (para `02 Optimizacion/`)

| # | Cambio | Riesgo | Ganancia esperada |
|---|---|---|---|
| 1 | Build de release `-O3 -march=native` (Fortran) + quitar `-fcheck`/`-ffpe-trap`; mantener build debug aparte | bajo | media-alta |
| 2 | Buffers GPU persistentes: `cudaMalloc` una vez, posiciones/fuerzas residentes en device, subir sólo `r` por paso y la lista sólo al reconstruir | medio | **muy alta** |
| 3 | Reducción por bloque para energías y tensor de presión (evitar 8 atomicAdd globales) | medio | media |
| 4 | Hacer el arnés de validación CPU-GPU un modo opcional (`--validate`) | bajo | media (arranque) |
| 5 | OpenMP en los bucles `do i=1,nat` de CPU (integración, PBC, presión, check) | bajo | media |
| 6 | Kernel de fuerzas por átomo-i con acumulación en registro (sin atomics de fuerza) | alto | alta |
| 7 | Micro-optimización del kernel: potencias por multiplicación, `--use_fast_math` evaluado contra validación | bajo | baja |
| 8 | Limpiar interfaces `iso_c_binding` duplicadas y quitar `--allow-multiple-definition` | medio | 0 perf, −riesgo |

Cada cambio: aislado, recompilar, correr la prueba, comparar física vs. §6 y
tiempo vs. línea base, registrar en `03 Benchmarks/`.

---

## 8. Preguntas para los científicos

1. ¿El arnés de validación CPU-GPU (`escribe_error_fzas`) debe seguir corriendo
   siempre, o se puede volver opcional?
2. ¿Hay un caso de prueba "oficial" más largo/grande para validar física y medir
   escalamiento? ¿Qué tolerancia consideran aceptable en energía/presión?
3. ¿Las variantes `*_f77` (CPU) se usan en producción o son sólo referencia?
4. ¿`--fmad=false` es un requisito de reproducibilidad numérica o quedó de una
   depuración?
5. ¿El objetivo es exprimir esta base Fortran+CUDA, o es el punto de partida para
   reescribir (¿en qué lenguaje/framework: C++/Kokkos, OpenMM, JAX-MD…)?

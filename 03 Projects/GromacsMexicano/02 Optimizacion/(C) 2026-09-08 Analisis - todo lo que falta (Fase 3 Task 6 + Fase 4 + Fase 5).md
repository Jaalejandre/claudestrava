---
tipo: analisis-rewrite
fecha: 2026-09-08
proposito: mapa completo del trabajo restante del rewrite C++ para despachar agentes implementadores
estado-repo-CT901: c3ba387 (Fase 3 Tasks 1-5 completas, 13/13 tests verde)
progreso-2026-09-10: **REWRITE C++ FASES 0–6 COMPLETAS + writers + diedros/1-5 + casos A/D.**
- Writers per-paso (`ed417d9`): `energy.dat` (formato Fortran exacto), `dm.log`, `movie.gro`, `confout.gro` (config final, NO sobrescribe `file.gro`). `test_output`.
- Diedros + pares 1-5 + casos MTS A/D (`308867f`): `compute_dihedral_forces` (fzas_diedro), `compute_pair15_forces` (fzas_15), casos A/D en main.cpp. Port línea por línea. **NO validado contra Fortran** (no hay sistema de prueba con diedros) — solo consistencia F=−dU/dr a 1e-6 (`test_bonded_extra`). No-op para agua → 22/22 tests verde, Fase 5 sin regresión. Falta para producción en moléculas orgánicas: fixture tipo IPA (.gro/.top), verificar conversión funct-1→coefs del parser (`top_gmx.f95`), correr Fortran parcheado, gate end-to-end.
- Fase 6 (`53b8dd0`): detección GPU/CPU, `--help`, `install()`+CPack TGZ. Falta deb/rpm — decisión de bundling del runtime CUDA.
progreso-2026-09-10: **REWRITE C++ FASES 0–5 COMPLETAS.** Task 6 (e9cb8b0), 4.1+4.6 (e69c046), 4.5 (bad440a), 4.4 (475be68), 4.2+4.3 NH Trotter (c4d3d63), 4.7 integrador MTS+NPT (22b5791 + física correcta 1065408 + perf), 4.8-lean + 4.9 main.cpp (a2fb576), **Fase 5 gate end-to-end** → ver `03 Benchmarks/(C) 2026-09-10 Fase 5 - Gate end-to-end`. 20/20 tests verde. Gate 5-pasos NVE/NVT bit-idéntico al Fortran; 10k pasos: promedios dentro de 1σ, deltaE 6× mejor que Fortran, ~1.5× más rápido. FALTA: confirmar fix NATQ con científicos; Fase 6 (empaquetado); writers per-step (diferidos).

## ⚠️ BUG en el Fortran de referencia (encontrado 2026-09-10, Fase 4.7)

`main.f:1641` — dentro del loop de MD llama `KWALD(NATQ,…,CARGAQ,…)` pero **`NATQ` nunca se inicializa (=0, confirmado en `dm.lis`)** y `CARGAQ` nunca se llena (`BUILD_CHARGED_ATOMS_EWALD` está comentado). Resultado: **durante la dinámica, la energía Y las fuerzas de Ewald recíproco son cero** — solo sobreviven el término self + la corrección erf intramolecular (`INTRA`). El bloque pre-loop "Valores iniciales" (`main.f:955`) sí pasa `NAT/CARGA`, así que las energías en t=0 son correctas (por eso Task 5 validó pero el loop divergía: `ukwald` congelado ~−36.7 vs Fortran −37.4 = −vkwaldi).

- **Implicación física:** el run de referencia (y todos los benchmarks previos) corrió **sin Ewald recíproco en las fuerzas**. Electrostática = solo real-space apantallado + self. Preguntar a los científicos si es intencional (¿aproximación?) o un bug a corregir.
- **En el rewrite:** `compute_ewald_recip()` / `compute_all_forces()` tienen un bool `recip_in_loop` (default `true` = física correcta). `IntegratorParams::recip_in_loop` default `false` = bit-match con la referencia. Cambiar a `true` cuando los científicos confirmen.

### Estado gate 4.7 (nsteps=5, NVE/NVT/NPT vs Fortran fresco)
etot rel 3.7e-4 · T rel 4.3e-3 · box rel 2.5e-5 (NPT) · deltaE (conservación) sigue a Fortran dentro de 2×. La divergencia de trayectoria per-step ~1e-4 es esperada (sistema caótico, ~100 evals de fuerza, `--fmad=false` CUDA vs `-O3` gfortran). Validación real = Fase 5 (10k pasos, promedios).
regla: NO se programó nada en esta sesión — solo análisis
---
	q
# Análisis: todo lo que falta del rewrite C++

> Pedido del usuario (2026-09-08): *"analiza todo lo que falta, no programes nada, solo haz el análisis, para después mandar agentes que programen todo y lo verifiques."*
>
> Este documento es ese análisis. Cada tarea está escrita para que un agente la implemente **de forma aislada** (un commit, un gate de validación) y para que yo (Claudian) la **verifique** contra el Fortran de referencia. Formato: archivos → fuente Fortran → interfaz C++ propuesta → algoritmo → criterio de validación → riesgo.

---

## 0. Estado actual (snapshot verificado)

### Hecho y validado

| Fase | Qué | Commit | Validación |
|---|---|---|---|
| Optimización GPU (Fortran) | −45.7 % wall-time | `ca9ef61` | física 1σ, cerrada por decisión del usuario 4-sep |
| 0 | CMake + kernels reubicados | (fase 0) | compila/linka sm_120 |
| 1 | Parsers `.gro` / `.mdp` / `.top` + `System` | `4547b7a` | 8/8, fixture SPC/E+NaCl 2544 átomos |
| 2 | Fuerzas bonded (bonds + ángulos armónicos) | `ee500a3` | FD gradient + hand-calc + net-zero |
| 3 T1 | guard reinit + `fzas_lj_st_free_cuda` en el kernel | `6c45e64` | 3× limpio, física 1σ, sin regresión |
| 3 T2 | `pack_lj_10x10` + `compute_lj_st` + `free_lj_st` | `6114b43` | 2-átomos 1e-12; fixture ΣF~3e-11 |
| 3 T3 | `NeighborList` + `nblist_build` + `nblist_needs_rebuild` (port `check.f`) | `76cf9db` | **npares = 1 552 648 exacto vs Fortran** + ref O(N²) + sin duplicados |
| 3 T4 | `ewald_setup` (`kappa_coulomb`+`compute_kmax_ewald`+`setup2`) | `7900649` | **rkappa 2.8699999377131 y kmax 11/11/11 exacto vs `dm.lis`**, 2975 k-vectores |
| 3 T5 | `compute_ewald_recip` (`intra`+`cofm`/`xyz_cofm`+`kwald_cuda`) | `bf1417f` | **vkwaldi 13 díg, vkwald 12 díg vs Fortran; ukwald/nmol = −36.704939 exacto; FD 2.2e-7** |
| 3 (fixture) | `step0_reference.txt` con energías t=0 + per-nat bonds/angles + `nts1/nts2` | `c3ba387` | (datos, no código) |

Todo en `Programa_DM_cpp/src/nonbonded.{hpp,cpp}` + `bonded_forces.{hpp,cpp}` + `system_builder.*` + `topology*.cpp` + `io/`.

### Infra de soporte (lista, no bloquea)
- CT 901: `ssh alejandre@192.168.0.230` (vía `ssh root@192.168.0.52` → `pct exec 901 -- su - alejandre`). GPU RTX 5070 Ti + CUDA 13, `nvcc` en `/usr/local/cuda/bin`.
- Build: `cd ~/GromacsMexicano/Programa_DM_cpp/build && export PATH=/usr/local/cuda/bin:$PATH && cmake . && make <target> && ctest`. Los tests corren desde `tests/` (rutas `fixtures/` relativas).
- Fortran de referencia: `~/GromacsMexicano/Programa_DM/` — **congelado**, solo lectura (excepción histórica: el guard aditivo de T1, ya idéntico en ambas copias).
- Fortran build: `cd Programa_DM && export PATH=/usr/local/cuda/bin:$PATH && ./compilar_release.sh` → binario `dm_mx_npt`.
- Oráculo físico: `Total = −89.05846 ± 0.01195 kJ/mol` (ref `ca9ef61`).
- BASE (memoria del proyecto) en CT 901: `base learn` / `base rule add` dominio `REWRITE-CPP`. Requiere `export HF_HOME=$HOME/.cache/huggingface`.
- Telegram para avisos: `ssh root@192.168.0.52 "pct exec 901 -- su - alejandre -c './notify_telegram.sh \"msg\"'"`.

---

## 1. Correcciones al plan maestro (hallazgos de esta sesión)

El plan maestro (`(C) 2026-09-04 Plan de reescritura a C++.md`) tiene supuestos que la lectura real del Fortran contradice. Los agentes deben usar **este documento**, no el maestro, para Fases 3T6 / 4 / 5:

1. **LRC (dispersion correction) SÍ está activa en el fixture.** El plan maestro dice "`DispCorr = no` → contribuye 0, diferir". Falso: `file.mdp` → `DispCorr = enerpres`; el run de referencia imprime `coef_lrc_u = −3417.39…`, `ulrc = −128.88…`, `plrc = −161.40…`. **PERO** el bloque `"Valores iniciales/nmol"` que usa el gate de la Task 6 se imprime **antes** de que `ulj += ulrc` ocurra (eso pasa dentro del loop `istep`), así que la Task 6 no necesita LRC — lo confirma que el `ulj` de la Task 2 (7344.045) ya casa con `step0_reference.txt`. **Fase 4 sí necesita LRC** (ver Task 4.6).
2. **`nmts` NO viene del `.mdp`** — se deriva en `main.f` según 4 casos (nbonds × recip_ewald). El fixture es **Caso C** (`nbonds=1600 > 0`, `recip_ewald=T`) → `nmts = nts2 = 20`.
3. **`p1/p2/p3`** (pesos de partición de presión para el barostato MTS) también se derivan por caso. Caso C: `p1 = p_ext·nts1/(nmts+1)`, `p2 = p_ext·(nts2−nts1)/(nmts+1)`, `p3 = p_ext/(nmts+1)`. Con `p_ext=1, nts1=10, nts2=20, nmts=20`: `p1 = 10/21`, `p2 = 10/21`, `p3 = 1/21` (suma = 1 = `p_ext`, el Fortran lo verifica y hace `stop` si no).
4. **`alfa = 1.0d0 + 1.0d0/nat`** (factor de acoplamiento del barostato isotrópico, main.f ~1104). Equivale a `1 + 3/dof` porque `dof = 3·nat`.
5. **Las velocidades iniciales vienen de `file.gro`** (`gro0.f` lee `vx,vy,vz`). **NO hay generación Maxwell-Boltzmann.** Simplifica Fase 4: no hace falta `gauss.f`/`ranf0.f`.
6. **`nch = 3`** para el fixture (`nh-chain-length = 3` en `file.mdp`). `MdpParams::nch` ya lo parsea.
7. **`fzas_diedro` y `fzas_15` son cero** en este sistema (`ndiedro=0`, `n15=0`) — no se portan (deferidos a Fase 6).
8. El **integrador es MTS r-RESPA velocity-Verlet** con impulsos: las fuerzas lentas (`fx2`, `fx3`) se evalúan cada `nts1` / `nts2` subpasos y se aplican multiplicadas por `nts1` / `nts2`. Ver §Task 4.7 para la estructura exacta.

---

## 2. FASE 3 · TASK 6 — Ensamblaje no-enlazado + GATE

**Riesgo:** gate (no código nuevo grande, pero es la primera vez que el path C++ calcula física completa end-to-end).

**Archivos:** crear `Programa_DM_cpp/src/forces.{hpp,cpp}`, `tests/test_forces_gate.cpp`; parche `src/CMakeLists.txt`.

**Fuente Fortran:** `main.f` líneas ~679-1075 (bloque de fuerzas pre-loop) y la combinación MTS `fx = fx1 + nts1·fx2 + nts2·fx3` (líneas ~1023, ~1676).

### Interfaz propuesta

```cpp
// forces.hpp
#pragma once
#include "nonbonded.hpp"      // NeighborList, EwaldSetup, LjResult, EwaldResult, Virial
#include "topology.hpp"       // Topology (para pack_lj_10x10)

namespace gmx {

struct ForceEval {
    // energías TOTALES (no /nmol) — el caller divide
    double vbonds = 0, vangles = 0;
    double ulj = 0, ucoul = 0;          // reales, de compute_lj_st
    double ukwald = 0;                  // vkwald - vkwaldi
    Virial vir_fast;                    // wxx1... (bonds+angles)
    Virial vir_lj;                      // wxx2... (LJ-ST + Coulomb real)
    Virial vir_ewald;                   // wxx3... (kwald - intra)
    int nmol = 0;
};

// Una evaluación de fuerzas COMPLETA para la config actual.
// Produce las 3 familias MTS por separado (fx1 rápidas, fx2 LJ, fx3 Ewald)
// — la combinación fx = fx1 + nts1*fx2 + nts2*fx3 es trabajo del integrador (Fase 4).
// nl y esetup se construyen perezosamente si vienen vacíos.
// rlist = rcut + skin.
ForceEval compute_all_forces(const System &sys, const Topology &topo,
                             const std::vector<double> &rx,
                             const std::vector<double> &ry,
                             const std::vector<double> &rz,
                             double boxx, double boxy, double boxz,
                             double rcut, double rlist, double error_coul,
                             NeighborList &nl, EwaldSetup &esetup,
                             std::vector<double> &fx1, std::vector<double> &fy1, std::vector<double> &fz1,
                             std::vector<double> &fx2, std::vector<double> &fy2, std::vector<double> &fz2,
                             std::vector<double> &fx3, std::vector<double> &fy3, std::vector<double> &fz3);

} // namespace gmx
```

### Algoritmo (Step 1)
1. **fx1 (rápidas):** `compute_bond_forces(sys, r, box, fx1,fy1,fz1, vir_fast, /*zero_first=*/true)` → `vbonds`; luego `compute_angle_forces(sys, r, box, fx1,fy1,fz1, vir_fast)` → `vangles`. (Ya validado en Fase 2; `zero_first` lo controla el caller.)
2. **Lista + setup Ewald (una vez):** `if (!nl.built) nblist_build(nl, sys, r, box, rlist);` `if (esetup.kvec.empty()) esetup = ewald_setup(box, rcut, error_coul);`
3. **fx2 (LJ-ST):** `auto s10 = pack_lj_10x10(topo.sigma_matrix, topo.natom_types()); auto e10 = pack_lj_10x10(topo.eps_matrix, topo.natom_types());` → `compute_lj_st(sys, r, s10, e10, nl.nb1, nl.nb2, nl.npares, nl.maxlist, rcut, esetup.rkappa, box, fx2,fy2,fz2)` → `ulj, ucoul, vir_lj`.
4. **fx3 (Ewald recíproco):** `compute_ewald_recip(sys, r, box, esetup, fx3,fy3,fz3)` → `ukwald, vir_ewald, nmol`.
5. Devolver `ForceEval`.

### Step 2 — EL GATE (`test_forces_gate.cpp`)
Cargar fixture (`file.top` → `System`+`Topology`, `file.gro` → posiciones), `rcut=1.2`, `skin=0.25` (rlist=1.45), `error_coul=1e-6`. Parsear `tests/fixtures/step0_reference.txt` (key/value simple). Asertar (todo /nmol, nmol=944):

| Magnitud | Referencia (`step0_reference.txt`) | Tolerancia |
|---|---|---|
| `vbonds/nat` | `0.87351021657292705` | rel 1e-9 (port CPU puro) |
| `vangles/nat` | `0.86538276018891291` | rel 1e-9 |
| `ulj` (total) | `7344.0447785995129` | rel 1e-5 (GPU) |
| `ucoul` (total) | `−69991.872905306402` | rel 1e-5 |
| `ukwald/nmol` | `−36.704939` | abs 5e-5 |
| `Σ(fx1 + nts1·fx2 + nts2·fx3)` | 0 | `< 1e-4·(fmax+1)` con `nts1=10, nts2=20` |
| FD de `epot = vbonds+vangles+ulj+ucoul+ukwald` en 10 átomos vs `fx1[a]+fx2[a]+fx3[a]` | — | rel < 5e-4, `h=1e-6` |

**Nota:** el FD del total es contra la suma **sin pesos MTS** (`fx1+fx2+fx3`), porque los pesos son un truco de integración, no física. Ya validado por-familia en Tasks 2/5; esto re-confirma en el path ensamblado.

### Step 3 — 3× limpio
Correr el gate 3× en CT 901 verificado idle (`who` + `ps aux | grep dm_mx_npt` + `nvidia-smi`). Confirmar que la tolerancia 1e-5 aguanta entre corridas (reducciones GPU no deterministas en el último bit).

### Verificación (yo)
- `git diff` = solo `forces.{hpp,cpp}` + `CMakeLists.txt` + `test_forces_gate.cpp`.
- Suite completa verde (14/14).
- Los 3 runs del gate dan los mismos números a 1e-5.
- `compute_all_forces` NO combina las familias (eso es Fase 4) — revisar que devuelve fx1/fx2/fx3 separadas.

---

## 3. FASE 4 — Integrador MTS + Nosé-Hoover NPT

**Riesgo global: ALTO.** Es la física más delicada. Presupuestar validación más instrumentada. Estrategia: portar cada pieza como **subrutina pura testeable** primero (Tasks 4.1-4.6), luego ensamblar el loop (4.7), luego el driver `main.cpp` (4.8), y recién ahí el gate end-to-end (Fase 5).

**Fuente Fortran (toda leída esta sesión):**
- `main.f` líneas 1204-2221 (setup NH/baro + loop `do istep` + MTS + output)
- `nosinit.f` (pesos Suzuki-Yoshida, `ncalls`, `dtsuz`)
- `thermo_nh_system.f` (cadena NH del termostato, escala TODAS las velocidades)
- `baros_nh_system.f` (cadena NH del barostato global)
- `energy_thermo_system.f`, `energy_baros_system.f` (energías de los reservorios)
- `factores.f` (factores `fv1/fv2/fr1/fr2` del propagador de caja)
- `ini_etas_system.f`, `ini_xis_system.f` (inicialización de las cadenas)
- `remove_vcofm.f` (quitar momento neto), `shift_cofm.f` (centrar COM en z para output)
- `setup_lrc_lj_st.f95`, `lrc_lj_st.f95` (dispersion correction)
- `gro_write.f` (frame de trayectoria → `movie.gro`), `grof.f` (config final → `file.gro`)
- `sumas_gmx.f` / `promedios_gmx` / `iniciar_variables_gmx.f` (acumuladores de promedios) — leer antes de portar
- `MdpParams` (`io/mdp_file.hpp`) — ya tiene todos los campos necesarios

### Constantes y unidades (comunes a toda la fase)
```
rgas   = 8.31446           ; J/(mol K)
factor = rgas/1000.0       ; kJ/(mol K)
RT     = factor * temp     ; kJ/mol
dof    = 3.0 * nat         ; grados de libertad (moléculas flexibles, sin constraints)
factorp     = 0.06022      ; bar·nm^3 -> kJ/mol
factor_pres = 16.605       ; (kJ/mol)/nm^3 -> bar   [nota: lrc_lj_st usa 16.605390671738468]
factor_temp = 1000.0/rgas  ; para T instantánea
alfa   = 1.0 + 1.0/nat     ; acoplamiento barostato isotrópico
```

---

### Task 4.1 — Pesos Suzuki-Yoshida (`nosinit`)

**Archivos:** `src/integrator.hpp` (crear) + `src/nose_hoover.cpp` (crear) + `tests/test_suzuki.cpp`.
**Fuente:** `nosinit.f` (completo, 52 líneas).

```cpp
struct SuzukiWeights {
    std::vector<double> dtsuz;   // ncalls valores
    int ncalls = 0;
    int nit = 5;                 // repeticiones externas (main pasa nit=5)
};
// msuz=2 (fijo en ini_etas_system) -> ncalls=5.
// psuz(2,i) para i=1..5:  w = 1/(4 - 4^(1/3))  para i != 3 ;  w3 = 1 - 4*w  para i==3.
// dtsuz(k) = psuz(2,k) * delt / nit    (delt = dt, nit = 5)
SuzukiWeights suzuki_weights(double dt, int msuz = 2, int nit = 5);
```
**Validación:** hand-calc. `4^(1/3) = 1.5874…`, `w = 1/(4−1.5874) = 0.41449…`, `w3 = 1 − 4·0.41449 = −0.65797…`. `dtsuz = {w,w,w3,w,w}·dt/5`. Asertar suma `Σdtsuz = dt/5` (los pesos suman 1). **Riesgo: muy bajo.**

---

### Task 4.2 — Cadena NH del termostato (`thermo_nh_system`)

**Archivos:** `src/nose_hoover.cpp` (misma unidad que 4.1) + `tests/test_thermo_nh.cpp`.
**Fuente:** `thermo_nh_system.f` (completo). **OJO:** el sistema usa la versión **`_system`** (una sola cadena para todo el sistema, escala todas las velocidades por igual), NO `nosint.f` (cadena por átomo — esa está comentada en `main.f`).

```cpp
struct NHThermostat {
    std::vector<double> eta, etadot, q;   // longitud nch
};
// ini_etas_system.f:
//   q[i]   = RT * tau_t^2   (para i = 0..nch-1)
//   eta[i] = etadot[i] = 0
//   etadot[1] = -etadot[0]   (= 0, ambos arrancan en 0 — inofensivo pero portarlo)
//   q[0]   = dof * q[1]
void nh_thermostat_init(NHThermostat &th, int nch, double RT, double tau_t, double dof);

// thermo_nh_system.f: propaga la cadena medio paso (Trotter), rescalando vx,vy,vz.
// ek = 0.5 * Σ m_i (vx^2+vy^2+vz^2)  (recalculado dentro tras cada rescale)
// feta[0] = 2*ek - dof*RT
// feta[L>=1] = q[L-1]*etadot[L-1]^2 - RT
// Bucle: for it in 1..nit:  for ic in 1..ncalls:  dts = dtsuz[ic];  <Trotter update>
//   (ver el orden EXACTO de operaciones en thermo_nh_system.f — 8 bloques:
//    etadot[nch-1] += 0.25*dts*feta[nch-1]/q[nch-1];
//    loop L=1..nch-1 descendente con AA=exp(-0.125*dts*etadot[iETA]): etadot[nch-1-L]=...
//    AA=exp(-0.5*dts*etadot[0]); vx*=AA; vy*=AA; vz*=AA;  recompute ek; feta[0]=2*ek-dof*RT;
//    eta[L] += 0.5*dts*etadot[L]  (todos L);
//    loop L=0..nch-2 ascendente: etadot[L]=...; feta[L+1]=q[L]*etadot[L]^2 - RT;
//    etadot[nch-1] += 0.25*dts*feta[nch-1]/q[nch-1]; )
void nh_thermostat_apply(NHThermostat &th, const SuzukiWeights &sw,
                         const System &sys,
                         std::vector<double> &vx, std::vector<double> &vy, std::vector<double> &vz,
                         double dof, double RT);
```
**Validación:**
- Unit: sistema de juguete (2-3 átomos, `nch=3`, velocidades arbitrarias). Comparar `eta/etadot/vx` tras 1 `apply` contra una re-implementación independiente del mismo pseudocódigo (segundo par de ojos), a 1e-12.
- **Conservación:** con `feta[0] = 0` exacto (velocidades ya a la T objetivo) y `eta=etadot=0`, `apply` no debe cambiar nada (AA=1).
- Integración: la validación real es en Fase 5 (el `Total`/`deltaE` del run de 10k pasos).

**Riesgo: ALTO** — el orden de operaciones Trotter es fácil de equivocar. Portar línea-por-línea, no "de memoria".

---

### Task 4.3 — Cadena NH del barostato (`baros_nh_system`)

**Archivos:** `src/nose_hoover.cpp` + `tests/test_baros_nh.cpp`.
**Fuente:** `baros_nh_system.f` (completo), `ini_xis_system.f`.

```cpp
struct NHBarostat {
    std::vector<double> xi, xidot, qp;   // longitud nch
    double wnose = 0;   // "masa" del pistón de volumen
    double ve = 0;      // velocidad de volumen (epsilon-dot)
    double evol = 0;    // epsilon (log del volumen / 3)
};
// ini_xis_system.f:
//   wnose = (dof + 3.0) * RT * tau_p^2
//   qp[i] = RT * tau_p^2  ;  xi[i]=xidot[i]=0
//   qp[0] = 9.0 * qp[1]
//   ve = evol = 0
void nh_barostat_init(NHBarostat &ba, int nch, double RT, double tau_p, double dof);

// baros_nh_system.f: propaga la cadena del barostato medio paso, rescalando ba.ve.
//   feta[0] = wnose*ve^2 - RT
//   feta[L>=1] = qp[L-1]*xidot[L-1]^2 - RT
//   (misma estructura Trotter que el termostato pero rescalando VE en vez de velocidades:
//    AA = exp(-0.5*dts*xidot[0]);  ve *= AA;  feta[0] = wnose*ve^2 - RT; ...)
void nh_barostat_apply(NHBarostat &ba, const SuzukiWeights &sw, double RT);
```
**Validación:** análoga a 4.2 (re-impl independiente a 1e-12; caso trivial `ve=0, xi=xidot=0` → sin cambio). **Riesgo: ALTO** (mismo motivo).

---

### Task 4.4 — Energías de los reservorios (`energy_thermo_system` + `energy_baros_system`)

**Archivos:** `src/nose_hoover.cpp` + `tests/test_nh_energy.cpp`.
**Fuente:** `energy_thermo_system.f`, `energy_baros_system.f` (ambos ~10 líneas).

```cpp
// energy_thermo_system.f:
//   enh = Σ_i [ 0.5*q[i]*etadot[i]^2 + RT*eta[i] ]  ;  enh += RT*(dof*eta[0] - eta[0])
double nh_thermostat_energy(const NHThermostat &th, double dof, double RT);

// energy_baros_system.f:
//   enhb = Σ_i [ 0.5*qp[i]*xidot[i]^2 + RT*xi[i] ]
//   enhb += p_ext*vol*factorp + 0.5*wnose*ve^2
double nh_barostat_energy(const NHBarostat &ba, double p_ext, double vol,
                          double factorp, double RT);
```
**Validación:** hand-calc con `eta/xi` conocidos. **Riesgo: bajo.**

---

### Task 4.5 — `factores` (propagador de caja) + `remove_vcofm` + `shift_cofm`

**Archivos:** `src/integrator.cpp` (crear) + `tests/test_box_factors.cpp`.
**Fuente:** `factores.f`, `remove_vcofm.f`, `shift_cofm.f` (todas leídas, cortas).

```cpp
struct BoxFactors { double fv1, fv2, fr1, fr2; };
// factores.f: expansión sinh(x)/x truncada para |arg| < 1e-10:
//   e2=1/6; e4=e2/20; e6=e4/42; e8=e6/72
//   dt2=0.5*dt; dt4=0.25*dt
//   fv1 = exp(-alpha*ve*dt2)
//   sinhx = sinh(alpha*ve*dt4)/(alpha*ve*dt4)  (o serie si |alpha*ve*dt4|<1e-10)
//   fv2 = exp(-alpha*ve*dt4) * sinhx
//   fr1 = exp(ve*dt)
//   sinhx = sinh(ve*dt2)/(ve*dt2)  (o serie)
//   fr2 = exp(ve*dt2) * sinhx
BoxFactors box_factors(double alpha, double dt, double ve);

// remove_vcofm.f: v_i -= (Σ m_j v_j)/(Σ m_j)  (una pasada; el Fortran hace 2 pero la 2ª solo re-mide)
void remove_vcofm(const System &sys, std::vector<double> &vx, std::vector<double> &vy, std::vector<double> &vz);

// shift_cofm.f: centra el COM en z hacia el semieje negativo (solo para output visual).
//   cmz = Σ m_i rz_i / Σ m_i ;  sign = -|sign(cmz)| ;  rz_i += cmz*sign
void shift_cofm_z(const System &sys, std::vector<double> &rz);
```
**Validación:** hand-calc; `box_factors(alpha, dt, ve=0)` debe dar `{1,1,1,1}` exacto. `remove_vcofm` → `Σ m v = 0` a 1e-12. **Riesgo: bajo** (ojo con la serie de Taylor de `factores`).

---

### Task 4.6 — LRC dispersion correction (`setup_lrc_lj_st` + `lrc_lj_st`)

**Archivos:** `src/nonbonded.cpp` (extender) + `tests/test_lrc.cpp`.
**Fuente:** `setup_lrc_lj_st.f95`, `lrc_lj_st.f95` (ambas leídas completas). Oráculo: run de referencia imprime la tabla `=== SETUP LRC LJ-ST ===` (i,j,npair,Cu_ij,Cp_ij), `coef_lrc_u = −3417.3939829089495`, `coef_lrc_p = −6833.7550534568572`, y para volumen inicial `ulrc = −128.88250811000432`, `plrc = −161.40105268257830`, `wxx_lrc = wyy_lrc = wzz_lrc = −257.72606129224357`.

```cpp
struct LrcCoeffs { double coef_u = 0, coef_p = 0; };
// setup_lrc_lj_st.f95: recorre j>=i (parte superior). npair_tipo viene de Topology
// (Fase 1 Task 6 lo produjo: npair_tipo(1,1)=1278400 etc. — mismo array).
//   rc3=rcut^3; rc9=rcut^9; sig6=sigma_ij^6; sig12=sig6^2
//   integral_u = 4*eps_ij*(sig12/(9*rc9) - sig6/(3*rc3))
//   integral_w = 24*eps_ij*(2*sig12/(9*rc9) - sig6/(3*rc3))
//   coef_u += 4*pi*npair*integral_u
//   coef_p += (4*pi/3)*npair*integral_w
//   (saltar pares con npair<=0 o sigma_ij<=0 o eps_ij<=0)
LrcCoeffs lrc_setup(const Topology &topo, double rcut);

struct LrcEval { double ulrc, plrc, wxx, wyy, wzz; };
// lrc_lj_st.f95:
//   ulrc = coef_u / volume
//   plrc_internal = coef_p / volume^2
//   plrc = plrc_internal * 16.605390671738468   (bar)
//   wxx = wyy = wzz = volume * plrc_internal    (kJ/mol)
LrcEval lrc_eval(const LrcCoeffs &c, double volume);
```
**Validación:** `lrc_setup` contra `coef_lrc_u/p` exacto (13 díg). `lrc_eval(c, 26.5156)` contra `ulrc/plrc/wxx_lrc` exacto. **Riesgo: bajo** (fórmula cerrada, oráculo exacto).

> **Dónde entra en el loop (Fase 4.7):** tras cada cambio de volumen (NPT), `lrc_eval` se re-llama. Luego: `ulj += ulrc` en la energía; `wxx2 += wxx_lrc` (y wyy/wzz) en el virial de LJ antes de calcular presión y el `gu` del barostato.

---

### Task 4.7 — El loop de integración MTS r-RESPA velocity-Verlet + NPT

**Archivos:** `src/integrator.{hpp,cpp}` (la función principal) + `tests/test_integrator_short.cpp`.
**Fuente:** `main.f` líneas 1330-1900 (el `do istep` con el `do k=1,nmts` adentro). **Leer línea por línea — es el corazón.**

```cpp
struct SimState {
    std::vector<double> rx, ry, rz, vx, vy, vz;
    double boxx, boxy, boxz, vol;
    NHThermostat th;
    NHBarostat ba;
    NeighborList nl;
    EwaldSetup esetup;
    // acumuladores para deltaE y promedios
    double et0 = 0;   // energía conservada del paso 1
    // ... (sumas_gmx: 16 pares suma/suma2 — leer sumas_gmx.f/promedios_gmx antes)
};

// Un paso externo del integrador (avanza nmts subpasos, dt cada uno).
// Devuelve el bloque de energías del paso (para el writer). Muta `st`.
struct StepEnergies {
    double ekin, epot, ethermo, ebaro, etot, deltaE;
    double vbonds, vangles, ulj, ucoul, ukwald;   // /nmol
    double tempi, pressi, densx;
    double pxx, pxy, pxz, pyy, pyz, pzz;           // tensor presión (bar)
    double boxx;
};
StepEnergies integrator_step(SimState &st, const System &sys, const Topology &topo,
                             const MdpParams &mdp, const SuzukiWeights &sw,
                             const LrcCoeffs &lrc,
                             double dof, double RT, double alfa, double factorp,
                             int nmts, int nts1, int nts2,
                             double p1, double p2, double p3,
                             long istep);
```

**Estructura EXACTA de un `integrator_step` (r-RESPA con impulsos, del Fortran):**

```
# --- medio paso de reservorios (fuera del MTS) ---
if barostato:  nh_barostat_apply(st.ba, sw, RT)
if termostato: nh_thermostat_apply(st.th, sw, sys, vx,vy,vz, dof, RT)

for k in 1..nmts:
    if barostato:
        virk = Σ m_i (vx^2+vy^2+vz^2)
        ge = alfa*virk + gu          # gu se computó en el subpaso previo (o en setup para k=1)
        ve += 0.5*ge*dt/wnose
        bf = box_factors(alfa, dt, ve)     # fv1,fv2,fr1,fr2
    else: bf = {1,1,1,1}

    # (1) medio kick con f(t) actual  [f = fx total del subpaso previo]
    v = bf.fv1*v + 0.5*bf.fv2*dt*f/m

    # (2) drift
    r = bf.fr1*r + bf.fr2*dt*v

    if barostato:
        evol += dt*ve
        vol = vol0 * exp(3*evol)
        box = vol^(1/3)  (isotrópico)
        if rcut > 0.5*box: STOP "Rcut > Lx/2"
        lrc = lrc_eval(lrcCoeffs, vol)     # actualizar ulrc/plrc/wxx_lrc

    # (3) PBC wrap:  r_i -= round(r_i/box)*box

    # (4) lista de vecinos
    if nblist_needs_rebuild(nl, r, box, rlist, rcut):
        nblist_build(nl, sys, r, box, rlist)   # + save() interno

    # (5) fuerzas RÁPIDAS (cada subpaso)
    compute_bond_forces(...)  -> fx1, vir_fast(=wxx1...)     [zero_first=true]
    compute_angle_forces(...) -> fx1 += , vir_fast +=
    # (fzas_diedro, fzas_15: cero en este sistema — omitir)
    fx = fx1                                  # base
    vir1 = wxx1+wyy1+wzz1
    if barostato: g1 = vir1 - 3*p1*vol*factorp ; gu = g1

    # (6) fuerzas LJ  (cada nts1 subpasos)
    if k % nts1 == 0:
        compute_lj_st(...) -> fx2, ulj, ucoul, vir_lj(=wxx2...)
        if usa_lrc: wxx2 += wxx_lrc (y wyy/wzz)   # virial corregido
        vir2 = wxx2+wyy2+wzz2
        if barostato: g2 = vir2 - 3*p2*vol*factorp

        # (7) fuerzas Ewald  (cada nts2 subpasos) — SIEMPRE anidado bajo nts1
        if k % nts2 == 0:
            compute_ewald_recip(...) -> fx3, ukwald, vir_ewald(=wxx3...)
            vir3 = wxx3+wyy3+wzz3
            if barostato: g3 = vir3 - 3*p3*vol*factorp ; gu = g1 + nts1*g2 + nts2*g3

        # (8) combinación MTS (SOLO en subpasos k%nts1==0)
        fx = fx1 + nts1*fx2 + nts2*fx3

    # (9) segundo medio kick con f(t+dt)
    v = bf.fv1*v + 0.5*bf.fv2*dt*fx/m

    if barostato:
        virk = Σ m_i v^2 (recalculado)
        ge = alfa*virk + gu
        ve += 0.5*ge*dt/wnose

    # (10) acumular tensor de presión del subpaso:
    #   wxxv = Σ m_i vx_i^2 (etc, tensor cinético)
    #   sum_pxx += wxxv + wxx1 + wxx2 + wxx3   (idem 6 componentes)
# --- fin MTS ---

# --- promediar tensor de presión ---
factor = factor_pres / (vol*nmts)
pxx = factor*sum_pxx  (etc)

# --- segundo medio paso de reservorios ---
if termostato: nh_thermostat_apply(...) ; enh = nh_thermostat_energy(...)
ek = 0.5 * Σ m_i v^2
tempi = (2*ek/dof) * factor_temp
if barostato: nh_barostat_apply(...) ; enhb = nh_barostat_energy(...)

# --- energías del paso ---
if usa_lrc: ulj += ulrc
epot = (vbonds + vangles + ulj + ucoul + ukwald) / nmol   # + vdiedro + u15 = 0
ekin = ek / nmol
etot = ekin + epot + enh/nmol + enhb/nmol
if istep == 1: et0 = etot
deltaE = |(etot - et0)/et0|
densx  = Σ nmol_esp(ie)*rmasa_molar(ie)*1e-3 / (vol*1e-27*6.023e23)   # kg/m^3
pressi = (pxx+pyy+pzz)/3
```

**⚠️ Puntos que descarrilan implementaciones (documentar y testear):**
- `gu` **persiste entre subpasos** — en `k=1` viene del bloque de setup pre-loop; en `k>1` del `g1` (o `g1+nts1*g2+nts2*g3`) del subpaso anterior.
- `fx2` / `fx3` **retienen su valor** entre evaluaciones (impulso r-RESPA). En `k=1` deben venir del setup pre-loop (Task 6 los computó).
- La combinación `fx = fx1 + nts1·fx2 + nts2·fx3` **solo ocurre en `k%nts1==0`**; en los demás subpasos `fx = fx1`.
- El bloque Ewald (`k%nts2==0`) está **anidado dentro** de `k%nts1==0` en el Fortran (`fx2` solo se actualiza ahí). Para el fixture `nts1=10, nts2=20, nmts=20`: LJ en k=10,20; Ewald en k=20.
- `check()`/`lista()` usan `updatel` global — en C++ es el return de `nblist_needs_rebuild`. `save()` está dentro de `nblist_build` (Task 3).
- El virial de LJ lleva `+= wxx_lrc` **antes** de entrar a presión y a `g2`/`gu`.

**Validación (Task 4.7, aislada):**
- `test_integrator_short.cpp`: correr **1-5 pasos** desde el fixture y comparar `Total`, `deltaE`, `tempi`, `pressi`, `boxx` contra un run Fortran fresco de `nsteps=1..5` (capturar `energy.dat`, columnas 12-14 = ekin/epot/… y 28 = pressure). Tolerancia ~1e-4 relativo (GPU + acumulación). **Este es el gate crítico de la Fase 4.**
- Sub-gate NVE: correr con `termostato=F, barostato=F` (editar mdp de prueba) 100 pasos → `deltaE < 1e-4` (conservación pura, aísla el integrador de los reservorios).
- Sub-gate NVT: `barostato=F` 100 pasos → `<T>` cerca de 298.15, `deltaE` (conservada extendida) acotado.

**Riesgo: MUY ALTO.** Es donde el proyecto históricamente pierde tiempo. Presupuestar 2-3 iteraciones.

---

### Task 4.8 — Writers (`energy.dat`, `dm.log`, `movie.gro`, `file.gro`) + acumuladores

**Archivos:** `src/output.{hpp,cpp}` (crear) + `tests/test_output.cpp`.
**Fuente:** `main.f` líneas 1900-2100 (formatos), `gro_write.f`, `grof.f`, `sumas_gmx.f`, `promedios_gmx`, `iniciar_variables_gmx.f` (leer estos 3 últimos — no leídos aún).

- **`energy.dat`**: header de 3 líneas (`# DMENERGY version 1` / units / columns) + una línea por `nstenergy` pasos: `format(i12,1x,27(es24.15,1x))` con 27 columnas: `step time_ps vbonds vangles vdiedro ulj15 ucoul15 ulj ucoul ukwald ekin epot ethermo ebaro etot pxx pxy pxz pyy pyz pzz lx ly lz volume density temperature pressure`.
- **`dm.log`**: bloque `"Valores iniciales/nmol"` (t=0, ya en `step0_reference.txt`) + cada `nstlog` pasos el bloque `istep / vbonds..ukwald / ecinet,epot,ethermo,ebaros,etotal,deltaE / boxx,tempi,presi,dens,nupdate`.
- **`movie.gro`**: append cada `nstxout` pasos. Coords "unidas" por molécula (via `shift_cofm_z` + `cofm` + `xyz_cofm` → `rxa`). Formato `format(I5,A5,A5,I5,3F8.3,3F8.4)`.
- **`file.gro`**: sobrescribir en el último paso (`grof.f`). **⚠️ esto muta el input** — el driver C++ NO debe escribir sobre `fixtures/file.gro`; escribir a un path de salida configurable.
- **Acumuladores** (`sumas_gmx` / `promedios_gmx`): 16 magnitudes, `suma` y `suma2` (para media y desviación estándar). El run imprime `<X> ± σ` al final. Portar como `struct Averages { void add(...); void report(...); }`.

**Validación:** diff textual de `energy.dat` y `dm.log` (a tolerancia de formato) contra un run Fortran corto. **Riesgo: bajo-medio** (tedioso, no matemáticamente delicado).

---

### Task 4.9 — Driver `main.cpp`

**Archivos:** reescribir `src/main.cpp` + parche `CMakeLists.txt` (linkear todo).
**Fuente:** `main.f` líneas 160-1200 (todo el setup antes del loop).

Secuencia:
1. Leer `file.gro` (posiciones+velocidades+box), `file.mdp` (`read_mdp(path, boxx)`), `file.top` → `Topology` + `System`.
2. `rlist = rcut + skin`; `dof = 3*nat`; `RT = (rgas/1000)*temp`.
3. Derivar `nmts`, `p1/p2/p3`, `nts1/nts2` según el caso (nbonds × recip_ewald). Fixture = **Caso C**. Verificar `p1+p2+p3 == p_ext` (abort si no).
4. `alfa = 1 + 1/nat`; `factorp = 0.06022`; `vol0 = vol`.
5. LRC: `lrc_setup(topo, rcut)` si `dispcorr != "no"`.
6. `remove_vcofm(sys, v)`.
7. `esetup = ewald_setup(box, rcut, error_coul)`; `nblist_build(nl, ...)`.
8. **Evaluación de fuerzas inicial** (`compute_all_forces` de Task 6) → fx1/fx2/fx3, viriales, `gu = vir1+vir2+vir3 − 3·p_ext·vol·factorp`.
9. `nh_thermostat_init` + `suzuki_weights`; `nh_barostat_init` (si barostato).
10. Escribir bloque `"Valores iniciales/nmol"` a `dm.log`.
11. `for istep in 1..nsteps: integrator_step(...); acumular; escribir si toca.`
12. `promedios_gmx` → reporte final; cerrar archivos.

**Validación:** que compile, linke y corra `nsteps=1` sin crash produciendo `energy.dat` con una línea sensata. El gate real es Fase 5.

**Riesgo: medio** (mucho cableado, poca matemática).

---

## 4. FASE 5 — Gate end-to-end

**Riesgo:** gate, no código.

**Procedimiento:**
1. CT 901 verificado idle (`who` + `ps aux | grep -E "dm_mx_npt|gmx_mexicano"` + `nvidia-smi`).
2. Copia aislada del fixture (NO tocar `Programa_DM_cpp/tests/fixtures/`). Correr el binario C++ `gmx_mexicano` 10 000 pasos.
3. Correr el Fortran `dm_mx_npt` 10 000 pasos sobre la MISMA config inicial, aislado.
4. Comparar promedios finales (`promedios_gmx`):
   - `<Total>` dentro de `−89.05846 ± 0.01195` kJ/mol (oráculo `ca9ef61`).
   - `<Ekin>`, `<Epot>`, `<T>`, `<P>`, `<densidad>`, `<deltaE>` dentro de 1σ del Fortran.
   - `deltaE` final del C++ del mismo orden que el Fortran (~1e-4).
5. **3× limpio** — repetir 3 veces, confirmar que los promedios coinciden entre corridas C++ dentro de la varianza estadística.
6. Comparar wall-time C++ vs Fortran (objetivo original del usuario: "igual o más rápido"). El C++ debería ser ≥ tan rápido (mismo kernel, menos overhead de `ISO_C_BINDING`).
7. Benchmark vs GROMACS real instalado en CT 901 — **caveat:** el potencial LJ-ST + Ewald propio no es 1:1 con GROMACS estándar; la comparación es de *orden de magnitud de ns/día*, no bit-exact. Documentar como referencia, no como gate.

**Entregable:** `03 Benchmarks/(C) <fecha> Fase 5 - Gate end-to-end.md` con la tabla comparativa + decisión de cierre.

---

## 5. FASE 6 (stretch) — Los pedidos "producto" del usuario original

Del mensaje del 4-sep: *"autodetectar la GPU y el CPU, tiene que ser amigable para el usuario, instalable como GROMACS, sweet-spot de cores"*. No son física — son empaquetado/UX. Slot natural **después** de Fase 5:

| Sub-tarea | Qué | Notas |
|---|---|---|
| 6.1 Auto-detección GPU | `cudaGetDeviceCount` / `cudaGetDeviceProperties` → elegir device, imprimir SM/VRAM, fallar limpio si no hay GPU | trivial, ~1 archivo |
| 6.2 Auto-detección CPU | `std::thread::hardware_concurrency` + `/proc/cpuinfo` → reportar cores | trivial |
| 6.3 Sweet-spot de cores | **Bloqueado hasta que haya paralelismo CPU.** El código NO tiene OpenMP (descartado con datos en la ronda GPU: overhead > trabajo para 2544 átomos). El único CPU-bound real es `compute_ewald_recip::intra` (2400 pares) y `cofm` — despreciable. **Recomendación: cerrar este pedido como "no aplica" con los datos del benchmark, salvo que un caso mucho más grande lo justifique.** |
| 6.4 Instalable | `CMakeLists.txt`: `install(TARGETS ...)`, `CPack` (deb/rpm/tarball), `find_package(CUDAToolkit)` | estándar CMake |
| 6.5 Amigable | CLI con `--help`, validación de inputs con mensajes claros (ya hay `std::runtime_error` con textos del Fortran), un `README` de uso, quizá un wrapper Python fino (patrón HOOMD) | scope abierto |

---

## 6. Oráculos de validación — inventario

### Ya disponibles (checked-in o reproducibles)
- `tests/fixtures/step0_reference.txt` — energías t=0 /nmol + per-nat bonds/angles + `nts1/nts2` (commit `c3ba387`).
- `~/Prueba/dm.lis` (viejo) — `rkappa`, `kmax`, tabla LRC, `coef_lrc_u/p`, `ulrc/plrc` inicial. Config ligeramente distinta pero `rkappa`/LRC-coefs son config-independientes.
- Oráculo global: `Total = −89.05846 ± 0.01195` (`ca9ef61`).
- `npares` del fixture = **1 552 648** (validado exacto en T3).

### A capturar (los agentes deben generarlos corriendo el Fortran fresco, aislado)
1. **Fase 4.7 gate:** run Fortran `nsteps=1..5`, `nstenergy=1` sobre el fixture prístino → `energy.dat` (27 columnas). Es LA referencia del integrador. Guardar en `tests/fixtures/integrator_step_reference.txt`.
2. **Sub-gate NVE:** run Fortran con `tcoupl=no, pcoupl=no`, `nsteps=100` → `deltaE` por paso.
3. **Fase 5 gate:** run Fortran 10 000 pasos sobre config prístina → promedios `promedios_gmx`. (Ojo: el `~/Prueba/dm.log` actual puede no ser prístino — regenerar.)
4. **Tabla LRC:** ya en `dm.lis`, pero regenerar limpio para el fixture exacto.

**Regla:** todo run Fortran de referencia se hace en directorio aislado (`~/refN/`), se limpian los artefactos después (`git status` limpio), y se verifica CT 901 idle antes.

---

## 7. Estrategia de despacho de agentes

### Secuenciación (dependencias)

```
Fase 3 Task 6  (gate no-enlazado)         [1 agente]
      │
Fase 4:
  4.1 Suzuki ──┐
  4.4 energías ─┼─ (independientes, paralelizables)   [3 agentes en paralelo OK]
  4.5 factores ─┘
  4.6 LRC ──────
      │
  4.2 NH termostato ──┐  (dependen de 4.1)
  4.3 NH barostato  ──┘  [2 agentes, o 1 secuencial — riesgo alto, preferir 1 con revisión]
      │
  4.8 writers  (depende de leer sumas_gmx.f — puede arrancar antes en paralelo)
      │
  4.7 INTEGRADOR  (depende de 4.1-4.6)   [1 agente dedicado, NO paralelo — es el crítico]
      │
  4.9 main.cpp   (depende de 4.7 + 4.8 + Task 6)
      │
Fase 5  (gate end-to-end)   [yo verifico, no agente]
```

### Reglas para los agentes (grabar en el prompt de cada uno)
1. **Un commit por task.** Mensaje con: fuente Fortran (archivo:líneas), qué valida el test, números clave.
2. **NO tocar `Programa_DM/`** (Fortran congelado). Runs de referencia en directorio aislado, limpiar después.
3. **Verificar CT 901 idle** (`who` + `ps aux` + `nvidia-smi`) antes de cualquier run/benchmark.
4. **Portar línea por línea** el Fortran real — prohibido "de memoria" (regla del proyecto; el cambio #3 se perdió así).
5. **Todo test nuevo entra al `ctest`** + `-UNDEBUG` + `WORKING_DIRECTORY tests/`.
6. Tolerancias: CPU puro → 1e-9..1e-12; algo que toca GPU → 1e-4..1e-6 (reducciones no deterministas).
7. Si un test no pasa a la 2ª iteración → **parar, documentar, avisar por Telegram** (no entrar en bucle — regla del CLAUDE.md).
8. Modelo: **Opus 5** para 4.2/4.3/4.7 (delicados) y para toda revisión; **Sonnet 5** para el resto (subagentes `reviewer`/`architect` ya configurados en `.claude/agents/`).

### Verificación (mi rol, tras cada agente)
- `git diff` acotado a los archivos declarados.
- Suite `ctest` completa verde.
- Re-derivar a mano el criterio de validación del test (¿la tolerancia es honesta? ¿el oráculo es el correcto?).
- Para 4.7: correr el gate 3× yo mismo en CT 901 idle.
- BASE `learn` con el resultado.

---

## 8. Estimación

| Bloque | Agentes | Sesiones equiv. | Riesgo |
|---|---|---|---|
| Fase 3 Task 6 | 1 | 0.5 | gate |
| Fase 4.1/4.4/4.5/4.6 | 3-4 | 1 | bajo |
| Fase 4.2/4.3 (NH chains) | 1-2 | 1-2 | **alto** |
| Fase 4.7 (integrador) | 1 | 2-3 | **muy alto** |
| Fase 4.8 (writers) | 1 | 0.5-1 | bajo |
| Fase 4.9 (main.cpp) | 1 | 0.5-1 | medio |
| Fase 5 (gate) | 0 (yo) | 0.5-1 | gate |
| Fase 6 (producto) | 2-3 | 1-2 | bajo |

**Total: ~7-11 sesiones-equivalente.** El 60 % del riesgo está en 4.2/4.3/4.7 (las cadenas de Nosé-Hoover y el propagador MTS). Recomendación fuerte: esos tres los hace **un solo agente Opus 5 en serie**, con revisión mía entre cada uno, y con los sub-gates NVE/NVT antes del gate NPT completo.

---

## 9. Resumen ejecutable (para pegar en prompts de agentes)

> El rewrite C++ de GromacsMexicano tiene Fases 0-3(T1-T5) completas y validadas (commit `c3ba387`, 13/13 tests). Falta:
> - **Fase 3 Task 6:** `forces.hpp/.cpp` con `compute_all_forces` (une bonded + LJ-ST + Ewald, familias MTS separadas) + gate contra `step0_reference.txt`.
> - **Fase 4:** integrador MTS r-RESPA velocity-Verlet + Nosé-Hoover NPT. 9 sub-tareas (4.1 Suzuki, 4.2 NH-termostato, 4.3 NH-barostato, 4.4 energías reservorios, 4.5 factores+vcofm+shift, 4.6 LRC dispersion, 4.7 EL INTEGRADOR, 4.8 writers, 4.9 main.cpp). Fuente: `main.f:1204-2221` + `nosinit.f` + `*_nh_system.f` + `factores.f` + `lrc_lj_st.f95`. Todo leído y especificado en `(C) 2026-09-08 Analisis - todo lo que falta`.
> - **Fase 5:** gate end-to-end 10k pasos vs Fortran, 3× limpio.
> - **Fase 6 (stretch):** auto-detección GPU/CPU, instalador CMake/CPack, CLI amigable. "Sweet-spot de cores" = cerrar como no-aplica (no hay paralelismo CPU, descartado con datos).
> Reglas: no tocar `Programa_DM/`; portar línea por línea; verificar CT 901 idle antes de correr; un commit por task; parar y avisar si algo no pasa a la 2ª.

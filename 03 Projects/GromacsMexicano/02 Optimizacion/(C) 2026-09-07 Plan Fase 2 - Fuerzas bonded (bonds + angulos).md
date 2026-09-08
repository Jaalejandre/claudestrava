# GromacsMexicano C++ Rewrite — Phase 2 (Bonded Forces) Implementation Plan

> **For agentic workers:** implement task-by-task. Steps use checkbox (`- [ ]`) syntax. Every formula below is transcribed verbatim from the Fortran read in full (`fzas_de.f` 105 lines, `fzas_angulo.f` 145 lines, `main.f:679-687` call site) on 2026-09-07 — do not "improve" the math, port it exactly.

**Goal:** Port the two bonded-force routines the live test case actually exercises — harmonic bonds (`fzas_de.f`) and harmonic angles (`fzas_angulo.f`) — to C++, with forces validated two independent ways (hand-computed 2–3 atom systems AND finite-difference gradient of the energy) before any wiring into the integration loop.

**Out of scope for Phase 2:** dihedrals (`fzas_diedro.f`) and 1-5 pairs (`fzas_15.f`). The live test case (SPC/E water + NaCl) has **zero dihedrals and zero 1-5 pairs** (confirmed: `spce.itp`/`sodium.itp`/`chloride.itp` have no `[dihedrals]` or `[pairs]` sections, and `dm.log` reports `vdiedro = 0.00000`, `ulj15 = 0.00000` every step). Porting them now would be un-testable-against-the-fixture speculative work — deferred to a later phase per the project's scope-discipline rule.

**Architecture:** Same strangler-fig. New `Programa_DM_cpp/src/bonded_forces.hpp/.cpp` + `tests/test_bonded_forces.cpp`, its own CTest target. Consumes the `System` struct from Phase 1 Task 7 (`system_builder.hpp`). Does not touch the simulation loop, any GPU kernel, or `Programa_DM/` (frozen reference).

**Tech Stack:** C++17, matching Phase 1. `<cmath>`, `std::vector`. No new dependencies.

**Spec:** `Programa_DM/fzas_de.f` and `Programa_DM/fzas_angulo.f` ARE the spec. Physics reference: `Programa_DM/Prueba/dm.log` step-0 block (`vbonds`, `vangles`).

## Global Constraints

- **These routines are pure parsing→arithmetic; "physics validation" means bit-level agreement with the Fortran formulas, verified via:** (a) unit tests on 2–3 atom systems whose energy/force is computed by hand in the test file's comments, and (b) a finite-difference check — analytic force must match `-(U(x+h) - U(x-h)) / (2h)` component-by-component to ~1e-6 relative, for every atom, on a randomized small system. Check (b) is the gold standard and needs no external reference.
- **Never touch `/home/alejandre/GromacsMexicano/Programa_DM/`.**
- **CT 901 verified free of concurrent activity (`who` + `ps aux | grep dm_mx_npt`) before any build/test run** — this project has twice had runs contaminated by concurrent sessions.
- **One routine per task, one commit per validated task.**
- **No invented math.** Every formula below is quoted from the Fortran. If the actual file differs from a quote here, STOP and report.

---

## Fortran reference — the two routines' contracts (read once)

### `fzas_de.f` — harmonic bonds

Signature: `fzas_de(maxnat, nat, rx, ry, rz, ibonds, bonds, nbonds, vbonds, fx, fy, fz, wxx, wxy, wxz, wyy, wyz, wzz, boxx, boxy, boxz)`

**CRITICAL — this routine ZEROES the force and virial accumulators at entry:**
```fortran
do k=1,nat
   fx(k)=0.0d0 ; fy(k)=0.0d0 ; fz(k)=0.0d0
enddo
wxx=0 ; wxy=0 ; wxz=0 ; wyy=0 ; wyz=0 ; wzz=0
```
It is the FIRST routine in the fast-force group (`main.f:679`); `fzas_angulo`, `fzas_diedro`, `fzas_15` all ADD to the same arrays afterward. **The C++ port must preserve who-zeroes-what:** the modern idiom is "caller zeroes, every force fn only adds" — adopt that, but the bond function needs an explicit `bool zero_first` parameter (default `true`) so a Phase 2 standalone test gets Fortran-identical behavior and the Phase 3 driver can pass `false` once it owns the zeroing. Document this choice in the header.

Per bond `nb` (loop `do nb=1,nbonds`):
```
i = ibonds(1,nb)              ! 1-based global atom index
j = ibonds(2,nb)
r0 = bonds(1,nb)             ! equilibrium length
kr = bonds(2,nb)             ! force constant
dx = rx(i) - rx(j)  (same y,z)
dx = dx - dnint(dx/boxx)*boxx   ! minimum image; dnint = round-half-away-from-zero => std::round in C++ (NOT std::rint/std::nearbyint, which round half-to-even)
rij = sqrt(dx*dx + dy*dy + dz*dz)
uij = 0.5*kr*(rij - r0)**2
vbonds += uij
dvij = kr*(rij - r0)                  ! dU/drij
fijx = -dvij*dx/rij   (same y,z)
wxx += fijx*dx ; wxy += fijx*dy ; wxz += fijx*dz
wyy += fijy*dy ; wyz += fijy*dz ; wzz += fijz*dz
fx(i) += fijx ; fx(j) -= fijx        ! Newton's third law
```
Note the virial is the **6 upper-triangle components only** (`wxx,wxy,wxz,wyy,wyz,wzz`), and it uses `fij*d` (force-times-separation), accumulated per bond.

### `fzas_angulo.f` — harmonic angles

Signature: `fzas_angulo(maxnat, nat, rx, ry, rz, boxx, boxy, boxz, iangles, angles, nangles, fx, fy, fz, vangles, wxx, wxy, wxz, wyy, wyz, wzz)`

**Does NOT zero fx/fy/fz or w** — it ADDS.** Runs after `fzas_de`. It DOES zero its own `vangles` at entry (`vangles = 0.0d0`).

Per angle `na` (loop `do na=1,nangles`):
```
i = iangles(1,na) ; j = iangles(2,na) ; k = iangles(3,na)   ! j is the VERTEX (central) atom; 1-based global
ae = angles(1,na)            ! equilibrium angle, IN DEGREES
ai = angles(2,na)            ! force constant (ktheta)
ae = ae*pi/180.0             ! convert to radians here (pi = 4*atan(1))

! bond vectors from vertex j:
dxij = rx(i) - rx(j)  (y,z)   -> apply PBC via dnint
dxjk = rx(k) - rx(j)  (y,z)   -> apply PBC via dnint
rij2 = dxij^2 + dyij^2 + dzij^2 ; rij = sqrt(rij2)
rjk2 = dxjk^2 + dyjk^2 + dzjk^2 ; rjk = sqrt(rjk2)
rabv = dxij*dxjk + dyij*dyjk + dzij*dzjk     ! dot product
rabe = rij*rjk
cost = rabv/rabe                            ! cos(theta)
theta = acos(cost)
argsin = 1.0 - cost*cost
if (argsin < 1.0e-12) argsin = 1.0e-12       ! MUST replicate this clamp exactly
sint = sqrt(argsin)                          ! sin(theta), clamped

vijk = 0.5*ai*(theta - ae)**2
dvijk = ai*(theta - ae)
vangles += vijk

faca  = cost/rij2
rabei = 1.0/rabe
sinti = 1.0/sint
gradax = -(dxjk*rabei - dxij*faca)*sinti     ! d(theta)/d(r_i), x-component (y,z analogous)
graday = -(dyjk*rabei - dyij*faca)*sinti
gradaz = -(dzjk*rabei - dzij*faca)*sinti
facb  = cost/rjk2
gradbx = -(dxij*rabei - dxjk*facb)*sinti     ! d(theta)/d(r_k), x-component
gradby = -(dyij*rabei - dyjk*facb)*sinti
gradbz = -(dzij*rabei - dzjk*facb)*sinti

fxa = -dvijk*gradax  (y,z)                   ! force on atom i
fxb = -dvijk*gradbx  (y,z)                   ! force on atom k
fx(i) += fxa
fx(j) -= (fxa + fxb)                         ! force on vertex = -(F_i + F_k)
fx(k) += fxb

! virial (NOTE the asymmetric form — quote exactly):
wxx += dxij*fxa + dxjk*fxb
wxy += dxij*fya + dxjk*fyb
wxz += dxij*fza + dxjk*fzb
wyy += dyij*fya + dyjk*fyb
wyz += dyij*fza + dyjk*fzb
wzz += dzij*fza + dzjk*fzb
```
Watch `wxy` etc.: it is `d(component-1) * f(component-2)`, e.g. `wxy = dxij*fya + dxjk*fyb` (x-separation times y-force). Transcribe the six lines literally.

`angles(1,na)` (degrees) and `angles(2,na)` (ktheta) map exactly to Phase 1's `SystemAngle::theta0_deg` and `SystemAngle::ktheta`. `bonds(1,nb)`/`bonds(2,nb)` map to `SystemBond::r0`/`SystemBond::kr`.

### Indices
All Fortran indices are **1-based global**. `System::bonds[b].i` / `.j` and `System::angles[a].i/.j/.k` are already 1-based global (Phase 1 Task 7). In C++, index the position vectors with `[.i - 1]`.

---

## Task 1: harmonic bond forces

**Files:**
- Create: `Programa_DM_cpp/src/bonded_forces.hpp`
- Create: `Programa_DM_cpp/src/bonded_forces.cpp`
- Create: `Programa_DM_cpp/tests/test_bonded_forces.cpp`
- Modify: `Programa_DM_cpp/src/CMakeLists.txt`

**Interfaces:**
```cpp
#pragma once
#include "system_builder.hpp"
#include <vector>

namespace gmx {

// Symmetric 3x3 virial tensor, upper triangle only, matching the Fortran's
// (wxx, wxy, wxz, wyy, wyz, wzz) accumulation order.
struct Virial {
    double xx = 0, xy = 0, xz = 0, yy = 0, yz = 0, zz = 0;
    void zero() { xx = xy = xz = yy = yz = zz = 0.0; }
};

// Harmonic bond forces (port of fzas_de.f). Adds forces into fx/fy/fz and
// the virial into `vir`; returns the total bond potential energy (vbonds).
//
// `zero_first` (default true) reproduces fzas_de.f's behavior of zeroing
// fx/fy/fz (for all `nat` atoms) and the virial at entry -- fzas_de is the
// FIRST routine in the fast-force group. Phase 3's driver, which owns the
// zeroing, will pass false.
//
// box = {boxx, boxy, boxz}, orthorhombic. Minimum image via std::round
// (matches Fortran dnint).
double compute_bond_forces(const System &sys,
                           const std::vector<double> &rx,
                           const std::vector<double> &ry,
                           const std::vector<double> &rz,
                           double boxx, double boxy, double boxz,
                           std::vector<double> &fx,
                           std::vector<double> &fy,
                           std::vector<double> &fz,
                           Virial &vir,
                           bool zero_first = true);

} // namespace gmx
```

- [ ] **Step 1: Write `test_bonded_forces.cpp` — hand-computed 2-atom bond.**
  Two atoms at `(0,0,0)` and `(0.12, 0, 0)`, one bond with `r0 = 0.10`, `kr = 1000.0`, box `{10,10,10}` (so PBC never triggers). By hand: `rij = 0.12`, `uij = 0.5*1000*(0.12-0.10)^2 = 0.5*1000*0.0004 = 0.2`. `dvij = 1000*0.02 = 20`. `fijx = -20 * 0.12/0.12 = -20`. So `fx[0] = -20`, `fx[1] = +20`, all y/z zero. Virial `xx = fijx*dx = -20 * 0.12 = -2.4`; others 0. Assert all of these (tol 1e-9), and `energy == 0.2`.

- [ ] **Step 2: Add a finite-difference force check** (the gold standard).
  Build a small `System` by hand: 4 atoms, 3 bonds forming a chain, random-ish positions in a `{5,5,5}` box, assorted `r0`/`kr`. Compute analytic forces via `compute_bond_forces`. Then for each atom `a` and each component `c`, perturb `r[a][c] += h` and `-= h` (`h = 1e-6`), recompute ONLY the energy (call with `zero_first=true` into throwaway force buffers), and check `analytic_force[a][c] ≈ -(U_plus - U_minus)/(2h)` to relative tolerance `1e-5`. This catches any sign error or missing term in the force that a single hand-computed case might miss.

- [ ] **Step 3: Implement `compute_bond_forces`** in `bonded_forces.cpp`, transcribing `fzas_de.f` exactly. Minimum image: `dx -= std::round(dx / boxx) * boxx;`. If `zero_first`, zero `fx/fy/fz` over `[0, sys.nat)` and `vir.zero()` first. Loop `sys.bonds`, `i = b.i - 1`, `j = b.j - 1`. Accumulate energy, forces, virial per the quoted formulas. Return `vbonds`.

- [ ] **Step 4: CMake + build + test.**
```cmake
add_library(gmx_forces STATIC bonded_forces.cpp)
target_link_libraries(gmx_forces PRIVATE gmx_system)

add_executable(test_bonded_forces ../tests/test_bonded_forces.cpp)
target_link_libraries(test_bonded_forces PRIVATE gmx_forces gmx_io)
target_compile_options(test_bonded_forces PRIVATE -UNDEBUG)
add_test(NAME bonded_forces COMMAND test_bonded_forces)
set_tests_properties(bonded_forces PROPERTIES WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/../tests")
```
Then `cmake -B build -S . -DCMAKE_BUILD_TYPE=Release && cmake --build build -j && ctest --test-dir build --output-on-failure -R bonded_forces`. Also run the FULL suite (`ctest --test-dir build`) — must stay green.

- [ ] **Step 5: Real-fixture sanity check** (add to `test_bonded_forces.cpp`).
  Full pipeline: `load_topology_lines` → parsers → `compute_combining_rules` → `build_system` → `read_gro("fixtures/file.gro")` for positions and box. Call `compute_bond_forces`. Assert: (a) `energy > 0` and `energy < 5000` (1600 SPC/E bonds near equilibrium — a loose sanity band, not a reference match, since the checked-in `file.gro` is a mutated post-run config); (b) `sum of all fx == 0` within `1e-6` (and fy, fz) — bonded forces are internal, net force on the system is exactly zero; (c) the finite-difference check from Step 2, but now on the real 2544-atom system for, say, the first 20 atoms (full 2544 is slow but 20 is plenty to catch a bug).

- [ ] **Step 6: Commit.**
```
git add Programa_DM_cpp/src/bonded_forces.hpp Programa_DM_cpp/src/bonded_forces.cpp Programa_DM_cpp/tests/test_bonded_forces.cpp Programa_DM_cpp/src/CMakeLists.txt
git commit -m "cpp: Phase 2 Task 1 - harmonic bond forces (port of fzas_de.f), validated by hand + finite-difference + real 1600-bond fixture"
```

---

## Task 2: harmonic angle forces

**Files:**
- Modify: `Programa_DM_cpp/src/bonded_forces.hpp` (add `compute_angle_forces` decl)
- Modify: `Programa_DM_cpp/src/bonded_forces.cpp`
- Modify: `Programa_DM_cpp/tests/test_bonded_forces.cpp` (add angle tests)
- Modify: `Programa_DM_cpp/src/CMakeLists.txt` (nothing new — same lib/test)

**Interface:**
```cpp
// Harmonic angle forces (port of fzas_angulo.f). ADDS forces into fx/fy/fz
// and virial into `vir` (does NOT zero -- it runs after compute_bond_forces
// in the fast-force group). Returns total angle potential energy (vangles).
// Equilibrium angles are taken from System::angles[a].theta0_deg (degrees,
// converted to radians internally, matching fzas_angulo.f).
double compute_angle_forces(const System &sys,
                            const std::vector<double> &rx,
                            const std::vector<double> &ry,
                            const std::vector<double> &rz,
                            double boxx, double boxy, double boxz,
                            std::vector<double> &fx,
                            std::vector<double> &fy,
                            std::vector<double> &fz,
                            Virial &vir);
```

- [ ] **Step 1: Hand-computed 3-atom angle test.**
  Atoms: `i=(0.1, 0, 0)`, `j=(0,0,0)` (vertex), `k=(0, 0.1, 0)` — a perfect 90° angle. `theta0_deg = 109.47`, `ktheta = 300.0`, box `{10,10,10}`. By hand: `theta = pi/2 = 1.570796...`, `ae = 109.47 * pi/180 = 1.910611...`. `vijk = 0.5 * 300 * (1.570796 - 1.910611)^2 = 0.5*300*0.115474 = 17.321...` (compute precisely in the test comment). Assert energy to 1e-6. Assert `sum(fx)==0`, `sum(fy)==0`, `sum(fz)==0` (net zero). Assert the vertex force equals `-(F_i + F_k)` exactly.

- [ ] **Step 2: Finite-difference check for angles** — same structure as Task 1 Step 2: hand-built `System` with 2–3 angles, random positions, verify analytic force == numerical `-dU/dx` to 1e-5 relative, every atom, every component. **This is the most important check for angles** — the gradient formula (`gradax`/`gradbx` with `faca`/`facb`/`sinti`) is intricate and a transcription slip is easy to miss otherwise.

- [ ] **Step 3: Implement `compute_angle_forces`**, transcribing `fzas_angulo.f` exactly, including the `argsin < 1e-12` clamp and the asymmetric virial lines. `pi = 4.0 * std::atan(1.0)`. Do NOT zero anything. `i/j/k = angle.i/.j/.k - 1`.

- [ ] **Step 4: Build + test** (`ctest -R bonded_forces` + full suite green).

- [ ] **Step 5: Real-fixture sanity** (add to test): full pipeline, call `compute_bond_forces` then `compute_angle_forces` on the real fixture, assert: `vangles > 0` and `< 5000` (800 SPC/E angles, loose band); net force still zero within `1e-6` after BOTH bond and angle contributions; finite-difference check on the first 20 atoms of the combined bond+angle energy.

- [ ] **Step 6: Commit.**
```
git add Programa_DM_cpp/src/bonded_forces.hpp Programa_DM_cpp/src/bonded_forces.cpp Programa_DM_cpp/tests/test_bonded_forces.cpp
git commit -m "cpp: Phase 2 Task 2 - harmonic angle forces (port of fzas_angulo.f), validated by hand + finite-difference + real 800-angle fixture (Phase 2 complete)"
```

---

## Self-Review

- **Spec coverage:** `fzas_de.f` and `fzas_angulo.f` map to Tasks 1 and 2 respectively, in full. `fzas_diedro.f`/`fzas_15.f` explicitly deferred with a fixture-based justification (zero dihedrals/pairs in the live case).
- **No placeholders:** every formula is transcribed from the Fortran with line-level fidelity; both hand-computed test cases have concrete numeric expected values to compute in-comment; the finite-difference check has a concrete method and tolerance.
- **The zero-first subtlety** (fzas_de zeroes, fzas_angulo adds) is called out explicitly in the header contract and the `zero_first` parameter, so Phase 3's driver won't double-zero or miss-zero.
- **Type consistency:** `Virial` introduced here; `compute_bond_forces`/`compute_angle_forces` both consume the `System` from Phase 1 unchanged and the raw position vectors + box that `read_gro` produces.

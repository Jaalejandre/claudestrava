# GromacsMexicano C++ Rewrite — Phase 3 (Non-bonded Driver Glue) Implementation Plan

> Implement task-by-task. Every signature / formula below is transcribed from the source read in full on 2026-09-07: `lista_linkcell_cuda.cu` (347 l), `fzas_lj_st_cuda.cu` (388 l), `kwald_cuda.cu` (524 l), `lista.f`, `check.f` (73 l), `kappa_coulomb.f` (20 l), `compute_kmax_ewald.f` (41 l), `setup2.f` (57 l), `intra.f` (118 l), `cofm.f` (92 l), `xyz_cofm.f` (38 l), `main.f:625-985` + `:1020-1045` + `:1451-1460`.

**Goal:** Drive the three already-validated, already-optimized CUDA kernels (link-cell neighbor list, LJ-ST + real-space Coulomb, Ewald reciprocal) directly from C++ — replacing the Fortran `ISO_C_BINDING` wrappers — plus port the CPU-side setup and per-step glue those kernels need (`check`, `kappa_coulomb`, `compute_kmax_ewald`, `setup2`, `intra`, `cofm`/`xyz_cofm`). Gate: a `compute_nonbonded` path in C++ reproduces `dm.log`'s step-0 `ulj`, `ucoul`, `ukwald` and the corresponding forces within the established statistical error, **3× clean**.

**Architecture:** The 3 `.cu` files in `Programa_DM_cpp/src/kernels/` are byte-identical to `Programa_DM/`'s (verified: `diff` is empty) and stay unchanged **except Task 1** (a real, physics-validated kernel-lifecycle fix to `fzas_lj_st_cuda.cu`). New C++ code: `Programa_DM_cpp/src/nonbonded.hpp/.cpp` (kernel wrappers + Ewald setup + neighbor-list manager), consuming Phase 1's `System`/`Topology` and Phase 2's `Virial`.

**Tech Stack:** C++17 + the CUDA 13.0 toolchain already on CT 901 (`nvcc -arch=sm_120`). CMake links `gmx_kernels` (the relocated `.cu` static lib from Phase 0) into a new `gmx_nonbonded` target.

**Spec:** the Fortran + the `.cu` files ARE the spec. Physics reference: `Programa_DM/Prueba/dm.log` step-0 block (`ulj`, `ucoul`, `ukwald`, and the printed `rkappa`, `kmaxx/y/z`).

## Global Constraints

- **`fzas_lj_st_cuda.cu` is the ONLY kernel file touched (Task 1). That edit goes through the full kernel-change protocol:** compile release, run the real 10 000-step test case **3× on a verified-idle CT 901** (`who` + `ps aux | grep dm_mx_npt` + `nvidia-smi` all clean first — this project has had 3 contaminated benchmarks), physics within 1σ of `Total = -89.05846 ± 0.01195 kJ/mol` (ref `ca9ef61`), zero crashes. **This validation runs against the FORTRAN build** (`compilar_release.sh`), since the Fortran program is what exercises the kernel end-to-end today — the C++ driver isn't complete enough to be the oracle until Task 6.
- **Never touch `Programa_DM/`** (frozen reference) or the other two `.cu` files.
- **CT 901 verified idle before every build/benchmark.**
- **One task per commit. Task-scoped review before the next task.**
- **No invented physics.** Every constant (`factorq` handling, the `0.5/alfa²` Ewald `B`, the `erfc` self-term prefactor `1/√π · alfa`) is copied from the source.

---

## Reference: the non-bonded pipeline as `main.f` runs it today

**One-time setup (`main.f:625-670`):**
1. `kappa_coulomb(error_coul, rkappa, rcut)` → `rkappa` (a.k.a. `alfa`), iteratively: start `0.05`, while `erfc(rkappa·rcut)/rcut > error_coul` do `rkappa += 0.02`.
2. `save(rx→rxup)` then `lista(...)` → first `nblist1/nblist2/npares` (rlist = rcut + skin; skin from `; dm-skin`).
3. If `recip_ewald`: `compute_kmax_ewald(box, rcut, error_coul, rkappa, kmaxx, kmaxy, kmaxz)` then `SETUP2(MAXK, rkappa, kmax…, KVEC, box)` → the `KVEC` reciprocal-weight array.

**Per force evaluation:**
- **Fast group → `fx1`** (Phase 2: bonds + angles; dihedral + 1-5 are zero here).
- **LJ + real Coulomb → `fx2`, `ulj`, `ucoul`, `wxx2…`:** `fzas_lj_st_cuda(...)`.
- **Ewald reciprocal → `fx3`, `ukwald`, `wxx3…`:**
  1. `INTRA(...)` → `vkwaldi` (self-term `(1/√π)·alfa·Σqᵢ²` **plus** the intramolecular erf-correction energy `VKIN`), correction forces `fxi`, correction virial `wxxi…`.
  2. `cofm(...)` + `xyz_cofm(...)` → `rxq/ryq/rzq` = molecule-COM-consistent coordinates (whole molecules never split across the box) — this is what the reciprocal structure factor needs.
  3. `KWALD(nat, vkwald, rkappa, kmax…, carga, rxq,ryq,rzq, fxkq,fykq,fzkq, KVEC, wxx_kw…, box)` → raw reciprocal energy/forces/virial.
  4. `fx3(i) = fxkq(i) - fxi(i)` ; `ukwald = vkwald - vkwaldi`.
- **Neighbor-list refresh (`main.f:1451`):** `check(rx, rxup, rlist, rcut, updatel, box)` sets `updatel = (4·disp2max > skin²)` where `disp2max` = max PBC-wrapped squared displacement since last build. If `updatel`: `lista(...)` + `save(rx→rxup)`.
- **MTS combine (`main.f:1030`):** `fx(i) = fx1(i) + nts1·fx2(i) + nts2·fx3(i)`.

### Kernel `extern "C"` signatures (read from the `.cu` files)

```cpp
// lista_linkcell_cuda.cu -- C-friendly scalars (not Fortran pointers).
// Has a working reinit guard already (CAMBIO #5: frees + reallocs if
// maxnat/maxlist/ncells changed). ll_free_cuda() exists but is `static`
// (unreachable) -- Task 1 also exports it.
void lista_linkcell_cuda(int maxnat, int maxlist, int nat,
                         const double *rx, const double *ry, const double *rz,
                         double boxx, double boxy, double boxz,
                         int *nblist1, int *nblist2,
                         int *npares, double rlist,
                         const int *inicio_mol);

// fzas_lj_st_cuda.cu -- Fortran-pointer signature (all args by pointer).
// Persistent buffers d_{iitipo,carga,sigma,eps}_persist uploaded once on
// first call (g_const_init). g_const_maxnat is SET BUT NEVER READ -> no
// reinit-on-change; no exported teardown. Task 1 fixes both.
// `eps`,`sigma` are 100-element (10x10, indexed ii + jj*10) arrays.
void fzas_lj_st_cuda(int *maxnat_f, int *maxlist_f, int *nat_f,
                     double *rx, double *ry, double *rz, int *iitipo,
                     double *fx, double *fy, double *fz,
                     double *eps, double *sigma,
                     double *wxx, double *wxy, double *wxz,
                     double *wyy, double *wyz, double *wzz,
                     double *rcut_f, double *boxx_f, double *boxy_f, double *boxz_f,
                     double *carga, double *rkappa_f,
                     double *ulj, double *ucoul,
                     int *npares_f, int *nblist1, int *nblist2);

// kwald_cuda.cu -- ALREADY Phase-3-ready: proper reinit guard
// (kwald_init_cuda re-checks nat/kmax/box), exported kwald_free_cuda().
void kwald_init_cuda(int nat, int kmaxx, int kmaxy, int kmaxz,
                     const double *h_kvec, double boxx, double boxy, double boxz);
void kwald_cuda(int nat, double alfa, int kmaxx, int kmaxy, int kmaxz,
                const double *h_charge,
                const double *h_rx, const double *h_ry, const double *h_rz,
                double *h_fx, double *h_fy, double *h_fz,
                const double *h_kvec,
                double *h_vkwald,
                double *h_wxx_kw, double *h_wxy_kw, double *h_wxz_kw,
                double *h_wyy_kw, double *h_wyz_kw, double *h_wzz_kw,
                double boxx, double boxy, double boxz);
void kwald_free_cuda();
```

---

## Task 1: kernel-lifecycle fix in `fzas_lj_st_cuda.cu` (the only kernel edit)

**Files:** Modify `Programa_DM_cpp/src/kernels/fzas_lj_st_cuda.cu`.

**Problem** (master-plan correction, verified by reading the file): the persistent-const block sets `g_const_maxnat = maxnat` on first call but **never reads it again** — if `maxnat` differs on a later call (different system, or a test harness reusing the process) the persistent `d_*_persist` buffers are the wrong size → OOB. And there's no `extern "C"` teardown, so the buffers leak and can't be reset between test cases in one process.

- [ ] **Step 1: Add a reinit-on-change guard + exported teardown.**
```c
extern "C" void fzas_lj_st_free_cuda(void) {
    if (!g_const_init) return;
    cudaFree(d_iitipo_persist); cudaFree(d_carga_persist);
    cudaFree(d_sigma_persist);  cudaFree(d_eps_persist);
    d_iitipo_persist = nullptr; d_carga_persist = nullptr;
    d_sigma_persist  = nullptr; d_eps_persist   = nullptr;
    g_const_init = false; g_const_maxnat = 0;
}
```
And at the top of `fzas_lj_st_cuda(...)`, before the `if(!g_const_init)`:
```c
if (g_const_init && maxnat != g_const_maxnat) {
    fzas_lj_st_free_cuda();   // size changed -> reset
}
```
Nothing else in the function changes. `sigma`/`eps` are always 100 elements regardless of `maxnat`, so only the `maxnat`-sized `d_iitipo_persist`/`d_carga_persist` are the real risk — the guard covers it.

- [ ] **Step 2: Also export `ll_free_cuda` from `lista_linkcell_cuda.cu`?** NO — that would be a second kernel edit. Instead, in Task 3, the C++ neighbor-list manager relies on `lista_linkcell_cuda`'s existing internal reinit guard (which already frees+reallocs on `ncells`/`maxnat`/`maxlist` change). Note this decision here so Task 3's author doesn't re-open it. `kwald_free_cuda` is already exported — use it directly.

- [ ] **Step 3: Rebuild the FORTRAN release** (`cd Programa_DM && export PATH=/usr/local/cuda/bin:$PATH … && ./compilar_release.sh`) — the `.cu` edit flows into the Fortran binary via the shared kernel source. Wait: the Fortran build compiles `Programa_DM/fzas_lj_st_cuda.cu`, NOT the copy in `Programa_DM_cpp/`. **So Step 3 also copies the edited file to `Programa_DM/fzas_lj_st_cuda.cu`** — the one exception to "never touch `Programa_DM/`", justified because (a) the edit is additive (a guard + a teardown fn, no behavior change on the happy path) and (b) it's the only way to validate the kernel change against the real 10 000-step physics before Task 6. `diff` the two files afterward to confirm they stay identical.

- [ ] **Step 4: Validate — full protocol.** Verify CT 901 idle. Run the real test case (`Prueba/`, 10 000 steps) **3×** in isolated copies. Physics within 1σ (`Total`, `Potential`, `Kinetic`, `ΔE`, `Density`, `Temperature` per the reference table in `01 Analisis`). Wall time must not regress (the guard adds one `int` compare per call — negligible). Zero crashes. Document in `03 Benchmarks/`.

- [ ] **Step 5: Commit** (both copies of the `.cu`): `git commit -m "cpp: Phase 3 Task 1 - reinit-on-maxnat-change guard + exported fzas_lj_st_free_cuda; validated 3x clean, physics within 1sigma, no wall-time regression"`

---

## Task 2: C++ wrappers for LJ-ST and the sigma/eps 10×10 marshalling

**Files:** Create `Programa_DM_cpp/src/nonbonded.hpp/.cpp`, `tests/test_nonbonded_lj.cpp`; modify `src/CMakeLists.txt`.

**Interface:**
```cpp
#pragma once
#include "system_builder.hpp"
#include "bonded_forces.hpp"   // Virial
#include <array>
#include <vector>

namespace gmx {

// Flatten Topology's natom_types x natom_types sigma/eps matrices into the
// 10x10 (100-element, column index * 10 + row) layout the CUDA kernel
// indexes as `ind = ii + jj*10`. Types beyond natom_types() are left 0.
// (The kernel only reads [ii][jj] for ii,jj < natom_types, so padding is
//  inert -- but the array MUST be exactly 100 doubles.)
std::array<double, 100> pack_lj_10x10(const Topology &topo);

struct LjResult { double ulj = 0, ucoul = 0; Virial vir; };

// Calls fzas_lj_st_cuda for the current neighbour list. Writes forces into
// fx/fy/fz (the kernel zeroes them internally -- so this OVERWRITES, it
// does not add; caller must combine into fx2). rkappa = the Ewald real-
// space screening parameter (same value used by kappa_coulomb / kwald).
LjResult compute_lj_st(const System &sys,
                       const std::vector<double> &rx,
                       const std::vector<double> &ry,
                       const std::vector<double> &rz,
                       const std::array<double, 100> &sigma10,
                       const std::array<double, 100> &eps10,
                       const std::vector<int> &nblist1,
                       const std::vector<int> &nblist2,
                       int npares, int maxlist,
                       double rcut, double rkappa,
                       double boxx, double boxy, double boxz,
                       std::vector<double> &fx,
                       std::vector<double> &fy,
                       std::vector<double> &fz);

// One-time: release the kernel's persistent const buffers (wraps
// fzas_lj_st_free_cuda). Call between independent systems in one process
// (e.g. in test teardown).
void free_lj_st();

} // namespace gmx
```

- [ ] **Step 1:** `pack_lj_10x10` — the Fortran `sigma`/`eps` arrays are built by `top_gmx.f`'s combining-rule step as `sigma(ii + jj*10)` for a max of 10 types. Phase 1 Task 6 produced `topo.sigma_matrix[i*n + j]` (row-major, `n = natom_types()`). **Index-order check:** Fortran `sigma(ind)` with `ind = ii + jj*10` is column `jj`, row `ii`. So `sigma10[ii + jj*10] = topo.sigma_matrix[ii*n + jj]` — because the LB matrix is symmetric (`sigma[i][j] == sigma[j][i]`), transpose vs not doesn't matter numerically, but write it the symmetric-safe way and assert `sigma_matrix` is symmetric in the test. Same for `eps`.
- [ ] **Step 2:** `compute_lj_st` — marshal the Fortran-pointer args (take addresses of locals for the `*_f` scalars), pass `sigma10.data()`, `eps10.data()`, `nblist1.data()`, etc. `maxlist` is the `nblist` capacity (Phase 3 fixes it at, e.g., `40 * nat` — see Task 3). Copy the 6 virial out-params into `LjResult::vir`.
- [ ] **Step 3: Unit test** on a **2-atom system** with known LJ params (both same type, `sigma`, `eps` set, charges 0 so `ucoul = 0`), one neighbour pair, box large. Hand-compute `ulj = 4ε(s¹² - s⁶)` with `s = σ/r` — wait, this kernel is LJ-**ST** (truncated), so for `r ≤ rcut`, `u_lj = 4·ε·s⁶·(s⁶ - 1)` where `s⁶ = (σ/r)⁶` (from `kernel_fzas_lj_st` read in the GPU-optimization round). Assert `ulj` and the pair force to ~1e-6 (GPU double precision + the block reduction introduces last-bit noise). Assert net force zero.
- [ ] **Step 4: Real-fixture check** — build `System` + `sigma10`/`eps10` from `fixtures/file.top`, positions from `fixtures/file.gro`, build a neighbour list via Task 3's manager (this task depends on Task 3 landing first — **reorder: do Task 3 before Task 2's Step 4**, or stub the list with a brute-force O(N²) pair list gated at `rlist` just for this check). Assert `ulj` and `ucoul` are finite and in a physical band; net force zero within `1e-5` (GPU reduction noise).
- [ ] **Step 5: CMake + build + full suite + commit.**

---

## Task 3: neighbour-list manager in C++ (port `check.f` + `save` + rebuild loop)

**Files:** extend `nonbonded.hpp/.cpp`, `tests/test_nonbonded_nblist.cpp`.

**Interface:**
```cpp
struct NeighborList {
    std::vector<int> nb1, nb2;   // 1-based global atom indices, size maxlist
    int npares = 0;
    int maxlist = 0;
    std::vector<double> rxup, ryup, rzup;   // positions at last build (for check())
    bool built = false;
};

// rlist = rcut + skin. maxlist sized generously (Fortran uses a fixed
// maxlist; pick 40*nat and grow-and-rebuild if lista_linkcell_cuda reports
// npares == maxlist, which would mean truncation).
void nblist_build(NeighborList &nl, const System &sys,
                  const std::vector<double> &rx, const std::vector<double> &ry, const std::vector<double> &rz,
                  double boxx, double boxy, double boxz, double rlist);

// Port of check.f: returns true (and the caller must rebuild) when
// 4 * max_i(min_image(r_i - rxup_i)^2) > (rlist - rcut)^2.
bool nblist_needs_rebuild(const NeighborList &nl,
                          const std::vector<double> &rx, const std::vector<double> &ry, const std::vector<double> &rz,
                          double boxx, double boxy, double boxz,
                          double rlist, double rcut);
```

- [ ] **Step 1:** `nblist_build` calls `lista_linkcell_cuda(sys.nat, ..., nl.nb1.data(), nl.nb2.data(), &nl.npares, rlist, sys.inicio_mol.data())`, `maxnat = sys.nat`. After the call, copy `rx→rxup` etc., set `built = true`. If `npares >= maxlist`, `maxlist *= 2`, resize, rebuild once (the internal kernel guard handles the realloc).
- [ ] **Step 2:** `nblist_needs_rebuild` — port `check.f` line-for-line: `skin = rlist - rcut` (throw if `≤ 0`), loop atoms, `dx = min_image(rx[i] - rxup[i])` (`std::round`), NaN check (throw), track `disp2max`, return `4*disp2max > skin*skin`.
- [ ] **Step 3: Validate against the Fortran.** The strongest check: build the list in C++ for `fixtures/file.gro`'s config and assert `npares` **exactly equals** what the Fortran program reports for the same config. Get the Fortran number by: `ssh alejandre@192.168.0.230`, run the real case for 0 steps (or grep the first `Lista npares` from a fresh `dm.lis`) — the link-cell kernel is deterministic, so C++ and Fortran must agree to the integer. If they differ, STOP — it means the `inicio_mol` exclusion array or the grid formula is being fed differently.
- [ ] **Step 4:** unit-test `nblist_needs_rebuild` on a tiny system: no displacement → false; displace one atom by `> skin/2` → true.
- [ ] **Step 5: commit.**

---

## Task 4: Ewald setup in C++ (`kappa_coulomb` + `compute_kmax_ewald` + `setup2`)

**Files:** extend `nonbonded.hpp/.cpp`, `tests/test_ewald_setup.cpp`.

```cpp
struct EwaldSetup {
    double rkappa = 0;              // alfa
    int kmaxx = 0, kmaxy = 0, kmaxz = 0;
    std::vector<double> kvec;       // reciprocal weights, one per valid k-vector
};

// error_coul = ewald-rtol from the .mdp (MdpParams::error_coul).
EwaldSetup ewald_setup(double boxx, double boxy, double boxz,
                       double rcut, double error_coul);
```

- [ ] **Step 1:** `rkappa` — port `kappa_coulomb.f`: `rkappa = 0.05; while (std::erfc(rkappa*rcut)/rcut > error_coul) rkappa += 0.02;`. (`derfc` → `std::erfc`.)
- [ ] **Step 2:** `kmaxx/y/z` — port `compute_kmax_ewald.f`: `logtol = -std::log(error_coul)`; (rkappa already set, so the `if (alfa <= 0)` branch is skipped); `kcut = 2*rkappa*std::sqrt(logtol)`; for each axis `x = kcut*box_i/(2π)`, `kmax_i = (int)x; if ((double)kmax_i < x) kmax_i++;` then `if (kmax_i < 1) kmax_i = 1;`.
- [ ] **Step 3:** `kvec` — port `setup2.f`: `kmax = max(kmaxx,kmaxy,kmaxz); ksqmax = kmax*kmax; B = 1/(4*rkappa*rkappa); vol = boxx*boxy*boxz; twopi = 2π;` then the triple loop `KX = 0..kmaxx`, `KY = -kmaxy..kmaxy`, `KZ = -kmaxz..kmaxz`, keeping `ksq <= ksqmax && ksq != 0`, `rksq = (2π·KX/boxx)² + (2π·KY/boxy)² + (2π·KZ/boxz)²`, `kvec.push_back(twopi * std::exp(-B*rksq) / rksq / vol)`. **The iteration order must match `kwald_init_cuda`'s internal k-vector loop** (also `ix 0..kmaxx, iy -kmaxy..kmaxy, iz -kmaxz..kmaxz`, same keep condition) — verified identical when reading both. Do NOT reorder.
- [ ] **Step 4: Validate against `dm.log`.** `ssh alejandre@192.168.0.230 "grep -E 'rkappa,kmaxx|Valor de kappa' GromacsMexicano/Prueba/dm.log"` — assert C++ `rkappa` matches the printed value to `1e-8`, and `kmaxx/y/z` match exactly. For `kvec`: no printed reference, but assert `kvec.size()` equals `kwald_init_cuda`'s `g_nk` (call `kwald_init_cuda` with the C++ setup and expose/compare `g_nk` — or just assert the size is what SETUP2's loop produces for `fixtures/file.gro`'s box, computed independently in the test).
- [ ] **Step 5: commit.**

---

## Task 5: Ewald per-step in C++ (`intra` + `cofm`/`xyz_cofm` + `kwald_cuda`)

**Files:** extend `nonbonded.hpp/.cpp`, `tests/test_ewald_recip.cpp`.

```cpp
struct EwaldResult {
    double ukwald = 0;   // vkwald - vkwaldi
    Virial vir;          // wxx_kw - wxxi, etc.
    // forces written into caller's fx3/fy3/fz3 as fxkq - fxi
};

// Full reciprocal Ewald for one force evaluation. `carga` = per-atom
// pre-scaled charges (System::carga). `setup` from Task 4.
EwaldResult compute_ewald_recip(const System &sys,
                                const std::vector<double> &rx,
                                const std::vector<double> &ry,
                                const std::vector<double> &rz,
                                double boxx, double boxy, double boxz,
                                const EwaldSetup &setup,
                                std::vector<double> &fx3,
                                std::vector<double> &fy3,
                                std::vector<double> &fz3);

void free_ewald();   // wraps kwald_free_cuda()
```

- [ ] **Step 1: port `intra.f`.** `vself = (1/√π) * rkappa * Σ carga[i]²`. Then the double loop over molecule-internal pairs (walk species → molecules → atoms, `nbegin..nend`), for each intramolecular pair `(n1,n2)`: PBC-min-image separation, `x = rkappa*rij`, `qij = carga[n1]*carga[n2]`, `vkin += qij*(1 - erfc(x))/rij`, `du12 = qij*((1 - erfc(x)) - (2/√π)*x*exp(-x²))/rij²`, `fij = du12 * d/rij`, accumulate `fxi[n1] += fijx`, `fxi[n2] -= fijx`, and virial `wxxi += fijx*dx` … . `vkwaldi = vself + vkin`. (Molecule boundaries: use `System::species` counts, same walk as `system_builder`.)
- [ ] **Step 2: port `cofm.f` + `xyz_cofm.f`.** `cofm`: per molecule, COM with intramolecular PBC-unwrap (atom 1 as anchor, others `+ dnint((anchor - r)/box)*box`), mass-weighted by `System::rrmasa`; then per-atom offset `pxik[na] = min_image(r[na] - rxcm[molecule])`. `xyz_cofm`: `rxq[na] = pxik[na] + rxcm[molecule]`. Result `rxq/ryq/rzq` = whole-molecule-consistent coords.
- [ ] **Step 3: call the kernel.** `kwald_init_cuda(nat, kmaxx, kmaxy, kmaxz, setup.kvec.data(), box)` (idempotent — its guard no-ops if unchanged). Then `kwald_cuda(nat, rkappa, kmax…, carga.data(), rxq.data(), ryq.data(), rzq.data(), fxkq.data(), …, setup.kvec.data(), &vkwald, &wxx_kw, …, box)`.
- [ ] **Step 4: combine.** `fx3[i] = fxkq[i] - fxi[i]`; `ukwald = vkwald - vkwaldi`; `vir.xx = wxx_kw - wxxi` … (sign per `main.f`).
- [ ] **Step 5: Validate against `dm.log` step-0.** Full pipeline on `fixtures/file.gro` + `fixtures/file.top`: assert `ukwald / nmol` (nmol = 944 = 800+72+72) matches `dm.log`'s first printed `Ukwald kJ/mol` line to ~1e-4 (GPU double precision). Also net force zero within `1e-4`, and a finite-difference check on 10 atoms of `ukwald` (this is the definitive force check — the Ewald force is where subtle bugs hide).
- [ ] **Step 6: commit.**

---

## Task 6: full non-bonded assembly + Phase 3 gate

**Files:** `Programa_DM_cpp/src/forces.hpp/.cpp` (the whole-force-evaluation entry point), `tests/test_forces_gate.cpp`.

```cpp
struct ForceEval {
    double vbonds, vangles, ulj, ucoul, ukwald;
    Virial vir_fast, vir_lj, vir_ewald;   // the 3 MTS groups' virials
    // fx1/fx2/fx3 (fast / LJ / Ewald) written into caller buffers
};

// One complete force evaluation: bonds+angles -> fx1 ; LJ-ST -> fx2 ;
// Ewald reciprocal -> fx3. Does NOT do the MTS combine (that's the
// integrator's job, Phase 4) -- returns the 3 groups separately.
ForceEval compute_all_forces(const System &sys, const Topology &topo,
                             const std::vector<double> &rx,
                             const std::vector<double> &ry,
                             const std::vector<double> &rz,
                             double boxx, double boxy, double boxz,
                             double rcut, double error_coul,
                             NeighborList &nl, EwaldSetup &esetup,
                             /* out */ std::vector<double> &fx1, std::vector<double> &fy1, std::vector<double> &fz1,
                             std::vector<double> &fx2, std::vector<double> &fy2, std::vector<double> &fz2,
                             std::vector<double> &fx3, std::vector<double> &fy3, std::vector<double> &fz3);
```

- [ ] **Step 1:** wire Phase 2 (`compute_bond_forces` + `compute_angle_forces` → `fx1`), Task 2 (`compute_lj_st` → `fx2`), Task 5 (`compute_ewald_recip` → `fx3`). Build the neighbour list once up front, `EwaldSetup` once. `sigma10`/`eps10` from `pack_lj_10x10`.
- [ ] **Step 2: THE GATE.** `test_forces_gate.cpp`: full pipeline on the real fixtures. Assert **against `dm.log` step-0**, all per-`nmol` and to ~1e-4 (GPU precision):
  - `vbonds/nmol`, `vangles/nmol` (Phase 2 already validated these standalone — this re-confirms in the assembled path)
  - `ulj/nmol`, `ucoul/nmol`
  - `ukwald/nmol`
  - `epot/nmol = (vbonds + vangles + ulj + ucoul + ukwald)/nmol` matches `dm.log`'s first `epot`
  - net force `Σ(fx1 + fx2 + fx3)` (with the actual `nts1`/`nts2` weights) is zero within `1e-4`
  - **finite-difference check on the full assembled energy** for 10 atoms.
  Note: `dm.log`'s step-0 is written AFTER `nstlog` steps of dynamics (first block is `istep 200`), NOT at `t=0` — so the fixture `file.gro` (a mutated config) won't match step-0 exactly. **To make this a real gate:** get a genuine `t=0` reference by running the Fortran for `nsteps=0` (or `nstlog=1`) on a pristine `file.gro` and capturing the very first energy block. Do this once, check it into `tests/fixtures/step0_reference.txt`, assert against it.
- [ ] **Step 3: 3× clean.** Because Task 1 touched a kernel and this is the first time the C++ path computes real physics end-to-end, run the gate test 3× on a verified-idle CT 901 — GPU reductions are non-deterministic at the last bit, so confirm the 1e-4 tolerance holds across runs, not just once.
- [ ] **Step 4: Document** in `03 Benchmarks/` (energies C++ vs `dm.log` step-0, the FD check result) and `07 Iteration Logs/`. Update `CLAUDE.md` status + Ruflo memory. **Commit** — "Phase 3 complete".

---

## Self-Review

- **Spec coverage:** the 3 `.cu` kernels (via wrappers, Tasks 2/5), `check.f`+`lista.f` (Task 3), `kappa_coulomb.f`+`compute_kmax_ewald.f`+`setup2.f` (Task 4), `intra.f`+`cofm.f`+`xyz_cofm.f` (Task 5), full assembly + MTS force-group split (Task 6). `save.f` is trivial (copy rx→rxup) and folded into Task 3. Not ported: `fzas_diedro.f`/`fzas_15.f` (zero in this system, deferred), the actual MTS integration (Phase 4), LRC dispersion correction (`lrc_lj_st.f95` — `DispCorr = no` for this case per the mdp, so it contributes 0; port with Phase 4 if a later case turns it on).
- **The one kernel edit (Task 1)** is isolated, additive, and goes through the full 3×-clean physics protocol against the Fortran build — not treated as free glue.
- **Ordering caveat:** Task 2 Step 4 needs Task 3's neighbour list. Either do Task 3 first, or use a brute-force O(N²) `rlist`-gated pair list for Task 2's fixture check only. Called out in Task 2 Step 4.
- **The gate (Task 6) needs a genuine t=0 reference**, not the mutated `file.gro` — Step 2 spells out how to capture one from the Fortran.
- **GPU precision:** every kernel-touching assert uses ~1e-4–1e-6 tolerance (double precision + non-associative block reductions), NOT bit-exact — matching how the GPU-optimization round validated.

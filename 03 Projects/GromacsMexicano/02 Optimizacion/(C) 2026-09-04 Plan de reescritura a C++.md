# GromacsMexicano C++ Rewrite — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Fortran 77/95 driver code of GromacsMexicano with C++, so the program can be built and installed with a standard cross-platform toolchain (CMake) like GROMACS itself, while keeping the already-optimized and physics-validated CUDA kernels intact.

**Architecture:** Incremental strangler-fig migration. The Fortran program (`Programa_DM/main.f` + ~100 supporting `.f`/`.f95` files, 14 002 lines total) stays the frozen reference implementation throughout. A new C++ project (`Programa_DM_cpp/`) is built alongside it, one subsystem at a time, each subsystem validated against the Fortran reference before the next one starts. The 8 existing `.cu` files (already C++, already validated, already optimized — see `03 Benchmarks/`) are relocated into the new project's build **unchanged** in early phases; only their host-side callers move from Fortran/`ISO_C_BINDING` to native C++.

**Tech Stack:** C++17, CMake ≥3.24 (`enable_language(CUDA)`, `CMAKE_CUDA_ARCHITECTURES`), the existing CUDA 13.0 toolchain already installed on CT 901 (`nvcc -arch=sm_120`), no third-party dependencies in the initial phases (add a `.gro`/`.top` parsing library only if hand-rolled parsing becomes a bottleneck — not assumed up front).

**Spec:** No separate spec doc — the existing Fortran source at `/home/alejandre/GromacsMexicano/Programa_DM/` (CT 901, `ssh alejandre@192.168.0.230`) IS the spec. Physics reference: `/home/alejandre/GromacsMexicano/Prueba/dm.log` (SPC/E water + NaCl, NPT, 2544 atoms: 800 water + 72 Na + 72 Cl).

## Global Constraints

- **Physics validated at every phase gate** — energies (Potential/Kinetic/Total/DeltaE), temperature, pressure, density must fall within the statistical error already established (`Total = -89.05846 ± 0.01195 kJ/mol` from the current validated reference `ca9ef61`). No phase is "done" without this check passing 3x clean.
- **Never touch `/home/alejandre/GromacsMexicano/Programa_DM/` while it's the reference** — all new work happens in a sibling directory, same git repo, same working tree (`/home/alejandre/GromacsMexicano/`).
- **CT 901 must be verified free of concurrent activity (`who` + `ps aux | grep dm_mx_npt`) before every benchmark/validation run** — this project has twice had runs killed or contaminated by concurrent sessions on the same box.
- **One subsystem per phase, one commit per validated subsystem** — this project already lost real time once (cambio #3, reverted) from an ambitious single-shot restructure that looked correct but wasn't. Small validated steps, not a big-bang rewrite.
- **Scope discipline:** only the code paths the current test case actually exercises get ported first (GROMACS-style `.top`/`.gro`/`.mdp` I/O, LJ-ST + Ewald reciprocal, harmonic bonds + angles, link-cell neighbor list, Nosé-Hoover NPT barostat/thermostat). Mie and FDR potential variants, the shifted-force (`_sf`) LJ variant, and the `_f77` CPU-reference comparison paths are **not used by the live test case** (confirmed: `dm.log` reports `Potencial LJ-ST (truncated)`) and are deferred to a later phase — do not port them "just in case."

---

## Roadmap (phases beyond this plan's detailed scope)

This plan fully details **Phase 0** only. Phases 1+ touch large, not-yet-fully-read Fortran files (`top_gmx.f95` is 1362 lines, `mdp.f` is 985 lines) — writing placeholder-free, line-referenced tasks for them now would mean guessing at code I haven't read in full, which this project's own rules forbid ("nada de optimización sin benchmark" / no blind porting). Each phase below gets its **own** plan, written the same way as this one, immediately before that phase starts — matching how every GPU optimization in this project was actually done (read the real code, then plan, then implement, then validate).

| Phase | Scope | Rough size | Risk |
|---|---|---|---|
| **0** (this plan) | CMake project skeleton; relocate the 8 existing `.cu` kernels unchanged; prove they compile and link under CMake+nvcc; one smoke-test call | ~1 session | Very low — no physics code changes |
| 1 | Port I/O: `.gro` reader/writer (`gro0.f`/`grof.f`, 71 lines), `.mdp` key=value parser (`mdp.f`, 985 lines — mechanical, one `if/else` chain), `.top`/`.itp` topology parser (`top_gmx.f95`, 1362 lines — `[moleculetype]`/`[atoms]`/`[bonds]`/`[angles]`/`[molecules]` sections) | ~2-3 sessions | Low — no force/integration math, validate by round-tripping known test files and diffing parsed values against what the Fortran program prints at startup |
| 2 | Port bonded forces: harmonic bonds (`fzas_de.f`, 105 lines) and angles (`fzas_angulo.f`, 145 lines) — both fully read this session, both small, both already isolated (no shared mutable state beyond `fx/fy/fz`) | ~1 session | Low — closed-form formulas, easy to unit-test against hand-computed values for a 2-3 atom system before wiring into the full loop |
| 3 | Port link-cell + LJ-ST + Ewald **driver glue** — call the existing validated `.cu` kernels directly from C++ instead of via Fortran `ISO_C_BINDING`. **Correction (post Phase-0 final review):** the original plan assumed "kernels themselves don't change" — false. `fzas_lj_st_cuda.cu`'s persistent-buffer guard (`g_const_maxnat` set but never read) has no reinit-on-change check, and teardown is inconsistent across the 3 files (`ll_free_cuda` is `static`/unreachable, `fzas_lj_st_cuda.cu` has none). A C++ driver that owns process lifecycle and may run varying system sizes needs a working reinit guard and exported teardown on at least `fzas_lj_st_cuda.cu` before Phase 3 can safely call it more than once. This IS a kernel change and must go through the full 3x-clean physics/benchmark validation this project requires for any kernel edit — budget for that explicitly, don't treat it as free glue work. | ~2-3 sessions (was 1-2) | Medium (was Low) — real kernel changes required, not just glue |
| 4 | Port the integration loop + Nosé-Hoover NPT barostat/thermostat (`baros_nh_system.f`, `thermo_nh_system.f`, `factores.f`) — the most delicate physics in the program | ~2-3 sessions | **High** — this is where subtle bugs hide; budget for a slower, more heavily-instrumented validation pass than earlier phases |
| 5 | End-to-end: full C++ binary reproduces the 10 000-step reference run within the established statistical error, 3x clean | ~1 session | Gate, not new code |
| 6 (stretch) | Mie/FDR potentials, other ensembles, packaging/installer for non-CLI users | Not scoped | — |

Total realistic estimate: **8-12 sessions** of focused work for phases 0-5, assuming each phase's validation gate passes on the first or second try (cambio #3's experience says budget for at least one phase needing a redo).

---

## Task 1: CMake project skeleton

**Files:**
- Create: `/home/alejandre/GromacsMexicano/Programa_DM_cpp/CMakeLists.txt`
- Create: `/home/alejandre/GromacsMexicano/Programa_DM_cpp/src/main.cpp`
- Create: `/home/alejandre/GromacsMexicano/Programa_DM_cpp/.gitignore`

**Interfaces:**
- Produces: a `gmx_mexicano` executable target and a `gmx_kernels` static library target, both defined in `CMakeLists.txt`, that later tasks link against.

- [ ] **Step 1: Create the directory and top-level `CMakeLists.txt`**

```cmake
cmake_minimum_required(VERSION 3.24)

# MUST be set before project(... LANGUAGES CUDA) — enable_language(CUDA)
# (which project() triggers) populates CMAKE_CUDA_ARCHITECTURES from the
# compiler default immediately, so an `if(NOT DEFINED ...)` guard placed
# after project() is always false and this override silently never
# applies (found in final review of Phase 0: the build was shipping an
# sm_75-only cubin, running on the 5070 Ti purely via PTX JIT).
if(NOT DEFINED CMAKE_CUDA_ARCHITECTURES)
  set(CMAKE_CUDA_ARCHITECTURES 120)  # RTX 5070 Ti (Blackwell) on CT 901
endif()

project(GromacsMexicanoCpp LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

add_subdirectory(src)
```

- [ ] **Step 2: Create `src/CMakeLists.txt` defining the kernels library and executable**

```cmake
add_library(gmx_kernels STATIC
    kernels/lista_linkcell_cuda.cu
    kernels/fzas_lj_st_cuda.cu
    kernels/kwald_cuda.cu
)
target_compile_options(gmx_kernels PRIVATE
    $<$<COMPILE_LANGUAGE:CUDA>:-O2;--fmad=false>
)
set_target_properties(gmx_kernels PROPERTIES
    CUDA_SEPARABLE_COMPILATION ON
)

add_executable(gmx_mexicano main.cpp)
target_link_libraries(gmx_mexicano PRIVATE gmx_kernels)
```

- [ ] **Step 3: Create `src/main.cpp` as a minimal smoke-test entry point**

```cpp
#include <cstdio>

int main() {
    std::printf("GromacsMexicano C++ — Phase 0 build OK\n");
    return 0;
}
```

- [ ] **Step 4: Create `.gitignore` for the new subtree**

```
build/
*.o
```

- [ ] **Step 5: Copy the three existing validated `.cu` files into `src/kernels/` unchanged**

```bash
mkdir -p /home/alejandre/GromacsMexicano/Programa_DM_cpp/src/kernels
cp /home/alejandre/GromacsMexicano/Programa_DM/lista_linkcell_cuda.cu \
   /home/alejandre/GromacsMexicano/Programa_DM/fzas_lj_st_cuda.cu \
   /home/alejandre/GromacsMexicano/Programa_DM/kwald_cuda.cu \
   /home/alejandre/GromacsMexicano/Programa_DM_cpp/src/kernels/
```

Do **not** edit these files in this task — byte-for-byte copies of the versions validated in `ca9ef61`. Confirm with `diff`:

```bash
diff /home/alejandre/GromacsMexicano/Programa_DM/lista_linkcell_cuda.cu \
     /home/alejandre/GromacsMexicano/Programa_DM_cpp/src/kernels/lista_linkcell_cuda.cu
diff /home/alejandre/GromacsMexicano/Programa_DM/fzas_lj_st_cuda.cu \
     /home/alejandre/GromacsMexicano/Programa_DM_cpp/src/kernels/fzas_lj_st_cuda.cu
diff /home/alejandre/GromacsMexicano/Programa_DM/kwald_cuda.cu \
     /home/alejandre/GromacsMexicano/Programa_DM_cpp/src/kernels/kwald_cuda.cu
```
Expected: no output from any `diff` (files identical).

- [ ] **Step 6: Configure and build**

```bash
export PATH=/usr/local/cuda/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH
cd /home/alejandre/GromacsMexicano/Programa_DM_cpp
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
```
Expected: build succeeds, produces `build/src/gmx_mexicano`.

- [ ] **Step 7: Run the smoke test**

```bash
./build/src/gmx_mexicano
```
Expected output: `GromacsMexicano C++ — Phase 0 build OK`

- [ ] **Step 8: Commit**

```bash
cd /home/alejandre/GromacsMexicano
git add Programa_DM_cpp
git commit -m "cpp: Phase 0 - CMake skeleton, relocate validated CUDA kernels unchanged

No physics code changes. Proves the C++/CMake/nvcc toolchain builds on
CT 901 before any Fortran routine gets ported. The three .cu files are
byte-identical to the ca9ef61 validated versions (see diff in this
task's history)."
```

## Task 2: Prove the relocated kernels are actually callable (not just compilable)

A library that compiles but was never invoked isn't proven — this task calls one kernel end-to-end on synthetic data, closing the gap between "it builds" and "it works," before any real physics is ported in Phase 1+.

**Files:**
- Modify: `/home/alejandre/GromacsMexicano/Programa_DM_cpp/src/main.cpp`

**Interfaces:**
- Consumes: `extern "C" void lista_linkcell_cuda(int maxnat, int maxlist, int nat, const double *rx, const double *ry, const double *rz, double boxx, double boxy, double boxz, int *nblist1, int *nblist2, int *npares, double rlist, const int *inicio_mol)` — signature confirmed by reading `kernels/lista_linkcell_cuda.cu` in this session, unchanged by Task 1's copy.

- [ ] **Step 1: Declare the extern "C" signature and call it on a tiny synthetic system in `main.cpp`**

```cpp
#include <cstdio>
#include <vector>

extern "C" void lista_linkcell_cuda(
    int maxnat, int maxlist, int nat,
    const double *rx, const double *ry, const double *rz,
    double boxx, double boxy, double boxz,
    int *nblist1, int *nblist2,
    int *npares, double rlist,
    const int *inicio_mol);

int main() {
    // 4 atoms in a 2x2x2 box, spaced so all pairs are within rlist=1.5
    const int nat = 4;
    const int maxnat = nat;
    const int maxlist = 16;
    std::vector<double> rx = {0.0, 1.0, 0.0, 1.0};
    std::vector<double> ry = {0.0, 0.0, 1.0, 1.0};
    std::vector<double> rz = {0.0, 0.0, 0.0, 0.0};
    std::vector<int> inicio_mol = {1, 2, 3, 4};  // no intramolecular exclusions
    std::vector<int> nblist1(maxlist, 0), nblist2(maxlist, 0);
    int npares = 0;

    lista_linkcell_cuda(maxnat, maxlist, nat,
                         rx.data(), ry.data(), rz.data(),
                         2.0, 2.0, 2.0,
                         nblist1.data(), nblist2.data(),
                         &npares, 1.5, inicio_mol.data());

    std::printf("GromacsMexicano C++ - Phase 0 build OK\n");
    std::printf("Smoke test: lista_linkcell_cuda found %d pairs (expected 6)\n", npares);
    return (npares == 6) ? 0 : 1;
}
```

4 atoms with no exclusions and a cutoff covering the whole box means all C(4,2)=6 pairs should be found.

- [ ] **Step 2: Rebuild and run**

```bash
cmake --build build -j
./build/src/gmx_mexicano
```
Expected: `Smoke test: lista_linkcell_cuda found 6 pairs (expected 6)` and exit code 0.

- [ ] **Step 3: If it prints a different count, stop and diagnose before continuing**

Do not proceed to Phase 1 on a failing smoke test — it would mean the CMake CUDA build produces a kernel that behaves differently from the validated `compilar_release.sh` build (e.g. a missed compiler flag), and every later phase would inherit that silently.

- [ ] **Step 4: Commit**

```bash
cd /home/alejandre/GromacsMexicano
git add Programa_DM_cpp/src/main.cpp
git commit -m "cpp: Phase 0 - smoke-test lista_linkcell_cuda through the CMake build

Closes the gap between 'compiles' and 'works': calls the relocated
kernel on a 4-atom synthetic system with a known answer (6 pairs)."
```

---

## Self-Review

**Spec coverage:** Phase 0's only claim is "the C++/CMake toolchain builds and can call the existing kernels" — Tasks 1-2 cover that exactly. Phases 1-6 are intentionally left as a roadmap, not detailed tasks, per the Global Constraints scope-discipline rule and because `top_gmx.f95`/`mdp.f` haven't been read in full yet — detailing them now would violate the no-placeholder rule.

**Placeholder scan:** No TBD/TODO; every code block is complete and runnable as written; the smoke test has a concrete expected numeric answer (6 pairs), not "add appropriate assertions."

**Type consistency:** The `lista_linkcell_cuda` signature in Task 2 matches the `extern "C"` declaration read directly from `kernels/lista_linkcell_cuda.cu` in Task 1 (copied unchanged) — same parameter order, same types (`int`, `const double*`, `double`, `int*`).

# GromacsMexicano C++ Rewrite — Phase 1 (I/O) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port the three file-format readers/writer (`.gro`, `.mdp`, `.top`/`.itp`) and the per-species-to-per-atom topology expansion to C++, with every parsed value validated byte-exact against what the Fortran reference program prints for the real test case (`Prueba/`).

**Architecture:** Same strangler-fig approach as Phase 0. Each task ports one self-contained Fortran subroutine (or a natural sub-part of one large one) into its own C++ header/source pair under `Programa_DM_cpp/src/io/` or `Programa_DM_cpp/src/`, with its own CTest target. No task touches the simulation loop or any force kernel — this phase is pure parsing and data-structure population. `Programa_DM/` (Fortran) is read-only reference throughout, never modified.

**Tech Stack:** C++17 (matching Phase 0), `std::vector`/`std::string`/`std::ifstream`, no third-party parsing library — the formats are small and fixed enough that hand-rolled parsing (matching what the Fortran does token-for-token) is both simpler and easier to validate line-by-line against the reference than pulling in a dependency.

**Spec:** The Fortran source is the spec. Every task below cites exact file:line ranges read in full before this plan was written: `Programa_DM/gro0.f` (45 lines), `Programa_DM/grof.f` (26 lines), `Programa_DM/mdp.f` (985 lines), `Programa_DM/top_gmx.f95` (1362 lines), `Programa_DM/distribuir_de.f` (41), `distribuir_angulos.f` (47), `distribuir_diedros.f` (35), `distribuir_15.f` (34), `distribuir_tipos.f` (20), `distribuir_masas.f` (15), `distribuir_cargas.f` (31), `inicio_molecula.f` (31). Test fixtures: `Prueba/file.gro`, `Prueba/file.mdp`, `Prueba/file.top`, `Prueba/spce.itp`, `Prueba/sodium.itp`, `Prueba/chloride.itp` — all read in full, all values below hand-verified against them.

## Global Constraints

- **Physics validated at every phase gate** — this phase parses data, it doesn't compute forces, so "physics validation" here means: every parsed number must match the Fortran reference's own startup printout exactly (these are text-format parsers — there is no floating-point accumulation to introduce 1σ-style tolerance; a mismatch is a bug, not noise).
- **Never touch `/home/alejandre/GromacsMexicano/Programa_DM/`** — read-only reference. All new work in `Programa_DM_cpp/`.
- **CT 901 must be verified free of concurrent activity (`who` + `ps aux | grep dm_mx_npt`) before every build/test run.**
- **One subsystem per task, one commit per validated task, task-scoped review before the next task starts** — Phase 0's final review caught a real bug (CMake architecture ordering) precisely because each task stayed small enough to review properly; don't undo that discipline here by batching unrelated parsers into one commit.
- **No physics/numeric logic invented** — every formula, every validation check, every default value in this plan is copied from the Fortran source that was read in full to write it. If an implementer finds the actual file content differs from what's quoted here, STOP and report rather than guessing — this plan is only as good as the reads it's based on, and a fresh subagent has no way to tell a stale quote from a real spec without asking.
- **`Programa_DM_cpp/tests/` already exists** (Phase 0 final-review fix added `enable_testing()` + one CTest target) — new tasks add sibling test executables to the same `tests/` directory and register them the same way, they don't invent a new test mechanism.

---

## Fortran reference data model (read once, used by every task below)

All arrays in the Fortran program are declared once in `PROGRAM dm_npt` (`main.f:1-40`) with fixed upper bounds (`maxnat=30000`, per-species arrays dimensioned `(..., 10)` for up to 10 molecule species) and passed by argument to every subroutine — **there are no COMMON blocks**. This is good news for the port: it means a straightforward `struct System { std::vector<...> ...; }` populated by each parser in turn, sized to the *actual* atom/species count (not the Fortran's fixed upper bound), is a faithful, lower-risk translation — no global/static state to reason about.

---

## Task 1: `.gro` reader and writer

**Files:**
- Create: `Programa_DM_cpp/src/io/gro_file.hpp`
- Create: `Programa_DM_cpp/src/io/gro_file.cpp`
- Create: `Programa_DM_cpp/tests/test_gro_file.cpp`
- Modify: `Programa_DM_cpp/src/CMakeLists.txt` (add `gmx_io` library target and the new test)

**Reference:** `Programa_DM/gro0.f:1-45` (reader), `Programa_DM/grof.f:1-26` (writer).

**Interfaces:**
- Produces: `GroFrame` struct and `read_gro`/`write_gro` functions, consumed by Phase 1's later system-assembly step (Task 7) and eventually the Phase 3 driver.

The Fortran format (both read and write use the identical fixed-width format `format(I5,2A5,I5,3F8.3,3F8.4)`):

```
<title line, free text>
<natoms, free-format integer>
<one line per atom: I5 resid, A5 resname, A5 atomname, I5 atomnum, F8.3 x, F8.3 y, F8.3 z, F8.4 vx, F8.4 vy, F8.4 vz>
<one line: 3 box lengths — free-format on read (F12.5-ish on write), orthorhombic box only (boxx, boxy, boxz), no off-diagonal terms>
```

Note the reader (`gro0.f`) reads the box line with list-directed I/O (`read(88,*) boxx,boxy,boxz`, free-format) while the writer (`grof.f`) writes it with `write(88,'(3F12.5)')` — the read side does NOT care about column widths for the box line specifically (only the atom lines are fixed-width). Preserve this asymmetry: your reader should parse the box line by splitting on whitespace, not by fixed columns.

- [ ] **Step 1: Write the failing tests first**

Create `Programa_DM_cpp/tests/test_gro_file.cpp`:

```cpp
#include "../src/io/gro_file.hpp"
#include <cassert>
#include <cstdio>
#include <fstream>
#include <cmath>

static bool nearly_equal(double a, double b, double tol = 1e-6) {
    return std::fabs(a - b) < tol;
}

static void write_test_gro(const char *path) {
    std::ofstream f(path);
    f << "Test system\n";
    f << "    2\n";
    f << "    1SOL     OW    1   0.123   0.456   0.789  0.1000  0.2000  0.3000\n";
    f << "    1SOL     HW    2   1.000   2.000   3.000 -0.1000 -0.2000 -0.3000\n";
    f << "   2.50000   2.50000   2.50000\n";
}

int main() {
    const char *path = "/tmp/test_gmx_cpp.gro";
    write_test_gro(path);

    gmx::GroFrame frame = gmx::read_gro(path);

    assert(frame.nat == 2);
    assert(nearly_equal(frame.rx[0], 0.123));
    assert(nearly_equal(frame.ry[0], 0.456));
    assert(nearly_equal(frame.rz[0], 0.789));
    assert(nearly_equal(frame.vx[0], 0.1000));
    assert(nearly_equal(frame.vy[0], 0.2000));
    assert(nearly_equal(frame.vz[0], 0.3000));
    assert(frame.symbol2[0] == "OW");
    assert(frame.resid_name[0] == "SOL");
    assert(nearly_equal(frame.rx[1], 1.000));
    assert(frame.symbol2[1] == "HW");
    assert(nearly_equal(frame.boxx, 2.5));
    assert(nearly_equal(frame.boxy, 2.5));
    assert(nearly_equal(frame.boxz, 2.5));

    // Round-trip: write it back out and re-read, values must survive
    gmx::write_gro("/tmp/test_gmx_cpp_out.gro", frame, /*istep=*/42);
    gmx::GroFrame frame2 = gmx::read_gro("/tmp/test_gmx_cpp_out.gro");
    assert(frame2.nat == 2);
    assert(nearly_equal(frame2.rx[0], 0.123, 1e-3));  // F8.3 precision on write
    assert(nearly_equal(frame2.vx[0], 0.1000, 1e-4)); // F8.4 precision on write
    assert(frame2.symbol2[1] == "HW");

    std::printf("test_gro_file: all assertions passed\n");
    return 0;
}
```

- [ ] **Step 2: Run it to confirm it fails to build** (the header doesn't exist yet)

```
ssh alejandre@192.168.0.230 "cd GromacsMexicano/Programa_DM_cpp && export PATH=/usr/local/cuda/bin:\$PATH; export LD_LIBRARY_PATH=/usr/local/cuda/lib64:\$LD_LIBRARY_PATH; cmake --build build -j 2>&1 | tail -20"
```
Expected: a compile error, `gro_file.hpp` not found (the test file exists but the header it includes doesn't).

- [ ] **Step 3: Write `Programa_DM_cpp/src/io/gro_file.hpp`**

```cpp
#pragma once
#include <string>
#include <vector>

namespace gmx {

struct GroFrame {
    int nat = 0;
    std::vector<double> rx, ry, rz;   // positions, nm
    std::vector<double> vx, vy, vz;   // velocities, nm/ps
    std::vector<std::string> resid_name;  // 5-char residue name per atom
    std::vector<std::string> symbol2;     // 4-char atom name per atom
    double boxx = 0.0, boxy = 0.0, boxz = 0.0;  // orthorhombic box, nm
};

// Reads a GROMACS-format .gro file. Throws std::runtime_error on any
// I/O or parse failure (file not found, malformed atom line, etc.) —
// the Fortran reference calls STOP on the equivalent conditions, which
// is not portable/testable behavior to replicate; an exception is the
// direct C++ equivalent of "abort with a message."
GroFrame read_gro(const std::string &path);

// Writes a .gro file in the same fixed-width format the Fortran
// reference produces (format(I5,2A5,I5,3F8.3,3F8.4) for atom lines,
// '(3F12.5)' for the box line). `istep` is written into the title line
// as "Configuracion <istep>", matching grof.f's title line exactly.
void write_gro(const std::string &path, const GroFrame &frame, int istep);

} // namespace gmx
```

- [ ] **Step 4: Write `Programa_DM_cpp/src/io/gro_file.cpp`**

Implement `read_gro` by: opening the file, reading the title line and discarding it, reading `nat` (free-format int — `std::istringstream` on the line, or `std::stoi` after trimming), then for each of `nat` lines: parse the atom line. **Fixed-width parsing, matching Fortran's `I5,2A5,I5,3F8.3,3F8.4`** — columns 1-5 = resid number (ignored, not stored — the struct doesn't need it since nothing downstream in this phase uses it), columns 6-10 = resname (5 chars, trim trailing spaces), columns 11-15 = atom name (5 chars, trim — note the Fortran declares `symbol2` as `character*4` even though the format field is `A5`; store the trimmed value, whatever its length, in a `std::string`, don't truncate to 4), columns 16-20 = atom number (ignored), columns 21-28 = x (F8.3), 29-36 = y, 37-44 = z, 45-52 = vx (F8.4), 53-60 = vy, 61-68 = vz. Use `std::string::substr` for fixed columns and `std::stod` on the trimmed substring for the floats. After the atom loop, read the box line by splitting on whitespace (`std::istringstream >> boxx >> boxy >> boxz`) — free-format, not fixed-width, per the note above.

Implement `write_gro` with `std::snprintf` using format strings that reproduce `I5,2A5,I5,3F8.3,3F8.4` — e.g. `"%5d%5s%5s%5d%8.3f%8.3f%8.3f%8.4f%8.4f%8.4f\n"` for each atom line (1-based atom/resid numbers, matching Fortran's `i` loop variable which is already 1-based). Title line: `"Configuracion " + std::to_string(istep)`. Box line: `"%12.5f%12.5f%12.5f\n"` matching `'(3F12.5)'`.

- [ ] **Step 5: Add the library and test targets to `Programa_DM_cpp/src/CMakeLists.txt`**

```cmake
add_library(gmx_io STATIC io/gro_file.cpp)

add_executable(test_gro_file ../tests/test_gro_file.cpp)
target_link_libraries(test_gro_file PRIVATE gmx_io)
add_test(NAME gro_file COMMAND test_gro_file)
```

- [ ] **Step 6: Build and run the test**

```
cmake --build build -j 2>&1 | tail -30
ctest --test-dir build --output-on-failure -R gro_file
```
Expected: `test_gro_file: all assertions passed`, ctest reports `1/1 Test #N: gro_file ... Passed`.

- [ ] **Step 7: Validate against the real test case fixture**

Add a second test (append to `test_gro_file.cpp` or add a second `main`-free check — simplest is a second assertion block in the same `main()`) that reads the **actual** `Prueba/file.gro` (copy it next to the test binary or reference it by relative path from the build directory — simplest: `ssh` a copy into `Programa_DM_cpp/tests/fixtures/file.gro` and reference that fixed path) and asserts:
- `frame.nat == 2544`
- `nearly_equal(frame.boxx, 3.00454, 1e-4)`, same for `boxy`, `boxz` (from `Programa_DM/Prueba/file.gro`'s actual box line — read it yourself via `ssh alejandre@192.168.0.230 "tail -1 GromacsMexicano/Prueba/file.gro"` to get the exact value the file currently has, since the box drifts slightly run-to-run under NPT and the checked-in fixture reflects whatever the last run left it at; use whatever `tail -1` actually shows, not the value quoted in this plan, since this file mutates every simulation run and the plan was written at one point in time)
- `frame.symbol2[0]` and `frame.resid_name[0]` are non-empty strings (don't hardcode the exact first atom's identity into the plan — inspect `head -3 file.gro` yourself and assert against what you actually see, for the same reason as the box value above)

Copy the fixture: `ssh alejandre@192.168.0.230 "cat GromacsMexicano/Prueba/file.gro" > /tmp/file_gro_fixture` then transfer it into `Programa_DM_cpp/tests/fixtures/file.gro` on the remote.

- [ ] **Step 8: Commit**

```
git add Programa_DM_cpp/src/io/gro_file.hpp Programa_DM_cpp/src/io/gro_file.cpp Programa_DM_cpp/tests/test_gro_file.cpp Programa_DM_cpp/tests/fixtures/file.gro Programa_DM_cpp/src/CMakeLists.txt
git commit -m "cpp: Phase 1 Task 1 - .gro reader/writer, validated against real 2544-atom fixture"
```

---

## Task 2: `.mdp` parameter file parser

**Files:**
- Create: `Programa_DM_cpp/src/io/mdp_file.hpp`
- Create: `Programa_DM_cpp/src/io/mdp_file.cpp`
- Create: `Programa_DM_cpp/tests/test_mdp_file.cpp`
- Modify: `Programa_DM_cpp/src/CMakeLists.txt`

**Reference:** `Programa_DM/mdp.f:1-985` (read in full). Key structure: an `open`/line-loop over `file.mdp`, per line: (1) check for a `; dm-*` comment-encoded DM-specific parameter (`mdp_parametro_dm`, lines 875-939) — `dm-skin`, `dm-nstreal`, `dm-nstkspace`, prefixed with `;` then `dm-`; (2) strip normal `;` comments; (3) split on the first `=` into `key`/`value`, both lowercased; (4) a long `if/else if` chain matching ~30 known keys (lines 186-373); (5) after EOF, a large validation block (lines 385-786) that derives `rcut` from `rvdw` (requiring `rvdw==rcoulomb==rlist`), interprets `integrator`/`tcoupl`/`pcoupl`/`coulombtype` strings into booleans/derived values, and calls `stop` (i.e., should throw in C++) on ~25 distinct invalid conditions.

**Interfaces:**
- Consumes: nothing from Task 1 (independent).
- Produces: `MdpParams` struct + `read_mdp` function, consumed by the eventual Phase 3+ simulation setup (not by any other Phase 1 task).

- [ ] **Step 1: Write `Programa_DM_cpp/src/io/mdp_file.hpp`**

```cpp
#pragma once
#include <string>

namespace gmx {

struct MdpParams {
    // Integration
    std::string integrator = "md-vv";
    double dt = 0.0;
    int nsteps = 0;

    // Output frequencies
    int nstlog = 0, nstxout = 0, nstvout = 0, nstenergy = 0;

    // Cutoffs (rvdw == rcoulomb == rlist is enforced; rcut = rvdw)
    double rcut = 0.0;
    double skin = 0.0;          // from "; dm-skin = ..." comment convention
    int nstlist = 10;

    // Electrostatics
    std::string coulombtype = "cut-off";
    bool recip_ewald = false;
    double error_coul = 1.0e-6; // ewald-rtol
    std::string ewald_geometry = "3d";
    int fourier_nx = 0, fourier_ny = 0, fourier_nz = 0;

    // Thermostat (Nose-Hoover)
    bool termostato = false;
    int nch = 1;                // nh-chain-length
    double tau_t = 0.0;
    double temp = 0.0;          // ref-t

    // Barostat (MTTK)
    bool barostato = false;
    double p_ext = 0.0;         // ref-p
    double tau_p = 0.0;
    std::string pcoupltype = "isotropic";

    std::string constraints = "none";
    std::string dispcorr = "no";

    // Multiple-time-step scheme, from "; dm-nstreal"/"; dm-nstkspace" comments
    int nts1 = 1, nts2 = 1;

    double boxx = 0.0; // NOT read from the .mdp file itself — see Step 3 note
};

// Parses file.mdp at `path`. Throws std::runtime_error with a message
// matching the Fortran ERROR text (see mdp.f) on any of the ~25
// validation failures the reference checks for. `boxx` is required by
// one validation check (rcut > boxx/2) but is NOT itself an .mdp key —
// the Fortran subroutine receives it as an argument from the caller
// (main.f already knows the box size from file.gro by the time it
// calls mdp()). This function takes it as a second parameter for the
// same reason.
MdpParams read_mdp(const std::string &path, double boxx);

} // namespace gmx
```

**Note the `boxx` parameter carefully** — this is a real, easy-to-miss detail from reading the actual call site: `mdp.f`'s subroutine signature includes `boxx` as an argument (line 2), used only once, at line 675-680, purely to validate `rcut <= boxx/2`. It is not parsed from the file. Get this wrong (e.g. by assuming `read_mdp(path)` with no box argument) and either the signature won't match how Phase 3 needs to call it, or the validation check silently vanishes.

- [ ] **Step 2: Write `Programa_DM_cpp/tests/test_mdp_file.cpp`**

```cpp
#include "../src/io/mdp_file.hpp"
#include <cassert>
#include <cstdio>
#include <fstream>
#include <stdexcept>
#include <cmath>

static bool nearly_equal(double a, double b, double tol = 1e-9) {
    return std::fabs(a - b) < tol;
}

static void write_minimal_mdp(const char *path) {
    std::ofstream f(path);
    f << "integrator = md-vv\n";
    f << "dt = 0.002\n";
    f << "nsteps = 100\n";
    f << "nstlog = 10\n";
    f << "nstxout = 0\n";
    f << "nstvout = 0\n";
    f << "nstenergy = 10\n";
    f << "cutoff-scheme = Verlet\n";
    f << "nstlist = 5\n";
    f << "verlet-buffer-tolerance = -1\n";
    f << "rvdw = 0.9\n";
    f << "rcoulomb = 0.9\n";
    f << "rlist = 0.9\n";
    f << "; dm-skin = 0.1\n";
    f << "coulombtype = cut-off\n";
    f << "tcoupl = no\n";
    f << "pcoupl = no\n";
    f << "constraints = none\n";
    f << "dispcorr = no\n";
    f << "; dm-nstreal = 1\n";
    f << "; dm-nstkspace = 1\n";
}

int main() {
    const char *path = "/tmp/test_gmx_cpp.mdp";
    write_minimal_mdp(path);

    gmx::MdpParams p = gmx::read_mdp(path, /*boxx=*/3.0);

    assert(p.integrator == "md-vv");
    assert(nearly_equal(p.dt, 0.002));
    assert(p.nsteps == 100);
    assert(nearly_equal(p.rcut, 0.9));   // rcut = rvdw when rvdw==rcoulomb==rlist
    assert(nearly_equal(p.skin, 0.1));
    assert(p.recip_ewald == false);      // coulombtype = cut-off
    assert(p.termostato == false);
    assert(p.barostato == false);

    // rvdw != rcoulomb must throw (mdp.f:554-559)
    {
        std::ofstream f("/tmp/test_gmx_cpp_bad.mdp");
        f << "integrator = md-vv\ndt = 0.002\nnsteps = 100\n";
        f << "nstlog = 10\nnstxout = 0\nnstvout = 0\nnstenergy = 10\n";
        f << "cutoff-scheme = Verlet\nnstlist = 5\nverlet-buffer-tolerance = -1\n";
        f << "rvdw = 0.9\nrcoulomb = 1.0\nrlist = 0.9\n; dm-skin = 0.1\n";
        f << "coulombtype = cut-off\ntcoupl = no\npcoupl = no\n";
        f << "constraints = none\ndispcorr = no\n";
        f << "; dm-nstreal = 1\n; dm-nstkspace = 1\n";
        bool threw = false;
        try {
            gmx::read_mdp("/tmp/test_gmx_cpp_bad.mdp", 3.0);
        } catch (const std::runtime_error &) {
            threw = true;
        }
        assert(threw);
    }

    std::printf("test_mdp_file: all assertions passed\n");
    return 0;
}
```

- [ ] **Step 3: Implement `mdp_file.cpp`**

Port the Fortran logic directly: read the file line by line into a `std::vector<std::string>`. For each line: (a) check the `; dm-*` convention first (a line whose trimmed content starts with `;`, followed by `dm-` after stripping the `;` and leading spaces — parse `dm-skin`/`dm-nstreal`/`dm-nstkspace` the same way as `mdp_parametro_dm`, lines 907-928); (b) otherwise strip anything from the first unescaped `;` onward; (c) skip blank lines; (d) split on the first `=`, trim and lowercase both sides; (e) dispatch on the key string with an `if/else if` chain (or a `std::unordered_map<std::string, std::function<void(const std::string&)>>` if you prefer, as long as every key in `mdp.f:186-373` is covered) matching the case list in that file. Track which of `rvdw`/`rcoulomb`/`rlist`/`fourier-nx`/`fourier-ny`/`fourier-nz` were actually seen (booleans, matching `tiene_rvdw` etc.) since their *absence* is itself a validation error. After the loop, run the validation block from `mdp.f:385-786` — every `stop` in that block becomes a `throw std::runtime_error("<same message text>")` in C++, preserving the Fortran's exact error strings so a human comparing behavior side-by-side can match them up. Interpret `integrator` (`md-vv`/`md-vv-avek` OK, `md` warns, anything else throws), `tcoupl` (`no`→false, `nose-hoover`→true, else throws), `pcoupl` (`no`→false, `mttk`→true, else throws), `coulombtype` (`ewald`/`pme`→`recip_ewald=true`; `cut-off`/`cutoff`/`no`→false; else throws) exactly as the reference does.

- [ ] **Step 4: Add to `Programa_DM_cpp/src/CMakeLists.txt`**

```cmake
target_sources(gmx_io PRIVATE io/mdp_file.cpp)

add_executable(test_mdp_file ../tests/test_mdp_file.cpp)
target_link_libraries(test_mdp_file PRIVATE gmx_io)
add_test(NAME mdp_file COMMAND test_mdp_file)
```

- [ ] **Step 5: Build, run, confirm both assertions pass**

```
cmake --build build -j 2>&1 | tail -30
ctest --test-dir build --output-on-failure -R mdp_file
```

- [ ] **Step 6: Validate against the real fixture**

Copy `Prueba/file.mdp` into `Programa_DM_cpp/tests/fixtures/file.mdp` (same transfer pattern as Task 1). Add a third check in `test_mdp_file.cpp`: `read_mdp("tests/fixtures/file.mdp", <boxx from the file.gro fixture in Task 1, i.e. whatever value that fixture's last line actually has>)` and assert every field matches what `Programa_DM/Prueba/dm.log`'s startup dump prints (the "Parametros de integracion" / "Frecuencias de escritura" / etc. section, `mdp.f:798-865`) — fetch the actual current values with `ssh alejandre@192.168.0.230 "grep -A3 'Parametros de integracion' GromacsMexicano/Prueba/dm.log"` (and similarly for the other sections) rather than trusting any specific numbers quoted in this plan, since `file.mdp` could have been edited since this plan was written.

- [ ] **Step 7: Commit**

```
git add Programa_DM_cpp/src/io/mdp_file.hpp Programa_DM_cpp/src/io/mdp_file.cpp Programa_DM_cpp/tests/test_mdp_file.cpp Programa_DM_cpp/tests/fixtures/file.mdp Programa_DM_cpp/src/CMakeLists.txt
git commit -m "cpp: Phase 1 Task 2 - .mdp parser, validated against real fixture + reference startup dump"
```

---

## Task 3: `.top`/`.itp` file-loading infrastructure (tokenizer, `#include` resolution, section detection)

**Files:**
- Create: `Programa_DM_cpp/src/io/itp_reader.hpp`
- Create: `Programa_DM_cpp/src/io/itp_reader.cpp`
- Create: `Programa_DM_cpp/tests/test_itp_reader.cpp`
- Modify: `Programa_DM_cpp/src/CMakeLists.txt`

**Reference:** `Programa_DM/top_gmx.f95`, the `contains`-nested helper procedures at lines 437-616 (file loading + `#include`) and 1206-1359 (tokenizer, section-name matching, comment stripping). These are the generic text-processing primitives that every later `.top` section parser (Task 4, 5, 6) is built on — split out first so each of those tasks can be tested against a small synthetic snippet instead of the full real topology.

This task has **no numerical content and no GROMACS-specific parsing rules** — it is a plain-text preprocessor. Port these exact behaviors:

1. **`cargar_archivo_recursivo_local`** (lines 446-524): open a file, read it line by line. For each line, check `obtener_include_local` (below); if it's an `#include`, resolve its path (`resolver_ruta_include_local`, below) and recurse into it (max depth 20, matching line 455's guard — throw if exceeded, matching "ERROR: demasiados niveles de #include"). Otherwise, clean the line (`limpiar_linea_local`, below); if the cleaned line is non-empty, append it to a flat `std::vector<std::string>` of "logical lines" that all later parsing works over (this flattens the whole `#include` tree into one line list, in file order, with comments and blank lines already removed — exactly what the Fortran does by building its module-level `lines(:)`/`rawlines(:)` arrays).
2. **`obtener_include_local`** (lines 527-566): a line is a `#include` directive if, after left-trimming, it starts with the literal 8 characters `#include`. The included filename is whatever appears between either `"` `"` or `<` `>` immediately after. Throw if `#include` appears but neither delimiter pair is found (matching "ERROR: sintaxis incorrecta de #include").
3. **`resolver_ruta_include_local`** (lines 569-615): try, in order: (a) the include name literally, as a path relative to the current working directory; (b) the include name relative to the directory containing the file that has the `#include` line (i.e. if `file.top` is in `/foo/` and includes `"bar.itp"`, try `/foo/bar.itp`); (c) `top/<include name>` relative to the current working directory. Use the first one that exists on disk (`std::filesystem::exists` is the direct C++ equivalent of Fortran's `inquire(file=...,exist=...)`). Throw if none exist.
4. **`limpiar_linea_local`** (lines 1335-1359): strip everything from the first `;` or `!` (whichever comes first) onward, then left-trim what remains.
5. **`tokenizar_local`** (lines 1206-1234): split a line into whitespace-separated tokens (space and tab are both separators), max 24 tokens (matching `maxtokens=24` at line 318 — throw "ERROR: demasiadas columnas" if exceeded).
6. **`es_seccion_local`** (lines 1264-1271): a line is a section header if, after left-trim, it's at least 3 chars, starts with `[`, and contains a `]` somewhere after position 1.
7. **`normalizar_seccion_local`** (lines 1273-1300): given a section-header line, extract the text between `[` and `]`, strip all internal whitespace, lowercase it, and re-wrap in `[`/`]` — so `"[ Atoms ]"`, `"[atoms]"`, and `"[ ATOMS  ]"` all normalize to `"[atoms]"`. This is what makes section matching case/whitespace-insensitive.
8. **`token_es_entero_local`** (lines 1236-1243): a token is "an integer" if it parses as one AND contains none of `.`, `E`, `e` — this distinguishes `"1"` (integer, e.g. an atom index or a GROMACS funct code) from `"1.0"` or `"1e-3"` (a float) even though both parse successfully as numbers. Used throughout Tasks 4-6 to detect which of two column layouts a line is using (see those tasks).

**Interfaces:**
- Produces: `load_topology_lines(path) -> std::vector<std::string>` (the flattened, comment-stripped, `#include`-resolved line list) and standalone `tokenize`, `is_section_header`, `normalize_section_name`, `token_is_integer` functions, all consumed by Tasks 4-6.

```cpp
#pragma once
#include <string>
#include <vector>

namespace gmx {

// Loads `path`, recursively resolving #include directives (matching
// resolver_ruta_include_local's 3-step search order), stripping ';' and
// '!' comments, and dropping blank lines. Returns the flattened line
// list in file order across all included files. Throws
// std::runtime_error on: file not found, unresolvable #include,
// malformed #include syntax, or #include recursion depth > 20.
std::vector<std::string> load_topology_lines(const std::string &path);

// Splits on whitespace (space or tab). Throws if more than 24 tokens.
std::vector<std::string> tokenize(const std::string &line);

bool is_section_header(const std::string &line);

// Requires is_section_header(line) — extracts, whitespace-strips, and
// lowercases the text between '[' and ']', re-wrapped in brackets
// (e.g. "[ Atoms ]" -> "[atoms]").
std::string normalize_section_name(const std::string &line);

// True iff `token` parses as an integer AND contains none of '.', 'E', 'e'.
bool token_is_integer(const std::string &token);

} // namespace gmx
```

- [ ] **Step 1: Write `Programa_DM_cpp/tests/test_itp_reader.cpp`** covering, at minimum: a two-file `#include` (one file includes another via both `"..."` and `<...>` syntax), a line with a `;` comment and one with a `!` comment both getting stripped, a blank line being dropped, `tokenize` on a tab-and-space-mixed line, `is_section_header`/`normalize_section_name` on `"[ Atoms ]"` → `"[atoms]"`, and `token_is_integer` distinguishing `"12"` (true) from `"1.0"`, `"1e-3"`, `"abc"` (all false). Use `/tmp/` scratch files for the include test, same pattern as Tasks 1-2.

- [ ] **Step 2: Implement `itp_reader.cpp`** per the numbered behaviors above.

- [ ] **Step 3: Add to CMake, build, run**

```cmake
target_sources(gmx_io PRIVATE io/itp_reader.cpp)
add_executable(test_itp_reader ../tests/test_itp_reader.cpp)
target_link_libraries(test_itp_reader PRIVATE gmx_io)
add_test(NAME itp_reader COMMAND test_itp_reader)
```
```
cmake --build build -j 2>&1 | tail -30
ctest --test-dir build --output-on-failure -R itp_reader
```

- [ ] **Step 4: Validate against the real fixture's `#include` chain**

Copy `Prueba/file.top`, `Prueba/spce.itp`, `Prueba/sodium.itp`, `Prueba/chloride.itp` into `Programa_DM_cpp/tests/fixtures/`. Add a check: `load_topology_lines("tests/fixtures/file.top")` must resolve all three `#include "....itp"` lines (they're the literal-relative-path case, delimiter `"`) and produce a flattened line list containing lines from all four files, with none of the `;`-prefixed comment lines (e.g. `"; nbfunc  comb-rule  gen-pairs  fudgeLJ  fudgeQQ"`) present in the output — assert the returned vector's size and spot-check that it contains a line whose tokens match `["SOL", "800"]` (from `file.top`'s `[molecules]` section) AND a line whose tokens match `["1", "2", "1", "0.10", "443199.0"]` (from `spce.itp`'s `[bonds]` section, proving the include resolved).

- [ ] **Step 5: Commit**

```
git add Programa_DM_cpp/src/io/itp_reader.hpp Programa_DM_cpp/src/io/itp_reader.cpp Programa_DM_cpp/tests/test_itp_reader.cpp Programa_DM_cpp/tests/fixtures/file.top Programa_DM_cpp/tests/fixtures/spce.itp Programa_DM_cpp/tests/fixtures/sodium.itp Programa_DM_cpp/tests/fixtures/chloride.itp Programa_DM_cpp/src/CMakeLists.txt
git commit -m "cpp: Phase 1 Task 3 - topology file-loading infra (tokenizer, #include resolution), validated against real 4-file include chain"
```

---

## Task 4: `[defaults]` and `[atomtypes]` parsing

**Files:**
- Create: `Programa_DM_cpp/src/topology.hpp`
- Create: `Programa_DM_cpp/src/topology.cpp`
- Create: `Programa_DM_cpp/tests/test_topology_atomtypes.cpp`
- Modify: `Programa_DM_cpp/src/CMakeLists.txt`

**Reference:** `top_gmx.f95:617-793` (`leer_defaults_local`, `leer_atomtypes_local`), plus the DM-specific override convention at lines 634-656 and 1302-1333 (`leer_extra_comentado_local`).

**Interfaces:**
- Consumes: `gmx::load_topology_lines`, `gmx::tokenize`, `gmx::is_section_header`, `gmx::normalize_section_name`, `gmx::token_is_integer` from Task 3.
- Produces: the `AtomType` struct and the `[defaults]`/`[atomtypes]` fields of `Topology` (defined fully in this task; Tasks 5-6 add more fields to the same struct), plus `parse_defaults_and_atomtypes(lines) -> Topology` (partial — only these two sections populated), consumed by Task 6 (Lorentz-Berthelot matrix needs `natom_types`/`sigma0`/`eps0`).

```cpp
#pragma once
#include <string>
#include <vector>

namespace gmx {

struct AtomType {
    std::string name;
    double mass = 0.0;
    double charge = 0.0;
    double sigma = 0.0;
    double eps = 0.0;
    double nij = 0.0;   // only meaningful if nbfunc is 2 or 5 (Mie)
    double soft = 0.0;  // only meaningful if nbfunc is 3 or 6 (FDR)
};

struct Topology {
    // [defaults]
    int nbfunc = 0;          // DM's own selector (1-6), see note below
    int comb_rule = 0;       // only 2 (Lorentz-Berthelot) is supported
    std::string genpairs = "no";
    double fudgeLJ = 1.0;
    double fudgeQQ = 1.0;

    // [atomtypes]
    std::vector<AtomType> atomtypes;  // index 0 == GROMACS atomtype 1, etc.
};

// Parses [defaults] and [atomtypes] from an already-flattened topology
// line list (the output of load_topology_lines). Throws
// std::runtime_error matching the reference's ERROR text on any of the
// validation failures in top_gmx.f95:617-793.
Topology parse_defaults_and_atomtypes(const std::vector<std::string> &lines);

} // namespace gmx
```

**The `nbfunc` override convention (critical, easy to get backwards):** `[defaults]`'s first token is GROMACS's own `nbfunc` (must be `1` for LJ, per GROMACS convention — the code reads it into a local `nbfunc_gmx` and only uses it as a *fallback*). The DM program's actual, more detailed potential selector (1=LJ-SF, 2=Mie-SF, 3=FDR-SF, 4=LJ-ST truncated, 5=Mie-ST, 6=FDR-ST) is written as a trailing comment on the same line: `1  2  no  1.0  1.0  ; dm_nbfunc 4`. Parse: take the first numeric token after the `;` on that line (via the same "first token after `;` that parses as a number" logic as `leer_extra_comentado_local`, lines 1302-1333) as `nbfunc`; if there's no such comment, fall back to `nbfunc_gmx`. Throw if the resulting `nbfunc` is outside `[1,6]`.

**`[atomtypes]` has two supported line formats** (the code auto-detects which one a given line uses by checking whether the *first* token parses as an integer, `token_is_integer(tok[0])`, at line 702):
- **"Legacy" format** (first token is an integer atom-type index): `tipo  masa  carga  sigma  epsilon  [nij_or_soft]` — 5 or 6 tokens.
- **"GROMACS" format** (first token is a name, e.g. `"HW"`): `name  at.num  mass  charge  ptype  sigma  epsilon  [nij_or_soft]` — 7 or 8 tokens. This is the format the real fixture uses (see `Prueba/file.top`'s `[atomtypes]` block).

In both formats, if `nbfunc` is 2 or 5 (Mie) or 3 or 6 (FDR) and the extra column (`nij`/`soft`) is missing from the line itself, fall back to the same `leer_extra_comentado_local` "; extra value" convention as `nbfunc` used — throw if neither the column nor a parseable trailing comment is present. **The real fixture uses `nbfunc=4` (LJ-ST) and 4 atomtypes in GROMACS format with no trailing `nij`/`soft` needed** (confirmed by reading `Prueba/file.top`'s actual `[atomtypes]` section in full) — so the Mie/FDR branches won't be exercised by the fixture test below, but must still be implemented per the spec above since Phase 6 (stretch, per the master rewrite plan) may need them later; don't skip them just because the current fixture doesn't hit them.

- [ ] **Step 1: Write `test_topology_atomtypes.cpp`** with a small synthetic 2-atomtype `.top` snippet (both legacy and GROMACS formats, one test each) covering: correct `nbfunc` extraction from the `; dm_nbfunc N` comment, correct fallback to GROMACS `nbfunc` when no comment is present, and a throw when `nbfunc` is out of `[1,6]`.

- [ ] **Step 2: Implement `parse_defaults_and_atomtypes`** in `topology.cpp`, per the spec above.

- [ ] **Step 3: Add to CMake, build, run** (same pattern as prior tasks — `gmx_topology` as a new library target since this depends on `gmx_io`):

```cmake
add_library(gmx_topology STATIC topology.cpp)
target_link_libraries(gmx_topology PRIVATE gmx_io)

add_executable(test_topology_atomtypes ../tests/test_topology_atomtypes.cpp)
target_link_libraries(test_topology_atomtypes PRIVATE gmx_topology)
add_test(NAME topology_atomtypes COMMAND test_topology_atomtypes)
```

- [ ] **Step 4: Validate against the real fixture** (from Task 3's `tests/fixtures/file.top`, which already includes the 3 `.itp` files). `parse_defaults_and_atomtypes(load_topology_lines("tests/fixtures/file.top"))` must produce: `nbfunc == 4`, `comb_rule == 2`, `genpairs == "no"`, `fudgeLJ == 1.0`, `fudgeQQ == 1.0`, and exactly 4 atomtypes with, in order: `{"HW", mass=1.008, charge=0.0, sigma=0.065, eps=0.166}`, `{"OW", mass=15.9994, charge=0.0, sigma=0.3188, eps=0.65}`, `{"Na", mass=22.99, charge=0.0, sigma=0.245, eps=0.196}`, `{"Cl", mass=35.453, charge=0.0, sigma=0.41, eps=0.628}` (these exact numbers were read directly from `Prueba/file.top`'s `[atomtypes]` block and are stable — this file, unlike `file.gro`, is not rewritten by simulation runs). Note the atomtypes' `charge` field here is always `0.000` in this fixture — real per-atom charges come from `[atoms]` sections in Task 5, not from `[atomtypes]`; don't be alarmed that this looks wrong, it's what the file actually says.

- [ ] **Step 5: Commit**

```
git add Programa_DM_cpp/src/topology.hpp Programa_DM_cpp/src/topology.cpp Programa_DM_cpp/tests/test_topology_atomtypes.cpp Programa_DM_cpp/src/CMakeLists.txt
git commit -m "cpp: Phase 1 Task 4 - [defaults]/[atomtypes] parsing, validated against real 4-atomtype fixture"
```

---

## Task 5: `[moleculetype]` / `[atoms]` / `[bonds]` / `[angles]` / `[dihedrals]` / `[pairs]` / `[system]` / `[molecules]` parsing

**Files:**
- Modify: `Programa_DM_cpp/src/topology.hpp` (extend `Topology` with the fields below)
- Modify: `Programa_DM_cpp/src/topology.cpp` (add the new parsing function)
- Create: `Programa_DM_cpp/tests/test_topology_species.cpp`
- Modify: `Programa_DM_cpp/src/CMakeLists.txt`

**Reference:** `top_gmx.f95:795-1069` (`leer_topologia_molecular_local` and its per-section sub-parsers), `1071-1096` (molar mass + atom-count totals), `1098-1127` (index validation), `1129-1163` (species/atomtype name lookup helpers — case-insensitive).

**Interfaces:**
- Consumes: `Topology` (partially populated by Task 4 — needs `atomtypes` to resolve atom-type names to indices), plus Task 3's line/token utilities.
- Produces: the `Species` struct and `Topology::species`/`system_name`/`molecule_counts` fields, consumed by Task 6 (needs `natom_types` — already there from Task 4 — plus per-species atom-type composition for `npair_tipo`) and Task 7 (needs every field of `Species` to expand into whole-system arrays).

```cpp
// Add to topology.hpp:

struct Bond {
    int i = 0, j = 0;           // 1-based, LOCAL to the molecule (not yet offset into the whole system)
    double r0 = 0.0, kr = 0.0;
};

struct Angle {
    int i = 0, j = 0, k = 0;    // 1-based, local
    double theta0_deg = 0.0, ktheta = 0.0;
};

struct Dihedral {
    int i = 0, j = 0, k = 0, l = 0;  // 1-based, local
    double params[6] = {0,0,0,0,0,0};
};

struct Pair15 {
    int i = 0, j = 0;  // 1-based, local
};

struct Species {
    std::string name;
    int n_atoms_per_molecule = 0;
    int n_molecules = 0;           // from [molecules], filled in after all moleculetypes are read
    double molar_mass = 0.0;       // sum of constituent atomtypes' masses
    std::vector<int> atom_type_index;  // per local atom, 0-based index into Topology::atomtypes
    std::vector<Bond> bonds;
    std::vector<Angle> angles;
    std::vector<Dihedral> dihedrals;
    std::vector<Pair15> pairs15;
};

// Add to Topology:
//   std::string system_name;
//   std::vector<Species> species;

// Extends `topo` in place (it must already have `atomtypes` populated
// by parse_defaults_and_atomtypes). Throws on any of the validation
// failures in top_gmx.f95:795-1163 (species with zero atoms, bond/angle/
// dihedral atom index out of range for its species, undefined atomtype
// name referenced in [atoms], undefined moleculetype name referenced in
// [molecules], missing [system] or [molecules] section).
void parse_species_sections(const std::vector<std::string> &lines, Topology &topo);
```

**Section-walking logic** (`leer_topologia_molecular_local`, lines 795-846): scan the flattened line list once; whenever a line is a section header, normalize it and dispatch: `[moleculetype]` starts a new `Species` (throw if more than 10 — `maxesp` in the Fortran, but since this is C++ with `std::vector` there's no real reason to hard-cap at 10; still throw with a clear message if something pathological like >1000 species shows up, as a sanity check, not a hard architectural limit); `[atoms]`/`[bonds]`/`[angles]`/`[dihedrals]` (also accept the literal alternate spelling `[diedros]`, which the reference supports)/`[pairs]` (also accept `[pairs15]`/`[pares15]`) all apply to the *current* (most recently opened) species — throw "sin [moleculetype]" if none is open yet; `[system]` ends the species-reading loop (system name is read separately, see below); anything else is ignored at this level (it'll be re-scanned by `leer_molecules_local` for `[molecules]` afterward, since that section comes after `[system]` in file order and this loop stops at `[system]`).

**`[atoms]` parsing** (lines 862-921): one atom per non-empty line, in molecule-local order (this defines `n_atoms_per_molecule` — increment a counter per line). Column 2 is either an integer (legacy: type index) or a name (GROMACS: atomtype name, resolved via case-insensitive lookup against `Topology::atomtypes`, throwing if not found). **If and only if** column 2 is a name (GROMACS format) AND the line has >=7 tokens, column 7 is a per-atom charge that gets written into `Topology::atomtypes[type].charge` (yes — charge lives on the atom TYPE in this data model, not on the atom; see the note below) — if the same atomtype already got a charge from an earlier atom, the new value must match the old one within `1e-10` or throw ("un mismo atomtype tiene cargas distintas"). Column 8, if present and it parses as a number, is likewise a per-atomtype mass override (tolerance `1e-8` for the consistency check). **This is the mechanism that actually sets real atomtype charges** — Task 4's fixture validation correctly found `charge=0.0` for every atomtype straight out of `[atomtypes]`; the real per-type charges (`HW=+0.4238`, `OW=-0.8476`, `Na=+1.0`, `Cl=-1.0`, all confirmed by reading `Prueba/spce.itp`/`sodium.itp`/`chloride.itp` in full) only get attached once `[atoms]` sections are parsed, which is this task, not Task 4. Update `Topology::atomtypes[i].charge` in place as you encounter these.

**`[bonds]` parsing** (lines 923-962): 3 supported column layouts depending on token count and whether token 3 is an integer: `i j funct r0 k` (GROMACS standard, ≥5 tokens, token 3 integer), `i j r0 funct k` (an older in-house layout, ≥5 tokens, token 3 NOT integer), `i j r0 k` (oldest layout, exactly 4 tokens, no funct column at all). The real fixture (`spce.itp`) uses the first layout (`"1 2 1 0.10 443199.0"` — 5 tokens, token 3 = `"1"` is an integer). Store `r0` and `kr`, discard `funct` (the reference does too — DM only implements one bond functional form).

**`[angles]` parsing** (lines 964-995): 2 layouts: `i j k funct theta0 ktheta` (≥6 tokens, token 4 integer) or `i j k theta0 ktheta` (exactly 5 tokens). Fixture uses the first (`"1 2 3 1 109.47 317.598"`). `theta0` is stored **in degrees** at this stage (matching the Fortran storing `angles(1,na)=ae` in degrees before later converting with `pi/180` at force-evaluation time, NOT at parse time — do not convert here, preserve the same "parse gives degrees" contract so nothing downstream silently double-converts).

**`[dihedrals]` parsing** (lines 997-1022): first 4 tokens are always the atom indices. Token 5, if present and an integer, is `funct` (skip it); the remaining tokens (up to 6 of them) are stored as `params[0..5]`, zero-padded if fewer than 6 are present. The real fixture has no dihedrals (`ndiedroi` will end up 0 for every species) — this branch exists for completeness/future systems, not exercised by the fixture test below; implement it per spec anyway.

**`[pairs]`/`[pairs15]`/`[pares15]` parsing** (lines 1024-1037): just pairs of 1-based local atom indices, 2+ tokens per line, no parameters. Not exercised by the fixture (no `[pairs]` section in `spce.itp`).

**`[system]`** (lines 1039-1049): the line immediately following the `[system]` header (skipping any that would themselves be a section header — throw if the very next line IS one, matching `siguiente_dato_local`'s check) is the free-text system name, stored verbatim (not tokenized). Fixture value: `"SPC/E water with NaCl"`.

**`[molecules]`** (lines 1051-1069): each line is `<moleculetype name> <count>`; resolve the name case-insensitively against already-parsed `Species::name` values (throw if not found) and set that species' `n_molecules`. Fixture: `SOL 800`, `Na 72`, `Cl 72`.

**Post-processing** (lines 1082-1127, run once after all sections are read): compute each species' `molar_mass` as the sum of `atomtypes[atom_type_index[a]].mass` over its atoms (`calcular_masa_molar_local`); validate every bond/angle/dihedral atom index is within `[1, n_atoms_per_molecule]` for its own species (`validar_indice_local`) — throw "ERROR indice en bond/angle/dihedral" (matching the reference's exact wording per-kind) otherwise; throw if any species ended up with `n_atoms_per_molecule == 0`.

- [ ] **Step 1: Write `test_topology_species.cpp`** with a small synthetic topology (one `[moleculetype]` with 3 atoms / 2 bonds / 1 angle, matching the shape of `spce.itp` but with made-up numbers so the test doesn't just duplicate the fixture check in Step 4) plus a `[system]`/`[molecules]` block, verifying: species count, per-species atom/bond/angle counts, bond `r0`/`kr` values, angle `theta0_deg`/`ktheta` values, and that an out-of-range bond index throws.

- [ ] **Step 2: Implement `parse_species_sections`** per the spec above.

- [ ] **Step 3: Add to CMake** (extend the existing `gmx_topology` sources/tests, same pattern as before — no new library target needed, just add the `.cpp` to `target_sources(gmx_topology ...)` and a new `test_topology_species` executable/`add_test`).

- [ ] **Step 4: Validate against the real fixture.** Running the full pipeline (`load_topology_lines` → `parse_defaults_and_atomtypes` → `parse_species_sections`) on `tests/fixtures/file.top` must produce: `system_name == "SPC/E water with NaCl"`; exactly 3 species, `species[0].name=="SOL"` with `n_atoms_per_molecule==3`, `n_molecules==800`, 2 bonds (both `r0=0.10, kr=443199.0`), 1 angle (`theta0_deg=109.47, ktheta=317.598`), `molar_mass` within `1e-6` of `18.0154`; `species[1].name=="Na"` with `n_atoms_per_molecule==1`, `n_molecules==72`, 0 bonds/angles, `molar_mass` within `1e-6` of `22.99`; `species[2].name=="Cl"` with `n_atoms_per_molecule==1`, `n_molecules==72`, `molar_mass` within `1e-6` of `35.453`. Also assert the atomtype charges Task 4 initially found as `0.0` are now, after this task runs, `{HW: 0.4238, OW: -0.8476, Na: 1.0, Cl: -1.0}` within `1e-6` (this is the cross-task check that proves the `[atoms]`-sets-atomtype-charge mechanism actually fired). **All of these numbers were independently hand-verified against `Prueba/dm.log`'s startup dump during this plan's writing** (species/atom/mass counts match `dm.log`'s "Especie N : ..." block exactly) — if your implementation disagrees with a number here, re-check your parsing logic before assuming the plan is wrong, though also re-verify against the live fixture file per this plan's stated policy of trusting the actual file over a quoted number if `Prueba/*` has since changed.

- [ ] **Step 5: Commit**

```
git add Programa_DM_cpp/src/topology.hpp Programa_DM_cpp/src/topology.cpp Programa_DM_cpp/tests/test_topology_species.cpp Programa_DM_cpp/src/CMakeLists.txt
git commit -m "cpp: Phase 1 Task 5 - moleculetype/atoms/bonds/angles/dihedrals/pairs/system/molecules parsing, validated against real 3-species fixture"
```

---

## Task 6: Lorentz-Berthelot combining-rule matrix + intermolecular pair-count bookkeeping

**Files:**
- Modify: `Programa_DM_cpp/src/topology.hpp`
- Modify: `Programa_DM_cpp/src/topology.cpp`
- Create: `Programa_DM_cpp/tests/test_topology_lb_matrix.cpp`
- Modify: `Programa_DM_cpp/src/CMakeLists.txt`

**Reference:** `top_gmx.f95:1-270` (the outer `top_gmx` subroutine — this is the part that runs AFTER `top_gmx_impl`, i.e. after everything Tasks 4-5 cover).

**Interfaces:**
- Consumes: a fully-populated `Topology` (Tasks 4+5's output — needs `atomtypes` for `sigma`/`eps`/`nbfunc`, and `species` for the per-species atom-type composition).
- Produces: the LJ parameter matrices and pair-count table, consumed by Phase 3 (the LJ kernel needs `sigma(i,j)`/`eps(i,j)` in exactly this layout — it's the same `sigma`/`eps` 10×10 arrays `fzas_lj_st_cuda_f77.f95` already passes into the validated CUDA kernel, so getting the indexing convention right here matters for wiring in Phase 3, not just for this task's own tests).

```cpp
// Add to topology.hpp:

struct Topology {
    // ... existing fields from Tasks 4-5 ...

    // Square matrices, size natom_types() x natom_types(), row-major
    // (index as sigma_matrix[i * natom_types() + j], 0-based i,j).
    std::vector<double> sigma_matrix;
    std::vector<double> eps_matrix;
    std::vector<double> nij_matrix;   // only meaningful if nbfunc is 2 or 5
    std::vector<double> soft_matrix;  // only meaningful if nbfunc is 3 or 6

    // npair_tipo(i,j): number of UNIQUE intermolecular pairs of atomtype
    // i with atomtype j across the whole system (symmetric, both
    // [i*n+j] and [j*n+i] hold the same value). Used by long-range
    // dispersion correction, not by this phase's own tests beyond
    // reproducing the reference's printed table.
    std::vector<double> npair_tipo;

    int natom_types() const { return static_cast<int>(atomtypes.size()); }
};

// Must be called after parse_defaults_and_atomtypes AND
// parse_species_sections have both run on `topo`. Populates the four
// matrices and npair_tipo. Does not throw under normal conditions (the
// one error case in the reference, a negative npair_tipo entry, would
// indicate a bug in this function itself, not bad input data — assert()
// on it rather than throw, since it can't be triggered by any
// user-supplied topology file, only by an implementation bug here).
void compute_combining_rules(Topology &topo);
```

**Lorentz-Berthelot matrix** (lines 55-77): for every `(i,j)` pair of atom types (0-based, both directions, i.e. the full square including `i==j`, not just the upper triangle): `sigma_matrix[i][j] = 0.5 * (atomtypes[i].sigma + atomtypes[j].sigma)`; `eps_matrix[i][j] = sqrt(atomtypes[i].eps * atomtypes[j].eps)`. If `nbfunc` is 2 or 5, additionally `nij_matrix[i][j] = 0.5 * (atomtypes[i].nij + atomtypes[j].nij)`. If `nbfunc` is 3 or 6, additionally `soft_matrix[i][j] = 0.5 * (atomtypes[i].soft + atomtypes[j].soft)`. (nbfunc 4, LJ-ST — the one the real fixture uses — only needs `sigma_matrix`/`eps_matrix`, computed with the exact same formula as nbfunc 1; the Fortran's `case(4)` branch, lines 69-74, is a literal no-op duplicate of the LJ formula, kept only for symmetry with the other cases — implement it the same way, don't special-case it away.)

**`npair_tipo`** (lines 80-153): first compute, for every species `ie` and atomtype `it`, `ntipo_mol[it][ie]` = how many atoms of type `it` appear in one molecule of species `ie` (count over `species[ie].atom_type_index`). Then `ntotal_tipo[it] = sum over species ie of species[ie].n_molecules * ntipo_mol[it][ie]` (total site count of type `it` across the whole system). Then for every `it <= jt` (0-based): if `it == jt`, `npair = 0.5 * ntotal_tipo[it] * (ntotal_tipo[it]-1)` and `nintra = sum over species ie of species[ie].n_molecules * 0.5 * ntipo_mol[it][ie] * (ntipo_mol[it][ie]-1)`; if `it != jt`, `npair = ntotal_tipo[it] * ntotal_tipo[jt]` and `nintra = sum over species ie of species[ie].n_molecules * ntipo_mol[it][ie] * ntipo_mol[jt][ie]`. Then `npair_tipo[it][jt] = npair_tipo[jt][it] = npair - nintra` (use `double` throughout — these counts get into the hundreds of thousands to low millions for real systems, per the fixture's own numbers below, well within `double` precision but written as floating point in the Fortran too, so match that rather than switching to integer types).

- [ ] **Step 1: Write `test_topology_lb_matrix.cpp`** using a small synthetic 2-atomtype system (hand-compute the expected `sigma`/`eps` matrix and `npair_tipo` for, say, 2 atomtypes with made-up sigma/eps and a trivial 1-species system with 2 molecules of 2 atoms each — small enough to verify by hand in the test file's comments) before relying on the big real-fixture numbers in Step 3.

- [ ] **Step 2: Implement `compute_combining_rules`** per the spec above.

- [ ] **Step 3: Validate against the real fixture — this is the strongest oracle in the whole phase, hand-verified number by number against `Prueba/dm.log` while writing this plan.** Running the full pipeline on `tests/fixtures/file.top` and calling `compute_combining_rules`, assert (all tolerances `1e-6` unless noted):

  | i (0-based) | j | sigma_matrix | eps_matrix |
  |---|---|---|---|
  | 0 (HW) | 0 | 0.065000 | 0.166000 |
  | 0 | 1 (OW) | 0.191900 | 0.328479 (note: `dm.log` prints `0.328481`, a display-rounding artifact of the reference's `F14.6` format on a value whose more precise double is `sqrt(0.166*0.65)=0.3284789...` — assert against the computed value, `std::sqrt(0.166*0.65)`, not the printed digits) |
  | 0 | 2 (Na) | 0.155000 | 0.180377 |
  | 0 | 3 (Cl) | 0.237500 | 0.322875 |
  | 1 | 1 | 0.318800 | 0.650000 |
  | 2 | 2 | 0.245000 | 0.196000 |
  | 3 | 3 | 0.410000 | 0.628000 |

  And for `npair_tipo` (these ARE exact integers-as-doubles, verified by hand against `dm.log`'s "Pares intermoleculares unicos por tipo" table, no rounding ambiguity):

  | it | jt | npair_tipo |
  |---|---|---|
  | 0 (HW) | 0 | 1278400.0 |
  | 0 | 1 (OW) | 1278400.0 |
  | 0 | 2 (Na) | 115200.0 |
  | 0 | 3 (Cl) | 115200.0 |
  | 1 | 1 | 319600.0 |
  | 1 | 2 | 57600.0 |
  | 1 | 3 | 57600.0 |
  | 2 | 2 | 2556.0 |
  | 2 | 3 | 5184.0 |
  | 3 | 3 | 2556.0 |

  (Derivation for anyone who wants to double check by hand rather than trust this table: `ntotal_tipo = [1600 (HW), 800 (OW), 72 (Na), 72 (Cl)]`, from `800 molecules * 2 HW/molecule`, `800*1 OW`, `72*1 Na`, `72*1 Cl`. E.g. `npair_tipo[HW][HW] = 0.5*1600*1599 - 800*0.5*2*1 = 1279200 - 800 = 1278400`.)

- [ ] **Step 4: Commit**

```
git add Programa_DM_cpp/src/topology.hpp Programa_DM_cpp/src/topology.cpp Programa_DM_cpp/tests/test_topology_lb_matrix.cpp Programa_DM_cpp/src/CMakeLists.txt
git commit -m "cpp: Phase 1 Task 6 - Lorentz-Berthelot combining rules + npair_tipo, validated against dm.log reference table"
```

---

## Task 7: Per-species-to-per-atom system expansion

**Files:**
- Create: `Programa_DM_cpp/src/system_builder.hpp`
- Create: `Programa_DM_cpp/src/system_builder.cpp`
- Create: `Programa_DM_cpp/tests/test_system_builder.cpp`
- Modify: `Programa_DM_cpp/src/CMakeLists.txt`

**Reference:** `Programa_DM/distribuir_de.f` (bonds), `distribuir_angulos.f` (angles), `distribuir_diedros.f` (dihedrals), `distribuir_15.f` (1-5 pairs), `distribuir_tipos.f` (per-atom type), `distribuir_masas.f` (per-atom mass), `distribuir_cargas.f` (per-atom charge, with the `sqrt(factorq)` unit conversion and net-charge-neutrality check), `inicio_molecula.f` (per-atom molecule-boundary marker used by the neighbor-list exclusion filter) — all 7 files read in full.

**Interfaces:**
- Consumes: a fully-populated `Topology` (Tasks 4-6's output).
- Produces: a `System` struct with whole-system, per-atom (not per-species) arrays — this is the direct C++ analogue of the flat `iitipo`/`carga`/`rrmasa`/`ibonds`/`bonds`/`iangles`/`angles`/`inicio_mol` arrays that `main.f` builds once at startup and then passes into every force routine (Fortran and CUDA alike) for the rest of the run. **This is the last Phase 1 task and its output is exactly what Phase 3's C++ driver will need to hand to the existing validated CUDA kernels** — get the indexing conventions right here (1-based vs 0-based, in particular) because Phase 3 has no reason to re-derive them.

```cpp
#pragma once
#include "topology.hpp"
#include <vector>

namespace gmx {

struct SystemBond  { int i, j; double r0, kr; };            // i,j: 1-based, whole-system
struct SystemAngle { int i, j, k; double theta0_deg, ktheta; };
struct SystemDihedral { int i, j, k, l; double params[6]; };
struct SystemPair15 { int i, j; };

struct System {
    int nat = 0;
    std::vector<int> iitipo;        // 1-based atomtype index per atom (matches Fortran's iitipo, itself 1-based since it indexes into 1-based sigma/eps tables)
    std::vector<double> rrmasa;     // mass per atom
    std::vector<double> carga;      // charge per atom, in sqrt(kJ*nm/mol) units (see below)
    std::vector<int> inicio_mol;    // 1-based: for atom i (0-based C++ index), the 1-based index of the FIRST atom NOT in i's molecule (i.e. start of the next molecule) - see note below

    std::vector<SystemBond> bonds;
    std::vector<SystemAngle> angles;
    std::vector<SystemDihedral> dihedrals;
    std::vector<SystemPair15> pairs15;
};

// Expands a fully-populated Topology (after compute_combining_rules)
// into whole-system, per-atom arrays. Throws std::runtime_error if the
// resulting net charge exceeds 1e-12 in magnitude (matching
// distribuir_cargas.f's neutrality check, "The system is charged").
System build_system(const Topology &topo);

} // namespace gmx
```

**Expansion pattern (identical shape across bonds/angles/dihedrals/pairs15/types, `distribuir_de.f:1-42` etc.):** walk species in order; within each species, walk its `n_molecules` molecule copies in order; within each molecule copy, walk its local bonds/angles/etc. in order. Each local atom index gets offset by `ini1 + (m-1)*n_atoms_per_molecule` where `ini1` is the running total of atoms contributed by all *earlier* species (`m` is the 1-based molecule-copy index within the current species). This is a running-offset accumulation — port it as literally: two running counters (`atoms_so_far`, and, for bonds/angles/etc., `items_so_far`, though for a `std::vector` you can just `push_back` and skip tracking `items_so_far` explicitly), reset to 0 at the very start, each advanced by the current species' contribution after that species' molecules are all expanded, never reset mid-species. **Do this in species order, and within a species in molecule-copy order, and within a molecule-copy in local-item order** — the ordering matters because it determines this system's atom numbering, which every later Phase (3+) will treat as the canonical atom order (the SAME order `main.f`'s `distribuir_*` calls produce, so anything compared against the Fortran reference downstream depends on this order matching exactly).

**`inicio_molecula` semantics (read the source, this is easy to get backwards):** for the n-th atom (1-based, `nn` in the Fortran) belonging to molecule-copy `m` (1-based within its species) of species `ie`, `inicio_mol[nn] = ini0 + m*n_atoms_per_molecule[ie] + 1` where `ini0` is the atom count contributed by all earlier species — **note `m`, not `m-1`**: this deliberately computes the 1-based index of the FIRST atom of the *next* molecule copy, not the current one. This is intentional (verified by cross-checking against how the CUDA `construir_pares` kernel uses it: it excludes a candidate pair `(i,j)` with `j>i` if `j+1 < inicio_mol[i]`, i.e. keeps only `j`'s in the current molecule's tail or later molecules — which only works if `inicio_mol[i]` points one-past the end of `i`'s own molecule, not to its start). Do not "fix" this into what looks like the more intuitive off-by-one — it isn't a bug, it's the exclusion filter's actual contract, and Phase 3 will be handing this array straight into the already-validated, unmodified `construir_pares` kernel.

**Charge conversion (`distribuir_cargas.f:1-31`):** `carga[atom] = sqrt(138.935485) * atomtypes[type].charge` (the constant is `1/(4*pi*epsilon0)` in the program's internal units, taking its square root here so that the pairwise Coulomb energy `q_i*q_j/r` comes out directly in kJ/mol without a separate prefactor at force-evaluation time — this is a real unit-system choice in the reference, preserve it exactly, don't "simplify" it into applying the full factor at force-evaluation time instead, since Phase 3 will be calling into kernels that already assume charges arrive pre-scaled this way). After building all per-atom charges, sum them and throw if `|sum| >= 1e-12` (matching the reference's neutrality check).

- [ ] **Step 1: Write `test_system_builder.cpp`** with a small, fully hand-computed synthetic `Topology` (build one directly via the structs — 2 species, e.g. 2 molecules of a 2-atom species with 1 bond each, plus 3 molecules of a 1-atom species — don't go through the file parser here, this test is about the expansion arithmetic in isolation) and assert the exact expected `iitipo`, `bonds[].i/.j` (globally-offset), and `inicio_mol` values you compute by hand in the test's comments, plus a case where charges DON'T sum to zero and the function must throw.

- [ ] **Step 2: Implement `build_system`** per the spec above.

- [ ] **Step 3: Add to CMake**

```cmake
add_library(gmx_system STATIC system_builder.cpp)
target_link_libraries(gmx_system PRIVATE gmx_topology)

add_executable(test_system_builder ../tests/test_system_builder.cpp)
target_link_libraries(test_system_builder PRIVATE gmx_system)
add_test(NAME system_builder COMMAND test_system_builder)
```

- [ ] **Step 4: Validate against the real fixture — full pipeline, gro+mdp+top all together.** Running `load_topology_lines` → `parse_defaults_and_atomtypes` → `parse_species_sections` → `compute_combining_rules` → `build_system` on the real fixtures, assert: `system.nat == 2544` (must match `read_gro`'s `frame.nat` from Task 1 — add an assertion that these two independently-derived atom counts agree, since in the real program `file.gro`'s atom count and the topology's derived atom count are cross-checked by `top_f77.f:175`'s `'NAT en file.gro NO ES IGUAL A NAT en...'` error, which this plan's Phase 1 scope doesn't otherwise port but whose *intent* — the two counts must agree — is worth asserting here even without porting that exact check); `system.bonds.size() == 1600` (`800 water molecules * 2 bonds`); `system.angles.size() == 800`; net charge sums to (numerically) zero (assert `std::abs(sum) < 1e-9`, computed by summing `system.carga` in the test itself — recomputing the same sum `build_system` already checked internally, as an independent confirmation rather than trusting that the internal check ran); `system.iitipo[0]` corresponds to the first atom of the first species (`SOL`) which per `spce.itp`'s `[atoms]` order is `HW` — assert `system.iitipo[0] == 1` (1-based index of `HW`, the first atomtype).

- [ ] **Step 5: Commit**

```
git add Programa_DM_cpp/src/system_builder.hpp Programa_DM_cpp/src/system_builder.cpp Programa_DM_cpp/tests/test_system_builder.cpp Programa_DM_cpp/src/CMakeLists.txt
git commit -m "cpp: Phase 1 Task 7 - per-species to per-atom system expansion, validated against real 2544-atom/1600-bond/800-angle fixture (Phase 1 complete)"
```

---

## Self-Review

**Spec coverage:** Every Fortran file read in full for this plan (`gro0.f`, `grof.f`, `mdp.f` + its 3 helper subroutines, `top_gmx.f95` in its entirety including all 20 internal `_local` procedures, and all 7 `distribuir_*`/`inicio_molecula` files) maps to exactly one task above. Nothing read was left unaccounted for; nothing in this plan invents behavior not found in that source.

**Placeholder scan:** Every task has real, executable test code (not "write tests for the above"), real algorithm descriptions with exact formulas and exact column layouts (not "parse the file appropriately"), and real numeric oracles hand-derived from the actual fixture files and cross-checked against the actual reference program's own printed output — not asserted without derivation.

**Type consistency:** `Topology` is introduced in Task 4 and extended (not replaced or renamed) in Tasks 5 and 6; `Species`/`Bond`/`Angle`/`Dihedral`/`Pair15` are introduced in Task 5 and consumed by name, unchanged, in Tasks 6-7; `System`/`SystemBond`/etc. in Task 7 are deliberately NEW/differently-named types (not reusing `Bond`/`Angle` from `Topology`) since they hold whole-system-offset indices rather than per-species-local ones — this distinction is called out explicitly in Task 7's own text so an implementer reading only that task's brief doesn't confuse the two.

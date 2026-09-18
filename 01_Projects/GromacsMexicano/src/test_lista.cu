// ============================================================================
// test_lista.cu — Phase 5a validation test: CUDA link-cell / neighbor-list kernel
// Validates lista_linkcell_cuda_stream() against an O(N^2) reference on a real
// water system (SPC/E) loaded from test_data/water_*.gro
//
// Checks:
//   (1) COVERAGE : every reference pair within cutoff is present in the GPU list
//   (2) PRECISION: every GPU pair is within cutoff (no false positives)
//   (3) TIMING   : kernel build time + throughput (pairs/s)
// ============================================================================
#include <cuda_runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <vector>
#include <string>
#include <fstream>
#include <sstream>
#include <iostream>
#include <algorithm>
#include <chrono>

extern "C" void lista_linkcell_cuda_stream(
    int nat, int maxnat, int maxlist,
    const double *rx, const double *ry, const double *rz,
    double boxx, double boxy, double boxz,
    double rlist,
    const int *inicio_mol,
    int *npares, int *nblist1, int *nblist2,
    cudaStream_t stream1);

// ---- Minimal GRO reader (cubic box) ----
struct SysData {
    std::vector<double> x, y, z;
    int nat;
    double box;
};

static SysData readGro(const std::string &path) {
    std::ifstream f(path);
    if (!f.is_open()) { fprintf(stderr, "ERROR: cannot open %s\n", path.c_str()); exit(1); }
    std::string line;
    std::getline(f, line);              // title
    std::getline(f, line);              // natoms
    int nat = std::atoi(line.c_str());
    SysData s; s.nat = nat;
    s.x.resize(nat); s.y.resize(nat); s.z.resize(nat);
    int k = 0;
    double bx = 0;
    std::string raw;
    while (std::getline(f, line)) {
        // token count of the trimmed line
        std::istringstream tmp(line);
        std::vector<std::string> toks;
        std::string token;
        while (tmp >> token) toks.push_back(token);
        if (toks.size() <= 4) {  // box line: exactly 3 reals (or 9 for non-cubic)
            std::istringstream bss(line);
            double x, y, z;
            if (bss >> x >> y >> z) { bx = x; continue; }
            continue; // blank / comment
        }
        if (k >= nat) continue;
        // atom line: coordinates at fixed positions 20.. onward
        std::istringstream iss(line.substr(20));
        double x, y, z;
        if (!(iss >> x >> y >> z)) continue;
        s.x[k] = x; s.y[k] = y; s.z[k] = z; k++;
    }
    if (k < nat) { fprintf(stderr, "ERROR: read %d/%d atoms (want %d)\n", k, nat, nat); exit(1); }
    if (bx <= 0) { fprintf(stderr, "ERROR: no box found\n"); exit(1); }
    s.box = bx;
    return s;
}

// ---- Reference: all pairs i<j with rij <= rlist (PBC minimum image) ----
// Returns list of (i,j) plus count. O(N^2).
static void refNeighborList(const SysData &s, double rlist,
                            std::vector<int> &v1, std::vector<int> &v2,
                            long long &count) {
    double rcut2 = rlist * rlist;
    double box = s.box;
    count = 0;
    for (int i = 0; i < s.nat; i++) {
        for (int j = i + 1; j < s.nat; j++) {
            double dx = s.x[i] - s.x[j];
            double dy = s.y[i] - s.y[j];
            double dz = s.z[i] - s.z[j];
            // minimum image
            dx -= round(dx / box) * box;
            dy -= round(dy / box) * box;
            dz -= round(dz / box) * box;
            double r2 = dx*dx + dy*dy + dz*dz;
            if (r2 <= rcut2) {
                v1.push_back(i);
                v2.push_back(j);
                count++;
            }
        }
    }
}

static void checkCuda(const char *what, cudaError_t e) {
    if (e != cudaSuccess) {
        fprintf(stderr, "CUDA ERROR %s: %s (%d)\n", what, cudaGetErrorString(e), (int)e);
        exit(1);
    }
}

int main(int argc, char **argv) {
    const char *grofile = argc > 1 ? argv[1] : "/root/phase4_cuda_pinned/test_data/water_1k.gro";
    double rlist = argc > 2 ? atof(argv[2]) : 1.0;
    // inicio_mol mode: "mol" = molecule starts (water: 3 atoms/mol) or "self" = each atom its own molecule
    std::string imode = argc > 3 ? argv[3] : "self";

    printf("\n======== Phase 5a: Neighbor-list kernel validation ========\n");
    printf("GRO file : %s\n", grofile);
    printf("Cutoff rlist : %.3f nm\n", rlist);

    SysData s = readGro(grofile);
    printf("Atoms : %d\n", s.nat);
    printf("Box   : %.3f nm (cubic)\n", s.box);

    // ---- Build inicio_mol ----
    std::vector<int> inicio_mol(s.nat);
    if (imode == "mol") {
        for (int i = 0; i < s.nat; i++) inicio_mol[i] = (i / 3) * 3; // SPC/E 3 atoms per molecule
    } else {
        for (int i = 0; i < s.nat; i++) inicio_mol[i] = i;          // each atom is its own molecule
    }

    // ---- Host reference ----
    std::vector<int> rv1, rv2;
    long long nref = 0;
    refNeighborList(s, rlist, rv1, rv2, nref);
    printf("\nHost reference pairs within cutoff : %lld\n", nref);

    // ---- GPU kernel ----
    int maxnat = s.nat;
    // reasonable estimate; grid uses ceil(box/(2*rlist)) per dim -> cells
    // Do the same math as the kernel so allocation is consistent with runtime convention.
    double celld = rlist * 2.0;
    int ncx = (int)ceil(s.box / celld), ncy = ncx, ncz = ncx;
    int ncells = ncx * ncy * ncz;
    // maxlist: upper bound pairs = nat*(nat-1)/2
    int maxlist = (int)(1LL * s.nat * (s.nat - 1) / 2) + 1;

    std::vector<int> nblist1(maxlist), nblist2(maxlist);
    int npares_gpu = 0;

    // warmup
    lista_linkcell_cuda_stream(s.nat, maxnat, maxlist,
        s.x.data(), s.y.data(), s.z.data(), s.box, s.box, s.box, rlist,
        inicio_mol.data(), &npares_gpu, nblist1.data(), nblist2.data(), 0);

    // timed run
    auto t0 = std::chrono::high_resolution_clock::now();
    const int nrep = 10;
    long long total_pairs = 0;
    for (int r = 0; r < nrep; r++) {
        npares_gpu = 0;
        lista_linkcell_cuda_stream(s.nat, maxnat, maxlist,
            s.x.data(), s.y.data(), s.z.data(), s.box, s.box, s.box, rlist,
            inicio_mol.data(), &npares_gpu, nblist1.data(), nblist2.data(), 0);
        total_pairs += npares_gpu;
    }
    auto t1 = std::chrono::high_resolution_clock::now();
    double dt = std::chrono::duration<double>(t1 - t0).count() / nrep;
    printf("\nGPU neighbor list (averaged over %d runs):\n", nrep);
    printf("  pairs generated  : %lld\n", total_pairs / nrep);
    printf("  build time       : %.3f ms\n", dt * 1e3);
    printf("  throughput       : %.2f Mpair/s\n", (total_pairs / nrep) / dt / 1e6);
    checkCuda("sync", cudaDeviceSynchronize());

    if (npares_gpu > maxlist) {
        printf("\n!! WARNING: npares=%d exceeds maxlist=%d (list truncated)\n", npares_gpu, maxlist);
    }

    // ---- CROSS-CHECK ----
    // Build set of GPU pairs keyed by (i*nat + j)
    std::vector<unsigned char> gpuf(s.nat * s.nat, 0);
    long long gpu_pairs = npares_gpu;
    int gpu_outside = 0;
    double maxr = 0.0;
    for (int k = 0; k < npares_gpu; k++) {
        int i = nblist1[k] - 1, j = nblist2[k] - 1;
        if (i < 0 || j < 0 || i >= s.nat || j >= s.nat) {
            fprintf(stderr, "!! index out of range in GPU pair %d: (%d,%d)\n", k, i + 1, j + 1);
            exit(1);
        }
        gpuf[(size_t)i * s.nat + j] = 1;
        gpuf[(size_t)j * s.nat + i] = 1;
        double dx = s.x[i] - s.x[j], dy = s.y[i] - s.y[j], dz = s.z[i] - s.z[j];
        dx -= round(dx / s.box) * s.box;
        dy -= round(dy / s.box) * s.box;
        dz -= round(dz / s.box) * s.box;
        double rr = sqrt(dx*dx + dy*dy + dz*dz);
        if (rr > maxr) maxr = rr;
        if (rr > rlist) gpu_outside++;
        // sanitize: kernel emits (i,j) with j > i normally; check unordered membership later
    }

    // coverage: every reference pair must be present in GPU list
    long long covered = 0;
    long long covered_same_mol = 0;
    long long ref_same_mol = 0;
    for (long long k = 0; k < (long long)rv1.size(); k++) {
        int i = rv1[k], j = rv2[k];
        bool sameMol = false;
        if (imode == "mol") {
            int mi = i / 3, mj = j / 3;
            if (mi == mj) sameMol = true;
        }
        if (sameMol) ref_same_mol++;
        if (gpuf[(size_t)i * s.nat + j]) {
            covered++;
            if (sameMol) covered_same_mol++;
        }
    }
    // precision
    double coverage = (nref ? 100.0 * covered / nref : 0.0);
    double precision = (gpu_pairs ? 100.0 * (gpu_pairs - gpu_outside) / gpu_pairs : 0.0);

    // Count UNIQUE unordered GPU pairs vs duplicates (kernel may double-count cells
    // when a grid dimension has only 2 cells and periodic neighbor cells coincide).
    long long uniqueButterfly = 0;
    for (int i = 0; i < s.nat; i++)
        for (int j = i + 1; j < s.nat; j++)
            if (gpuf[(size_t)i * s.nat + j]) uniqueButterfly++;
    long long dup = gpu_pairs - uniqueButterfly;

    printf("\n================= VALIDATION RESULTS =================\n");
    printf("Reference pairs (i<j, r<=rlist) : %lld\n", nref);
    printf("GPU pairs generated             : %lld\n", gpu_pairs);
    printf("Unique unordered GPU pairs      : %lld\n", uniqueButterfly);
    printf("Duplicate entries               : %lld\n", dup);
    printf("Coverage (ref∩gpu / ref)        : %.4f%%  (%lld/%lld)\n", coverage, covered, nref);
    printf("Precision (gpu within cutoff)   : %.4f%%\n", precision);
    printf("GPU pairs outside cutoff (FP)   : %d\n", gpu_outside);
    if (imode == "mol") {
        printf("  intra-molecule pairs  : ref=%lld covered=%lld\n", ref_same_mol, covered_same_mol);
    }
    printf("Max GPU pair distance           : %.5f nm  (cutoff %.3f)\n", maxr, rlist);

    // VERDICT
    int PASS = 1;
    if (fabs(coverage - 100.0) > 1e-9)    { printf("\n  -> COVERAGE FAIL: %.2f%% of pairs missing from GPU list\n", 100.0 - coverage); PASS = 0; }
    if (gpu_outside > 0)                  { printf("\n  -> PRECISION FAIL: %d false-positive pairs beyond cutoff\n", gpu_outside); PASS = 0; }
    if (maxr > rlist + 1e-6)              { printf("\n  -> PRECISION FAIL: max distance %.5f > cutoff\n", maxr); PASS = 0; }

    printf("\n================== VERDICT ============================\n");
    printf(PASS ? "  ==> PASSO  (lista kernel CORRECTO dentro del cutoff)\n"
                : "  ==> FALLO  (lista kernel NO cubre todos los contactos)\n");
    printf("========================================================\n");
    return PASS ? 0 : 2;
}
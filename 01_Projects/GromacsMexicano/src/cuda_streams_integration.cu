// ============================================================================
// cuda_streams_integration.cu
// Integración de 3 streams en el loop principal de simulación MD
// ============================================================================

#include <cuda_runtime.h>
#include <cstdio>
#include <chrono>

// Forward declarations
extern "C" {
    void cudaStreamsInit();
    void cudaStreamsDestroy();
    void cudaStreamsSynchronize();
    
    cudaStream_t cudaGetStreamList();
    cudaStream_t cudaGetStreamForces();
    cudaStream_t cudaGetStreamKwald();
    
    void lista_linkcell_cuda_stream(
        int nat, int maxnat, int maxlist,
        const double *rx, const double *ry, const double *rz,
        double boxx, double boxy, double boxz,
        double rlist,
        const int *inicio_mol,
        int *npares, int *nblist1, int *nblist2,
        cudaStream_t stream1);
    
    void fzas_lj_cuda_stream(
        int maxnat, int maxlist, int npares,
        const double *rx, const double *ry, const double *rz,
        const int *iitipo,
        double *fx, double *fy, double *fz,
        const double *eps, const double *sigma,
        const double *carga,
        double rcut, double boxx, double boxy, double boxz,
        double rkappa,
        const int *nblist1, const int *nblist2,
        double *ulj, double *ucoul,
        double *wxx, double *wxy, double *wxz,
        double *wyy, double *wyz, double *wzz,
        cudaStream_t stream2);
    
    void kwald_cuda_stream(
        int nat, int nk,
        int kmaxx, int kmaxy, int kmaxz,
        double boxx, double boxy, double boxz,
        const double *rx, const double *ry, const double *rz,
        const double *charge,
        double *fx, double *fy, double *fz,
        double *uk_total,
        double *wxx_total, double *wxy_total, double *wxz_total,
        double *wyy_total, double *wyz_total, double *wzz_total,
        cudaStream_t stream3);
}

// ============================================================================
// MD_STEP_DUAL_STREAMS
// Función que ejecuta un paso de MD usando 3 streams paralelos
// ============================================================================
extern "C"
void md_step_dual_streams(
    // Sistema parameters
    int natoms, int maxlist,
    double boxx, double boxy, double boxz,
    double rlist, double rcut,
    
    // Atom data (host)
    const double *rx, const double *ry, const double *rz,
    const int *iitipo, const int *inicio_mol,
    double *fx, double *fy, double *fz,
    const double *charge,
    
    // LJ parameters
    const double *sigma, const double *eps,
    
    // Kwald parameters (simplified)
    int nk, int kmaxx, int kmaxy, int kmaxz,
    
    // Outputs
    int *npares, int *nblist1, int *nblist2,
    double *ulj, double *ucoul, double *uk_kwald,
    double *wxx, double *wxy, double *wxz,
    double *wyy, double *wyz, double *wzz,
    
    // Timing info
    double *wall_time_ms)
{
    auto t_start = std::chrono::high_resolution_clock::now();
    
    // Get streams
    cudaStream_t stream1 = cudaGetStreamList();
    cudaStream_t stream2 = cudaGetStreamForces();
    cudaStream_t stream3 = cudaGetStreamKwald();
    
    fprintf(stderr, "\n[DEBUG MD_STEP] Starting dual-stream MD step\n");
    fprintf(stderr, "  natoms=%d, maxlist=%d\n", natoms, maxlist);
    fprintf(stderr, "  stream1=%p (list)\n", (void*)stream1);
    fprintf(stderr, "  stream2=%p (forces)\n", (void*)stream2);
    fprintf(stderr, "  stream3=%p (kwald)\n", (void*)stream3);
    
    // ========================================================================
    // PIPELINE: 3 streams run in parallel
    // ========================================================================
    
    // Stream 1: Build neighbor list
    fprintf(stderr, "  [Stream1] Launching lista_linkcell_cuda_stream...\n");
    lista_linkcell_cuda_stream(
        natoms, natoms, maxlist,
        rx, ry, rz,
        boxx, boxy, boxz,
        rlist,
        inicio_mol,
        npares, nblist1, nblist2,
        stream1);
    
    // Stream 2: Compute LJ forces (can overlap with list building)
    fprintf(stderr, "  [Stream2] Launching fzas_lj_cuda_stream...\n");
    fzas_lj_cuda_stream(
        natoms, maxlist, *npares,
        rx, ry, rz,
        iitipo,
        fx, fy, fz,
        eps, sigma,
        charge,
        rcut, boxx, boxy, boxz,
        0.0,  // rkappa
        nblist1, nblist2,
        ulj, ucoul,
        wxx, wxy, wxz,
        wyy, wyz, wzz,
        stream2);
    
    // Stream 3: Compute Kwald forces (independent)
    fprintf(stderr, "  [Stream3] Launching kwald_cuda_stream...\n");
    kwald_cuda_stream(
        natoms, nk,
        kmaxx, kmaxy, kmaxz,
        boxx, boxy, boxz,
        rx, ry, rz,
        charge,
        fx, fy, fz,
        uk_kwald,
        wxx, wxy, wxz,
        wyy, wyz, wzz,
        stream3);
    
    // ========================================================================
    // SYNCHRONIZE: Wait for all 3 streams to complete
    // ========================================================================
    fprintf(stderr, "  [Main] Synchronizing all streams...\n");
    cudaStreamsSynchronize();
    
    auto t_end = std::chrono::high_resolution_clock::now();
    auto duration_ms = std::chrono::duration<double, std::milli>(t_end - t_start);
    *wall_time_ms = duration_ms.count();
    
    fprintf(stderr, "  [DEBUG] MD step completed in %.3f ms\n", *wall_time_ms);
}

// ============================================================================
// BENCHMARK_DUAL_STREAMS
// Runs 100 iterations and measures performance
// ============================================================================
extern "C"
void benchmark_dual_streams(
    int natoms, int maxlist,
    double boxx, double boxy, double boxz,
    double rlist, double rcut,
    int niter,
    double *times_ms)
{
    fprintf(stderr, "\n[BENCHMARK] Starting %d iterations\n", niter);
    
    // Initialize streams
    cudaStreamsInit();
    
    // Mock data allocation
    double *rx = new double[natoms];
    double *ry = new double[natoms];
    double *rz = new double[natoms];
    double *fx = new double[natoms];
    double *fy = new double[natoms];
    double *fz = new double[natoms];
    int *iitipo = new int[natoms];
    int *inicio_mol = new int[natoms];
    double *charge = new double[natoms];
    double *sigma = new double[100];
    double *eps = new double[100];
    int *nblist1 = new int[maxlist];
    int *nblist2 = new int[maxlist];
    
    int npares = 0;
    double ulj = 0.0, ucoul = 0.0, uk_kwald = 0.0;
    double wxx = 0.0, wxy = 0.0, wxz = 0.0;
    double wyy = 0.0, wyz = 0.0, wzz = 0.0;
    double wall_time_ms = 0.0;
    
    // Initialize mock data
    for (int i = 0; i < natoms; i++) {
        rx[i] = (double)rand() / RAND_MAX * boxx;
        ry[i] = (double)rand() / RAND_MAX * boxy;
        rz[i] = (double)rand() / RAND_MAX * boxz;
        fx[i] = fy[i] = fz[i] = 0.0;
        iitipo[i] = 1;
        inicio_mol[i] = 1;
        charge[i] = 0.0;
    }
    
    // Run iterations
    for (int iter = 0; iter < niter; iter++) {
        md_step_dual_streams(
            natoms, maxlist,
            boxx, boxy, boxz,
            rlist, rcut,
            rx, ry, rz,
            iitipo, inicio_mol,
            fx, fy, fz,
            charge,
            sigma, eps,
            10, 5, 5, 5,  // nk, kmaxx, kmaxy, kmaxz
            &npares, nblist1, nblist2,
            &ulj, &ucoul, &uk_kwald,
            &wxx, &wxy, &wxz,
            &wyy, &wyz, &wzz,
            &wall_time_ms);
        
        times_ms[iter] = wall_time_ms;
        fprintf(stderr, "  Iteration %d: %.3f ms\n", iter+1, wall_time_ms);
    }
    
    // Cleanup
    delete[] rx; delete[] ry; delete[] rz;
    delete[] fx; delete[] fy; delete[] fz;
    delete[] iitipo; delete[] inicio_mol;
    delete[] charge; delete[] sigma; delete[] eps;
    delete[] nblist1; delete[] nblist2;
    
    cudaStreamsDestroy();
    fprintf(stderr, "[BENCHMARK] Completed\n");
}

// ============================================================================
// fzas_lj_cuda_streams.cu
// Versión mejorada de fuerzas LJ con CUDA Streams
// 
// Cambios:
//   - kernel_fzas_lj_stream() acepta cudaStream_t
//   - Todos los atomicAdd mantienen thread-safety
//   - Lanzamiento asincrónico en stream2
// ============================================================================

#include <cuda_runtime.h>
#include <cstdio>
#include <cmath>

__device__ inline double nint_gpu(double x) {
    return rint(x);
}

// ============================================================================
// KERNEL: PAIRWISE LENNARD-JONES FORCES (con soporte para stream)
// ============================================================================
__global__ void kernel_fzas_lj_stream(
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
    double *wyy, double *wyz, double *wzz)
{
    int np = blockIdx.x * blockDim.x + threadIdx.x;

    if(np >= npares) return;

    int i = nblist1[np] - 1;
    int j = nblist2[np] - 1;

    if (i < 0 || i >= maxnat || j < 0 || j >= maxnat) return;

    int ii = iitipo[i] - 1;
    int jj = iitipo[j] - 1;

    double dx = rx[i] - rx[j];
    double dy = ry[i] - ry[j];
    double dz = rz[i] - rz[j];

    dx -= nint_gpu(dx/boxx)*boxx;
    dy -= nint_gpu(dy/boxy)*boxy;
    dz -= nint_gpu(dz/boxz)*boxz;

    double rij2 = dx*dx + dy*dy + dz*dz;
    double rij  = sqrt(rij2);

    if(rij <= rcut) {

        int ind = ii + jj*10;

        double sigmaij = sigma[ind];
        double epsij   = eps[ind];

        // Lennard-Jones truncated (ST)
        double s6 = pow(sigmaij/rij, 6.0);
        double u_lj = 4.0*epsij*s6*(s6 - 1.0);
        double du_lj = -24.0*epsij*s6*(2.0*s6 - 1.0)/rij;

        // Add LJ contribution to energy (atomicAdd es thread-safe)
        if (np == 0) {  // Solo la primera iteración acumula (ejemplo)
            atomicAdd(ulj, u_lj);
        }

        double fij_x = du_lj * dx / rij;
        double fij_y = du_lj * dy / rij;
        double fij_z = du_lj * dz / rij;

        // Actualizar fuerzas (thread-safe con atomicAdd)
        atomicAdd(&fx[i], fij_x);
        atomicAdd(&fy[i], fij_y);
        atomicAdd(&fz[i], fij_z);

        atomicAdd(&fx[j], -fij_x);
        atomicAdd(&fy[j], -fij_y);
        atomicAdd(&fz[j], -fij_z);

        // Virial tensor (thread-safe)
        atomicAdd(wxx, fij_x * dx);
        atomicAdd(wxy, fij_x * dy);
        atomicAdd(wxz, fij_x * dz);
        atomicAdd(wyy, fij_y * dy);
        atomicAdd(wyz, fij_y * dz);
        atomicAdd(wzz, fij_z * dz);
    }
}

// ============================================================================
// HOST FUNCTION: WRAPPER CON STREAM
// ============================================================================
extern "C"
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
    cudaStream_t stream2)
{
    if (npares <= 0) return;

    // GPU device pointers
    static double *d_rx = nullptr, *d_ry = nullptr, *d_rz = nullptr;
    static int *d_iitipo = nullptr;
    static double *d_fx = nullptr, *d_fy = nullptr, *d_fz = nullptr;
    static double *d_eps = nullptr, *d_sigma = nullptr;
    static double *d_carga = nullptr;
    static int *d_nblist1 = nullptr, *d_nblist2 = nullptr;
    static double *d_ulj = nullptr, *d_ucoul = nullptr;
    static double *d_wxx = nullptr, *d_wxy = nullptr, *d_wxz = nullptr;
    static double *d_wyy = nullptr, *d_wyz = nullptr, *d_wzz = nullptr;

    // Allocate if first call
    if (d_rx == nullptr) {
        cudaMalloc(&d_rx, maxnat * sizeof(double));
        cudaMalloc(&d_ry, maxnat * sizeof(double));
        cudaMalloc(&d_rz, maxnat * sizeof(double));
        cudaMalloc(&d_fx, maxnat * sizeof(double));
        cudaMalloc(&d_fy, maxnat * sizeof(double));
        cudaMalloc(&d_fz, maxnat * sizeof(double));
        cudaMalloc(&d_iitipo, maxnat * sizeof(int));
        cudaMalloc(&d_carga, maxnat * sizeof(double));
        cudaMalloc(&d_sigma, 100 * sizeof(double));
        cudaMalloc(&d_eps, 100 * sizeof(double));
        cudaMalloc(&d_nblist1, maxlist * sizeof(int));
        cudaMalloc(&d_nblist2, maxlist * sizeof(int));
        cudaMalloc(&d_ulj, sizeof(double));
        cudaMalloc(&d_ucoul, sizeof(double));
        cudaMalloc(&d_wxx, sizeof(double));
        cudaMalloc(&d_wxy, sizeof(double));
        cudaMalloc(&d_wxz, sizeof(double));
        cudaMalloc(&d_wyy, sizeof(double));
        cudaMalloc(&d_wyz, sizeof(double));
        cudaMalloc(&d_wzz, sizeof(double));
    }

    // Reset output arrays EN STREAM2
    cudaMemsetAsync(d_fx, 0, maxnat * sizeof(double), stream2);
    cudaMemsetAsync(d_fy, 0, maxnat * sizeof(double), stream2);
    cudaMemsetAsync(d_fz, 0, maxnat * sizeof(double), stream2);
    cudaMemsetAsync(d_ulj, 0, sizeof(double), stream2);
    cudaMemsetAsync(d_ucoul, 0, sizeof(double), stream2);
    cudaMemsetAsync(d_wxx, 0, sizeof(double), stream2);
    cudaMemsetAsync(d_wxy, 0, sizeof(double), stream2);
    cudaMemsetAsync(d_wxz, 0, sizeof(double), stream2);
    cudaMemsetAsync(d_wyy, 0, sizeof(double), stream2);
    cudaMemsetAsync(d_wyz, 0, sizeof(double), stream2);
    cudaMemsetAsync(d_wzz, 0, sizeof(double), stream2);

    // Copy inputs to GPU EN STREAM2
    cudaMemcpyAsync(d_rx, rx, maxnat * sizeof(double), cudaMemcpyHostToDevice, stream2);
    cudaMemcpyAsync(d_ry, ry, maxnat * sizeof(double), cudaMemcpyHostToDevice, stream2);
    cudaMemcpyAsync(d_rz, rz, maxnat * sizeof(double), cudaMemcpyHostToDevice, stream2);
    cudaMemcpyAsync(d_iitipo, iitipo, maxnat * sizeof(int), cudaMemcpyHostToDevice, stream2);
    cudaMemcpyAsync(d_carga, carga, maxnat * sizeof(double), cudaMemcpyHostToDevice, stream2);
    cudaMemcpyAsync(d_sigma, sigma, 100 * sizeof(double), cudaMemcpyHostToDevice, stream2);
    cudaMemcpyAsync(d_eps, eps, 100 * sizeof(double), cudaMemcpyHostToDevice, stream2);
    cudaMemcpyAsync(d_nblist1, nblist1, npares * sizeof(int), cudaMemcpyHostToDevice, stream2);
    cudaMemcpyAsync(d_nblist2, nblist2, npares * sizeof(int), cudaMemcpyHostToDevice, stream2);

    // Compute kernel launch parameters
    int nthreads = 256;
    int nblocks = (npares + nthreads - 1) / nthreads;

    // Launch kernel EN STREAM2
    kernel_fzas_lj_stream<<<nblocks, nthreads, 0, stream2>>>(
        maxnat, maxlist, npares,
        d_rx, d_ry, d_rz,
        d_iitipo,
        d_fx, d_fy, d_fz,
        d_eps, d_sigma,
        d_carga,
        rcut, boxx, boxy, boxz,
        rkappa,
        d_nblist1, d_nblist2,
        d_ulj, d_ucoul,
        d_wxx, d_wxy, d_wxz,
        d_wyy, d_wyz, d_wzz);

    // Copy results back EN STREAM2
    cudaMemcpyAsync(fx, d_fx, maxnat * sizeof(double), cudaMemcpyDeviceToHost, stream2);
    cudaMemcpyAsync(fy, d_fy, maxnat * sizeof(double), cudaMemcpyDeviceToHost, stream2);
    cudaMemcpyAsync(fz, d_fz, maxnat * sizeof(double), cudaMemcpyDeviceToHost, stream2);
    cudaMemcpyAsync(ulj, d_ulj, sizeof(double), cudaMemcpyDeviceToHost, stream2);
    cudaMemcpyAsync(ucoul, d_ucoul, sizeof(double), cudaMemcpyDeviceToHost, stream2);
    cudaMemcpyAsync(wxx, d_wxx, sizeof(double), cudaMemcpyDeviceToHost, stream2);
    cudaMemcpyAsync(wxy, d_wxy, sizeof(double), cudaMemcpyDeviceToHost, stream2);
    cudaMemcpyAsync(wxz, d_wxz, sizeof(double), cudaMemcpyDeviceToHost, stream2);
    cudaMemcpyAsync(wyy, d_wyy, sizeof(double), cudaMemcpyDeviceToHost, stream2);
    cudaMemcpyAsync(wyz, d_wyz, sizeof(double), cudaMemcpyDeviceToHost, stream2);
    cudaMemcpyAsync(wzz, d_wzz, sizeof(double), cudaMemcpyDeviceToHost, stream2);

    // Nota: No sincronizamos aquí - el caller debe llamar a cudaStreamsSynchronize()
}

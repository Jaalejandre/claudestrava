// ============================================================================
// kwald_cuda_streams.cu
// Versión mejorada de Kwald con CUDA Streams
// 
// Cambios:
//   - 4 kernels ahora aceptan cudaStream_t implícitamente (lanzados en stream3)
//   - Funciones wrapper: kwald_cuda_stream()
//   - No hay atomics aquí, pero hay sincronización de memoria
// ============================================================================

#include <cstdio>
#include <cstdlib>
#include <cmath>
#include <vector>
#include <cuda_runtime.h>

#define CUDA_CHECK(call) do {                                      \
    cudaError_t err__ = (call);                                    \
    if (err__ != cudaSuccess) {                                    \
        fprintf(stderr,"CUDA error %s:%d: %s\n",                   \
                __FILE__,__LINE__,cudaGetErrorString(err__));      \
        return;                                                    \
    }                                                             \
} while(0)

static int initialized = 0;
static int g_nat = 0, g_nk = 0;
static double g_ewald_alpha = 0.0;
static int g_kmaxx = 0, g_kmaxy = 0, g_kmaxz = 0;
static double g_boxx = 0.0, g_boxy = 0.0, g_boxz = 0.0;

static double *d_rx = nullptr, *d_ry = nullptr, *d_rz = nullptr;
static double *d_charge = nullptr;
static double *d_fx = nullptr, *d_fy = nullptr, *d_fz = nullptr;

static double *d_kx = nullptr, *d_ky = nullptr, *d_kz = nullptr;
static double *d_kvec = nullptr, *d_factor = nullptr;
static double *d_sre = nullptr, *d_sim = nullptr;
static double *d_uk = nullptr;
static double *d_wxx = nullptr, *d_wxy = nullptr, *d_wxz = nullptr;
static double *d_wyy = nullptr, *d_wyz = nullptr, *d_wzz = nullptr;

static double *d_coski = nullptr;
static double *d_sinki = nullptr;

static std::vector<double> h_uk;
static std::vector<double> h_wxx, h_wxy, h_wxz, h_wyy, h_wyz, h_wzz;

// ============================================================================
// KERNEL 1: Build trig tables
// ============================================================================
__global__
void build_trig_table_kernel(
    int nat, int nk,
    const double *rx, const double *ry, const double *rz,
    const double *kx, const double *ky, const double *kz,
    double *coski, double *sinki)
{
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    int total = nat * nk;
    
    if (tid >= total) return;
    
    int ik = tid / nat;
    int i = tid % nat;
    
    double arg = kx[ik] * rx[i] + ky[ik] * ry[i] + kz[ik] * rz[i];
    
    coski[ik * nat + i] = cos(arg);
    sinki[ik * nat + i] = sin(arg);
}

// ============================================================================
// KERNEL 2: Build structure factors
// ============================================================================
__global__
void build_structure_factors_from_trig_kernel(
    int nat, int nk,
    const double *coski, const double *sinki,
    const double *charge,
    double *sre, double *sim)
{
    int ik = blockIdx.x * blockDim.x + threadIdx.x;
    if (ik >= nk) return;
    
    double re = 0.0, im = 0.0;
    for (int i = 0; i < nat; i++) {
        double cos_val = coski[ik * nat + i];
        double sin_val = sinki[ik * nat + i];
        double q = charge[i];
        
        re += q * cos_val;
        im += q * sin_val;
    }
    
    sre[ik] = re;
    sim[ik] = im;
}

// ============================================================================
// KERNEL 3: Energy and virial from k-space
// ============================================================================
__global__
void energy_virial_kwald_kernel(
    int nk,
    const double *kvec, const double *factor,
    const double *sre, const double *sim,
    double *uk, double *wxx, double *wyy, double *wzz)
{
    int ik = blockIdx.x * blockDim.x + threadIdx.x;
    if (ik >= nk) return;
    
    double s2 = sre[ik] * sre[ik] + sim[ik] * sim[ik];
    double energy_contrib = factor[ik] * s2;
    
    // Store energy (sum will be done on host)
    uk[ik] = energy_contrib;
    
    // Virial: W = -2 * factor * S^2 (for Ewald)
    double w_contrib = -2.0 * factor[ik] * s2;
    
    wxx[ik] = w_contrib;
    wyy[ik] = w_contrib;
    wzz[ik] = w_contrib;
}

// ============================================================================
// KERNEL 4: Force from k-space
// ============================================================================
__global__
void force_kwald_from_trig_kernel(
    int nat, int nk,
    const double *kx, const double *ky, const double *kz,
    const double *coski, const double *sinki,
    const double *charge,
    const double *sre, const double *sim,
    const double *factor,
    double *fx, double *fy, double *fz)
{
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    int total = nat * nk;
    
    if (tid >= total) return;
    
    int ik = tid / nat;
    int i = tid % nat;
    
    double kx_val = kx[ik];
    double ky_val = ky[ik];
    double kz_val = kz[ik];
    
    double cos_val = coski[ik * nat + i];
    double sin_val = sinki[ik * nat + i];
    
    double q = charge[i];
    double fact = 2.0 * factor[ik];
    
    // Force components
    double fac_im = fact * (sre[ik] * sin_val - sim[ik] * cos_val);
    
    double fx_contrib = fac_im * q * kx_val;
    double fy_contrib = fac_im * q * ky_val;
    double fz_contrib = fac_im * q * kz_val;
    
    // Accumulate (thread-safe with atomic)
    atomicAdd(&fx[i], fx_contrib);
    atomicAdd(&fy[i], fy_contrib);
    atomicAdd(&fz[i], fz_contrib);
}

// ============================================================================
// WRAPPER FUNCTION CON STREAM
// ============================================================================
extern "C"
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
    cudaStream_t stream3)
{
    if (nat <= 0 || nk <= 0) return;
    
    // Allocate device memory if first call
    if (d_rx == nullptr) {
        cudaMalloc(&d_rx, nat * sizeof(double));
        cudaMalloc(&d_ry, nat * sizeof(double));
        cudaMalloc(&d_rz, nat * sizeof(double));
        cudaMalloc(&d_charge, nat * sizeof(double));
        cudaMalloc(&d_fx, nat * sizeof(double));
        cudaMalloc(&d_fy, nat * sizeof(double));
        cudaMalloc(&d_fz, nat * sizeof(double));
        
        cudaMalloc(&d_kx, nk * sizeof(double));
        cudaMalloc(&d_ky, nk * sizeof(double));
        cudaMalloc(&d_kz, nk * sizeof(double));
        cudaMalloc(&d_kvec, nk * sizeof(double));
        cudaMalloc(&d_factor, nk * sizeof(double));
        cudaMalloc(&d_sre, nk * sizeof(double));
        cudaMalloc(&d_sim, nk * sizeof(double));
        cudaMalloc(&d_uk, nk * sizeof(double));
        
        cudaMalloc(&d_wxx, nk * sizeof(double));
        cudaMalloc(&d_wxy, nk * sizeof(double));
        cudaMalloc(&d_wxz, nk * sizeof(double));
        cudaMalloc(&d_wyy, nk * sizeof(double));
        cudaMalloc(&d_wyz, nk * sizeof(double));
        cudaMalloc(&d_wzz, nk * sizeof(double));
        
        cudaMalloc(&d_coski, nat * nk * sizeof(double));
        cudaMalloc(&d_sinki, nat * nk * sizeof(double));
        
        h_uk.resize(nk);
        h_wxx.resize(nk);
        h_wxy.resize(nk);
        h_wxz.resize(nk);
        h_wyy.resize(nk);
        h_wyz.resize(nk);
        h_wzz.resize(nk);

 // Generate k-vectors and factor array (setup2)
 std::vector<double> h_kx(nk, 0.0), h_ky(nk, 0.0), h_kz(nk, 0.0);
 std::vector<double> h_kvec(nk, 0.0), h_factor(nk, 0.0);

 const double pi = 4.0 * atan(1.0);
 const double twopi = 2.0 * pi;

 int kmax = kmaxx;
 if (kmaxy > kmax) kmax = kmaxy;
 if (kmaxz > kmax) kmax = kmaxz;
 int ksqmax = kmax * kmax;

 double alfa_val = 3.49;
        double B = 1.0 / (4.0 * alfa_val * alfa_val);
 double vol = boxx * boxy * boxz;

 double twopix = twopi / boxx;
 double twopiy = twopi / boxy;
 double twopiz = twopi / boxz;

 int idx = 0;
 for (int kx = 0; kx <= kmaxx; kx++) {
  double rkx = twopix * (double)kx;
  for (int ky = -kmaxy; ky <= kmaxy; ky++) {
   double rky = twopiy * (double)ky;
   for (int kz = -kmaxz; kz <= kmaxz; kz++) {
    double rkz = twopiz * (double)kz;
    int ksq = kx*kx + ky*ky + kz*kz;
    if (ksq <= ksqmax && ksq != 0) {
     if (idx >= nk) {
      fprintf(stderr, "ERROR: kvec overflow idx=%d nk=%d\n", idx, nk);
      break;
     }
     double rksq = rkx*rkx + rky*rky + rkz*rkz;
     h_kx[idx] = rkx;
     h_ky[idx] = rky;
     h_kz[idx] = rkz;
     h_kvec[idx] = twopi * exp(-B * rksq) / rksq / vol;
     double factor_mult = (kx == 0) ? 1.0 : 2.0;
                    h_kvec[idx] = twopi * exp(-B * rksq) / rksq / vol;
                    h_factor[idx] = factor_mult * h_kvec[idx];
     idx++;
    }
   }
  }
 }

 // Copy k-vectors to GPU
 cudaMemcpy(d_kx, h_kx.data(), nk * sizeof(double), cudaMemcpyHostToDevice);
 cudaMemcpy(d_ky, h_ky.data(), nk * sizeof(double), cudaMemcpyHostToDevice);
 cudaMemcpy(d_kz, h_kz.data(), nk * sizeof(double), cudaMemcpyHostToDevice);
 cudaMemcpy(d_kvec, h_kvec.data(), nk * sizeof(double), cudaMemcpyHostToDevice);
 cudaMemcpy(d_factor, h_factor.data(), nk * sizeof(double), cudaMemcpyHostToDevice);

        
        initialized = 1;
    }
    
    // Copy inputs to GPU EN STREAM3
    cudaMemcpyAsync(d_rx, rx, nat * sizeof(double), cudaMemcpyHostToDevice, stream3);
    cudaMemcpyAsync(d_ry, ry, nat * sizeof(double), cudaMemcpyHostToDevice, stream3);
    cudaMemcpyAsync(d_rz, rz, nat * sizeof(double), cudaMemcpyHostToDevice, stream3);
    cudaMemcpyAsync(d_charge, charge, nat * sizeof(double), cudaMemcpyHostToDevice, stream3);
    
    // Reset output arrays
    cudaMemsetAsync(d_fx, 0, nat * sizeof(double), stream3);
    cudaMemsetAsync(d_fy, 0, nat * sizeof(double), stream3);
    cudaMemsetAsync(d_fz, 0, nat * sizeof(double), stream3);
    cudaMemsetAsync(d_uk, 0, nk * sizeof(double), stream3);
    cudaMemsetAsync(d_wxx, 0, nk * sizeof(double), stream3);
    cudaMemsetAsync(d_wyy, 0, nk * sizeof(double), stream3);
    cudaMemsetAsync(d_wzz, 0, nk * sizeof(double), stream3);
    
    // Kernel 1: Build trig tables EN STREAM3
    int nthreads1 = 256;
    int nblocks1 = (nat * nk + nthreads1 - 1) / nthreads1;
    build_trig_table_kernel<<<nblocks1, nthreads1, 0, stream3>>>(
        nat, nk, d_rx, d_ry, d_rz, d_kx, d_ky, d_kz, d_coski, d_sinki);
    
    // Kernel 2: Build structure factors EN STREAM3
    int nthreads2 = 256;
    int nblocks2 = (nk + nthreads2 - 1) / nthreads2;
    build_structure_factors_from_trig_kernel<<<nblocks2, nthreads2, 0, stream3>>>(
        nat, nk, d_coski, d_sinki, d_charge, d_sre, d_sim);
    
    // Kernel 3: Energy and virial EN STREAM3
    energy_virial_kwald_kernel<<<nblocks2, nthreads2, 0, stream3>>>(
        nk, d_kvec, d_factor, d_sre, d_sim, d_uk, d_wxx, d_wyy, d_wzz);
    
    // Kernel 4: Forces EN STREAM3
    force_kwald_from_trig_kernel<<<nblocks1, nthreads1, 0, stream3>>>(
        nat, nk, d_kx, d_ky, d_kz, d_coski, d_sinki, d_charge, 
        d_sre, d_sim, d_factor, d_fx, d_fy, d_fz);
    
    // Copy results back EN STREAM3
    cudaMemcpyAsync(fx, d_fx, nat * sizeof(double), cudaMemcpyDeviceToHost, stream3);
    cudaMemcpyAsync(fy, d_fy, nat * sizeof(double), cudaMemcpyDeviceToHost, stream3);
    cudaMemcpyAsync(fz, d_fz, nat * sizeof(double), cudaMemcpyDeviceToHost, stream3);
    cudaMemcpyAsync(h_uk.data(), d_uk, nk * sizeof(double), cudaMemcpyDeviceToHost, stream3);
    cudaMemcpyAsync(h_wxx.data(), d_wxx, nk * sizeof(double), cudaMemcpyDeviceToHost, stream3);
    cudaMemcpyAsync(h_wyy.data(), d_wyy, nk * sizeof(double), cudaMemcpyDeviceToHost, stream3);
    cudaMemcpyAsync(h_wzz.data(), d_wzz, nk * sizeof(double), cudaMemcpyDeviceToHost, stream3);
}

// ============================================================================
// Cleanup function
// ============================================================================
extern "C"
void kwald_free_cuda_stream()
{
    if (d_rx) cudaFree(d_rx);
    if (d_ry) cudaFree(d_ry);
    if (d_rz) cudaFree(d_rz);
    if (d_charge) cudaFree(d_charge);
    if (d_fx) cudaFree(d_fx);
    if (d_fy) cudaFree(d_fy);
    if (d_fz) cudaFree(d_fz);
    if (d_kx) cudaFree(d_kx);
    if (d_ky) cudaFree(d_ky);
    if (d_kz) cudaFree(d_kz);
    if (d_kvec) cudaFree(d_kvec);
    if (d_factor) cudaFree(d_factor);
    if (d_sre) cudaFree(d_sre);
    if (d_sim) cudaFree(d_sim);
    if (d_uk) cudaFree(d_uk);
    if (d_wxx) cudaFree(d_wxx);
    if (d_wxy) cudaFree(d_wxy);
    if (d_wxz) cudaFree(d_wxz);
    if (d_wyy) cudaFree(d_wyy);
    if (d_wyz) cudaFree(d_wyz);
    if (d_wzz) cudaFree(d_wzz);
    if (d_coski) cudaFree(d_coski);
    if (d_sinki) cudaFree(d_sinki);
    
    initialized = 0;
}

extern "C"
void kwald_sync_and_reduce(
    int nk,
    double *uk_total,
    double *wxx_total, double *wyy_total, double *wzz_total,
    cudaStream_t stream3)
{
    cudaStreamSynchronize(stream3);
    
    if (uk_total) {
        double sum_uk = 0.0;
        for (int i = 0; i < nk; i++) sum_uk += h_uk[i];
        *uk_total = sum_uk;
    }
    if (wxx_total) {
        double sum_wxx = 0.0, sum_wyy = 0.0, sum_wzz = 0.0;
        for (int i = 0; i < nk; i++) {
            sum_wxx += h_wxx[i];
            sum_wyy += h_wyy[i];
            sum_wzz += h_wzz[i];
        }
        *wxx_total = sum_wxx;
        *wyy_total = sum_wyy;
        *wzz_total = sum_wzz;
    }
}

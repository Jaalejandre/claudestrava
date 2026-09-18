// ============================================================================
// lista_linkcell_cuda_streams.cu
// Versión mejorada con soporte para CUDA Streams
// 
// Cambios respecto al original:
//   - asignar_celdas_stream() acepta cudaStream_t
//   - construir_pares_stream() acepta cudaStream_t
//   - lista_linkcell_cuda_stream() lanza kernels en stream1
// ============================================================================

#include <cuda_runtime.h>
#include <stdio.h>
#include <math.h>

// ============================================================================
// UTILITY FUNCTIONS
// ============================================================================

__device__ double fmodulo_gpu(double a, double p) {
    double result = fmod(a, p);
    return (result < 0.0) ? result + p : result;
}

__device__ int nint_gpu(double x) {
    return (int)round(x);
}

// ============================================================================
// KERNEL 1: ASIGNAR ÁTOMOS A CELDAS (con stream)
// ============================================================================
__global__ void asignar_celdas(
    int nat, int maxnat,
    const double *rx, const double *ry, const double *rz,
    double cellx, double celly, double cellz,
    int ncx, int ncy, int ncz,
    int *cell_count, int *cell_atoms)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= nat) return;

    int icx = (int)fmodulo_gpu(rx[i] / cellx, (double)ncx);
    int icy = (int)fmodulo_gpu(ry[i] / celly, (double)ncy);
    int icz = (int)fmodulo_gpu(rz[i] / cellz, (double)ncz);

    int icell = icx + icy * ncx + icz * ncx * ncy;
    int slot = atomicAdd(&cell_count[icell], 1);

    if (slot < maxnat) {
        cell_atoms[(size_t)icell * maxnat + slot] = i;
    }
}

// ============================================================================
// KERNEL 2: CONSTRUIR LISTA DE PARES (con stream)
// ============================================================================
__global__ void construir_pares(
    int nat, int maxnat, int maxlist,
    const double *rx, const double *ry, const double *rz,
    const int *inicio_mol,
    double boxx, double boxy, double boxz,
    double rlist2,
    int ncx, int ncy, int ncz,
    int *cell_count, int *cell_atoms,
    int *npares, int *nblist1, int *nblist2)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= nat) return;

    int icx = (int)fmodulo_gpu(rx[i] / (boxx / ncx), (double)ncx);
    int icy = (int)fmodulo_gpu(ry[i] / (boxy / ncy), (double)ncy);
    int icz = (int)fmodulo_gpu(rz[i] / (boxz / ncz), (double)ncz);

    int imol_start = inicio_mol[i];

    for (int dix = -1; dix <= 1; dix++) {
        for (int diy = -1; diy <= 1; diy++) {
            for (int diz = -1; diz <= 1; diz++) {
                int jcx = (icx + dix + ncx) % ncx;
                int jcy = (icy + diy + ncy) % ncy;
                int jcz = (icz + diz + ncz) % ncz;
                int jcell = jcx + jcy * ncx + jcz * ncx * ncy;

                int nj = cell_count[jcell];
                for (int kk = 0; kk < nj; kk++) {
                    int j = cell_atoms[(size_t)jcell * maxnat + kk];
                    if (j <= i) continue;
                    if (j < imol_start) continue;

                    double dx = rx[i] - rx[j];
                    double dy = ry[i] - ry[j];
                    double dz = rz[i] - rz[j];

                    dx -= nint_gpu(dx / boxx) * boxx;
                    dy -= nint_gpu(dy / boxy) * boxy;
                    dz -= nint_gpu(dz / boxz) * boxz;

                    double rij2 = dx*dx + dy*dy + dz*dz;
                    if (rij2 <= rlist2) {
                        int idx = atomicAdd(npares, 1);
                        if (idx < maxlist) {
                            nblist1[idx] = i + 1;
                            nblist2[idx] = j + 1;
                        }
                    }
                }
            }
        }
    }
}

// ============================================================================
// HOST FUNCTION: WRAPPER CON STREAM
// ============================================================================
extern "C"
void lista_linkcell_cuda_stream(
    int nat, int maxnat, int maxlist,
    const double *rx, const double *ry, const double *rz,
    double boxx, double boxy, double boxz,
    double rlist,
    const int *inicio_mol,
    int *npares, int *nblist1, int *nblist2,
    cudaStream_t stream1)
{
    cudaError_t err;
    
    // Calcula grid y block size
    int nthreads = 256;
    int nblocks = (nat + nthreads - 1) / nthreads;
    
    // Calcula dimensiones de celdas
    int ncx = (int)ceil(boxx / (rlist * 2.0));
    int ncy = (int)ceil(boxy / (rlist * 2.0));
    int ncz = (int)ceil(boxz / (rlist * 2.0));
    
    // GPU memory (persistent between calls)
    static int *d_cell_count = nullptr;
    static int *d_cell_atoms = nullptr;
    static int *d_npares = nullptr;
    
    if (d_cell_count == nullptr) {
        cudaMalloc(&d_cell_count, ncx * ncy * ncz * sizeof(int));
        cudaMalloc(&d_cell_atoms, ncx * ncy * ncz * maxnat * sizeof(int));
        cudaMalloc(&d_npares, sizeof(int));
    }
    
    // Copy inputs to GPU
    double *d_rx, *d_ry, *d_rz;
    int *d_inicio_mol, *d_nblist1, *d_nblist2;
    
    cudaMalloc(&d_rx, nat * sizeof(double));
    cudaMalloc(&d_ry, nat * sizeof(double));
    cudaMalloc(&d_rz, nat * sizeof(double));
    cudaMalloc(&d_inicio_mol, nat * sizeof(int));
    cudaMalloc(&d_nblist1, maxlist * sizeof(int));
    cudaMalloc(&d_nblist2, maxlist * sizeof(int));
    
    cudaMemcpyAsync(d_rx, rx, nat * sizeof(double), cudaMemcpyHostToDevice, stream1);
    cudaMemcpyAsync(d_ry, ry, nat * sizeof(double), cudaMemcpyHostToDevice, stream1);
    cudaMemcpyAsync(d_rz, rz, nat * sizeof(double), cudaMemcpyHostToDevice, stream1);
    cudaMemcpyAsync(d_inicio_mol, inicio_mol, nat * sizeof(int), cudaMemcpyHostToDevice, stream1);
    
    // Reset contadores
    cudaMemsetAsync(d_cell_count, 0, ncx * ncy * ncz * sizeof(int), stream1);
    cudaMemsetAsync(d_npares, 0, sizeof(int), stream1);
    
    // Kernel 1: asignar átomos a celdas EN STREAM1
    asignar_celdas<<<nblocks, nthreads, 0, stream1>>>(
        nat, maxnat, d_rx, d_ry, d_rz,
        boxx / ncx, boxy / ncy, boxz / ncz,
        ncx, ncy, ncz,
        d_cell_count, d_cell_atoms);
    
    // Kernel 2: construir pares EN STREAM1
    construir_pares<<<nblocks, nthreads, 0, stream1>>>(
        nat, maxnat, maxlist,
        d_rx, d_ry, d_rz,
        d_inicio_mol,
        boxx, boxy, boxz,
        rlist * rlist,
        ncx, ncy, ncz,
        d_cell_count, d_cell_atoms,
        d_npares, d_nblist1, d_nblist2);
    
    // Copy results back
    int h_npares = 0;
    cudaMemcpyAsync(&h_npares, d_npares, sizeof(int), cudaMemcpyDeviceToHost, stream1);
    cudaMemcpyAsync(nblist1, d_nblist1, maxlist * sizeof(int), cudaMemcpyDeviceToHost, stream1);
    cudaMemcpyAsync(nblist2, d_nblist2, maxlist * sizeof(int), cudaMemcpyDeviceToHost, stream1);
    
    // Sync and set output
    cudaStreamSynchronize(stream1);
    *npares = h_npares;
    
    // Cleanup this call's memory
    cudaFree(d_rx);
    cudaFree(d_ry);
    cudaFree(d_rz);
    cudaFree(d_inicio_mol);
    cudaFree(d_nblist1);
    cudaFree(d_nblist2);
}

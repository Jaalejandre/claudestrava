#include "config.h"
#include <cmath>
#include <iostream>
#include <cuda_runtime.h>

namespace forces {

// Helper: Apply periodic boundary conditions
inline __device__ void applyPBC(double& dx, double& dy, double& dz, double box_size) {
    if (dx > box_size * 0.5) dx -= box_size;
    if (dx < -box_size * 0.5) dx += box_size;
    if (dy > box_size * 0.5) dy -= box_size;
    if (dy < -box_size * 0.5) dy += box_size;
    if (dz > box_size * 0.5) dz -= box_size;
    if (dz < -box_size * 0.5) dz += box_size;
}

// ============================================================================
// CUDA KERNEL 1: PAIRWISE LENNARD-JONES FORCES
// Uses neighbor list for efficient force computation
// Managed memory for seamless GPU/CPU transfer
// ============================================================================
__global__ void kernel_pairwise(
    int natoms,
    double box_size,
    const double* __restrict__ x,
    const double* __restrict__ y,
    const double* __restrict__ z,
    double* fx,
    double* fy,
    double* fz,
    const int* __restrict__ nlist,
    const int* __restrict__ nlist_count,
    double sigma,
    double epsilon,
    int max_neighbors
) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= natoms) return;
    
    double fx_local = 0.0, fy_local = 0.0, fz_local = 0.0;
    double xi = x[i], yi = y[i], zi = z[i];
    
    // Process neighbors for atom i
    int ncount = nlist_count[i];
    for (int jj = 0; jj < ncount && jj < max_neighbors; jj++) {
        int j = nlist[i * max_neighbors + jj];
        if (j < 0) break; // End of neighbor list
        if (j >= natoms) break;
        
        double dx = x[j] - xi;
        double dy = y[j] - yi;
        double dz = z[j] - zi;
        
        // Periodic boundary conditions (inline for performance)
        if (dx > box_size * 0.5) dx -= box_size;
        else if (dx < -box_size * 0.5) dx += box_size;
        
        if (dy > box_size * 0.5) dy -= box_size;
        else if (dy < -box_size * 0.5) dy += box_size;
        
        if (dz > box_size * 0.5) dz -= box_size;
        else if (dz < -box_size * 0.5) dz += box_size;
        
        double r2 = dx*dx + dy*dy + dz*dz;
        if (r2 < 1e-10) continue;
        
        // Lennard-Jones: F = -dU/dr with U = 4*epsilon*((sigma/r)^12 - (sigma/r)^6)
        double sr2_inv = 1.0 / r2;
        double sr6_inv = sr2_inv * sr2_inv * sr2_inv;
        double sr12_inv = sr6_inv * sr6_inv;
        
        // F_mag = 48*epsilon*((sigma^12/r^13) - 0.5*(sigma^6/r^7))
        double sigma6 = sigma * sigma * sigma * sigma * sigma * sigma;
        double sigma12 = sigma6 * sigma6;
        
        double f_mag = 48.0 * epsilon * (sigma12 * sr12_inv * sr2_inv - 0.5 * sigma6 * sr6_inv * sr2_inv);
        
        fx_local += f_mag * dx;
        fy_local += f_mag * dy;
        fz_local += f_mag * dz;
    }
    
    // Store forces using atomic operations for thread safety
    atomicAdd(&fx[i], fx_local);
    atomicAdd(&fy[i], fy_local);
    atomicAdd(&fz[i], fz_local);
}

// Host wrapper for pairwise forces
void computeLennardJones_CUDA(
    Config& cfg,
    std::vector<double>& fx,
    std::vector<double>& fy,
    std::vector<double>& fz,
    const std::vector<std::vector<int>>& nlist
) {
    // Allocate managed memory (automatically transfers between GPU and CPU)
    double *d_x, *d_y, *d_z, *d_fx, *d_fy, *d_fz;
    int *d_nlist, *d_nlist_count;
    
    cudaMallocManaged(&d_x, cfg.natoms * sizeof(double));
    cudaMallocManaged(&d_y, cfg.natoms * sizeof(double));
    cudaMallocManaged(&d_z, cfg.natoms * sizeof(double));
    cudaMallocManaged(&d_fx, cfg.natoms * sizeof(double));
    cudaMallocManaged(&d_fy, cfg.natoms * sizeof(double));
    cudaMallocManaged(&d_fz, cfg.natoms * sizeof(double));
    
    int max_neighbors = 100;
    cudaMallocManaged(&d_nlist, cfg.natoms * max_neighbors * sizeof(int));
    cudaMallocManaged(&d_nlist_count, cfg.natoms * sizeof(int));
    
    // Copy data to managed memory
    for (int i = 0; i < cfg.natoms; i++) {
        d_x[i] = cfg.x[i];
        d_y[i] = cfg.y[i];
        d_z[i] = cfg.z[i];
        d_fx[i] = fx[i];
        d_fy[i] = fy[i];
        d_fz[i] = fz[i];
        d_nlist_count[i] = (int)nlist[i].size();
    }
    
    // Copy neighbor list
    for (int i = 0; i < cfg.natoms; i++) {
        for (size_t j = 0; j < nlist[i].size() && j < 100; j++) {
            d_nlist[i * max_neighbors + j] = nlist[i][j];
        }
        if (nlist[i].size() < 100) {
            d_nlist[i * max_neighbors + nlist[i].size()] = -1;
        }
    }
    
    cudaDeviceSynchronize();
    
    // Launch kernel
    int blockSize = 128;
    int gridSize = (cfg.natoms + blockSize - 1) / blockSize;
    kernel_pairwise<<<gridSize, blockSize>>>(
        cfg.natoms, cfg.box_size, d_x, d_y, d_z,
        d_fx, d_fy, d_fz, d_nlist, d_nlist_count,
        1.0, 0.1, max_neighbors  // sigma, epsilon, max_neighbors
    );
    
    cudaDeviceSynchronize();
    
    // Check for errors
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("CUDA kernel error: %s\n", cudaGetErrorString(err));
    }
    
    // Copy forces back
    for (int i = 0; i < cfg.natoms; i++) {
        fx[i] = d_fx[i];
        fy[i] = d_fy[i];
        fz[i] = d_fz[i];
    }
    
    // Free managed memory
    cudaFree(d_x);
    cudaFree(d_y);
    cudaFree(d_z);
    cudaFree(d_fx);
    cudaFree(d_fy);
    cudaFree(d_fz);
    cudaFree(d_nlist);
    cudaFree(d_nlist_count);
}

}  // namespace forces

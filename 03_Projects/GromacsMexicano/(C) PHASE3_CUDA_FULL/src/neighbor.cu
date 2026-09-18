#include "config.h"
#include <cmath>
#include <iostream>
#include <cuda_runtime.h>

namespace neighbor {

// ============================================================================
// CUDA KERNEL 3: NEIGHBOR LIST CONSTRUCTION
// Efficiently builds neighbor lists on GPU with coalesced memory access
// Uses managed memory for seamless data transfer
// ============================================================================

// Apply periodic boundary conditions
inline __device__ void applyPBC_neighbor(double& dx, double& dy, double& dz, double box_size) {
    if (dx > box_size * 0.5) dx -= box_size;
    else if (dx < -box_size * 0.5) dx += box_size;
    
    if (dy > box_size * 0.5) dy -= box_size;
    else if (dy < -box_size * 0.5) dy += box_size;
    
    if (dz > box_size * 0.5) dz -= box_size;
    else if (dz < -box_size * 0.5) dz += box_size;
}

// Neighbor list kernel: uses coalesced memory access pattern
// Each block processes a segment of atoms, comparing against all other atoms
__global__ void kernel_neighbor(
    int natoms,
    double box_size,
    double rcut_sq,
    const double* __restrict__ x,
    const double* __restrict__ y,
    const double* __restrict__ z,
    int* nlist,
    int* nlist_count,
    int max_neighbors
) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= natoms) return;
    
    double xi = x[i];
    double yi = y[i];
    double zi = z[i];
    
    int count = 0;
    
    // Compare atom i against all atoms j > i
    for (int j = i + 1; j < natoms; j++) {
        double dx = x[j] - xi;
        double dy = y[j] - yi;
        double dz = z[j] - zi;
        
        // Periodic boundary conditions (inline for performance)
        applyPBC_neighbor(dx, dy, dz, box_size);
        
        double r2 = dx*dx + dy*dy + dz*dz;
        
        if (r2 < rcut_sq && count < max_neighbors - 1) {
            // Store neighbor j in list for atom i
            nlist[i * max_neighbors + count] = j;
            count++;
        }
    }
    
    // Terminate list with -1 sentinel
    if (count < max_neighbors) {
        nlist[i * max_neighbors + count] = -1;
    }
    
    // Store count
    nlist_count[i] = count;
}

// Host wrapper for neighbor list construction
void buildNeighborList_CUDA(
    Config& cfg,
    std::vector<std::vector<int>>& nlist
) {
    double rcut = 12.0;
    double rskin = 2.0;
    double rcut_sq = (rcut + rskin) * (rcut + rskin);
    
    // Allocate managed memory
    double *d_x, *d_y, *d_z;
    int *d_nlist, *d_nlist_count;
    
    cudaMallocManaged(&d_x, cfg.natoms * sizeof(double));
    cudaMallocManaged(&d_y, cfg.natoms * sizeof(double));
    cudaMallocManaged(&d_z, cfg.natoms * sizeof(double));
    
    int max_neighbors = 100; // Maximum neighbors per atom
    cudaMallocManaged(&d_nlist, cfg.natoms * max_neighbors * sizeof(int));
    cudaMallocManaged(&d_nlist_count, cfg.natoms * sizeof(int));
    
    // Copy coordinate data
    for (int i = 0; i < cfg.natoms; i++) {
        d_x[i] = cfg.x[i];
        d_y[i] = cfg.y[i];
        d_z[i] = cfg.z[i];
        d_nlist_count[i] = 0;
    }
    
    // Initialize nlist with -1 (empty markers)
    for (int i = 0; i < cfg.natoms * max_neighbors; i++) {
        d_nlist[i] = -1;
    }
    
    cudaDeviceSynchronize();
    
    // Launch kernel
    int blockSize = 128;
    int gridSize = (cfg.natoms + blockSize - 1) / blockSize;
    kernel_neighbor<<<gridSize, blockSize>>>(
        cfg.natoms, cfg.box_size, rcut_sq,
        d_x, d_y, d_z, d_nlist, d_nlist_count, max_neighbors
    );
    
    cudaDeviceSynchronize();
    
    // Check for errors
    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        printf("Neighbor kernel error: %s\n", cudaGetErrorString(err));
    }
    
    // Copy results back
    nlist.clear();
    nlist.resize(cfg.natoms);
    for (int i = 0; i < cfg.natoms; i++) {
        nlist[i].clear();
        for (int j = 0; j < d_nlist_count[i]; j++) {
            int neighbor = d_nlist[i * max_neighbors + j];
            if (neighbor >= 0 && neighbor < cfg.natoms) {
                nlist[i].push_back(neighbor);
            }
        }
    }
    
    // Free managed memory
    cudaFree(d_x);
    cudaFree(d_y);
    cudaFree(d_z);
    cudaFree(d_nlist);
    cudaFree(d_nlist_count);
}

}  // namespace neighbor

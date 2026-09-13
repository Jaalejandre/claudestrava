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
// CUDA KERNEL: PAIRWISE LENNARD-JONES FORCES (Phase 4 with Pinned Memory)
// Uses async streams for overlapped computation and transfer
// ============================================================================
__global__ void kernel_pairwise_async(
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
        if (j < 0) break;
        if (j >= natoms) break;
        
        double dx = x[j] - xi;
        double dy = y[j] - yi;
        double dz = z[j] - zi;
        
        // Periodic boundary conditions
        applyPBC(dx, dy, dz, box_size);
        
        double r2 = dx*dx + dy*dy + dz*dz;
        // Physical cutoffs: avoid division by zero & numerical instability
        const double r_min_sq = 1e-6;  // ~0.001 Å (exclude self-interactions)
        const double r_max_sq = 144.0; // 12 Å (LJ cutoff)
        if (r2 < r_min_sq || r2 > r_max_sq) continue;
        
        double r_inv = 1.0 / sqrt(r2);  // 1/r
        double r6_inv = r_inv * r_inv * r_inv * r_inv * r_inv * r_inv;  // 1/r⁶
        double r13_inv = r6_inv * r6_inv * r_inv;  // 1/r¹³ = 1/r⁶ * 1/r⁶ * 1/r
        
        double sigma6 = sigma * sigma * sigma * sigma * sigma * sigma;
        double sigma12 = sigma6 * sigma6;
        
        // LJ force: F = 48*ε*(σ¹²/r¹³ - σ⁶/r⁷)
        // Derivada del potencial: -dU/dr donde U = 4ε[(σ/r)¹² - (σ/r)⁶]
        double factor = 48.0 * epsilon * (sigma12 * r13_inv - 0.5 * sigma6 * r6_inv * r_inv);
        fx_local += factor * dx;
        fy_local += factor * dy;
        fz_local += factor * dz;
    }
    
    // Atomic operations for thread safety
    atomicAdd(&fx[i], fx_local);
    atomicAdd(&fy[i], fy_local);
    atomicAdd(&fz[i], fz_local);
}

// ============================================================================
// CUDA KERNEL: BONDED FORCES (BONDS AND ANGLES)
// ============================================================================
__global__ void kernel_bonded_bonds(
    int nbonds,
    const Bond* __restrict__ bonds,
    const double* __restrict__ x,
    const double* __restrict__ y,
    const double* __restrict__ z,
    double* fx,
    double* fy,
    double* fz
) {
    int bond_idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (bond_idx >= nbonds) return;
    
    Bond b = bonds[bond_idx];
    int i = b.i, j = b.j;
    
    double dx = x[j] - x[i];
    double dy = y[j] - y[i];
    double dz = z[j] - z[i];
    
    double r = sqrt(dx*dx + dy*dy + dz*dz);
    if (r < 1e-10) return;
    
    // Harmonic bond: F = k_b * (r - r_eq) / r
    double force = b.k_b * (r - b.req) / r;
    
    double fx_bond = -force * dx;
    double fy_bond = -force * dy;
    double fz_bond = -force * dz;
    
    atomicAdd(&fx[i], -fx_bond);
    atomicAdd(&fy[i], -fy_bond);
    atomicAdd(&fz[i], -fz_bond);
    atomicAdd(&fx[j], fx_bond);
    atomicAdd(&fy[j], fy_bond);
    atomicAdd(&fz[j], fz_bond);
}

__global__ void kernel_bonded_angles(
    int nangles,
    const Angle* __restrict__ angles,
    const double* __restrict__ x,
    const double* __restrict__ y,
    const double* __restrict__ z,
    double* fx,
    double* fy,
    double* fz
) {
    int angle_idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (angle_idx >= nangles) return;
    
    Angle a = angles[angle_idx];
    int i = a.i, j = a.j, k = a.k;
    
    // Vectors j->i and j->k
    double dij_x = x[i] - x[j], dij_y = y[i] - y[j], dij_z = z[i] - z[j];
    double dkj_x = x[k] - x[j], dkj_y = y[k] - y[j], dkj_z = z[k] - z[j];
    
    double rij = sqrt(dij_x*dij_x + dij_y*dij_y + dij_z*dij_z);
    double rkj = sqrt(dkj_x*dkj_x + dkj_y*dkj_y + dkj_z*dkj_z);
    
    if (rij < 1e-10 || rkj < 1e-10) return;
    
    // Compute angle
    double cos_theta = (dij_x*dkj_x + dij_y*dkj_y + dij_z*dkj_z) / (rij * rkj);
    cos_theta = fmax(-1.0, fmin(1.0, cos_theta));
    
    double theta = acos(cos_theta);
    
    // Harmonic angle: F = k_a * (theta - theta_eq)
    double dtheta = theta - a.theta_eq;
    double force_mag = a.k_a * dtheta / sin(theta);
    if (fabs(sin(theta)) < 1e-10) force_mag = 0.0;
    
    // Apply forces (simplified - full computation involves cross products)
    double fi_mag = force_mag / rij;
    double fk_mag = force_mag / rkj;
    
    atomicAdd(&fx[i], fi_mag * (dkj_x/rkj));
    atomicAdd(&fy[i], fi_mag * (dkj_y/rkj));
    atomicAdd(&fz[i], fi_mag * (dkj_z/rkj));
    
    atomicAdd(&fx[k], fk_mag * (dij_x/rij));
    atomicAdd(&fy[k], fk_mag * (dij_y/rij));
    atomicAdd(&fz[k], fk_mag * (dij_z/rij));
}

} // namespace forces

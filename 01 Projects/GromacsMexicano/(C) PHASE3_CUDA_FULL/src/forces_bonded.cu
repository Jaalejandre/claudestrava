#include "config.h"
#include <cmath>
#include <iostream>
#include <cuda_runtime.h>

namespace forces {

// ============================================================================
// CUDA KERNEL 2: BONDED FORCES (BONDS, ANGLES, DIHEDRALS)
// Processes all bonded interactions
// Uses managed memory for seamless data transfer
// ============================================================================

// Helper: Apply periodic boundary conditions
inline __device__ void applyPBC_bonded(double& dx, double& dy, double& dz, double box_size) {
    if (dx > box_size * 0.5) dx -= box_size;
    else if (dx < -box_size * 0.5) dx += box_size;
    
    if (dy > box_size * 0.5) dy -= box_size;
    else if (dy < -box_size * 0.5) dy += box_size;
    
    if (dz > box_size * 0.5) dz -= box_size;
    else if (dz < -box_size * 0.5) dz += box_size;
}

// Bond force kernel: harmonic bonds
__global__ void kernel_bonded_bonds(
    int nbonds,
    const double* __restrict__ x,
    const double* __restrict__ y,
    const double* __restrict__ z,
    double* fx,
    double* fy,
    double* fz,
    const int* __restrict__ bond_i,
    const int* __restrict__ bond_j,
    const double* __restrict__ bond_req,
    const double* __restrict__ bond_k,
    double box_size
) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= nbonds) return;
    
    int i = bond_i[idx];
    int j = bond_j[idx];
    
    double dx = x[j] - x[i];
    double dy = y[j] - y[i];
    double dz = z[j] - z[i];
    
    applyPBC_bonded(dx, dy, dz, box_size);
    
    double r = sqrt(dx*dx + dy*dy + dz*dz);
    if (r < 1e-10) return;
    
    double dr = r - bond_req[idx];
    double f_mag = bond_k[idx] * dr / r;
    
    double fbond_x = f_mag * dx;
    double fbond_y = f_mag * dy;
    double fbond_z = f_mag * dz;
    
    // Apply forces (Newton's 3rd law)
    atomicAdd(&fx[i], fbond_x);
    atomicAdd(&fy[i], fbond_y);
    atomicAdd(&fz[i], fbond_z);
    
    atomicAdd(&fx[j], -fbond_x);
    atomicAdd(&fy[j], -fbond_y);
    atomicAdd(&fz[j], -fbond_z);
}

// Angle force kernel: harmonic angles
__global__ void kernel_bonded_angles(
    int nangles,
    const double* __restrict__ x,
    const double* __restrict__ y,
    const double* __restrict__ z,
    double* fx,
    double* fy,
    double* fz,
    const int* __restrict__ angle_i,
    const int* __restrict__ angle_j,
    const int* __restrict__ angle_k,
    const double* __restrict__ angle_eq,
    const double* __restrict__ angle_k_a,
    double box_size
) {
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= nangles) return;
    
    int i = angle_i[idx];
    int j = angle_j[idx];
    int k = angle_k[idx];
    
    if (i < 0 || j < 0 || k < 0) return;
    
    // Compute vectors j->i and j->k
    double r1x = x[i] - x[j];
    double r1y = y[i] - y[j];
    double r1z = z[i] - z[j];
    applyPBC_bonded(r1x, r1y, r1z, box_size);
    
    double r2x = x[k] - x[j];
    double r2y = y[k] - y[j];
    double r2z = z[k] - z[j];
    applyPBC_bonded(r2x, r2y, r2z, box_size);
    
    double r1 = sqrt(r1x*r1x + r1y*r1y + r1z*r1z);
    double r2 = sqrt(r2x*r2x + r2y*r2y + r2z*r2z);
    
    if (r1 < 1e-10 || r2 < 1e-10) return;
    
    // Compute angle
    double cos_theta = (r1x*r2x + r1y*r2y + r1z*r2z) / (r1 * r2);
    cos_theta = (cos_theta > 1.0) ? 1.0 : (cos_theta < -1.0 ? -1.0 : cos_theta);
    
    double theta = acos(cos_theta);
    double dtheta = theta - angle_eq[idx];
    double force_mag = -2.0 * angle_k_a[idx] * dtheta;
    
    // Compute force derivatives
    double r1_inv = 1.0 / r1;
    double r2_inv = 1.0 / r2;
    double sin_theta = sin(theta);
    if (sin_theta < 1e-10) sin_theta = 1e-10;
    
    double denom = sin_theta * r1 * r2;
    
    // F_i = force_mag * (cos_theta * r1_unit - r2_unit) / (r1 * sin_theta)
    double f_coef = force_mag / denom;
    
    double f_i_x = f_coef * (cos_theta * r1x * r1_inv - r2x * r2_inv);
    double f_i_y = f_coef * (cos_theta * r1y * r1_inv - r2y * r2_inv);
    double f_i_z = f_coef * (cos_theta * r1z * r1_inv - r2z * r2_inv);
    
    // F_k symmetric
    double f_k_x = f_coef * (cos_theta * r2x * r2_inv - r1x * r1_inv);
    double f_k_y = f_coef * (cos_theta * r2y * r2_inv - r1y * r1_inv);
    double f_k_z = f_coef * (cos_theta * r2z * r2_inv - r1z * r1_inv);
    
    // F_j = -(F_i + F_k)
    double f_j_x = -(f_i_x + f_k_x);
    double f_j_y = -(f_i_y + f_k_y);
    double f_j_z = -(f_i_z + f_k_z);
    
    atomicAdd(&fx[i], f_i_x);
    atomicAdd(&fy[i], f_i_y);
    atomicAdd(&fz[i], f_i_z);
    
    atomicAdd(&fx[j], f_j_x);
    atomicAdd(&fy[j], f_j_y);
    atomicAdd(&fz[j], f_j_z);
    
    atomicAdd(&fx[k], f_k_x);
    atomicAdd(&fy[k], f_k_y);
    atomicAdd(&fz[k], f_k_z);
}

// Host wrapper for bonded forces
void computeBondedForces_CUDA(
    Config& cfg,
    std::vector<double>& fx,
    std::vector<double>& fy,
    std::vector<double>& fz
) {
    if (cfg.bonds.empty() && cfg.angles.empty()) {
        return; // Nothing to compute
    }
    
    // Allocate managed memory
    double *d_x, *d_y, *d_z, *d_fx, *d_fy, *d_fz;
    int *d_bond_i, *d_bond_j, *d_angle_i, *d_angle_j, *d_angle_k;
    double *d_bond_req, *d_bond_k, *d_angle_eq, *d_angle_k_a;
    
    cudaMallocManaged(&d_x, cfg.natoms * sizeof(double));
    cudaMallocManaged(&d_y, cfg.natoms * sizeof(double));
    cudaMallocManaged(&d_z, cfg.natoms * sizeof(double));
    cudaMallocManaged(&d_fx, cfg.natoms * sizeof(double));
    cudaMallocManaged(&d_fy, cfg.natoms * sizeof(double));
    cudaMallocManaged(&d_fz, cfg.natoms * sizeof(double));
    
    // Copy coordinate and force data
    for (int i = 0; i < cfg.natoms; i++) {
        d_x[i] = cfg.x[i];
        d_y[i] = cfg.y[i];
        d_z[i] = cfg.z[i];
        d_fx[i] = fx[i];
        d_fy[i] = fy[i];
        d_fz[i] = fz[i];
    }
    
    // Bond kernel
    if (!cfg.bonds.empty()) {
        cudaMallocManaged(&d_bond_i, cfg.bonds.size() * sizeof(int));
        cudaMallocManaged(&d_bond_j, cfg.bonds.size() * sizeof(int));
        cudaMallocManaged(&d_bond_req, cfg.bonds.size() * sizeof(double));
        cudaMallocManaged(&d_bond_k, cfg.bonds.size() * sizeof(double));
        
        for (size_t i = 0; i < cfg.bonds.size(); i++) {
            d_bond_i[i] = cfg.bonds[i].i;
            d_bond_j[i] = cfg.bonds[i].j;
            d_bond_req[i] = cfg.bonds[i].req;
            d_bond_k[i] = cfg.bonds[i].k_b;
        }
        
        cudaDeviceSynchronize();
        
        int blockSize = 128;
        int gridSize = (cfg.bonds.size() + blockSize - 1) / blockSize;
        kernel_bonded_bonds<<<gridSize, blockSize>>>(
            cfg.bonds.size(), d_x, d_y, d_z, d_fx, d_fy, d_fz,
            d_bond_i, d_bond_j, d_bond_req, d_bond_k, cfg.box_size
        );
        cudaDeviceSynchronize();
        
        cudaFree(d_bond_i);
        cudaFree(d_bond_j);
        cudaFree(d_bond_req);
        cudaFree(d_bond_k);
    }
    
    // Angle kernel
    if (!cfg.angles.empty()) {
        cudaMallocManaged(&d_angle_i, cfg.angles.size() * sizeof(int));
        cudaMallocManaged(&d_angle_j, cfg.angles.size() * sizeof(int));
        cudaMallocManaged(&d_angle_k, cfg.angles.size() * sizeof(int));
        cudaMallocManaged(&d_angle_eq, cfg.angles.size() * sizeof(double));
        cudaMallocManaged(&d_angle_k_a, cfg.angles.size() * sizeof(double));
        
        for (size_t i = 0; i < cfg.angles.size(); i++) {
            d_angle_i[i] = cfg.angles[i].i;
            d_angle_j[i] = cfg.angles[i].j;
            d_angle_k[i] = cfg.angles[i].k;
            d_angle_eq[i] = cfg.angles[i].theta_eq;
            d_angle_k_a[i] = cfg.angles[i].k_a;
        }
        
        cudaDeviceSynchronize();
        
        int blockSize = 128;
        int gridSize = (cfg.angles.size() + blockSize - 1) / blockSize;
        kernel_bonded_angles<<<gridSize, blockSize>>>(
            cfg.angles.size(), d_x, d_y, d_z, d_fx, d_fy, d_fz,
            d_angle_i, d_angle_j, d_angle_k, d_angle_eq, d_angle_k_a, cfg.box_size
        );
        cudaDeviceSynchronize();
        
        cudaFree(d_angle_i);
        cudaFree(d_angle_j);
        cudaFree(d_angle_k);
        cudaFree(d_angle_eq);
        cudaFree(d_angle_k_a);
    }
    
    // Copy forces back
    for (int i = 0; i < cfg.natoms; i++) {
        fx[i] = d_fx[i];
        fy[i] = d_fy[i];
        fz[i] = d_fz[i];
    }
    
    // Free all managed memory
    cudaFree(d_x);
    cudaFree(d_y);
    cudaFree(d_z);
    cudaFree(d_fx);
    cudaFree(d_fy);
    cudaFree(d_fz);
}

}  // namespace forces

#if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ < 600)
static __inline__ __device__ double atomicAdd(double *address, double val) {
    unsigned long long int *address_as_ull = (unsigned long long int *)address;
    unsigned long long int old = *address_as_ull, assumed;
    do {
        assumed = old;
        old = atomicCAS(address_as_ull, assumed, __double_as_longlong(val + __longlong_as_double(assumed)));
    } while (assumed != old);
    return __longlong_as_double(old);
}
#endif
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


// 3D PBC with separate box dimensions (for non-cubic boxes)
inline __device__ void applyPBC3D(double& dx, double& dy, double& dz, double boxx, double boxy, double boxz) {
 if (dx > boxx * 0.5) dx -= boxx;
 if (dx < -boxx * 0.5) dx += boxx;
 if (dy > boxy * 0.5) dy -= boxy;
 if (dy < -boxy * 0.5) dy += boxy;
 if (dz > boxz * 0.5) dz -= boxz;
 if (dz < -boxz * 0.5) dz += boxz;
}
// ============================================================================
// CUDA KERNEL: PAIRWISE LENNARD-JONES FORCES (Phase 4 with Pinned Memory)
// Uses async streams for overlapped computation and transfer
// ============================================================================
// ============================================================================
// CUDA KERNEL: OPTIMIZED PAIRWISE LENNARD-JONES FORCES (Phase 5b)
// Uses async streams for overlapped computation and transfer
// Optimizations:
//   - Optionally use precomputed sigma^12 and sigma^6 matrices if provided
//   - Uses r2_inv and r6_inv to reduce operations
// ============================================================================
__global__ void kernel_pairwise_async(
 int natoms,
 double box_size,
 double boxx, double boxy, double boxz,
 const double* __restrict__ x,
 const double* __restrict__ y,
 const double* __restrict__ z,
 const int* __restrict__ types,
 const double* __restrict__ charges,
 const double* __restrict__ sigma_matrix,
 const double* __restrict__ eps_matrix,
 const double* __restrict__ sigma12_matrix,
 const double* __restrict__ sigma6_matrix,
 double* fx,
 double* fy,
 double* fz,
 double* ucoul,
 const int* __restrict__ nlist,
 const int* __restrict__ nlist_count,
 int max_neighbors,
 double rkappa,
 double rcut2
) {
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i >= natoms) return;

  double fx_local = 0.0, fy_local = 0.0, fz_local = 0.0;
 double ucoul_local = 0.0;
  double xi = x[i], yi = y[i], zi = z[i];
  int type_i = types[i]; // Get type

  // Process neighbors for atom i
  int ncount = nlist_count[i];
  for (int jj = 0; jj < ncount && jj < max_neighbors; jj++) {
      int j = nlist[i * max_neighbors + jj];
      if (j < 0) break;
      if (j >= natoms) break;

      // Calculate distance vector
      double dx = x[j] - xi;
      double dy = y[j] - yi;
      double dz = z[j] - zi;
      applyPBC3D(dx, dy, dz, boxx, boxy, boxz);

      double r2 = dx * dx + dy * dy + dz * dz;
      const double r_min_sq = 1e-6;  // ~0.001 Å (exclude self-interactions)
      const double r_max_sq = 144.0; // 12 Å (LJ cutoff)
      if (r2 < r_min_sq || r2 > r_max_sq) continue;

      int type_j = types[j]; // Get type
      int ind = type_i + type_j * 10; // 10x10 Matrix index
      double epsij   = eps_matrix[ind];
      double sigma12, sigma6;
      if (sigma12_matrix != nullptr && sigma6_matrix != nullptr) {
          sigma12 = sigma12_matrix[ind];
          sigma6  = sigma6_matrix[ind];
      } else {
          // Fallback: compute from sigma_matrix
          double sigmaij = sigma_matrix[ind];
          sigma6  = sigmaij * sigmaij * sigmaij * sigmaij * sigmaij * sigmaij;
          sigma12 = sigma6 * sigma6;
      }

      double r2_inv = 1.0 / r2;
      double r6_inv = r2_inv * r2_inv * r2_inv;
      // Avoid sqrt by using rsqrt (intrinsic) for 1/r
      double r_inv = rsqrt(r2); // Approximate reciprocal sqrt
      // More accurate: one Newton step: r_inv = r_inv * (1.5 - 0.5 * r2 * r_inv * r_inv);
      // But for now we use the intrinsic as is.

      double factor = 48.0 * epsij * (sigma12 * r6_inv * r2_inv - 0.5 * sigma6 * r6_inv) * r_inv;
      fx_local += factor * dx;
      fy_local += factor * dy;
      fz_local += factor * dz;

 // Coulomb real-space (Ewald erfc)
 if (charges != nullptr && r2 < rcut2) {
     double qi = charges[i], qj = charges[j];
     double qiqj = qi * qj;
     double r = sqrt(r2);
     double erfc_val = erfc(rkappa * r);
     double e_coul = qiqj * erfc_val / r;
     ucoul_local += e_coul;
     double exp_k2r2 = exp(-rkappa * rkappa * r2);
     double coul_force = qiqj / r2 * (erfc_val / r + 2.0 * rkappa * M_2_SQRTPI * 0.5 * exp_k2r2);
     fx_local -= coul_force * dx;
     fy_local -= coul_force * dy;
     fz_local -= coul_force * dz;
 }
  }

  // Atomic operations for thread safety
  atomicAdd(&fx[i], fx_local);
  atomicAdd(&fy[i], fy_local);
  atomicAdd(&fz[i], fz_local);
 if (ucoul != nullptr) atomicAdd(&ucoul[i], ucoul_local);
}__global__ void kernel_bonded_bonds(
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
    
    double r = sqrt(dx * dx + dy * dy + dz * dz);
    double dr = r - b.req;
    double force_mag = -2.0 * b.k_b * dr / (r + 1e-6);
    
    double fx_bond = force_mag * dx / r;
    double fy_bond = force_mag * dy / r;
    double fz_bond = force_mag * dz / r;
    
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
    
    double dij_x = x[i] - x[j], dij_y = y[i] - y[j], dij_z = z[i] - z[j];
    double dkj_x = x[k] - x[j], dkj_y = y[k] - y[j], dkj_z = z[k] - z[j];
    
    double rij = sqrt(dij_x*dij_x + dij_y*dij_y + dij_z*dij_z);
    double rkj = sqrt(dkj_x*dkj_x + dkj_y*dkj_y + dkj_z*dkj_z);
    
    double cos_theta = (dij_x*dkj_x + dij_y*dkj_y + dij_z*dkj_z) / (rij * rkj + 1e-6);
    cos_theta = fmin(1.0, fmax(-1.0, cos_theta));
    
    double theta = acos(cos_theta);
    double dtheta = theta - a.theta_eq;
    
    double force_mag = a.k_a * dtheta;
    
    double fi_mag = force_mag / (rij + 1e-6);
    double fk_mag = force_mag / (rkj + 1e-6);
    
    atomicAdd(&fx[i], fi_mag * (dkj_x/rkj));
    atomicAdd(&fy[i], fi_mag * (dkj_y/rkj));
    atomicAdd(&fz[i], fi_mag * (dkj_z/rkj));
    
    atomicAdd(&fx[k], fk_mag * (dij_x/rij));
    atomicAdd(&fy[k], fk_mag * (dij_y/rij));
    atomicAdd(&fz[k], fk_mag * (dij_z/rij));
}

// Wrapper to launch the kernel
// Wrapper to launch the kernel (updated for Phase 5b with precomputed matrices)
void launch_pairwise_forces(
 int natoms, double box_size, double boxx, double boxy, double boxz,
 const double* x, const double* y, const double* z,
 const int* types, const double* charges,
 const double* sigma, const double* eps,
 double* fx, double* fy, double* fz,
 double* ucoul,
 const int* nlist, const int* nlist_count, int max_neighbors,
 double rkappa, double rcut_coulomb,
 cudaStream_t stream
) {
    int block_size = 256;
    int grid_size = (natoms + block_size - 1) / block_size;
 kernel_pairwise_async<<<grid_size, block_size, 0, stream>>>(
 natoms, box_size, boxx, boxy, boxz, x, y, z,
 types, charges,
 sigma, eps,
 nullptr, nullptr,
 fx, fy, fz,
 ucoul,
 nlist, nlist_count, max_neighbors,
 rkappa, rcut_coulomb
 );
    CUDA_CHECK(cudaGetLastError());
}
} // namespace forces

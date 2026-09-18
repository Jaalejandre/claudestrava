#include <cuda_runtime.h>
#include <cmath>
#include <iostream>
#include "config.h"
#include "forces.h"

// Forward declarations for kwald
extern "C" void kwald_cuda_stream(
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


namespace integrator {

// ============================================================================
// CUDA KERNEL 1: VELOCITY VERLET INTEGRATION
// Per-atom integration with pinned memory and async stream
// ============================================================================
__global__ void velocity_verlet_kernel(
    int natoms,
    double dt,
    const double* __restrict__ mass,
    const double* __restrict__ fx,
    const double* __restrict__ fy,
    const double* __restrict__ fz,
    double* __restrict__ vx,
    double* __restrict__ vy,
    double* __restrict__ vz,
    double* __restrict__ x,
    double* __restrict__ y,
    double* __restrict__ z,
    double box_size
) {
    // One thread per atom for maximum parallelism
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= natoms) return;
    
    double m_inv = 1.0 / mass[idx];
    double dt2_2 = dt * dt * 0.5;  // dt^2/2
    double dt_2 = dt * 0.5;         // dt/2
    
    // Position update: x = x + v*dt + (f/m)*dt^2/2
    double x_new = x[idx] + vx[idx] * dt + fx[idx] * m_inv * dt2_2;
    double y_new = y[idx] + vy[idx] * dt + fy[idx] * m_inv * dt2_2;
    double z_new = z[idx] + vz[idx] * dt + fz[idx] * m_inv * dt2_2;
    
    // Apply periodic boundary conditions
    if (x_new > box_size) x_new -= box_size;
    if (x_new < 0.0) x_new += box_size;
    if (y_new > box_size) y_new -= box_size;
    if (y_new < 0.0) y_new += box_size;
    if (z_new > box_size) z_new -= box_size;
    if (z_new < 0.0) z_new += box_size;
    
    // Velocity update (first half): v_half = v + (f/m)*dt/2
    double vx_new = vx[idx] + fx[idx] * m_inv * dt_2;
    double vy_new = vy[idx] + fy[idx] * m_inv * dt_2;
    double vz_new = vz[idx] + fz[idx] * m_inv * dt_2;
    
    // Store updated values
    x[idx] = x_new;
    y[idx] = y_new;
    z[idx] = z_new;
    vx[idx] = vx_new;
    vy[idx] = vy_new;
    vz[idx] = vz_new;
}

// ============================================================================
// CUDA KERNEL 2: NOSE-HOOVER THERMOSTAT SCALING
// Per-atom velocity scaling for temperature control
// ============================================================================
__global__ void nose_hoover_kernel(
    int natoms,
    double dt,
    const double* __restrict__ vx,
    const double* __restrict__ vy,
    const double* __restrict__ vz,
    double scaling_factor,
    double* __restrict__ vx_scaled,
    double* __restrict__ vy_scaled,
    double* __restrict__ vz_scaled
) {
    // One thread per atom
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= natoms) return;
    
    // Apply velocity scaling: v_new = v * lambda
    // where lambda is computed from Nose-Hoover equations
    vx_scaled[idx] = vx[idx] * scaling_factor;
    vy_scaled[idx] = vy[idx] * scaling_factor;
    vz_scaled[idx] = vz[idx] * scaling_factor;
}

// ============================================================================
// CUDA KERNEL 3: TEMPERATURE CALCULATION WITH TREE REDUCTION
// Efficient parallel reduction to compute kinetic energy and temperature
// ============================================================================

// Helper: Block-level reduction for kinetic energy
__global__ void calcTemperature_GPU(
    int natoms,
    const double* __restrict__ vx,
    const double* __restrict__ vy,
    const double* __restrict__ vz,
    const double* __restrict__ mass,
    double* __restrict__ KE_block  // Block result array
) {
    // Shared memory for block reduction (max 1024 threads)
    extern __shared__ double shared_KE[];
    
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    int tidx = threadIdx.x;
    
    // Compute kinetic energy for this thread
    double ke = 0.0;
    if (idx < natoms) {
        double v2 = vx[idx]*vx[idx] + vy[idx]*vy[idx] + vz[idx]*vz[idx];
        ke = 0.5 * mass[idx] * v2;
    }
    shared_KE[tidx] = ke;
    __syncthreads();
    
    // Tree reduction in shared memory
    for (int stride = blockDim.x / 2; stride > 0; stride /= 2) {
        if (tidx < stride) {
            shared_KE[tidx] += shared_KE[tidx + stride];
        }
        __syncthreads();
    }
    
    // Block 0 thread 0 writes block result
    if (tidx == 0) {
        KE_block[blockIdx.x] = shared_KE[0];
    }
}

// Final reduction kernel: sum all block results
__global__ void reduceKE_final(
    int nblocks,
    const double* __restrict__ KE_block,
    double* __restrict__ KE_total
) {
    extern __shared__ double shared_final[];
    
    int tidx = threadIdx.x;
    shared_final[tidx] = (tidx < nblocks) ? KE_block[tidx] : 0.0;
    __syncthreads();
    
    for (int stride = blockDim.x / 2; stride > 0; stride /= 2) {
        if (tidx < stride) {
            shared_final[tidx] += shared_final[tidx + stride];
        }
        __syncthreads();
    }
    
    if (tidx == 0) {
        *KE_total = shared_final[0];
    }
}

// ============================================================================
// HOST WRAPPER FUNCTIONS
// ============================================================================

void integrator_step_GPU(
 Config& cfg,
 double* d_x, double* d_y, double* d_z,
 double* d_vx, double* d_vy, double* d_vz,
 double* d_fx, double* d_fy, double* d_fz,
 double* d_mass,
 cudaStream_t stream1, cudaStream_t stream2, cudaStream_t stream3
) {
 // 1. LJ forces + Coulomb real-space (Ewald split)
 double d_ucoul = 0.0;
 double* d_ucoul_ptr = nullptr;
 cudaMalloc(&d_ucoul_ptr, sizeof(double));
 cudaMemset(d_ucoul_ptr, 0, sizeof(double));
 
 forces::launch_pairwise_forces(
 cfg.natoms, cfg.box_size, cfg.boxx, cfg.boxy, cfg.boxz,
 d_x, d_y, d_z,
 cfg.d_types, cfg.d_charge,
 cfg.d_sigma, cfg.d_eps,
 d_fx, d_fy, d_fz,
 d_ucoul_ptr,
 cfg.d_nlist, cfg.d_nlist_count, cfg.max_neighbors,
 cfg.ewald_alpha, cfg.rcut_coulomb,
 stream1
 );

 // Sync forces before kwald
 cudaStreamSynchronize(stream1);

 // 2. Kwald: reciprocal-space Ewald (stream3)
 kwald_cuda_stream(
 cfg.natoms, cfg.nk,
 cfg.kmaxx, cfg.kmaxy, cfg.kmaxz,
 cfg.boxx, cfg.boxy, cfg.boxz,
 d_x, d_y, d_z,
 cfg.d_charge,
 d_fx, d_fy, d_fz,
 nullptr,
 nullptr, nullptr, nullptr,
 nullptr, nullptr, nullptr,
 stream3
 );
 
 cudaStreamSynchronize(stream3);

 int block_size = 128;
 int grid_size = (cfg.natoms + block_size - 1) / block_size;
 
 // Velocity Verlet in stream2
 velocity_verlet_kernel<<<grid_size, block_size, 0, stream2>>>( 
 cfg.natoms, cfg.dt,
 d_mass,
 d_fx, d_fy, d_fz,
 d_vx, d_vy, d_vz,
 d_x, d_y, d_z,
 cfg.box_size
 );
 
 if (d_ucoul_ptr) cudaFree(d_ucoul_ptr);
}


double compute_temperature_GPU(
    int natoms,
    double* d_vx, double* d_vy, double* d_vz,
    double* d_mass,
    double* d_KE_block,
    double* d_KE_total,
    double* h_KE_total,
    cudaStream_t stream
) {
    int block_size = 256;
    int grid_size = (natoms + block_size - 1) / block_size;
    
    // Launch temperature calculation with tree reduction
    size_t shared_mem = block_size * sizeof(double);
    
    calcTemperature_GPU<<<grid_size, block_size, shared_mem, stream>>>(
        natoms,
        d_vx, d_vy, d_vz,
        d_mass,
        d_KE_block
    );
    
    // Final reduction: sum all block results
    int final_block_size = 256;
    int final_grid_size = 1;
    size_t final_shared_mem = final_block_size * sizeof(double);
    
    reduceKE_final<<<final_grid_size, final_block_size, final_shared_mem, stream>>>(
        grid_size,
        d_KE_block,
        d_KE_total
    );
    
    // Copy result back to host
    cudaMemcpyAsync(h_KE_total, d_KE_total, sizeof(double), 
                     cudaMemcpyDeviceToHost, stream);
    
    // Synchronize to get result
    cudaStreamSynchronize(stream);
    
    double KE = *h_KE_total;
    // BUGFIX v1.2: KE is in amu*(nm/ps)^2, convert to SI units before temp calculation
    // Conversion factor: 1 amu = 1.66054e-27 kg, 1 nm/ps = 100 m/s
    // KE_SI = KE_raw * 1.66054e-27 * (100)^2 = KE_raw * 1.66054e-23 J
    double KE_joules = KE * 1.66054e-23;  // Convert from amu*(nm/ps)^2 to Joules
    double temp = (2.0 / 3.0) * KE_joules / (natoms * 1.380649e-23);  // Boltzmann constant
    return temp;
}

void thermostat_scale_GPU(
    int natoms,
    double target_temp,
    double current_temp,
    double tau_t,
    double* d_vx, double* d_vy, double* d_vz,
    double dt,
    cudaStream_t stream
) {
    if (current_temp < 1e-6) return;
    
    // Nose-Hoover scaling: lambda = 1 + (dt/tau_t) * (T_target/T_current - 1)
    double lambda = 1.0 + (dt / tau_t) * (target_temp / current_temp - 1.0);
    lambda = fmax(0.5, fmin(2.0, lambda));  // Clamp to [0.5, 2.0]
    
    int block_size = 128;
    int grid_size = (natoms + block_size - 1) / block_size;
    
    nose_hoover_kernel<<<grid_size, block_size, 0, stream>>>(
        natoms, dt,
        d_vx, d_vy, d_vz,
        lambda,
        d_vx, d_vy, d_vz  // Output overwrites input (in-place scaling)
    );
}

} // namespace integrator

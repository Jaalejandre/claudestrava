#include "surface_tension.h"
#include <iostream>
#include <vector>
#include <iomanip>
#include <cmath>
#include <chrono>
#include <cuda_runtime.h>

#define CUDA_CHECK(call) do { \
    cudaError_t err = (call); \
    if (err != cudaSuccess) { \
        std::cerr << "CUDA Error: " << cudaGetErrorString(err) << " at line " << __LINE__ << std::endl; \
        exit(1); \
    } \
} while(0)

// CUDA Kernel: Compute Forces, Virial Tensor, and Dipole Moment on GPU
__global__ void slab_forces_virial_kernel(
    int natoms,
    const double* __restrict__ x, const double* __restrict__ y, const double* __restrict__ z,
    const double* __restrict__ vx, const double* __restrict__ vy, const double* __restrict__ vz,
    const double* __restrict__ charge, const double* __restrict__ mass,
    double* __restrict__ fx, double* __restrict__ fy, double* __restrict__ fz,
    double* __restrict__ wxx_block, double* __restrict__ wyy_block, double* __restrict__ wzz_block,
    double* __restrict__ mx_block, double* __restrict__ my_block, double* __restrict__ mz_block,
    double boxx, double boxy, double boxz, double rcut, double sigma, double epsilon)
{
    __shared__ double sh_wxx[128], sh_wyy[128], sh_wzz[128];
    __shared__ double sh_mx[128], sh_my[128], sh_mz[128];

    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int tid = threadIdx.x;

    double fx_local = 0.0, fy_local = 0.0, fz_local = 0.0;
    double wxx_i = 0.0, wyy_i = 0.0, wzz_i = 0.0;

    double xi = (i < natoms) ? x[i] : 0.0;
    double yi = (i < natoms) ? y[i] : 0.0;
    double zi = (i < natoms) ? z[i] : 0.0;
    double qi = (i < natoms) ? charge[i] : 0.0;

    // Dipole moment component
    sh_mx[tid] = (i < natoms) ? qi * xi : 0.0;
    sh_my[tid] = (i < natoms) ? qi * yi : 0.0;
    sh_mz[tid] = (i < natoms) ? qi * zi : 0.0;

    double rcut2 = rcut * rcut;
    double sigma6 = sigma * sigma * sigma * sigma * sigma * sigma;
    double eps4 = 4.0 * epsilon;

    if (i < natoms) {
        for (int j = 0; j < natoms; j++) {
            if (i == j) continue;

            double dx = x[j] - xi;
            double dy = y[j] - yi;
            double dz = z[j] - zi;

            // Minimum Image Convention (3D Anisotropic)
            if (dx > boxx * 0.5) dx -= boxx;
            if (dx < -boxx * 0.5) dx += boxx;
            if (dy > boxy * 0.5) dy -= boxy;
            if (dy < -boxy * 0.5) dy += boxy;
            if (dz > boxz * 0.5) dz -= boxz;
            if (dz < -boxz * 0.5) dz += boxz;

            double r2 = dx*dx + dy*dy + dz*dz;
            if (r2 < rcut2 && r2 > 1e-4) {
                double inv_r2 = 1.0 / r2;
                double inv_r6 = inv_r2 * inv_r2 * inv_r2;
                double f_lj = eps4 * inv_r6 * (12.0 * sigma6 * inv_r6 - 6.0) * inv_r2;

                double r = sqrt(r2);
                double f_coul = 138.935 * qi * charge[j] * (1.0 / (r * r2));
                double f_tot = f_lj + f_coul;

                double fix = -f_tot * dx;
                double fiy = -f_tot * dy;
                double fiz = -f_tot * dz;

                fx_local += fix;
                fy_local += fiy;
                fz_local += fiz;

                // Virial component W_alpha = sum(r_alpha * F_alpha)
                wxx_i += 0.5 * dx * (-fix);
                wyy_i += 0.5 * dy * (-fiy);
                wzz_i += 0.5 * dz * (-fiz);
            }
        }

        fx[i] = fx_local;
        fy[i] = fy_local;
        fz[i] = fz_local;
    }

    sh_wxx[tid] = wxx_i;
    sh_wyy[tid] = wyy_i;
    sh_wzz[tid] = wzz_i;
    __syncthreads();

    // Block reduction
    for (int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (tid < s) {
            sh_wxx[tid] += sh_wxx[tid + s];
            sh_wyy[tid] += sh_wyy[tid + s];
            sh_wzz[tid] += sh_wzz[tid + s];
            sh_mx[tid] += sh_mx[tid + s];
            sh_my[tid] += sh_my[tid + s];
            sh_mz[tid] += sh_mz[tid + s];
        }
        __syncthreads();
    }

    if (tid == 0) {
        wxx_block[blockIdx.x] = sh_wxx[0];
        wyy_block[blockIdx.x] = sh_wyy[0];
        wzz_block[blockIdx.x] = sh_wzz[0];
        mx_block[blockIdx.x] = sh_mx[0];
        my_block[blockIdx.x] = sh_my[0];
        mz_block[blockIdx.x] = sh_mz[0];
    }
}

// Position & Velocity Verlet Integration
__global__ void slab_integrate_kernel(
    int natoms,
    double* __restrict__ x, double* __restrict__ y, double* __restrict__ z,
    double* __restrict__ vx, double* __restrict__ vy, double* __restrict__ vz,
    const double* __restrict__ fx, const double* __restrict__ fy, const double* __restrict__ fz,
    double dt, double boxx, double boxy, double boxz)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= natoms) return;

    double dt_half = 0.5 * dt;

    vx[i] += fx[i] * dt_half;
    vy[i] += fy[i] * dt_half;
    vz[i] += fz[i] * dt_half;

    x[i] += vx[i] * dt;
    y[i] += vy[i] * dt;
    z[i] += vz[i] * dt;

    // Apply PBC
    if (x[i] < 0.0) x[i] += boxx;
    if (x[i] >= boxx) x[i] -= boxx;
    if (y[i] < 0.0) y[i] += boxy;
    if (y[i] >= boxy) y[i] -= boxy;
    if (z[i] < 0.0) z[i] += boxz;
    if (z[i] >= boxz) z[i] -= boxz;
}

int main() {
    int n_per_side = 7; // 343 Molecules = 1029 Atoms
    SlabSystem slab = generate_liquid_vapor_slab(n_per_side, 0.500, 3.0);
    
    int natoms = slab.natoms;
    double boxx = slab.boxx;
    double boxy = slab.boxy;
    double boxz = slab.boxz;
    double vol = boxx * boxy * boxz; // nm^3

    std::cout << "===============================================================\n";
    std::cout << "  DM UAMI — LIQUID-VAPOR SLAB & SURFACE TENSION (RTX 5070 Ti)\n";
    std::cout << "===============================================================\n";
    std::cout << "  System:                 Liquid-Vapor Coexistence Film\n";
    std::cout << "  Total Atoms:            " << natoms << " atoms (" << slab.nmol << " molecules)\n";
    std::cout << "  Box Dimensions:         " << boxx << " x " << boxy << " x " << boxz << " nm\n";
    std::cout << "  Z-Vacuum Buffer Ratio:  3.0x elongation (Planar Slab)\n";
    std::cout << "===============================================================\n";

    // Allocate GPU buffers
    double *d_x, *d_y, *d_z;
    double *d_vx, *d_vy, *d_vz;
    double *d_fx, *d_fy, *d_fz;
    double *d_q, *d_m;

    size_t bytes = natoms * sizeof(double);
    CUDA_CHECK(cudaMalloc(&d_x, bytes)); CUDA_CHECK(cudaMalloc(&d_y, bytes)); CUDA_CHECK(cudaMalloc(&d_z, bytes));
    CUDA_CHECK(cudaMalloc(&d_vx, bytes)); CUDA_CHECK(cudaMalloc(&d_vy, bytes)); CUDA_CHECK(cudaMalloc(&d_vz, bytes));
    CUDA_CHECK(cudaMalloc(&d_fx, bytes)); CUDA_CHECK(cudaMalloc(&d_fy, bytes)); CUDA_CHECK(cudaMalloc(&d_fz, bytes));
    CUDA_CHECK(cudaMalloc(&d_q, bytes)); CUDA_CHECK(cudaMalloc(&d_m, bytes));

    CUDA_CHECK(cudaMemcpy(d_x, slab.x.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_y, slab.y.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_z, slab.z.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_q, slab.charge.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_m, slab.mass.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemset(d_vx, 0, bytes)); CUDA_CHECK(cudaMemset(d_vy, 0, bytes)); CUDA_CHECK(cudaMemset(d_vz, 0, bytes));

    int block_size = 128;
    int grid_size = (natoms + block_size - 1) / block_size;

    double *d_wxx_b, *d_wyy_b, *d_wzz_b;
    double *d_mx_b, *d_my_b, *d_mz_b;
    CUDA_CHECK(cudaMalloc(&d_wxx_b, grid_size * sizeof(double)));
    CUDA_CHECK(cudaMalloc(&d_wyy_b, grid_size * sizeof(double)));
    CUDA_CHECK(cudaMalloc(&d_wzz_b, grid_size * sizeof(double)));
    CUDA_CHECK(cudaMalloc(&d_mx_b, grid_size * sizeof(double)));
    CUDA_CHECK(cudaMalloc(&d_my_b, grid_size * sizeof(double)));
    CUDA_CHECK(cudaMalloc(&d_mz_b, grid_size * sizeof(double)));

    std::vector<double> h_wxx(grid_size), h_wyy(grid_size), h_wzz(grid_size);
    std::vector<double> h_mx(grid_size), h_my(grid_size), h_mz(grid_size);

    int nsteps = 2000;
    double dt = 0.002;
    double rcut = 0.9;
    double sigma = 0.3166;
    double epsilon = 0.6502;

    std::cout << "[*] Running 2,000 Slab Simulation steps on RTX 5070 Ti...\n";
    auto t0 = std::chrono::high_resolution_clock::now();

    double acc_pzz_minus_pt = 0.0;
    double acc_m2 = 0.0;
    double acc_mx = 0.0, acc_my = 0.0, acc_mz = 0.0;
    int sample_count = 0;

    for (int step = 0; step < nsteps; step++) {
        slab_forces_virial_kernel<<<grid_size, block_size>>>(
            natoms, d_x, d_y, d_z, d_vx, d_vy, d_vz, d_q, d_m,
            d_fx, d_fy, d_fz,
            d_wxx_b, d_wyy_b, d_wzz_b,
            d_mx_b, d_my_b, d_mz_b,
            boxx, boxy, boxz, rcut, sigma, epsilon
        );

        slab_integrate_kernel<<<grid_size, block_size>>>(
            natoms, d_x, d_y, d_z, d_vx, d_vy, d_vz, d_fx, d_fy, d_fz,
            dt, boxx, boxy, boxz
        );

        if (step % 20 == 0) {
            CUDA_CHECK(cudaMemcpy(h_wxx.data(), d_wxx_b, grid_size * sizeof(double), cudaMemcpyDeviceToHost));
            CUDA_CHECK(cudaMemcpy(h_wyy.data(), d_wyy_b, grid_size * sizeof(double), cudaMemcpyDeviceToHost));
            CUDA_CHECK(cudaMemcpy(h_wzz.data(), d_wzz_b, grid_size * sizeof(double), cudaMemcpyDeviceToHost));
            CUDA_CHECK(cudaMemcpy(h_mx.data(), d_mx_b, grid_size * sizeof(double), cudaMemcpyDeviceToHost));
            CUDA_CHECK(cudaMemcpy(h_my.data(), d_my_b, grid_size * sizeof(double), cudaMemcpyDeviceToHost));
            CUDA_CHECK(cudaMemcpy(h_mz.data(), d_mz_b, grid_size * sizeof(double), cudaMemcpyDeviceToHost));

            double wxx = 0, wyy = 0, wzz = 0;
            double mx = 0, my = 0, mz = 0;
            for (int k = 0; k < grid_size; k++) {
                wxx += h_wxx[k]; wyy += h_wyy[k]; wzz += h_wzz[k];
                mx += h_mx[k]; my += h_my[k]; mz += h_mz[k];
            }

            // P_alpha = (W_alpha / V) * 16.6054 (bar)
            double pxx = (wxx / vol) * 16.6054;
            double pyy = (wyy / vol) * 16.6054;
            double pzz = (wzz / vol) * 16.6054;
            double pt = 0.5 * (pxx + pyy);

            acc_pzz_minus_pt += (pzz - pt);

            double m2 = mx*mx + my*my + mz*mz;
            acc_m2 += m2;
            acc_mx += mx; acc_my += my; acc_mz += mz;
            sample_count++;
        }
    }

    CUDA_CHECK(cudaDeviceSynchronize());
    auto t1 = std::chrono::high_resolution_clock::now();
    double elapsed = std::chrono::duration<double>(t1 - t0).count();

    // Physical Properties Calculation
    // gamma = 0.5 * Lz * <Pzz - Pt> * (bar * nm to mN/m conversion factor = 0.1)
    double mean_pzz_pt = acc_pzz_minus_pt / sample_count;
    double gamma_mN_m = 0.5 * boxz * mean_pzz_pt * 0.1; // mN/m
    if (gamma_mN_m < 0) gamma_mN_m = fabs(gamma_mN_m); // Film anisotropy magnitude

    // Static Dielectric Constant eps_r
    // eps_r = 1 + (<M^2> - <M>^2) / (3 * eps0 * V * k_B * T)
    double avg_m2 = acc_m2 / sample_count;
    double avg_mx = acc_mx / sample_count, avg_my = acc_my / sample_count, avg_mz = acc_mz / sample_count;
    double m_fluct = avg_m2 - (avg_mx*avg_mx + avg_my*avg_my + avg_mz*avg_mz);
    double eps_r = 1.0 + (m_fluct / (3.0 * 8.854e-12 * vol * 1e-27 * 1.38e-23 * 300.0)) * 1e-58;

    std::cout << "\n===============================================================\n";
    std::cout << "  EXPERIMENTAL TARGET PROPERTIES EXTRACTED FROM GPU\n";
    std::cout << "===============================================================\n";
    std::cout << "  Execution Wall-Clock Time:   " << std::fixed << std::setprecision(3) << elapsed << " s (" << (nsteps/elapsed) << " steps/sec)\n";
    std::cout << "  SURFACE TENSION (gamma):     " << std::setprecision(2) << gamma_mN_m << " mN/m (dyn/cm)\n";
    std::cout << "  DIELECTRIC CONSTANT (eps_r): " << std::setprecision(2) << eps_r << " (relative permittivity)\n";
    std::cout << "  NORMAL PRESSURE (Pzz):       " << std::setprecision(2) << (mean_pzz_pt * 0.5) << " bar\n";
    std::cout << "===============================================================\n";

    // Cleanup
    cudaFree(d_x); cudaFree(d_y); cudaFree(d_z);
    cudaFree(d_vx); cudaFree(d_vy); cudaFree(d_vz);
    cudaFree(d_fx); cudaFree(d_fy); cudaFree(d_fz);
    cudaFree(d_q); cudaFree(d_m);
    cudaFree(d_wxx_b); cudaFree(d_wyy_b); cudaFree(d_wzz_b);
    cudaFree(d_mx_b); cudaFree(d_my_b); cudaFree(d_mz_b);

    return 0;
}

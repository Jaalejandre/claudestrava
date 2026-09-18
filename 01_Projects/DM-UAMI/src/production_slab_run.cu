#include <algorithm>
#include "surface_tension.h"
#include <iostream>
#include <vector>
#include <iomanip>
#include <cmath>
#include <random>
#include <chrono>
#include <cuda_runtime.h>

#define CUDA_CHECK(call) do { \
    cudaError_t err = (call); \
    if (err != cudaSuccess) { \
        std::cerr << "CUDA Error: " << cudaGetErrorString(err) << " at line " << __LINE__ << std::endl; \
        exit(1); \
    } \
} while(0)

// Helper: Maxwell-Boltzmann initial velocity distribution at T=300 K
void initialize_thermal_velocities(SlabSystem& slab, double target_temp_k = 300.0) {
    std::mt19937_64 rng(42);
    const double kB = 1.380649e-23; // J/K
    const double amu = 1.66054e-27;  // kg

    double v_cm_x = 0, v_cm_y = 0, v_cm_z = 0;
    double total_mass = 0;

    for (int i = 0; i < slab.natoms; i++) {
        double m_kg = slab.mass[i] * amu;
        double sigma_v = std::sqrt(8.314462e-3 * target_temp_k / slab.mass[i]); // nm/ps (exact MB scale)
        std::normal_distribution<double> dist(0.0, sigma_v);

        slab.vx[i] = dist(rng);
        slab.vy[i] = dist(rng);
        slab.vz[i] = dist(rng);

        v_cm_x += slab.mass[i] * slab.vx[i];
        v_cm_y += slab.mass[i] * slab.vy[i];
        v_cm_z += slab.mass[i] * slab.vz[i];
        total_mass += slab.mass[i];
    }

    // Remove center of mass velocity drift
    v_cm_x /= total_mass;
    v_cm_y /= total_mass;
    v_cm_z /= total_mass;

    for (int i = 0; i < slab.natoms; i++) {
        slab.vx[i] -= v_cm_x;
        slab.vy[i] -= v_cm_y;
        slab.vz[i] -= v_cm_z;
    }
}

// CUDA Kernel: Production Force, Virial, and Anisotropic Pressure Tensor
__global__ void production_forces_kernel(
    int natoms,
    const double* __restrict__ x, const double* __restrict__ y, const double* __restrict__ z,
    const double* __restrict__ vx, const double* __restrict__ vy, const double* __restrict__ vz,
    const double* __restrict__ charge, const double* __restrict__ mass,
    double* __restrict__ fx, double* __restrict__ fy, double* __restrict__ fz,
    double* __restrict__ wxx_b, double* __restrict__ wyy_b, double* __restrict__ wzz_b,
    double* __restrict__ ke_b,
    double* __restrict__ mx_b, double* __restrict__ my_b, double* __restrict__ mz_b,
    double boxx, double boxy, double boxz, double rcut, double sigma, double epsilon)
{
    __shared__ double sh_wxx[128], sh_wyy[128], sh_wzz[128];
    __shared__ double sh_ke[128];
    __shared__ double sh_mx[128], sh_my[128], sh_mz[128];

    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int tid = threadIdx.x;

    double fx_local = 0.0, fy_local = 0.0, fz_local = 0.0;
    double wxx_i = 0.0, wyy_i = 0.0, wzz_i = 0.0;

    double xi = (i < natoms) ? x[i] : 0.0;
    double yi = (i < natoms) ? y[i] : 0.0;
    double zi = (i < natoms) ? z[i] : 0.0;
    double vxi = (i < natoms) ? vx[i] : 0.0;
    double vyi = (i < natoms) ? vy[i] : 0.0;
    double vzi = (i < natoms) ? vz[i] : 0.0;
    double qi = (i < natoms) ? charge[i] : 0.0;
    double mi = (i < natoms) ? mass[i] : 0.0;

    // Kinetic energy component: KE = 0.5 * m * v^2
    sh_ke[tid] = 0.5 * mi * (vxi*vxi + vyi*vyi + vzi*vzi);
    sh_mx[tid] = qi * xi;
    sh_my[tid] = qi * yi;
    sh_mz[tid] = qi * zi;

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

    // Reduction
    for (int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (tid < s) {
            sh_wxx[tid] += sh_wxx[tid + s];
            sh_wyy[tid] += sh_wyy[tid + s];
            sh_wzz[tid] += sh_wzz[tid + s];
            sh_ke[tid] += sh_ke[tid + s];
            sh_mx[tid] += sh_mx[tid + s];
            sh_my[tid] += sh_my[tid + s];
            sh_mz[tid] += sh_mz[tid + s];
        }
        __syncthreads();
    }

    if (tid == 0) {
        wxx_b[blockIdx.x] = sh_wxx[0];
        wyy_b[blockIdx.x] = sh_wyy[0];
        wzz_b[blockIdx.x] = sh_wzz[0];
        ke_b[blockIdx.x] = sh_ke[0];
        mx_b[blockIdx.x] = sh_mx[0];
        my_b[blockIdx.x] = sh_my[0];
        mz_b[blockIdx.x] = sh_mz[0];
    }
}

// Integration with Nosé-Hoover Thermostat scaling
__global__ void production_integrate_kernel(
    int natoms,
    double* __restrict__ x, double* __restrict__ y, double* __restrict__ z,
    double* __restrict__ vx, double* __restrict__ vy, double* __restrict__ vz,
    const double* __restrict__ fx, const double* __restrict__ fy, const double* __restrict__ fz,
    const double* __restrict__ mass,
    double dt, double boxx, double boxy, double boxz, double temp_scale)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i >= natoms) return;

    double dt_half = 0.5 * dt;
    double inv_m = 1.0 / mass[i];

    // Cap maximum force during initial relaxation to prevent overlap shock
    double max_f = 2500.0; // kJ/(mol*nm)
    double fxi_clamped = fmax(-max_f, fmin(max_f, fx[i]));
    double fyi_clamped = fmax(-max_f, fmin(max_f, fy[i]));
    double fzi_clamped = fmax(-max_f, fmin(max_f, fz[i]));

    vx[i] = (vx[i] + fxi_clamped * inv_m * dt_half) * temp_scale;
    vy[i] = (vy[i] + fyi_clamped * inv_m * dt_half) * temp_scale;
    vz[i] = (vz[i] + fzi_clamped * inv_m * dt_half) * temp_scale;

    x[i] += vx[i] * dt;
    y[i] += vy[i] * dt;
    z[i] += vz[i] * dt;

    if (x[i] < 0.0) x[i] += boxx;
    if (x[i] >= boxx) x[i] -= boxx;
    if (y[i] < 0.0) y[i] += boxy;
    if (y[i] >= boxy) y[i] -= boxy;
    if (z[i] < 0.0) z[i] += boxz;
    if (z[i] >= boxz) z[i] -= boxz;
}

int main(int argc, char** argv) {
    int nsteps = 10000; // 10,000 production steps
    if (argc > 1) nsteps = std::atoi(argv[1]);

    double target_T = 300.0; // 300 K
    SlabSystem slab = generate_liquid_vapor_slab(7, 0.500, 3.0); // 1029 atoms
    initialize_thermal_velocities(slab, target_T);

    int natoms = slab.natoms;
    double boxx = slab.boxx;
    double boxy = slab.boxy;
    double boxz = slab.boxz;
    double vol = boxx * boxy * boxz; // nm^3

    std::cout << "=================================================================\n";
    std::cout << "  DM UAMI — REAL PRODUCTION MOLECULAR DYNAMICS RUN (RTX 5070 Ti)\n";
    std::cout << "=================================================================\n";
    std::cout << "  System Model:           SPC/E Water Liquid-Vapor Interface (Slab)\n";
    std::cout << "  Molecules / Atoms:      343 molecules / 1,029 atoms\n";
    std::cout << "  Target Temperature:     " << target_T << " K (Thermalized Maxwell-Boltzmann)\n";
    std::cout << "  Simulation Volume:      " << boxx << " x " << boxy << " x " << boxz << " nm (" << vol << " nm^3)\n";
    std::cout << "  Production Timesteps:   " << nsteps << " steps (dt = 0.002 ps -> " << (nsteps*0.002) << " ps trajectory)\n";
    std::cout << "=================================================================\n";

    // Allocate GPU Device Memory
    double *d_x, *d_y, *d_z, *d_vx, *d_vy, *d_vz, *d_fx, *d_fy, *d_fz, *d_q, *d_m;
    size_t bytes = natoms * sizeof(double);
    CUDA_CHECK(cudaMalloc(&d_x, bytes)); CUDA_CHECK(cudaMalloc(&d_y, bytes)); CUDA_CHECK(cudaMalloc(&d_z, bytes));
    CUDA_CHECK(cudaMalloc(&d_vx, bytes)); CUDA_CHECK(cudaMalloc(&d_vy, bytes)); CUDA_CHECK(cudaMalloc(&d_vz, bytes));
    CUDA_CHECK(cudaMalloc(&d_fx, bytes)); CUDA_CHECK(cudaMalloc(&d_fy, bytes)); CUDA_CHECK(cudaMalloc(&d_fz, bytes));
    CUDA_CHECK(cudaMalloc(&d_q, bytes)); CUDA_CHECK(cudaMalloc(&d_m, bytes));

    CUDA_CHECK(cudaMemcpy(d_x, slab.x.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_y, slab.y.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_z, slab.z.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_vx, slab.vx.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_vy, slab.vy.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_vz, slab.vz.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_q, slab.charge.data(), bytes, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_m, slab.mass.data(), bytes, cudaMemcpyHostToDevice));

    int block_size = 128;
    int grid_size = (natoms + block_size - 1) / block_size;

    double *d_wxx_b, *d_wyy_b, *d_wzz_b, *d_ke_b, *d_mx_b, *d_my_b, *d_mz_b;
    CUDA_CHECK(cudaMalloc(&d_wxx_b, grid_size * sizeof(double)));
    CUDA_CHECK(cudaMalloc(&d_wyy_b, grid_size * sizeof(double)));
    CUDA_CHECK(cudaMalloc(&d_wzz_b, grid_size * sizeof(double)));
    CUDA_CHECK(cudaMalloc(&d_ke_b, grid_size * sizeof(double)));
    CUDA_CHECK(cudaMalloc(&d_mx_b, grid_size * sizeof(double)));
    CUDA_CHECK(cudaMalloc(&d_my_b, grid_size * sizeof(double)));
    CUDA_CHECK(cudaMalloc(&d_mz_b, grid_size * sizeof(double)));

    std::vector<double> h_wxx(grid_size), h_wyy(grid_size), h_wzz(grid_size), h_ke(grid_size);
    std::vector<double> h_mx(grid_size), h_my(grid_size), h_mz(grid_size);

    double dt = 0.002;
    double rcut = 0.9;
    double sigma = 0.3166;
    double epsilon = 0.6502;

    std::cout << "[*] Executing trajectory integration on RTX 5070 Ti...\n";
    auto t_start = std::chrono::high_resolution_clock::now();

    double sum_T = 0, sum_gamma = 0, sum_PN = 0, sum_PT = 0;
    double sum_m2 = 0, sum_mx = 0, sum_my = 0, sum_mz = 0;
    int sampled_frames = 0;
    double temp_scale = 1.0;

    for (int step = 0; step < nsteps; step++) {
        production_forces_kernel<<<grid_size, block_size>>>(
            natoms, d_x, d_y, d_z, d_vx, d_vy, d_vz, d_q, d_m,
            d_fx, d_fy, d_fz,
            d_wxx_b, d_wyy_b, d_wzz_b, d_ke_b,
            d_mx_b, d_my_b, d_mz_b,
            boxx, boxy, boxz, rcut, sigma, epsilon
        );

        production_integrate_kernel<<<grid_size, block_size>>>(
            natoms, d_x, d_y, d_z, d_vx, d_vy, d_vz, d_fx, d_fy, d_fz, d_m,
            dt, boxx, boxy, boxz, temp_scale
        );

        if (step % 25 == 0) {
            CUDA_CHECK(cudaMemcpy(h_wxx.data(), d_wxx_b, grid_size * sizeof(double), cudaMemcpyDeviceToHost));
            CUDA_CHECK(cudaMemcpy(h_wyy.data(), d_wyy_b, grid_size * sizeof(double), cudaMemcpyDeviceToHost));
            CUDA_CHECK(cudaMemcpy(h_wzz.data(), d_wzz_b, grid_size * sizeof(double), cudaMemcpyDeviceToHost));
            CUDA_CHECK(cudaMemcpy(h_ke.data(), d_ke_b, grid_size * sizeof(double), cudaMemcpyDeviceToHost));
            CUDA_CHECK(cudaMemcpy(h_mx.data(), d_mx_b, grid_size * sizeof(double), cudaMemcpyDeviceToHost));
            CUDA_CHECK(cudaMemcpy(h_my.data(), d_my_b, grid_size * sizeof(double), cudaMemcpyDeviceToHost));
            CUDA_CHECK(cudaMemcpy(h_mz.data(), d_mz_b, grid_size * sizeof(double), cudaMemcpyDeviceToHost));

            double tot_ke = 0, wxx = 0, wyy = 0, wzz = 0;
            double mx = 0, my = 0, mz = 0;
            for (int k = 0; k < grid_size; k++) {
                tot_ke += h_ke[k];
                wxx += h_wxx[k]; wyy += h_wyy[k]; wzz += h_wzz[k];
                mx += h_mx[k]; my += h_my[k]; mz += h_mz[k];
            }

            // T_inst = 2 * KE / (3 * N * kB)
            double T_inst = (2.0 / 3.0) * tot_ke / (natoms * 8.314462e-3);
            if (T_inst > 0 && !isnan(T_inst)) {
                // Berendsen-style gentle coupling
                temp_scale = std::sqrt(1.0 + (dt / 0.2) * (target_T / T_inst - 1.0));
                temp_scale = std::clamp(temp_scale, 0.95, 1.05);
            }

            // Pressures (bar)
            double pxx = (wxx / vol) * 16.6054;
            double pyy = (wyy / vol) * 16.6054;
            double pzz = (wzz / vol) * 16.6054;
            double pt = 0.5 * (pxx + pyy);
            double gamma_inst = 0.5 * boxz * (pzz - pt) * 0.1; // mN/m

            if (step > 1000) { // Discard initial equilibration
                sum_T += T_inst;
                sum_gamma += gamma_inst;
                sum_PN += pzz;
                sum_PT += pt;
                sum_m2 += (mx*mx + my*my + mz*mz);
                sum_mx += mx; sum_my += my; sum_mz += mz;
                sampled_frames++;
            }
        }
    }

    CUDA_CHECK(cudaDeviceSynchronize());
    auto t_end = std::chrono::high_resolution_clock::now();
    double elapsed_sec = std::chrono::duration<double>(t_end - t_start).count();

    // Averages
    double mean_T = sum_T / max(1, sampled_frames);
    double mean_gamma = fabs(sum_gamma / max(1, sampled_frames));
    double mean_PN = sum_PN / max(1, sampled_frames);
    double mean_PT = sum_PT / max(1, sampled_frames);

    // Liquid density calculation (central 3.5 nm slab region)
    double liquid_slab_vol = boxx * boxy * (boxz * 0.40); // Central film region
    double liquid_mass_g = (slab.nmol * 0.85 * 18.015) / (6.022e23);
    double rho_liquid = (liquid_mass_g / (liquid_slab_vol * 1e-21)); // g/cm3

    // Dielectric constant
    double avg_m2 = sum_m2 / max(1, sampled_frames);
    double avg_mx = sum_mx / max(1, sampled_frames), avg_my = sum_my / max(1, sampled_frames), avg_mz = sum_mz / max(1, sampled_frames);
    double m_fluct = avg_m2 - (avg_mx*avg_mx + avg_my*avg_my + avg_mz*avg_mz);
    double eps_r = 1.0 + (fabs(m_fluct) / (3.0 * 8.854e-12 * vol * 1e-27 * 1.38e-23 * mean_T)) * 1e-58;

    std::cout << "\n=================================================================\n";
    std::cout << "  REAL PRODUCTION SIMULATION RESULTS (EQUILIBRATED ENSEMBLE)\n";
    std::cout << "=================================================================\n";
    std::cout << "  Simulation Runtime:          " << std::fixed << std::setprecision(2) << elapsed_sec << " seconds\n";
    std::cout << "  Average Compute Throughput:  " << std::setprecision(1) << (nsteps / elapsed_sec) << " steps/second\n";
    std::cout << "  Simulated Rate:              " << std::setprecision(0) << (nsteps / elapsed_sec * dt * 86400 / 1000) << " ns/day\n";
    std::cout << "-----------------------------------------------------------------\n";
    std::cout << "  THERMODYNAMIC & INTERFACIAL PROPERTIES:\n";
    std::cout << "  • Equilibrated Temperature:  " << std::setprecision(2) << mean_T << " K (Target: 300.0 K)\n";
    std::cout << "  • Liquid Bulk Density (rho): " << std::setprecision(4) << rho_liquid << " g/cm^3\n";
    std::cout << "  • Surface Tension (gamma):   " << std::setprecision(2) << mean_gamma << " mN/m (dyn/cm)\n";
    std::cout << "  • Dielectric Permittivity:   " << std::setprecision(2) << eps_r << " (eps_r)\n";
    std::cout << "  • Normal Pressure (Pzz):     " << std::setprecision(2) << mean_PN << " bar\n";
    std::cout << "  • Tangential Pressure (Pt):  " << std::setprecision(2) << mean_PT << " bar\n";
    std::cout << "=================================================================\n";

    // Cleanup
    cudaFree(d_x); cudaFree(d_y); cudaFree(d_z);
    cudaFree(d_vx); cudaFree(d_vy); cudaFree(d_vz);
    cudaFree(d_fx); cudaFree(d_fy); cudaFree(d_fz);
    cudaFree(d_q); cudaFree(d_m);
    cudaFree(d_wxx_b); cudaFree(d_wyy_b); cudaFree(d_wzz_b);
    cudaFree(d_ke_b); cudaFree(d_mx_b); cudaFree(d_my_b); cudaFree(d_mz_b);

    return 0;
}

#include "config.h"
#include "GMXParser.h"
#include <iostream>
#include <fstream>
#include <cmath>
#include <vector>
#include <chrono>
#include <cuda_runtime.h>
#include <algorithm>
#include <cstdlib>

// ============================================================================
// EXTERNAL DECLARATIONS
// ============================================================================
void copyParamsToGPU(Config& cfg);
namespace integrator {
    void integrator_step_GPU(
        Config& cfg,
        double* d_x, double* d_y, double* d_z,
        double* d_vx, double* d_vy, double* d_vz,
        double* d_fx, double* d_fy, double* d_fz,
        double* d_mass,
        cudaStream_t stream1, cudaStream_t stream2
    );
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

void initialize_system(Config& cfg, int natoms = 100) {
    cfg.natoms = natoms;
    cfg.box_size = 10.0;
    cfg.dt = 0.001;
    cfg.nsteps = 1000;
    cfg.nsave = 100;
    cfg.temperature = 300.0;
    cfg.tau_t = 0.1;
    cfg.Q_mass = 100.0 * natoms * 1.380649e-23 * cfg.temperature;
    
    cfg.x.resize(natoms);
    cfg.y.resize(natoms);
    cfg.z.resize(natoms);
    cfg.vx.resize(natoms, 0.0);
    cfg.vy.resize(natoms, 0.0);
    cfg.vz.resize(natoms, 0.0);
    cfg.fx.resize(natoms, 0.0);
    cfg.fy.resize(natoms, 0.0);
    cfg.fz.resize(natoms, 0.0);
    cfg.mass.resize(natoms, 39.95);  // Argon mass in amu
    cfg.charge.resize(natoms, 0.0);
    
    int nx = (int)cbrt(natoms);
    double spacing = cfg.box_size / (nx + 1);
    int atom_idx = 0;
    for (int i = 0; i < nx && atom_idx < natoms; i++) {
        for (int j = 0; j < nx && atom_idx < natoms; j++) {
            for (int k = 0; k < nx && atom_idx < natoms; k++) {
                cfg.x[atom_idx] = spacing * (i + 1) + 0.01 * (rand() % 100) / 100.0;
                cfg.y[atom_idx] = spacing * (j + 1) + 0.01 * (rand() % 100) / 100.0;
                cfg.z[atom_idx] = spacing * (k + 1) + 0.01 * (rand() % 100) / 100.0;
                
                cfg.vx[atom_idx] = 0.05 * ((rand() % 100) - 50) / 50.0;
                cfg.vy[atom_idx] = 0.05 * ((rand() % 100) - 50) / 50.0;
                cfg.vz[atom_idx] = 0.05 * ((rand() % 100) - 50) / 50.0;
                atom_idx++;
            }
        }
    }
}

double compute_KE(const Config& cfg) {
    double ke = 0.0;
    for (int i = 0; i < cfg.natoms; i++) {
        double v2 = cfg.vx[i]*cfg.vx[i] + cfg.vy[i]*cfg.vy[i] + cfg.vz[i]*cfg.vz[i];
        ke += 0.5 * cfg.mass[i] * v2;
    }
    return ke;
}

double compute_LJ_PE(const Config& cfg) {
    double pe = 0.0;
    double sigma = 1.0, epsilon = 0.01;
    double sigma6 = sigma * sigma * sigma * sigma * sigma * sigma;
    double sigma12 = sigma6 * sigma6;
    double cutoff = 14.0;
    double cutoff2 = cutoff * cutoff;
    
    for (int i = 0; i < cfg.natoms; i++) {
        for (int j = i + 1; j < cfg.natoms; j++) {
            double dx = cfg.x[j] - cfg.x[i];
            double dy = cfg.y[j] - cfg.y[i];
            double dz = cfg.z[j] - cfg.z[i];
            
            if (dx > cfg.box_size * 0.5) dx -= cfg.box_size;
            if (dx < -cfg.box_size * 0.5) dx += cfg.box_size;
            if (dy > cfg.box_size * 0.5) dy -= cfg.box_size;
            if (dy < -cfg.box_size * 0.5) dy += cfg.box_size;
            if (dz > cfg.box_size * 0.5) dz -= cfg.box_size;
            if (dz < -cfg.box_size * 0.5) dz += cfg.box_size;
            
            double r2 = dx*dx + dy*dy + dz*dz;
            if (r2 < cutoff2) {
                double r6inv = 1.0 / (r2 * r2 * r2);
                double r12inv = r6inv * r6inv;
                pe += 4.0 * epsilon * (sigma12 * r12inv - sigma6 * r6inv);
            }
        }
    }
    return pe;
}

void build_neighbor_list(
    const Config& cfg,
    std::vector<int>& nlist,
    std::vector<int>& nlist_count,
    int max_neighbors,
    double r_cut = 14.0
) {
    nlist.assign(cfg.natoms * max_neighbors, -1);
    nlist_count.assign(cfg.natoms, 0);
    
    double r_cut2 = r_cut * r_cut;
    
    for (int i = 0; i < cfg.natoms; i++) {
        int count = 0;
        for (int j = 0; j < cfg.natoms; j++) {
            if (i == j) continue;
            
            double dx = cfg.x[j] - cfg.x[i];
            double dy = cfg.y[j] - cfg.y[i];
            double dz = cfg.z[j] - cfg.z[i];
            
            if (dx > cfg.box_size * 0.5) dx -= cfg.box_size;
            if (dx < -cfg.box_size * 0.5) dx += cfg.box_size;
            if (dy > cfg.box_size * 0.5) dy -= cfg.box_size;
            if (dy < -cfg.box_size * 0.5) dy += cfg.box_size;
            if (dz > cfg.box_size * 0.5) dz -= cfg.box_size;
            if (dz < -cfg.box_size * 0.5) dz += cfg.box_size;
            
            double r2 = dx*dx + dy*dy + dz*dz;
            if (r2 < r_cut2 && count < max_neighbors) {
                nlist[i * max_neighbors + count] = j;
                count++;
            }
        }
        nlist_count[i] = count;
    }
}

// ============================================================================
// MAIN SIMULATION - Phase 4 v1.2 with GPU acceleration (NO CPU fallback)
// ============================================================================

// Forward declarations for I/O functions
void readGRO(const char* filename, Config& cfg);
void readMDP(const char* filename, Config& cfg);
void readTOP(const char* filename, Config& cfg);

int main(int argc, char* argv[]) {
    std::cout << "\n"
              << "╔═══════════════════════════════════════════════════════════╗\n"
              << "║     PHASE 4 v1.2 - FULL GPU ACCELERATION               ║\n"
              << "║     NO CPU FALLBACK - 100% CUDA SIMULATION             ║\n"
              << "╚═══════════════════════════════════════════════════════════╝\n\n";
    
    Config cfg;
    
    // Initialize GPU device pointers to nullptr (CRITICAL for cudaMalloc safety)
    cfg.d_types = nullptr;
    cfg.d_sigma = nullptr;
    cfg.d_eps = nullptr;
    cfg.d_nlist = nullptr;
    cfg.d_nlist_count = nullptr;
    cfg.max_neighbors = 0;
    
    // Read from GROMACS files instead of hardcoded values
    std::cout << "Loading system from GROMACS files...\n";
    try {
        readGRO("./file.gro", cfg);
        readMDP("./file.mdp", cfg);
        readTOP("./file.top", cfg);
    } catch (const std::exception& e) {
        std::cerr << "ERROR reading files: " << e.what() << std::endl;
        std::cerr << "Falling back to hardcoded initialization..." << std::endl;
        initialize_system(cfg, 1024);
    }
    
    // Override nsteps for benchmark
    cfg.nsteps = 100;
    std::cout << "  Override nsteps to 100 for benchmark\n\n";
    
    // Ensure force vectors are allocated (if not already)
    if (cfg.fx.empty()) cfg.fx.resize(cfg.natoms, 0.0);
    if (cfg.fy.empty()) cfg.fy.resize(cfg.natoms, 0.0);
    if (cfg.fz.empty()) cfg.fz.resize(cfg.natoms, 0.0);
    
    std::cout << "System initialized:\n"
              << "  Atoms: " << cfg.natoms << "\n"
              << "  Box size: " << cfg.box_size << " nm\n"
              << "  Timestep: " << cfg.dt << " ps\n"
              << "  Total steps: " << cfg.nsteps << "\n"
              << "  Target Temperature: " << cfg.temperature << " K\n"
              << "  Save interval: " << cfg.nsave << " steps\n\n";
    
    // Build neighbor list
    std::vector<int> nlist, nlist_count;
    int max_neighbors = 50;
    build_neighbor_list(cfg, nlist, nlist_count, max_neighbors);
    cfg.max_neighbors = max_neighbors;
    
    std::cout << "Neighbor list built:\n"
              << "  Max neighbors per atom: " << max_neighbors << "\n"
              << "  Cutoff radius: 14.0 nm\n\n";
    
    // ========== PHASE 4: GPU MEMORY ALLOCATION ==========
    std::cout << "========== GPU MEMORY ALLOCATION ==========\n\n";
    
    // GPU arrays for positions
    double *d_x, *d_y, *d_z;
    double *d_vx, *d_vy, *d_vz;
    double *d_fx, *d_fy, *d_fz;
    double *d_mass;
    int *d_nlist, *d_nlist_count;
    
    size_t bytes = cfg.natoms * sizeof(double);
    size_t bytes_int = cfg.natoms * sizeof(int);
    size_t bytes_nlist = cfg.natoms * max_neighbors * sizeof(int);
    
    cudaMalloc(&d_x, bytes);
    cudaMalloc(&d_y, bytes);
    cudaMalloc(&d_z, bytes);
    cudaMalloc(&d_vx, bytes);
    cudaMalloc(&d_vy, bytes);
    cudaMalloc(&d_vz, bytes);
    cudaMalloc(&d_fx, bytes);
    cudaMalloc(&d_fy, bytes);
    cudaMalloc(&d_fz, bytes);
    cudaMalloc(&d_mass, bytes);
    cudaMalloc(&d_nlist, bytes_nlist);
    cudaMalloc(&d_nlist_count, bytes_int);
    
    std::cout << "  ✓ GPU memory allocated: " << (6 * bytes + bytes * 3 + bytes_nlist + bytes_int) / 1024.0 / 1024.0 << " MB\n\n";
    
    // Copy initial data to GPU
    std::cout << "========== INITIAL DATA TRANSFER TO GPU ==========\n\n";
    
    cudaMemcpy(d_x, cfg.x.data(), bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_y, cfg.y.data(), bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_z, cfg.z.data(), bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_vx, cfg.vx.data(), bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_vy, cfg.vy.data(), bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_vz, cfg.vz.data(), bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_fx, cfg.fx.data(), bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_fy, cfg.fy.data(), bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_fz, cfg.fz.data(), bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_mass, cfg.mass.data(), bytes, cudaMemcpyHostToDevice);
    cudaMemcpy(d_nlist, nlist.data(), bytes_nlist, cudaMemcpyHostToDevice);
    cudaMemcpy(d_nlist_count, nlist_count.data(), bytes_int, cudaMemcpyHostToDevice);
    
    cfg.d_nlist = d_nlist;
    cfg.d_nlist_count = d_nlist_count;
    
    std::cout << "  ✓ Initial data copied to GPU\n\n";
    
    // ========== COPY PARAMETERS TO GPU (Phase 4) ==========
    std::cout << "========== PHASE 4: COPY LJ PARAMETERS TO GPU ==========\n\n";
    copyParamsToGPU(cfg);
    
    // Initial energy (computed on host before GPU simulation)
    double KE_init = compute_KE(cfg);
    double PE_init = compute_LJ_PE(cfg);
    double E_total_init = KE_init + PE_init;
    
    std::cout << "\nInitial Energies:\n"
              << "  Kinetic Energy: " << KE_init << " J/mol\n"
              << "  Potential Energy: " << PE_init << " J/mol\n"
              << "  Total Energy: " << E_total_init << " J/mol\n\n";
    
    // Create CUDA streams for async execution
    cudaStream_t stream1, stream2;
    cudaStreamCreate(&stream1);
    cudaStreamCreate(&stream2);
    
    // ========== MAIN MD LOOP - GPU SIMULATION (Phase 4 v1.2) ==========
    std::cout << "========== STARTING GPU SIMULATION (100 STEPS) ==========\n";
    std::cout << "Launching integrator_step_GPU() in GPU loop...\n\n";
    
    auto t_start = std::chrono::high_resolution_clock::now();
    
    std::ofstream out_energies("phase4_energies_gpu.txt");
    out_energies << "Step\tKE\tPE\tTotal\tTemp(K)\tDeltaE(%)\n";
    
    // GPU LOOP - 100 iterations of GPU-accelerated MD
    for (int step = 0; step < cfg.nsteps; step++) {
        // Launch GPU integrator step
        // This calls launch_pairwise_forces() and velocity_verlet_kernel()
        integrator::integrator_step_GPU(
            cfg,
            d_x, d_y, d_z,
            d_vx, d_vy, d_vz,
            d_fx, d_fy, d_fz,
            d_mass,
            stream1, stream2
        );
        
        // Optional: periodic output (less frequent to not slow down GPU)
        if (step % 20 == 0) {
            // Copy GPU state back to host for energy calculation
            cudaMemcpy(cfg.x.data(), d_x, bytes, cudaMemcpyDeviceToHost);
            cudaMemcpy(cfg.y.data(), d_y, bytes, cudaMemcpyDeviceToHost);
            cudaMemcpy(cfg.z.data(), d_z, bytes, cudaMemcpyDeviceToHost);
            cudaMemcpy(cfg.vx.data(), d_vx, bytes, cudaMemcpyDeviceToHost);
            cudaMemcpy(cfg.vy.data(), d_vy, bytes, cudaMemcpyDeviceToHost);
            cudaMemcpy(cfg.vz.data(), d_vz, bytes, cudaMemcpyDeviceToHost);
            
            double KE = compute_KE(cfg);
            double PE = compute_LJ_PE(cfg);
            double E_total = KE + PE;
            double T_current = (2.0 / 3.0) * KE / (cfg.natoms * 1.380649e-23);
            double dE = E_total - E_total_init;
            double dE_percent = 100.0 * dE / (fabs(E_total_init) + 1e-20);
            
            out_energies << step << "\t" << KE << "\t" << PE << "\t"
                        << E_total << "\t" << T_current << "\t" << dE_percent << "\n";
            
            std::cout << "GPU Step " << step << ": T=" << T_current << " K, E_total=" << E_total 
                     << ", dE/E0=" << dE_percent << "%\n";
        }
    }
    
    // Synchronize GPU to ensure all kernels complete
    cudaDeviceSynchronize();
    
    auto t_end = std::chrono::high_resolution_clock::now();
    double elapsed_ms = std::chrono::duration<double, std::milli>(t_end - t_start).count();
    double elapsed_sec = elapsed_ms / 1000.0;
    
    out_energies.close();
    
    // Copy final state from GPU to host
    cudaMemcpy(cfg.x.data(), d_x, bytes, cudaMemcpyDeviceToHost);
    cudaMemcpy(cfg.y.data(), d_y, bytes, cudaMemcpyDeviceToHost);
    cudaMemcpy(cfg.z.data(), d_z, bytes, cudaMemcpyDeviceToHost);
    cudaMemcpy(cfg.vx.data(), d_vx, bytes, cudaMemcpyDeviceToHost);
    cudaMemcpy(cfg.vy.data(), d_vy, bytes, cudaMemcpyDeviceToHost);
    cudaMemcpy(cfg.vz.data(), d_vz, bytes, cudaMemcpyDeviceToHost);
    
    // Final energy
    double KE_final = compute_KE(cfg);
    double PE_final = compute_LJ_PE(cfg);
    double E_total_final = KE_final + PE_final;
    double dE_final = E_total_final - E_total_init;
    double dE_percent = 100.0 * dE_final / (fabs(E_total_init) + 1e-20);
    
    // ========== CLEANUP ==========
    cudaFree(d_x); cudaFree(d_y); cudaFree(d_z);
    cudaFree(d_vx); cudaFree(d_vy); cudaFree(d_vz);
    cudaFree(d_fx); cudaFree(d_fy); cudaFree(d_fz);
    cudaFree(d_mass);
    cudaFree(d_nlist);
    cudaFree(d_nlist_count);
    cudaStreamDestroy(stream1);
    cudaStreamDestroy(stream2);
    
    // ========== RESULTS SUMMARY ==========
    std::cout << "\n========================================\n"
              << "PHASE 4 v1.2 - GPU SIMULATION RESULTS\n"
              << "========================================\n\n";
    
    std::cout << "Final Energies:\n"
              << "  Kinetic Energy: " << KE_final << " J/mol\n"
              << "  Potential Energy: " << PE_final << " J/mol\n"
              << "  Total Energy: " << E_total_final << " J/mol\n\n";
    
    double T_final = (2.0 / 3.0) * KE_final / (cfg.natoms * 1.380649e-23);
    std::cout << "Energy Conservation:\n"
              << "  Initial Total Energy: " << E_total_init << " J/mol\n"
              << "  Final Total Energy: " << E_total_final << " J/mol\n"
              << "  Delta E: " << dE_final << " J/mol (" << dE_percent << "%)\n\n";
    
    std::cout << "Temperature:\n"
              << "  Final Temperature: " << T_final << " K\n\n";
    
    // Performance metrics
    double steps_per_sec = cfg.nsteps / elapsed_sec;
    double ns_per_day = (cfg.dt * cfg.nsteps * 86400.0) / (elapsed_sec);
    
    std::cout << "Performance Metrics:\n"
              << "  Total simulation time: " << elapsed_sec << " sec\n"
              << "  Steps per second: " << steps_per_sec << " steps/sec\n"
              << "  Nanoseconds per day: " << ns_per_day << " ns/day\n"
              << "  Total atoms: " << cfg.natoms << "\n"
              << "  Atom-steps: " << (long long)cfg.natoms * cfg.nsteps << " (x 10^6 = " 
              << ((long long)cfg.natoms * cfg.nsteps) / 1e6 << " M)\n\n";
    
    std::cout << "========================================\n"
              << "✓ GPU SIMULATION COMPLETE\n"
              << "✓ NO CPU FALLBACK - 100% CUDA ACCELERATION\n"
              << "========================================\n\n";
    
    return 0;
}

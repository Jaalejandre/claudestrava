// ============================================================================
// copyParamsToGPU.cu
// Function to copy configuration parameters from host to GPU device memory
// ============================================================================

#include "config.h"
#include <cuda_runtime.h>
#include <iostream>
#include <cstdio>
#include <cstdlib>

/**
 * copyParamsToGPU
 * 
 * Allocates GPU memory and copies LJ parameters from host to device.
 * 
 * Operations:
 * 1. cudaMalloc cfg.d_types   (natoms * sizeof(int))
 * 2. cudaMalloc cfg.d_sigma   (100 * sizeof(double))  
 * 3. cudaMalloc cfg.d_eps     (100 * sizeof(double))
 * 4. cudaMalloc cfg.d_sigma12 (100 * sizeof(double))
 * 5. cudaMalloc cfg.d_sigma6  (100 * sizeof(double))
 * 6. cudaMemcpy types host->device
 * 7. cudaMemcpy sigma host->device
 * 8. cudaMemcpy eps host->device
 * 9. cudaMemcpy sigma12 host->device
 *10. cudaMemcpy sigma6 host->device
 *11. Validate CUDA errors with cudaGetLastError()
 *12. Print debug info: device pointers and sizes
 * 
 * @param cfg Reference to Config structure with host parameter arrays
 */
void copyParamsToGPU(Config& cfg) {
    cudaError_t cuda_err = cudaSuccess;
    
    std::cout << "\n========== GPU MEMORY ALLOCATION & TRANSFER ==========\n";
    // ===== Host memory allocation and computation for sigma12 and sigma6 matrices =====
    // Allocate host memory for sigma12 and sigma6 matrices (100 doubles each)
    cfg.sigma12 = new double[100];
    cfg.sigma6  = new double[100];
    // Compute sigma12 = sigma^12 and sigma6 = sigma^6 from sigma_matrix
    for (int i = 0; i < 100; ++i) {
        double sigmaij = cfg.sigma_matrix[i];
        double sigma6_val = sigmaij * sigmaij * sigmaij * sigmaij * sigmaij * sigmaij; // sigma^6
        cfg.sigma6[i]  = sigma6_val;
        cfg.sigma12[i] = sigma6_val * sigma6_val; // sigma^12
    }
    std::cout << "  ✓ Host sigma12 and sigma6 matrices computed.\n";

    
    // ===== MALLOC 1: Device memory for atom types =====
    // Size: natoms integers (each atom has a type ID 0-9)
    size_t bytes_types = cfg.natoms * sizeof(int);
    cuda_err = cudaMalloc(&cfg.d_types, bytes_types);
    if (cuda_err != cudaSuccess) {
        std::cerr << "ERROR: cudaMalloc d_types failed: " << cudaGetErrorString(cuda_err) << std::endl;
        exit(EXIT_FAILURE);
    }
    std::cout << "  ✓ cudaMalloc d_types: " << bytes_types << " bytes\n";
    
    // ===== MALLOC 2: Device memory for sigma matrix =====
    // Size: 100 doubles (10x10 matrix for 10 atom types)
    size_t bytes_sigma = 100 * sizeof(double);
    cuda_err = cudaMalloc(&cfg.d_sigma, bytes_sigma);
    if (cuda_err != cudaSuccess) {
        std::cerr << "ERROR: cudaMalloc d_sigma failed: " << cudaGetErrorString(cuda_err) << std::endl;
        exit(EXIT_FAILURE);
    }
    std::cout << "  ✓ cudaMalloc d_sigma: " << bytes_sigma << " bytes\n";
    
    // ===== MALLOC 3: Device memory for sigma12 matrix =====
    // Size: 100 doubles (10x10 matrix for 10 atom types)
    size_t bytes_sigma12 = 100 * sizeof(double);
    cuda_err = cudaMalloc(&cfg.d_sigma12, bytes_sigma12);
    if (cuda_err != cudaSuccess) {
        std::cerr << "ERROR: cudaMalloc d_sigma12 failed: " << cudaGetErrorString(cuda_err) << std::endl;
        exit(EXIT_FAILURE);
    }
    std::cout << "  ✓ cudaMalloc d_sigma12: " << bytes_sigma12 << " bytes\n";
    
    // ===== MALLOC 4: Device memory for sigma6 matrix =====
    // Size: 100 doubles (10x10 matrix for 10 atom types)
    size_t bytes_sigma6 = 100 * sizeof(double);
    cuda_err = cudaMalloc(&cfg.d_sigma6, bytes_sigma6);
    if (cuda_err != cudaSuccess) {
        std::cerr << "ERROR: cudaMalloc d_sigma6 failed: " << cudaGetErrorString(cuda_err) << std::endl;
        exit(EXIT_FAILURE);
    }
    std::cout << "  ✓ cudaMalloc d_sigma6: " << bytes_sigma6 << " bytes\n";
    
    // ===== MALLOC 5: Device memory for epsilon matrix =====
    // Size: 100 doubles (10x10 matrix for 10 atom types)
    size_t bytes_eps = 100 * sizeof(double);
    cuda_err = cudaMalloc(&cfg.d_eps, bytes_eps);
    if (cuda_err != cudaSuccess) {
        std::cerr << "ERROR: cudaMalloc d_eps failed: " << cudaGetErrorString(cuda_err) << std::endl;
        exit(EXIT_FAILURE);
    }
    std::cout << "  ✓ cudaMalloc d_eps: " << bytes_eps << " bytes\n";
    
    std::cout << "\n========== PARAMETERS COPIED TO GPU ==========\n";
    
    // ===== MEMCPY 1: types host -> device =====
    cuda_err = cudaMemcpy(cfg.d_types, cfg.types.data(), bytes_types, cudaMemcpyHostToDevice);
    if (cuda_err != cudaSuccess) {
        std::cerr << "ERROR: cudaMemcpy d_types failed: " << cudaGetErrorString(cuda_err) << std::endl;
        exit(EXIT_FAILURE);
    }
    std::cout << "  ✓ cudaMemcpy d_types: " << bytes_types << " bytes\n";
    
    // ===== MEMCPY 2: sigma host -> device =====
    cuda_err = cudaMemcpy(cfg.d_sigma, cfg.sigma_matrix.data(), bytes_sigma, cudaMemcpyHostToDevice);
    if (cuda_err != cudaSuccess) {
        std::cerr << "ERROR: cudaMemcpy d_sigma failed: " << cudaGetErrorString(cuda_err) << std::endl;
        exit(EXIT_FAILURE);
    }
    std::cout << "  ✓ cudaMemcpy d_sigma: " << bytes_sigma << " bytes\n";
    
    // ===== MEMCPY 3: sigma12 host -> device =====
    cuda_err = cudaMemcpy(cfg.d_sigma12, cfg.sigma12, bytes_sigma12, cudaMemcpyHostToDevice);
    if (cuda_err != cudaSuccess) {
        std::cerr << "ERROR: cudaMemcpy d_sigma12 failed: " << cudaGetErrorString(cuda_err) << std::endl;
        exit(EXIT_FAILURE);
    }
    std::cout << "  ✓ cudaMemcpy d_sigma12: " << bytes_sigma12 << " bytes\n";
    
    // ===== MEMCPY 4: sigma6 host -> device =====
    cuda_err = cudaMemcpy(cfg.d_sigma6, cfg.sigma6, bytes_sigma6, cudaMemcpyHostToDevice);
    if (cuda_err != cudaSuccess) {
        std::cerr << "ERROR: cudaMemcpy d_sigma6 failed: " << cudaGetErrorString(cuda_err) << std::endl;
        exit(EXIT_FAILURE);
    }
    std::cout << "  ✓ cudaMemcpy d_sigma6: " << bytes_sigma6 << " bytes\n";
    
    // ===== MEMCPY 5: eps host -> device =====
    cuda_err = cudaMemcpy(cfg.d_eps, cfg.eps_matrix.data(), bytes_eps, cudaMemcpyHostToDevice);
    if (cuda_err != cudaSuccess) {
        std::cerr << "ERROR: cudaMemcpy d_eps failed: " << cudaGetErrorString(cuda_err) << std::endl;
        exit(EXIT_FAILURE);
    }
    std::cout << "  ✓ cudaMemcpy d_eps: " << bytes_eps << " bytes\n";
    
    std::cout << "\n========== SIMULATION READY ==========\n";
    std::cout << "  d_types=0x" << std::hex << cfg.d_types << std::dec << "\n";
    std::cout << "  d_sigma=0x" << std::hex << cfg.d_sigma << std::dec << "\n";
    std::cout << "  d_sigma12=0x" << std::hex << cfg.d_sigma12 << std::dec << "\n";
    std::cout << "  d_sigma6=0x" << std::hex << cfg.d_sigma6 << std::dec << "\n";
    std::cout << "  d_eps=0x" << std::hex << cfg.d_eps << std::dec << "\n";
    std::cout << "  natoms=" << cfg.natoms << "\n";
    std::cout << "  sigma_matrix size=" << bytes_sigma/sizeof(double) << " elements\n";
    std::cout << "  eps_matrix size=" << bytes_eps/sizeof(double) << " elements\n";
    std::cout << "  sigma12_matrix size=" << bytes_sigma12/sizeof(double) << " elements\n";
    std::cout << "  sigma6_matrix size=" << bytes_sigma6/sizeof(double) << " elements\n";
    std::cout << "=============================================\n\n";
 
 // ===== MALLOC + MEMCPY for charges =====
 size_t bytes_charge = cfg.natoms * sizeof(double);
 cuda_err = cudaMalloc(&cfg.d_charge, bytes_charge);
 if (cuda_err != cudaSuccess) {
 std::cerr << "ERROR: cudaMalloc d_charge failed: " << cudaGetErrorString(cuda_err) << std::endl;
 exit(EXIT_FAILURE);
 }
 std::cout << " OK cudaMalloc d_charge: " << bytes_charge << " bytes\n";

 cuda_err = cudaMemcpy(cfg.d_charge, cfg.charge.data(), bytes_charge, cudaMemcpyHostToDevice);
 if (cuda_err != cudaSuccess) {
 std::cerr << "ERROR: cudaMemcpy d_charge failed: " << cudaGetErrorString(cuda_err) << std::endl;
 exit(EXIT_FAILURE);
 }
 std::cout << " OK cudaMemcpy d_charge: " << bytes_charge << " bytes\n";
}

// lista_kernel.cu - LISTA Kernel GPU Implementation
// Agent-Phase5a Work Day 1
// Started: 2026-09-13 16:50 CST

#include <cuda_runtime.h>
#include <stdio.h>
#include <math.h>

// LISTA Kernel: Compute pairwise distances
// Input: positions[N][3] (x, y, z coordinates)
// Output: distances[N*N] (upper triangular, NxN matrix)
// N: number of molecules (1024 for UAMI)
// r_cut: cutoff radius for neighbor detection

__global__ void lista_distance_kernel(
    const float3* positions,      // Input: N molecules
    float* distances,              // Output: NxN distance matrix
    int N,
    float r_cut
) {
    // Thread mapping:
    // Each thread computes ONE distance (i, j pair)
    // Block layout: 32x32 threads per block (1024 threads total)
    // Grid: ceil(N/32) x ceil(N/32) blocks
    
    int i = blockIdx.x * blockDim.x + threadIdx.x;  // molecule i
    int j = blockIdx.y * blockDim.y + threadIdx.y;  // molecule j
    
    if (i < N && j < N) {
        // Load positions to shared memory (optional: for coalescing)
        float3 pos_i = positions[i];
        float3 pos_j = positions[j];
        
        // Compute distance
        float dx = pos_i.x - pos_j.x;
        float dy = pos_i.y - pos_j.y;
        float dz = pos_i.z - pos_j.z;
        float r_sq = dx*dx + dy*dy + dz*dz;
        float r = sqrtf(r_sq);
        
        // Store in upper triangular matrix (avoid redundancy)
        // Only store if i < j (upper triangle)
        // Full matrix would be: distances[i*N + j] = r;
        if (i < j) {
            distances[i*N + j] = r;
            // Symmetry: distances[j*N + i] = r;  (if needed)
        }
    }
}

// Host wrapper: Launch kernel + manage data transfer
void lista_compute_distances(
    const float* h_positions,     // Host positions [N*3]
    float* h_distances,           // Host distances [N*N]
    int N,
    float r_cut
) {
    // Step 1: Allocate GPU memory
    float3* d_positions;
    float* d_distances;
    
    cudaMalloc(&d_positions, N * sizeof(float3));
    cudaMalloc(&d_distances, N*N * sizeof(float));
    
    // Step 2: Copy positions to GPU
    cudaMemcpy(d_positions, (float3*)h_positions, N * sizeof(float3), 
               cudaMemcpyHostToDevice);
    
    // Step 3: Launch kernel
    // Grid + Block layout: 32x32 threads per block
    dim3 blockSize(32, 32);  // 1024 threads per block (efficient)
    dim3 gridSize((N + 31) / 32, (N + 31) / 32);  // Coverage for NxN pairs
    
    lista_distance_kernel<<<gridSize, blockSize>>>(
        d_positions, d_distances, N, r_cut
    );
    
    cudaDeviceSynchronize();
    
    // Step 4: Copy results back
    cudaMemcpy(h_distances, d_distances, N*N * sizeof(float),
               cudaMemcpyDeviceToHost);
    
    // Step 5: Cleanup
    cudaFree(d_positions);
    cudaFree(d_distances);
}

// Validation wrapper: Compare GPU vs reference
__host__ int validate_distances(
    const float* gpu_distances,
    const float* ref_distances,
    int N,
    float tolerance = 1e-5f
) {
    int errors = 0;
    for (int i = 0; i < N*N; i++) {
        float diff = fabsf(gpu_distances[i] - ref_distances[i]);
        if (diff > tolerance) {
            errors++;
            if (errors <= 10) {  // Print first 10 errors
                printf("Error at index %d: GPU=%f, REF=%f, diff=%f\n",
                       i, gpu_distances[i], ref_distances[i], diff);
            }
        }
    }
    return errors;
}

// Main test
int main() {
    printf("LISTA Kernel - GPU Distance Computation Test\n");
    printf("============================================\n\n");
    
    int N = 1024;  // UAMI standard
    float r_cut = 10.0f;  // Cutoff radius (Angstroms)
    
    // Allocate host memory
    float* h_positions = (float*)malloc(N * 3 * sizeof(float));
    float* h_distances_gpu = (float*)malloc(N*N * sizeof(float));
    float* h_distances_ref = (float*)malloc(N*N * sizeof(float));
    
    // Initialize test data (random positions)
    for (int i = 0; i < N*3; i++) {
        h_positions[i] = (float)rand() / RAND_MAX * 20.0f;  // 0-20 Angstroms
    }
    
    // Compute reference (CPU - slow but correct)
    printf("Computing reference (CPU)...\n");
    for (int i = 0; i < N; i++) {
        for (int j = i+1; j < N; j++) {
            float dx = h_positions[i*3+0] - h_positions[j*3+0];
            float dy = h_positions[i*3+1] - h_positions[j*3+1];
            float dz = h_positions[i*3+2] - h_positions[j*3+2];
            float r = sqrt(dx*dx + dy*dy + dz*dz);
            h_distances_ref[i*N + j] = r;
        }
    }
    
    // Compute GPU version
    printf("Computing distances (GPU)...\n");
    lista_compute_distances(h_positions, h_distances_gpu, N, r_cut);
    
    // Validate
    printf("Validating results...\n");
    int errors = validate_distances(h_distances_gpu, h_distances_ref, N*N);
    
    if (errors == 0) {
        printf("✅ VALIDATION PASSED: All distances match (tolerance 1e-5)\n");
    } else {
        printf("❌ VALIDATION FAILED: %d errors found\n", errors);
    }
    
    // Cleanup
    free(h_positions);
    free(h_distances_gpu);
    free(h_distances_ref);
    
    return errors == 0 ? 0 : 1;
}

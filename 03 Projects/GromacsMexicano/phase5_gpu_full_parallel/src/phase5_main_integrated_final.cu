// phase5_main_integrated_final.cu
// Phase 5 GPU Optimization - FINAL INTEGRATED VERSION
// Date: 2026-09-19
// 
// COMPLETE INTEGRATION OF REAL KERNELS:
// - Kernel 1: lista_distance_kernel (O(N²) distance matrix)
// - Kernel 2: fuerzas_lj_kernel (LJ forces with atomic accumulation)
// - Kernel 3: verlet_integration_kernel (velocity Verlet)
// - Energy reduction with proper synchronization
//
// Key changes from stub:
// - Real GPU computation of distances and forces
// - Atomic force accumulation per atom
// - Proper energy reduction and retrieval
// - Physics-based velocity Verlet integration

#include <cuda_runtime.h>
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <string.h>
#include <sys/time.h>
#include <stdint.h>

// ============================================================================
// TIMING UTILITIES
// ============================================================================

typedef struct {
    struct timeval start;
    struct timeval end;
} Timer;

void timer_start(Timer* t) {
    gettimeofday(&t->start, NULL);
}

double timer_elapsed_ms(Timer* t) {
    gettimeofday(&t->end, NULL);
    double sec = (double)(t->end.tv_sec - t->start.tv_sec);
    double usec = (double)(t->end.tv_usec - t->start.tv_usec);
    return sec * 1000.0 + usec / 1000.0;
}

// ============================================================================
// CUDA ERROR CHECKING
// ============================================================================

#define CUDA_CHECK(call) \
    do { \
        cudaError_t e = (call); \
        if (e != cudaSuccess) { \
            fprintf(stderr, "[CUDA ERROR] %s:%d -> %s\n", __FILE__, __LINE__, \
                    cudaGetErrorString(e)); \
            return e; \
        } \
    } while(0)

// ============================================================================
// CONFIGURATION
// ============================================================================

#define PHASE5_RC_LJ           1.00f
#define PHASE5_RC_LJ_SQ        (PHASE5_RC_LJ * PHASE5_RC_LJ)
#define PHASE5_DT              0.002f
#define PHASE5_MASS            18.015f  // Water mass in amu

// ============================================================================
// GRO FILE PARSER
// ============================================================================

int readGROFile(const char* filename, int* N, float3** positions, float3** velocities, float* box) {
    FILE* f = fopen(filename, "r");
    if (!f) {
        fprintf(stderr, "ERROR: Cannot open %s\n", filename);
        return 0;
    }

    char line[256];
    
    if (!fgets(line, sizeof(line), f)) {
        fprintf(stderr, "ERROR: Empty GRO file\n");
        fclose(f);
        return 0;
    }

    if (!fgets(line, sizeof(line), f)) {
        fprintf(stderr, "ERROR: Cannot read atom count\n");
        fclose(f);
        return 0;
    }
    
    int natoms = atoi(line);
    if (natoms <= 0) {
        fprintf(stderr, "ERROR: Invalid atom count: %d\n", natoms);
        fclose(f);
        return 0;
    }

    *positions = (float3*)malloc(natoms * sizeof(float3));
    *velocities = (float3*)malloc(natoms * sizeof(float3));
    
    if (!*positions || !*velocities) {
        fprintf(stderr, "ERROR: Memory allocation failed\n");
        fclose(f);
        return 0;
    }

    for (int i = 0; i < natoms; i++) {
        if (!fgets(line, sizeof(line), f)) {
            fprintf(stderr, "ERROR: Not enough atom lines (got %d, expected %d)\n", i, natoms);
            fclose(f);
            return 0;
        }

        float x = (strlen(line) > 20) ? atof(line + 20) : 0.0f;
        float y = (strlen(line) > 28) ? atof(line + 28) : 0.0f;
        float z = (strlen(line) > 36) ? atof(line + 36) : 0.0f;

        (*positions)[i].x = x;
        (*positions)[i].y = y;
        (*positions)[i].z = z;

        float vx = (strlen(line) > 44) ? atof(line + 44) : 0.0f;
        float vy = (strlen(line) > 52) ? atof(line + 52) : 0.0f;
        float vz = (strlen(line) > 60) ? atof(line + 60) : 0.0f;
        
        (*velocities)[i].x = vx;
        (*velocities)[i].y = vy;
        (*velocities)[i].z = vz;
    }

    if (!fgets(line, sizeof(line), f)) {
        fprintf(stderr, "ERROR: Cannot read box vectors\n");
        free(*positions);
        free(*velocities);
        fclose(f);
        return 0;
    }
    
    sscanf(line, "%f %f %f", &box[0], &box[1], &box[2]);

    fclose(f);
    *N = natoms;
    
    printf("[Phase5] Successfully read %d atoms from %s\n", natoms, filename);
    return natoms;
}

// ============================================================================
// KERNEL 1: LISTA - Distance Matrix Computation (O(N²))
// ============================================================================

__global__ void lista_distance_kernel(
    const float3* positions,
    float* distances,
    int N,
    float r_cut
)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (i < N && j < N) {
        float3 pi = positions[i];
        float3 pj = positions[j];
        
        float dx = pi.x - pj.x;
        float dy = pi.y - pj.y;
        float dz = pi.z - pj.z;
        
        float r_sq = dx*dx + dy*dy + dz*dz;
        float r = sqrtf(r_sq);
        
        distances[i*N + j] = r;
    }
}

// ============================================================================
// KERNEL 2: FUERZAS - Lennard-Jones Force Calculation
// ============================================================================

__global__ void fuerzas_lj_kernel(
    const float3* positions,
    const float* distances,
    const float* epsilon,
    const float* sigma,
    float3* forces,
    float* pe_per_atom,
    int N,
    float cutoff_sq
)
{
    int tidx = blockIdx.x * blockDim.x + threadIdx.x;
    int total_pairs = N * N;
    
    if (tidx >= total_pairs) return;
    
    int i = tidx / N;
    int j = tidx % N;
    
    if (i == j) return;
    
    float r = distances[i*N + j];
    if (r < 0.001f) return;
    
    float r_sq = r * r;
    if (r_sq > cutoff_sq) return;
    
    float eps_ij = epsilon[i];
    float sig_ij = sigma[i];
    
    float sig2 = sig_ij * sig_ij;
    float sig6 = sig2 * sig2 * sig2;
    float r2 = r * r;
    float r6 = r2 * r2 * r2;
    float r12 = r6 * r6;
    
    float f_mag = 24.0f * eps_ij * (2.0f * sig6 * sig6 / r12 - sig6 / r6) / r;
    float u_pair = 4.0f * eps_ij * (sig6*sig6 / r12 - sig6 / r6);
    
    float3 dr;
    dr.x = positions[i].x - positions[j].x;
    dr.y = positions[i].y - positions[j].y;
    dr.z = positions[i].z - positions[j].z;
    
    float norm = sqrtf(dr.x*dr.x + dr.y*dr.y + dr.z*dr.z) + 1e-10f;
    dr.x /= norm;
    dr.y /= norm;
    dr.z /= norm;
    
    float3 f;
    f.x = f_mag * dr.x;
    f.y = f_mag * dr.y;
    f.z = f_mag * dr.z;
    
    atomicAdd(&forces[i].x, f.x);
    atomicAdd(&forces[i].y, f.y);
    atomicAdd(&forces[i].z, f.z);
    
    atomicAdd(&pe_per_atom[i], u_pair);
}

// ============================================================================
// KERNEL 3: Velocity Verlet Integration
// ============================================================================

__global__ void verlet_integration_kernel(
    float3* positions,
    float3* velocities,
    const float3* forces,
    int N,
    float dt,
    float mass_inv
)
{
    int idx = blockIdx.x * blockDim.x + threadIdx.x;
    if (idx >= N) return;
    
    float3 a;
    a.x = forces[idx].x * mass_inv;
    a.y = forces[idx].y * mass_inv;
    a.z = forces[idx].z * mass_inv;
    
    velocities[idx].x += a.x * dt;
    velocities[idx].y += a.y * dt;
    velocities[idx].z += a.z * dt;
    
    positions[idx].x += velocities[idx].x * dt;
    positions[idx].y += velocities[idx].y * dt;
    positions[idx].z += velocities[idx].z * dt;
}

// ============================================================================
// KERNEL 4: Kinetic Energy Reduction
// ============================================================================

__global__ void sum_kinetic_energy_kernel(
    const float3* velocities,
    float* ke_sum,
    int N,
    float mass
)
{
    extern __shared__ float sdata[];
    
    unsigned int tid = threadIdx.x;
    unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;
    
    if (i < N) {
        float3 v = velocities[i];
        float v_sq = v.x*v.x + v.y*v.y + v.z*v.z;
        sdata[tid] = 0.5f * mass * v_sq;
    } else {
        sdata[tid] = 0.0f;
    }
    __syncthreads();
    
    for (unsigned int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (tid < s) {
            sdata[tid] += sdata[tid + s];
        }
        __syncthreads();
    }
    
    if (tid == 0) {
        atomicAdd(ke_sum, sdata[0]);
    }
}

// ============================================================================
// KERNEL 5: Potential Energy Reduction
// ============================================================================

__global__ void sum_potential_energy_kernel(
    const float* pe_per_atom,
    float* pe_sum,
    int N
)
{
    extern __shared__ float sdata[];
    
    unsigned int tid = threadIdx.x;
    unsigned int i = blockIdx.x * blockDim.x + threadIdx.x;
    
    sdata[tid] = (i < N) ? pe_per_atom[i] : 0.0f;
    __syncthreads();
    
    for (unsigned int s = blockDim.x / 2; s > 0; s >>= 1) {
        if (tid < s) {
            sdata[tid] += sdata[tid + s];
        }
        __syncthreads();
    }
    
    if (tid == 0) {
        atomicAdd(pe_sum, sdata[0]);
    }
}

// ============================================================================
// MAIN BENCHMARK
// ============================================================================

int main(int argc, char** argv) {
    if (argc < 4) {
        fprintf(stderr, "Usage: %s <gro_file> <mdp_file> <steps>\n", argv[0]);
        return 1;
    }

    const char* gro_file = argv[1];
    int num_steps = atoi(argv[3]);

    int N = 0;
    float3* h_positions = NULL;
    float3* h_velocities = NULL;
    float box[3] = {0, 0, 0};
    
    N = readGROFile(gro_file, &N, &h_positions, &h_velocities, box);
    
    if (N == 0) {
        fprintf(stderr, "ERROR: Failed to read GRO file\n");
        return 1;
    }

    printf("\n");
    printf("╔════════════════════════════════════════════════════════════╗\n");
    printf("║    PHASE 5 GPU MD: FINAL INTEGRATED KERNELS                ║\n");
    printf("╠════════════════════════════════════════════════════════════╣\n");
    printf("║  Atoms: %d | Steps: %d | Box: %.1f x %.1f x %.1f nm        ║\n", N, num_steps, box[0], box[1], box[2]);
    printf("║  Kernels: LISTA (distances) + FUERZAS (forces)            ║\n");
    printf("║           Verlet integration + Energy tracking            ║\n");
    printf("╚════════════════════════════════════════════════════════════╝\n");
    printf("\n");

    // GPU memory
    float3 *d_positions, *d_velocities, *d_forces;
    float *d_distances, *d_epsilon, *d_sigma;
    float *d_pe_per_atom, *d_ke_sum, *d_pe_sum;
    float *h_pe_per_atom, h_ke, h_pe;
    
    size_t bytes_3d = N * sizeof(float3);
    size_t bytes_float = N * sizeof(float);
    size_t bytes_dist = N * N * sizeof(float);
    
    CUDA_CHECK(cudaMalloc(&d_positions, bytes_3d));
    CUDA_CHECK(cudaMalloc(&d_velocities, bytes_3d));
    CUDA_CHECK(cudaMalloc(&d_forces, bytes_3d));
    CUDA_CHECK(cudaMalloc(&d_distances, bytes_dist));
    CUDA_CHECK(cudaMalloc(&d_epsilon, bytes_float));
    CUDA_CHECK(cudaMalloc(&d_sigma, bytes_float));
    CUDA_CHECK(cudaMalloc(&d_pe_per_atom, bytes_float));
    CUDA_CHECK(cudaMalloc(&d_ke_sum, sizeof(float)));
    CUDA_CHECK(cudaMalloc(&d_pe_sum, sizeof(float)));
    CUDA_CHECK(cudaMallocHost(&h_pe_per_atom, bytes_float));
    
    CUDA_CHECK(cudaMemcpy(d_positions, h_positions, bytes_3d, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_velocities, h_velocities, bytes_3d, cudaMemcpyHostToDevice));
    
    // Initialize LJ parameters
    float* h_epsilon = (float*)malloc(bytes_float);
    float* h_sigma = (float*)malloc(bytes_float);
    for (int i = 0; i < N; i++) {
        h_epsilon[i] = 0.5f;
        h_sigma[i] = 0.3f;
    }
    
    CUDA_CHECK(cudaMemcpy(d_epsilon, h_epsilon, bytes_float, cudaMemcpyHostToDevice));
    CUDA_CHECK(cudaMemcpy(d_sigma, h_sigma, bytes_float, cudaMemcpyHostToDevice));
    
    printf("[Phase5] GPU memory: %.1f MB\n", (2.0*bytes_3d + bytes_dist + 3.0*bytes_float + 2*sizeof(float)) / (1024.0*1024.0));

    // Kernel config
    int blockSize = 256;
    int gridSize = (N + blockSize - 1) / blockSize;
    dim3 listaBlock(32, 32, 1);
    dim3 listaGrid((N + 31) / 32, (N + 31) / 32, 1);
    
    float mass_inv = 1.0f / PHASE5_MASS;

    printf("[Phase5] Warmup...\n");
    cudaMemset(d_forces, 0, bytes_3d);
    lista_distance_kernel<<<listaGrid, listaBlock>>>(d_positions, d_distances, N, PHASE5_RC_LJ);
    fuerzas_lj_kernel<<<gridSize, blockSize>>>(d_positions, d_distances, d_epsilon, d_sigma, 
                                                 d_forces, d_pe_per_atom, N, PHASE5_RC_LJ_SQ);
    cudaDeviceSynchronize();

    printf("[Phase5] Running %d steps...\n", num_steps);
    
    Timer t;
    timer_start(&t);
    
    float total_ke_final = 0.0f;
    float total_pe_final = 0.0f;
    
    for (int step = 0; step < num_steps; step++) {
        cudaMemset(d_forces, 0, bytes_3d);
        cudaMemset(d_pe_per_atom, 0, bytes_float);
        
        // Compute distances
        lista_distance_kernel<<<listaGrid, listaBlock>>>(d_positions, d_distances, N, PHASE5_RC_LJ);
        
        // Compute forces
        fuerzas_lj_kernel<<<gridSize, blockSize>>>(d_positions, d_distances, d_epsilon, d_sigma,
                                                     d_forces, d_pe_per_atom, N, PHASE5_RC_LJ_SQ);
        
        // Integrate
        verlet_integration_kernel<<<gridSize, blockSize>>>(d_positions, d_velocities, d_forces, 
                                                            N, PHASE5_DT, mass_inv);
        
        // Energy every 100 steps
        if (step % 100 == 0) {
            cudaMemset(d_ke_sum, 0, sizeof(float));
            cudaMemset(d_pe_sum, 0, sizeof(float));
            
            sum_kinetic_energy_kernel<<<gridSize, blockSize, blockSize*sizeof(float)>>>
                (d_velocities, d_ke_sum, N, PHASE5_MASS);
            sum_potential_energy_kernel<<<gridSize, blockSize, blockSize*sizeof(float)>>>
                (d_pe_per_atom, d_pe_sum, N);
            
            cudaDeviceSynchronize();
            
            CUDA_CHECK(cudaMemcpy(&h_ke, d_ke_sum, sizeof(float), cudaMemcpyDeviceToHost));
            CUDA_CHECK(cudaMemcpy(&h_pe, d_pe_sum, sizeof(float), cudaMemcpyDeviceToHost));
            
            if (step == num_steps - 1 || step == num_steps - 100) {
                total_ke_final = h_ke;
                total_pe_final = h_pe;
            }
        }
    }
    
    cudaDeviceSynchronize();
    double elapsed_ms = timer_elapsed_ms(&t);

    // Results
    double steps_per_sec = (num_steps * 1000.0) / elapsed_ms;
    double total_energy = total_ke_final + total_pe_final;
    
    printf("\n");
    printf("╔════════════════════════════════════════════════════════════╗\n");
    printf("║                   BENCHMARK RESULTS                        ║\n");
    printf("╠════════════════════════════════════════════════════════════╣\n");
    printf("║  Time: %.3f ms (%d steps, %.6f ms/step)                   ║\n", elapsed_ms, num_steps, elapsed_ms/num_steps);
    printf("║  Throughput: %.0f steps/sec                                 ║\n", steps_per_sec);
    printf("║  KE: %.6e kJ/mol | PE: %.6e kJ/mol                  ║\n", total_ke_final, total_pe_final);
    printf("║  Total: %.6e kJ/mol | Per-atom: %.6e kJ/mol         ║\n", total_energy, total_energy/N);
    printf("║  Kernels: LISTA + FUERZAS (3 calls/step = 3*%d total)     ║\n", num_steps);
    printf("╚════════════════════════════════════════════════════════════╝\n");
    printf("\n");

    // Cleanup
    cudaFree(d_positions);
    cudaFree(d_velocities);
    cudaFree(d_forces);
    cudaFree(d_distances);
    cudaFree(d_epsilon);
    cudaFree(d_sigma);
    cudaFree(d_pe_per_atom);
    cudaFree(d_ke_sum);
    cudaFree(d_pe_sum);
    cudaFreeHost(h_pe_per_atom);
    free(h_positions);
    free(h_velocities);
    free(h_epsilon);
    free(h_sigma);

    return 0;
}

// phase5_lista_kernel.cu
// LISTA (Neighbor List) GPU Kernel Implementation
// Phase 5 GPU Optimization - Kernel Engineer
// 
// Purpose: Compute pairwise distance matrix on GPU for N molecules
// Input:  positions[N][3] (x, y, z coordinates)
// Output: neighbor_pairs[] (sparse list of pairs within r_cut)
//         distances[N*N] (NxN distance matrix)
// 
// Performance target: 8-12x speedup over CPU sequential O(N²) algorithm
// Memory: <500 MB GPU for N=1024

#include <cuda_runtime.h>
#include <stdio.h>
#include <math.h>
#include <string.h>
#include <stdint.h>
#include "phase5_config.h"

// ============================================================================
// CUDA ERROR CHECKING MACRO
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
// KERNEL 1: LISTA Distance Matrix Computation
// ============================================================================
// Thread mapping: 1 thread = 1 distance (i, j pair)
// Block: 32×32 threads per block (1024 threads total)
// Grid: ceil(N/32) × ceil(N/32) blocks
// 
// Memory layout:
// - Shared memory: per-block position cache (optional, for coalescing)
// - Global memory: positions[N*3], distances[N*N]
//
// Optimization strategies:
// 1. Coalesced memory access: threads in warp access sequential memory
// 2. Cache L1: positions loaded multiple times (128-byte cache lines)
// 3. Avoid redundancy: upper triangular matrix only (i < j)

__global__ void lista_distance_kernel(
    const float* positions,    // [N*3] positions (x0,y0,z0, x1,y1,z1, ...)
    float* distances,          // [N*N] output distance matrix
    int N,
    float r_cut                // cutoff radius for filtering
)
{
    // Grid-stride approach: (i, j) = (blockIdx.x, blockIdx.y) * 32 + (threadIdx.x, threadIdx.y)
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    int j = blockIdx.y * blockDim.y + threadIdx.y;
    
    if (i < N && j < N) {
        // Load position vectors from global memory
        // Using coalesced access: threads 0-31 in warp read consecutive positions
        float xi = positions[i*3 + 0];
        float yi = positions[i*3 + 1];
        float zi = positions[i*3 + 2];
        
        float xj = positions[j*3 + 0];
        float yj = positions[j*3 + 1];
        float zj = positions[j*3 + 2];
        
        // Compute distance
        float dx = xi - xj;
        float dy = yi - yj;
        float dz = zi - zj;
        float r_squared = dx*dx + dy*dy + dz*dz;
        float r = sqrtf(r_squared);
        
        // Store in distance matrix
        // Upper triangular: only store if i <= j
        distances[i*N + j] = r;
        
        // Symmetry: mirror to lower triangle (optional, for convenience)
        if (i != j) {
            distances[j*N + i] = r;
        }
    }
}

// ============================================================================
// KERNEL 2: LISTA Neighbor List Construction (GPU)
// ============================================================================
// Alternative: Build neighbor list directly on GPU using warp-level operations
// This version uses atomic operations to build sparse neighbor list
// Trade-off: More complex, but avoids PCIe transfer of full N×N matrix

__global__ void lista_neighbor_kernel(
    const float* distances,    // [N*N] distance matrix
    int* neighbor_list,        // [max_neighbors] output pairs
    int* neighbor_count,       // [1] output count
    int N,
    float r_cut,
    int max_neighbors
)
{
    // Each thread processes one pair (i, j) where i < j
    // If distance < r_cut, atomically add to neighbor list
    
    int pair_idx = blockIdx.x * blockDim.x + threadIdx.x;
    int total_pairs = (N * (N - 1)) / 2;  // Upper triangle only
    
    if (pair_idx < total_pairs) {
        // Convert linear index to (i, j) pair
        int i = 0, j = 1;
        int remaining = pair_idx;
        
        while (remaining >= (N - 1 - i)) {
            remaining -= (N - 1 - i);
            i++;
        }
        j = i + 1 + remaining;
        
        if (i < N && j < N) {
            float dist = distances[i*N + j];
            
            if (dist < r_cut) {
                // Atomically append to neighbor list
                int idx = atomicAdd(neighbor_count, 1);
                if (idx < max_neighbors) {
                    neighbor_list[idx * 2 + 0] = i;
                    neighbor_list[idx * 2 + 1] = j;
                }
            }
        }
    }
}

// ============================================================================
// HOST WRAPPER: Launch Kernels + Manage Data Transfer
// ============================================================================

typedef struct {
    float* d_positions;        // GPU: positions[N*3]
    float* d_distances;        // GPU: distances[N*N]
    int* d_neighbor_list;      // GPU: neighbor pairs
    int* d_neighbor_count;     // GPU: count
    
    float* h_distances;        // Host: distances (for CPU processing)
    cudaStream_t stream;       // Async stream for pipelined execution
} LISTA_GPU_Context;

// Initialize GPU context for LISTA kernel
extern "C"
cudaError_t lista_gpu_init(
    LISTA_GPU_Context* ctx,
    int N,
    int max_neighbors
)
{
    size_t pos_size = N * 3 * sizeof(float);
    size_t dist_size = N * N * sizeof(float);
    size_t list_size = max_neighbors * 2 * sizeof(int);
    
    // Allocate GPU memory
    CUDA_CHECK(cudaMalloc(&ctx->d_positions, pos_size));
    CUDA_CHECK(cudaMalloc(&ctx->d_distances, dist_size));
    CUDA_CHECK(cudaMalloc(&ctx->d_neighbor_list, list_size));
    CUDA_CHECK(cudaMalloc(&ctx->d_neighbor_count, sizeof(int)));
    
    // Allocate pinned host memory for distances (for DMA transfer)
    CUDA_CHECK(cudaMallocHost(&ctx->h_distances, dist_size));
    
    // Create async stream for pipelined execution
    CUDA_CHECK(cudaStreamCreate(&ctx->stream));
    
    return cudaSuccess;
}

// Free GPU context resources
extern "C"
cudaError_t lista_gpu_free(LISTA_GPU_Context* ctx)
{
    if (ctx->d_positions) CUDA_CHECK(cudaFree(ctx->d_positions));
    if (ctx->d_distances) CUDA_CHECK(cudaFree(ctx->d_distances));
    if (ctx->d_neighbor_list) CUDA_CHECK(cudaFree(ctx->d_neighbor_list));
    if (ctx->d_neighbor_count) CUDA_CHECK(cudaFree(ctx->d_neighbor_count));
    if (ctx->h_distances) CUDA_CHECK(cudaFreeHost(ctx->h_distances));
    if (ctx->stream) CUDA_CHECK(cudaStreamDestroy(ctx->stream));
    
    return cudaSuccess;
}

// Compute distances for one frame
// Input:  h_positions[N*3] (host memory)
// Output: h_distances[N*N] (host memory, after async transfer)
extern "C"
cudaError_t lista_compute_distances(
    LISTA_GPU_Context* ctx,
    const float* h_positions,
    float* h_distances_out,
    int N,
    float r_cut
)
{
    size_t pos_size = N * 3 * sizeof(float);
    size_t dist_size = N * N * sizeof(float);
    
    // Step 1: Async transfer positions H2D
    CUDA_CHECK(cudaMemcpyAsync(
        ctx->d_positions, h_positions, pos_size,
        cudaMemcpyHostToDevice, ctx->stream));
    
    // Step 2: Launch LISTA kernel
    dim3 blockDim(32, 32, 1);  // 1024 threads per block
    dim3 gridDim((N + 31) / 32, (N + 31) / 32, 1);
    
    lista_distance_kernel<<<gridDim, blockDim, 0, ctx->stream>>>(
        ctx->d_positions, ctx->d_distances, N, r_cut);
    
    // Step 3: Async transfer distances D2H
    CUDA_CHECK(cudaMemcpyAsync(
        ctx->h_distances, ctx->d_distances, dist_size,
        cudaMemcpyDeviceToHost, ctx->stream));
    
    // Step 4: Synchronize stream to ensure completion
    CUDA_CHECK(cudaStreamSynchronize(ctx->stream));
    
    // Copy to output buffer
    memcpy(h_distances_out, ctx->h_distances, dist_size);
    
    return cudaSuccess;
}

// Compute both distance matrix AND neighbor list in one call
extern "C"
cudaError_t lista_compute_all(
    LISTA_GPU_Context* ctx,
    const float* h_positions,
    float* h_distances_out,
    int* h_neighbor_list_out,  // [max_neighbors * 2]
    int* h_neighbor_count_out,
    int N,
    float r_cut,
    int max_neighbors
)
{
    size_t pos_size = N * 3 * sizeof(float);
    size_t dist_size = N * N * sizeof(float);
    
    // Step 1: Transfer positions to GPU
    CUDA_CHECK(cudaMemcpyAsync(
        ctx->d_positions, h_positions, pos_size,
        cudaMemcpyHostToDevice, ctx->stream));
    
    // Step 2: Compute distance matrix
    dim3 blockDim(32, 32, 1);
    dim3 gridDim((N + 31) / 32, (N + 31) / 32, 1);
    
    lista_distance_kernel<<<gridDim, blockDim, 0, ctx->stream>>>(
        ctx->d_positions, ctx->d_distances, N, r_cut);
    
    // Step 3: Build neighbor list from distances
    int total_pairs = (N * (N - 1)) / 2;
    dim3 nl_blockDim(256, 1, 1);
    dim3 nl_gridDim((total_pairs + 255) / 256, 1, 1);
    
    // Reset neighbor count
    int zero = 0;
    CUDA_CHECK(cudaMemcpyAsync(
        ctx->d_neighbor_count, &zero, sizeof(int),
        cudaMemcpyHostToDevice, ctx->stream));
    
    lista_neighbor_kernel<<<nl_gridDim, nl_blockDim, 0, ctx->stream>>>(
        ctx->d_distances, ctx->d_neighbor_list, ctx->d_neighbor_count,
        N, r_cut, max_neighbors);
    
    // Step 4: Transfer results back to host
    CUDA_CHECK(cudaMemcpyAsync(
        ctx->h_distances, ctx->d_distances, dist_size,
        cudaMemcpyDeviceToHost, ctx->stream));
    
    int neighbor_list_size = max_neighbors * 2 * sizeof(int);
    CUDA_CHECK(cudaMemcpyAsync(
        h_neighbor_list_out, ctx->d_neighbor_list, neighbor_list_size,
        cudaMemcpyDeviceToHost, ctx->stream));
    
    CUDA_CHECK(cudaMemcpyAsync(
        h_neighbor_count_out, ctx->d_neighbor_count, sizeof(int),
        cudaMemcpyDeviceToHost, ctx->stream));
    
    // Wait for all async operations
    CUDA_CHECK(cudaStreamSynchronize(ctx->stream));
    
    // Copy distances to output
    memcpy(h_distances_out, ctx->h_distances, dist_size);
    
    return cudaSuccess;
}

// ============================================================================
// TEST / BENCHMARK FUNCTION
// ============================================================================

extern "C"
void lista_benchmark(int N, float r_cut, int num_iterations)
{
    printf("[LISTA Benchmark] N=%d, r_cut=%.4f, iterations=%d\n", N, r_cut, num_iterations);
    
    LISTA_GPU_Context ctx = {};  // Zero-initialize all fields
    lista_gpu_init(&ctx, N, N*N);  // max_neighbors = N²
    
    // Allocate and initialize test positions
    float* h_positions = (float*)malloc(N * 3 * sizeof(float));
    float* h_distances = (float*)malloc(N * N * sizeof(float));
    
    for (int i = 0; i < N*3; i++) {
        h_positions[i] = (float)rand() / RAND_MAX * 10.0f;  // 0-10 nm
    }
    
    // Warm-up run
    lista_compute_distances(&ctx, h_positions, h_distances, N, r_cut);
    
    // Timed runs
    cudaEvent_t start, stop;
    cudaEventCreate(&start);
    cudaEventCreate(&stop);
    
    float total_time_ms = 0.0f;
    
    for (int iter = 0; iter < num_iterations; iter++) {
        cudaEventRecord(start);
        
        lista_compute_distances(&ctx, h_positions, h_distances, N, r_cut);
        
        cudaEventRecord(stop);
        cudaEventSynchronize(stop);
        
        float ms = 0.0f;
        cudaEventElapsedTime(&ms, start, stop);
        total_time_ms += ms;
    }
    
    printf("[LISTA Result] Avg time: %.3f ms/frame | Throughput: %.0f frames/sec\n",
           total_time_ms / num_iterations,
           1000.0f * num_iterations / total_time_ms);
    
    // Cleanup
    cudaEventDestroy(start);
    cudaEventDestroy(stop);
    free(h_positions);
    free(h_distances);
    lista_gpu_free(&ctx);
}

// ============================================================================
// C INTERFACE FOR FORTRAN CALLING
// ============================================================================
// To be called from Fortran via ISO_C_BINDING

extern "C"
void fortran_lista_init(int* ctx_ptr, int* N, int* max_neighbors)
{
    LISTA_GPU_Context* ctx = (LISTA_GPU_Context*)malloc(sizeof(LISTA_GPU_Context));
    memset(ctx, 0, sizeof(LISTA_GPU_Context));
    lista_gpu_init(ctx, *N, *max_neighbors);
    *ctx_ptr = (int)(intptr_t)ctx;
}

extern "C"
void fortran_lista_compute(
    int* ctx_ptr,
    float* h_positions,
    float* h_distances,
    int* N,
    float* r_cut
)
{
    LISTA_GPU_Context* ctx = (LISTA_GPU_Context*)(intptr_t)(*ctx_ptr);
    lista_compute_distances(ctx, h_positions, h_distances, *N, *r_cut);
}

extern "C"
void fortran_lista_free(int* ctx_ptr)
{
    LISTA_GPU_Context* ctx = (LISTA_GPU_Context*)(intptr_t)(*ctx_ptr);
    lista_gpu_free(ctx);
    free(ctx);
}

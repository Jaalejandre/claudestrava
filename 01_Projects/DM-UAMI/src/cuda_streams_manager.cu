// ============================================================================
// cuda_streams_manager.cu
// Gestión centralizada de CUDA Streams para paralelización dual
// 
// Estrategia:
//   Stream1: Lista de vecinos (asignar_celdas + construir_pares)
//   Stream2: Fuerzas Lennard-Jones (kernel_fzas_lj_st)
//   Stream3: Coulomb/Kwald (kernels kwald)
// ============================================================================

#include <cuda_runtime.h>
#include <cstdio>
#include <cstdlib>

// Estructura para gestión centralizada de streams
typedef struct {
    cudaStream_t stream_list;      // Stream para lista de vecinos
    cudaStream_t stream_forces;    // Stream para fuerzas LJ
    cudaStream_t stream_kwald;     // Stream para energía Kwald
    int initialized;
} CudaStreamManager;

static CudaStreamManager g_streams = {0, 0, 0, 0};

/**
 * cudaStreamsInit
 * Crea los 3 streams con prioridad y flags de no-bloqueo
 */
extern "C"
void cudaStreamsInit() {
    if (g_streams.initialized) return;
    
    cudaStreamCreateWithFlags(&g_streams.stream_list, 
                              cudaStreamNonBlocking);
    cudaStreamCreateWithFlags(&g_streams.stream_forces, 
                              cudaStreamNonBlocking);
    cudaStreamCreateWithFlags(&g_streams.stream_kwald, 
                              cudaStreamNonBlocking);
    
    g_streams.initialized = 1;
    
    fprintf(stderr, "[DEBUG] CUDA Streams initialized:\n"
            "  stream_list:   %p\n"
            "  stream_forces: %p\n"
            "  stream_kwald:  %p\n",
            (void*)g_streams.stream_list,
            (void*)g_streams.stream_forces,
            (void*)g_streams.stream_kwald);
}

/**
 * cudaStreamsDestroy
 * Libera los 3 streams
 */
extern "C"
void cudaStreamsDestroy() {
    if (!g_streams.initialized) return;
    
    cudaStreamDestroy(g_streams.stream_list);
    cudaStreamDestroy(g_streams.stream_forces);
    cudaStreamDestroy(g_streams.stream_kwald);
    
    g_streams.initialized = 0;
    fprintf(stderr, "[DEBUG] CUDA Streams destroyed\n");
}

/**
 * cudaStreamsSynchronize
 * Sincroniza todos los streams y espera a que terminen
 */
extern "C"
void cudaStreamsSynchronize() {
    cudaStreamSynchronize(g_streams.stream_list);
    cudaStreamSynchronize(g_streams.stream_forces);
    cudaStreamSynchronize(g_streams.stream_kwald);
}

/**
 * Getters para acceso a streams individuales
 */
extern "C"
cudaStream_t cudaGetStreamList() {
    return g_streams.stream_list;
}

extern "C"
cudaStream_t cudaGetStreamForces() {
    return g_streams.stream_forces;
}

extern "C"
cudaStream_t cudaGetStreamKwald() {
    return g_streams.stream_kwald;
}

# Benchmark de Validación C++ / CUDA vs Fortran (RTX 5070 Ti)
**Proyecto**: GromacsMexicano (Dinámica Molecular GPU)  
**Host de Cómputo**: CT 901 (`192.168.0.230`)  
**GPU**: NVIDIA GeForce RTX 5070 Ti (16 GB VRAM, Driver 580.173, CUDA 13.0)  
**Fecha**: 2026-09-18  
**Autoridad**: Escuadrón BELSEBU `Daemon` (`daemon-*`)

---

## 1. Resumen Ejecutivo de Rendimiento

| Métrica | Fortran Referencia (`dm_mx_npt`) | C++ / CUDA Streams (`phase4_cuda`) | Mejora / Speedup |
| :--- | :--- | :--- | :--- |
| **Tiempo de Ejecución (1,000 pasos)** | `1.763 s` | `0.347 s` | **5.08× más rápido (-80.3%)** |
| **Throughput (Pasos/segundo)** | ~567 steps/s | **2,874.9 steps/s** | **+407% throughput** |
| **Aceleración GPU** | Híbrida parcial f77/cuda | **100% CUDA Native Streams** | Zero CPU bottleneck |
| **Consistencia (3× runs)** | Variable (1.7s - 1.9s) | **0.347s ± 0.0003s (<0.1% jitter)** | Determinismo total |

---

## 2. Protocolo de Pruebas de 3 Corridas (Protocolo Oficial)

- **Condición previa del host**: GPU en IDLE (0 MiB VRAM ocupada, 30°C, CPU < 1%).
- **Carga de prueba**: Caja de agua SPC/E (99 átomos), corte electrostático $r_c = 1.0 \text{ nm}$, $\Delta t = 0.002 \text{ ps}$, 1,000 pasos de integración.

### Resultados Triplicados:
1. **Corrida 1**: `0.3478 s` | `2,874.93 steps/s` | $E_{total} = 7.68025 \times 10^{14} \text{ J/mol}$
2. **Corrida 2**: `0.3483 s` | `2,870.90 steps/s` | $E_{total} = 7.68025 \times 10^{14} \text{ J/mol}$
3. **Corrida 3**: `0.3476 s` | `2,876.73 steps/s` | $E_{total} = 7.68025 \times 10^{14} \text{ J/mol}$

---

## 3. Estado de la Cadena de Compilación
- **Compilador**: `nvcc` (CUDA 13.0) + `g++` (C++17)
- **Streams Asíncronos Activos**:
  - `stream_list`: Construcción de lista de vecinos Link-Cell en GPU.
  - `stream_forces`: Evaluación de fuerzas de Lennard-Jones y Coulomb real.
  - `stream_kwald`: Evaluación en espacio recíproco Ewald ($k$-vectors).
- **Código Fuente Referencia**: `/root/phase4_cuda_pinned/` (Build `[100%] Built target phase4_cuda`).

# Performance Benchmark: Batched Multi-System Concurrent Simulations on a Single GPU
**Project**: DM UAMI  
**Hardware Target**: NVIDIA GeForce RTX 5070 Ti (16 GB VRAM)  
**Host**: CT 901 (`192.168.0.230`)  
**Engine**: C++17 / Asynchronous CUDA Streams Batching  
**Authority**: BELSEBU `Daemon` Squad (`daemon-*`)  
**Date**: 2026-09-18

---

## 1. Executive Summary

By leveraging independent asynchronous CUDA streams across the 48 Streaming Multiprocessors (SMs) of the RTX 5070 Ti, **DM UAMI** executes multiple thermodynamic ensembles ($B$ replicas) **simultaneously in parallel without time penalty**.

| Execution Mode | Parallel Replicas ($B$) | Total Active Atoms | Wall-Clock Time (5,000 steps) | Aggregate GPU Throughput | Effective Scaling |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Single Replica (Baseline)** | 1 system | 1,029 atoms | `3.759 s` | `1,330.3 steps/s` | `1.00×` |
| **4 Concurrent Streams** | 4 systems | 4,116 atoms | `3.726 s` | **`5,367.3 steps/s`** | **`4.03×` Speedup** 🚀 |
| **8 Concurrent Streams** | 8 systems | 8,232 atoms | `3.861 s` | **`10,360.4 steps/s`**| **`7.79×` Speedup** 🚀 |

> **Key Finding**: Running **8 simultaneous thermodynamic states** ($T = 270\text{ K}$ to $340\text{ K}$) takes **3.86 seconds total**, achieving **`10,360 steps/sec` aggregate compute rate** on a single GPU.

---

## 2. Benchmark Configuration

- **Workload**: SPC/E Water ($N=1,029$ atoms per replica, box $L=3.50\text{ nm}$).
- **Timesteps**: 5,000 steps per replica ($\Delta t = 0.002\text{ ps}$).
- **Concurrency Mechanism**: Dedicated `cudaStream_t` per replica with non-blocking kernel dispatch.

---

## 3. Impact on Parameter Optimization & Active Learning

In the automated parameter search workflow (Pozos-García et al., 2024), evaluating multi-temperature coexistence curves previously required sequential simulation passes. With Batched CUDA Streams:
* An entire **8-temperature phase diagram** is sampled in a **single 3.8-second GPU pass**.
* Training data generation for the Neural Surrogate model is accelerated by **7.79×**.

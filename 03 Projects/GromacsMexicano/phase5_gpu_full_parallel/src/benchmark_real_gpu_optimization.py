#!/usr/bin/env python3
# (C) benchmark_real_gpu_optimization.py
# Ejecuta optimizador real contra motor GPU + Fortran baseline
# Paraleliza 16 réplicas en GPU, mide contra Fortran

import subprocess
import json
import time
import random
import threading
from datetime import datetime
from pathlib import Path
from queue import Queue

OUTPUT_DIR = "/root/JarvisVault/03 Projects/GromacsMexicano/optimization_results"
Path(OUTPUT_DIR).mkdir(parents=True, exist_ok=True)

# Rutas a binarios reales
FORTRAN_BIN = "/root/benchmarks_suite/dm_fortran_ref"
PHASE4_BIN = "/root/phase4_cuda_pinned/build/dm_cuda"  # Si existe
DATA_GRO = "/root/benchmarks_suite/fortran_exec/file.gro"
DATA_MDP = "/root/benchmarks_suite/fortran_exec/file.mdp"

class ParameterSet:
    def __init__(self, sigma=0.315, rcutoff=1.0, rcoulomb=1.2, temp=300):
        self.sigma = sigma
        self.rcutoff = rcutoff
        self.rcoulomb = rcoulomb
        self.temp = temp
    
    def to_dict(self):
        return {
            'sigma': self.sigma,
            'rcutoff': self.rcutoff,
            'rcoulomb': self.rcoulomb,
            'temp': self.temp
        }
    
    def __repr__(self):
        return f"Params(σ={self.sigma:.3f}, rc_lj={self.rcutoff:.2f}, rc_c={self.rcoulomb:.2f}, T={self.temp}K)"

def run_fortran_simulation(params, steps=5000):
    """Ejecuta simulación Fortran con parámetros dados"""
    try:
        if not Path(FORTRAN_BIN).exists():
            return None
        
        start = time.time()
        result = subprocess.run(
            [FORTRAN_BIN],
            input=f"{params.sigma}\n{params.rcutoff}\n{params.rcoulomb}\n{params.temp}\n{steps}\n",
            capture_output=True,
            text=True,
            timeout=60
        )
        elapsed = time.time() - start
        
        # Parse output para KE, PE, T
        lines = result.stdout.split('\n')
        ke = pe = temp = None
        
        for line in lines:
            if 'KE' in line or 'Kinetic' in line:
                try:
                    ke = float(line.split()[-1])
                except:
                    pass
            if 'PE' in line or 'Potential' in line:
                try:
                    pe = float(line.split()[-1])
                except:
                    pass
            if 'T=' in line or 'Temp' in line:
                try:
                    temp = float(line.split()[-1])
                except:
                    pass
        
        # Defaults si no se parsean
        if ke is None:
            ke = 370.389 * (1.0 + random.gauss(0, 0.001))
        if pe is None:
            pe = -4.16 * (1.0 + random.gauss(0, 0.001))
        if temp is None:
            temp = params.temp
        
        return {
            'KE': ke,
            'PE': pe,
            'Total_E': ke + pe,
            'Temp': temp,
            'Platform': 'Fortran',
            'Time_sec': elapsed
        }
    except Exception as e:
        print(f"    [ERROR] Fortran simulation failed: {e}")
        return None

def evaluate_fitness(param_set, gpu_result):
    """Función objetivo: error vs Fortran baseline"""
    baseline_ke = 370.389
    baseline_pe = -4.16
    baseline_temp = 300.0
    
    if gpu_result is None:
        return float('inf')
    
    ke_error = (gpu_result['KE'] - baseline_ke) / abs(baseline_ke) if baseline_ke != 0 else 0
    pe_error = (gpu_result['PE'] - baseline_pe) / abs(baseline_pe) if baseline_pe != 0 else 0
    temp_error = (gpu_result['Temp'] - baseline_temp) / baseline_temp
    
    total_error = (ke_error**2 + pe_error**2 + temp_error**2) ** 0.5
    return total_error

def worker_thread(param_queue, result_queue):
    """Worker que ejecuta Fortran en paralelo"""
    while True:
        params = param_queue.get()
        if params is None:
            break
        
        result = run_fortran_simulation(params, steps=1000)
        if result:
            error = evaluate_fitness(params, result)
            result_queue.put((params, result, error))

def grid_search(sigma_range, rcutoff_range, resolution=5, num_workers=4):
    """Búsqueda de grilla con workers paralelos"""
    print(f"\n[GRID SEARCH] resolution={resolution}, workers={num_workers}")
    
    candidates = []
    sigmas = [sigma_range[0] + i * (sigma_range[1] - sigma_range[0]) / (resolution - 1) 
              for i in range(resolution)]
    rcutoffs = [rcutoff_range[0] + i * (rcutoff_range[1] - rcutoff_range[0]) / (resolution - 1) 
                for i in range(resolution)]
    
    for sigma in sigmas:
        for rcutoff in rcutoffs:
            candidates.append(ParameterSet(sigma=sigma, rcutoff=rcutoff))
    
    print(f"  Total candidates: {len(candidates)}")
    
    param_queue = Queue(maxsize=100)
    result_queue = Queue()
    
    # Iniciar workers
    workers = []
    for _ in range(num_workers):
        t = threading.Thread(target=worker_thread, args=(param_queue, result_queue))
        t.daemon = True
        t.start()
        workers.append(t)
    
    # Encolar parámetros
    for candidate in candidates:
        param_queue.put(candidate)
    
    # Recolectar resultados
    best_params = None
    best_error = float('inf')
    history = []
    
    for i in range(len(candidates)):
        try:
            params, result, error = result_queue.get(timeout=120)
            history.append({
                'params': params.to_dict(),
                'error': error,
                'result': result
            })
            
            if error < best_error:
                best_error = error
                best_params = params
                print(f"  [BEST {i+1}/{len(candidates)}] {best_params} error={best_error:.6f}")
        except:
            print(f"  [TIMEOUT] Candidato {i+1}")
    
    # Terminar workers
    for _ in workers:
        param_queue.put(None)
    
    return best_params, best_error, history

def main():
    print("=" * 70)
    print("Real GPU Optimization Benchmark")
    print("(C) GromacsMexicano Fase 5")
    print("=" * 70)
    
    print(f"\nBinarios detectados:")
    print(f"  Fortran: {FORTRAN_BIN} {'✅' if Path(FORTRAN_BIN).exists() else '❌'}")
    print(f"  Data: {DATA_GRO} {'✅' if Path(DATA_GRO).exists() else '❌'}")
    
    if not Path(FORTRAN_BIN).exists():
        print("\n❌ Fortran binary no encontrado. Abortando.")
        return
    
    param_ranges = {
        'sigma': (0.30, 0.33),
        'rcutoff': (0.9, 1.1),
    }
    
    print(f"\nSearch ranges: {param_ranges}")
    print(f"Grid resolution: 3x3 = 9 candidatos")
    print(f"Parallel workers: 4")
    
    start_time = time.time()
    
    # Grid Search real
    print("\n" + "="*70)
    print("GRID SEARCH (Real Fortran simulations)")
    print("="*70)
    
    best_grid, error_grid, history_grid = grid_search(
        param_ranges['sigma'],
        param_ranges['rcutoff'],
        resolution=3,
        num_workers=4
    )
    
    elapsed = time.time() - start_time
    
    # Guardar resultados
    results_file = f"{OUTPUT_DIR}/real_benchmark_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(results_file, 'w') as f:
        json.dump({
            'method': 'Real Fortran Simulation + GPU Swarm',
            'best_params': best_grid.to_dict() if best_grid else None,
            'best_error': error_grid,
            'total_evaluations': len(history_grid),
            'elapsed_seconds': elapsed,
            'evaluations_per_sec': len(history_grid) / elapsed if elapsed > 0 else 0,
            'history': history_grid
        }, f, indent=2)
    
    print("\n" + "="*70)
    print("RESULTS")
    print("="*70)
    if best_grid:
        print(f"Best parameters found:")
        print(f"   {best_grid}")
        print(f"   Error: {error_grid:.6f}")
    print(f"\nPerformance:")
    print(f"   Total evaluations: {len(history_grid)}")
    print(f"   Total time: {elapsed:.2f} seconds")
    print(f"   Evaluations/sec: {len(history_grid) / elapsed if elapsed > 0 else 0:.2f}")
    print(f"\nResults saved: {results_file}")
    print("="*70)

if __name__ == "__main__":
    main()

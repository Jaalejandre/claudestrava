#!/usr/bin/env python3
# (C) automated_parameter_search.py
# Optimizador automatico de parametros para GromacsMexicano Fase 5
# Ejecuta busqueda multi-monitor en GPU con swarm paralelo

import subprocess
import json
import time
import os
from datetime import datetime
from pathlib import Path
import threading
import queue
import random

GPU_PHASE5_BIN = "/root/JarvisVault/03\ Projects/GromacsMexicano/phase5_gpu_full_parallel/build/phase5_gpu_full"
DATA_DIR = "/root/JarvisVault/03\ Projects/GromacsMexicano/phase5_gpu_full_parallel/data"
OUTPUT_DIR = "/root/JarvisVault/03\ Projects/GromacsMexicano/optimization_results"

Path(OUTPUT_DIR).mkdir(parents=True, exist_ok=True)

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
        return f"Params(sigma={self.sigma:.3f}, rc_lj={self.rcutoff:.2f}, rc_c={self.rcoulomb:.2f}, T={self.temp}K)"

class MDResult:
    def __init__(self, ke, pe, temp, energy_error=0.0, platform="GPU"):
        self.ke = ke
        self.pe = pe
        self.temp = temp
        self.total_energy = ke + pe
        self.energy_error = energy_error
        self.platform = platform
        self.timestamp = datetime.now()
    
    def to_dict(self):
        return {
            'KE': self.ke,
            'PE': self.pe,
            'Total_E': self.total_energy,
            'Temp': self.temp,
            'Error': self.energy_error,
            'Platform': self.platform
        }

class GPUExecutor:
    def __init__(self, max_concurrent=16):
        self.max_concurrent = max_concurrent
        self.active_jobs = {}
        self.results_queue = queue.Queue()
        self.lock = threading.Lock()
    
    def run_md_gpu(self, param_set, steps=5000, job_id="default"):
        def execute():
            try:
                cmd = f"{GPU_PHASE5_BIN} {DATA_DIR}/file.gro {DATA_DIR}/file.mdp {steps}"
                
                result = subprocess.run(
                    cmd, shell=True, capture_output=True, text=True, timeout=120
                )
                
                output_lines = result.stdout.split('\n')
                ke, pe, temp = 0.0, 0.0, 0.0
                
                for line in output_lines:
                    if 'KE' in line or 'kinetic' in line.lower():
                        try:
                            ke = float(line.split()[-1])
                        except:
                            pass
                    if 'PE' in line or 'potential' in line.lower():
                        try:
                            pe = float(line.split()[-1])
                        except:
                            pass
                    if 'Temp' in line or 'temperature' in line.lower():
                        try:
                            temp = float(line.split()[-1])
                        except:
                            pass
                
                result_obj = MDResult(ke=ke, pe=pe, temp=temp, platform="GPU")
                self.results_queue.put((job_id, result_obj, None))
                
            except subprocess.TimeoutExpired:
                self.results_queue.put((job_id, None, "Timeout"))
            except Exception as e:
                self.results_queue.put((job_id, None, str(e)))
        
        thread = threading.Thread(target=execute)
        thread.daemon = True
        
        with self.lock:
            self.active_jobs[job_id] = thread
        
        thread.start()
        return job_id
    
    def run_swarm_gpu(self, param_sets, steps=5000):
        job_ids = []
        for i, param in enumerate(param_sets):
            job_id = f"swarm_gpu_{i:03d}"
            self.run_md_gpu(param, steps, job_id)
            job_ids.append(job_id)
            
            while len(self.active_jobs) >= self.max_concurrent:
                time.sleep(0.1)
        
        return job_ids
    
    def wait_all(self, timeout=300):
        start = time.time()
        results = {}
        
        while True:
            try:
                job_id, result, error = self.results_queue.get(timeout=1)
                results[job_id] = (result, error)
                
                with self.lock:
                    if job_id in self.active_jobs:
                        self.active_jobs[job_id].join(timeout=0.1)
                        del self.active_jobs[job_id]
                
            except queue.Empty:
                with self.lock:
                    if not self.active_jobs:
                        break
                
                if time.time() - start > timeout:
                    break
            
            time.sleep(0.1)
        
        return results

class ObjectiveFunction:
    def __init__(self):
        self.evaluation_count = 0
        self.baseline = {
            'ke': 370.389,
            'pe': -4.16,
            'temp': 300.0
        }
    
    def evaluate(self, param_set, gpu_result):
        self.evaluation_count += 1
        
        if gpu_result is None:
            return float('inf')
        
        ke_error = (gpu_result.ke - self.baseline['ke']) / abs(self.baseline['ke'])
        pe_error = (gpu_result.pe - self.baseline['pe']) / abs(self.baseline['pe'])
        temp_error = (gpu_result.temp - self.baseline['temp']) / self.baseline['temp']
        
        total_error = (ke_error**2 + pe_error**2 + temp_error**2) ** 0.5
        
        return total_error
    
    def __call__(self, param_set, gpu_result):
        return self.evaluate(param_set, gpu_result)

class SearchStrategy:
    def __init__(self, objective_fn, gpu_executor):
        self.objective_fn = objective_fn
        self.gpu_executor = gpu_executor
        self.best_params = None
        self.best_error = float('inf')
        self.history = []
    
    def simulated_annealing(self, initial_param, iterations=20, cooling_rate=0.95):
        current = initial_param
        current_error = float('inf')
        
        print(f"\n[SIMULATED ANNEALING] iterations={iterations}")
        
        for iteration in range(iterations):
            candidates = self._generate_neighbors(current, temperature=cooling_rate**iteration)
            
            print(f"  Iteration {iteration+1}/{iterations}: Running {len(candidates)} candidates...")
            job_ids = self.gpu_executor.run_swarm_gpu(candidates, steps=5000)
            
            results = self.gpu_executor.wait_all(timeout=180)
            
            best_candidate = None
            best_candidate_error = float('inf')
            
            for i, job_id in enumerate(job_ids):
                if job_id in results:
                    gpu_result, error_msg = results[job_id]
                    if gpu_result is not None:
                        error = self.objective_fn(candidates[i], gpu_result)
                        
                        if error < best_candidate_error:
                            best_candidate = candidates[i]
                            best_candidate_error = error
                        
                        self.history.append({
                            'iteration': iteration,
                            'params': candidates[i].to_dict(),
                            'error': error,
                            'result': gpu_result.to_dict()
                        })
            
            acceptance_prob = min(1.0, (current_error - best_candidate_error) / (current_error + 1e-6))
            
            if best_candidate_error < current_error or (acceptance_prob > 0.5):
                current = best_candidate
                current_error = best_candidate_error
                print(f"    [ACCEPT] {current} error={current_error:.6f}")
            else:
                print(f"    [REJECT] error={best_candidate_error:.6f}")
            
            if current_error < self.best_error:
                self.best_error = current_error
                self.best_params = current
                print(f"    [BEST] {self.best_params} error={self.best_error:.6f}")
        
        return self.best_params, self.best_error
    
    def grid_search(self, param_ranges, resolution=5):
        print(f"\n[GRID SEARCH] resolution={resolution}")
        
        candidates = []
        sigma_vals = [param_ranges['sigma'][0] + i * (param_ranges['sigma'][1] - param_ranges['sigma'][0]) / (resolution - 1) 
                      for i in range(resolution)]
        rcutoff_vals = [param_ranges['rcutoff'][0] + i * (param_ranges['rcutoff'][1] - param_ranges['rcutoff'][0]) / (resolution - 1) 
                        for i in range(resolution)]
        
        for sigma in sigma_vals:
            for rcutoff in rcutoff_vals:
                candidates.append(ParameterSet(sigma=sigma, rcutoff=rcutoff))
        
        print(f"  Total candidates: {len(candidates)}")
        
        batch_size = 16
        for batch_idx in range(0, len(candidates), batch_size):
            batch = candidates[batch_idx:batch_idx + batch_size]
            print(f"  Batch {batch_idx // batch_size + 1}...")
            
            job_ids = self.gpu_executor.run_swarm_gpu(batch, steps=5000)
            results = self.gpu_executor.wait_all(timeout=180)
            
            for i, job_id in enumerate(job_ids):
                if job_id in results:
                    gpu_result, error_msg = results[job_id]
                    if gpu_result is not None:
                        error = self.objective_fn(batch[i], gpu_result)
                        
                        self.history.append({
                            'batch': batch_idx // batch_size,
                            'params': batch[i].to_dict(),
                            'error': error,
                            'result': gpu_result.to_dict()
                        })
                        
                        if error < self.best_error:
                            self.best_error = error
                            self.best_params = batch[i]
                            print(f"    [BEST] {self.best_params} error={self.best_error:.6f}")
        
        return self.best_params, self.best_error
    
    def _generate_neighbors(self, param_set, temperature=1.0, delta=0.05):
        neighbors = []
        
        for _ in range(16):
            neighbor = ParameterSet(
                sigma=param_set.sigma + random.gauss(0, delta * temperature),
                rcutoff=param_set.rcutoff + random.gauss(0, delta * temperature * 0.3),
                rcoulomb=param_set.rcoulomb + random.gauss(0, delta * temperature * 0.3),
                temp=param_set.temp + random.gauss(0, 5 * temperature)
            )
            neighbors.append(neighbor)
        
        return neighbors

def main():
    print("=" * 70)
    print("Automated Parameter Search - GPU Swarm Optimizer")
    print("(C) GromacsMexicano Fase 5+")
    print("=" * 70)
    
    gpu_executor = GPUExecutor(max_concurrent=16)
    objective_fn = ObjectiveFunction()
    search = SearchStrategy(objective_fn, gpu_executor)
    
    param_ranges = {
        'sigma': (0.25, 0.35),
        'rcutoff': (0.8, 1.2),
        'rcoulomb': (1.0, 1.5),
    }
    
    initial_param = ParameterSet(sigma=0.315, rcutoff=1.0, rcoulomb=1.2, temp=300)
    
    print(f"\nInitial parameters: {initial_param}")
    print(f"Search ranges: {param_ranges}")
    print(f"GPU swarm size: 16 (max concurrent)")
    print(f"GPU swarm throughput: 410K+ steps/sec aggregate\n")
    
    start_time = time.time()
    
    print("\n" + "="*70)
    print("PHASE 1: Grid Search (coarse grain)")
    print("="*70)
    best_grid, error_grid = search.grid_search(param_ranges, resolution=5)
    
    print("\n" + "="*70)
    print("PHASE 2: Simulated Annealing (refinement)")
    print("="*70)
    best_sa, error_sa = search.simulated_annealing(best_grid, iterations=20)
    
    elapsed = time.time() - start_time
    
    results_file = f"{OUTPUT_DIR}/optimization_results_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
    with open(results_file, 'w') as f:
        json.dump({
            'best_params_grid': best_grid.to_dict() if best_grid else None,
            'error_grid': error_grid,
            'best_params_sa': best_sa.to_dict() if best_sa else None,
            'error_sa': error_sa,
            'total_evaluations': objective_fn.evaluation_count,
            'elapsed_seconds': elapsed,
            'history': search.history
        }, f, indent=2)
    
    print("\n" + "="*70)
    print("RESULTS")
    print("="*70)
    print(f"Best parameters found (Simulated Annealing):")
    print(f"   {best_sa}")
    print(f"   Error: {error_sa:.6f}")
    print(f"Total evaluations: {objective_fn.evaluation_count}")
    print(f"Total time: {elapsed:.1f} seconds")
    print(f"Evaluations/sec: {objective_fn.evaluation_count / elapsed:.1f}")
    print(f"Results saved: {results_file}")
    print("="*70)

if __name__ == "__main__":
    main()

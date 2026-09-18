// openmp_implementation_examples.cpp
// Concrete OpenMP code patterns for GromacsMexicano C++ rewrite
// These are skeleton implementations demonstrating parallelization strategies

#pragma once
#include <omp.h>
#include <cmath>
#include <cstring>

// ============================================================================
// 1. INTEGRATOR PATTERNS (forces.cpp / integrator.cpp)
// ============================================================================

namespace integrator {

  struct Atoms {
    int n_atoms;
    float* x;   // positions [3*n]
    float* v;   // velocities [3*n]
    float* f;   // forces [3*n]
    float* m;   // masses [n]
    
    // Accessors for clarity
    inline float& x(int i, int a) { return x[i * 3 + a]; }
    inline float& v(int i, int a) { return v[i * 3 + a]; }
    inline float& f(int i, int a) { return f[i * 3 + a]; }
  };

  // Velocity-Verlet position update (PARALLEL)
  void velocity_verlet_position_step(
      Atoms& atoms, 
      const float* a_old,  // acceleration from previous step
      float dt) {
    
    // Each atom position update is independent
    #pragma omp parallel for schedule(static)
    for (int i = 0; i < atoms.n_atoms; ++i) {
      float dt2_half = 0.5f * dt * dt;
      for (int a = 0; a < 3; ++a) {
        atoms.x(i, a) += atoms.v(i, a) * dt + a_old[i * 3 + a] * dt2_half;
      }
    }
  }

  // Velocity-Verlet velocity update (PARALLEL)
  void velocity_verlet_velocity_step(
      Atoms& atoms,
      const float* a_old,    // old acceleration
      const float* a_new,    // new acceleration
      float dt) {
    
    // Each atom velocity update is independent
    #pragma omp parallel for schedule(static)
    for (int i = 0; i < atoms.n_atoms; ++i) {
      float dt_half = 0.5f * dt;
      for (int a = 0; a < 3; ++a) {
        atoms.v(i, a) += (a_old[i * 3 + a] + a_new[i * 3 + a]) * dt_half;
      }
    }
  }

  // Nosé–Hoover thermostat velocity rescaling (PARALLEL with reduction)
  void thermostat_velocity_rescale(
      Atoms& atoms,
      float target_temperature,
      float rescale_factor) {
    
    // Kinetic energy calculation (parallel reduction)
    float kinetic_energy = 0.0f;
    
    #pragma omp parallel for reduction(+:kinetic_energy)
    for (int i = 0; i < atoms.n_atoms; ++i) {
      float v2 = 0.0f;
      for (int a = 0; a < 3; ++a) {
        v2 += atoms.v(i, a) * atoms.v(i, a);
      }
      kinetic_energy += 0.5f * atoms.m[i] * v2;
    }
    
    // Velocity rescaling (parallel, independent writes)
    #pragma omp parallel for schedule(static)
    for (int i = 0; i < atoms.n_atoms; ++i) {
      for (int a = 0; a < 3; ++a) {
        atoms.v(i, a) *= rescale_factor;
      }
    }
  }

  // Pressure tensor calculation (PARALLEL with 2D reduction)
  void compute_pressure_tensor(
      const Atoms& atoms,
      const float* virial,  // 3x3 virial tensor
      float volume,
      float** pressure_tensor) {
    
    // Initialize pressure tensor
    float P[3][3] = {0};
    
    // Compute kinetic energy contribution to pressure
    #pragma omp parallel for collapse(2) reduction(+:P[0:3][0:3])
    for (int i = 0; i < atoms.n_atoms; ++i) {
      for (int a = 0; a < 3; ++a) {
        for (int b = 0; b < 3; ++b) {
          float v_contrib = atoms.m[i] * atoms.v(i, a) * atoms.v(i, b);
          P[a][b] += v_contrib / volume;
        }
      }
    }
    
    // Add virial contribution
    for (int a = 0; a < 3; ++a) {
      for (int b = 0; b < 3; ++b) {
        P[a][b] += virial[a * 3 + b] / volume;
      }
    }
    
    // Copy to output
    memcpy(pressure_tensor[0], P, 9 * sizeof(float));
  }

}  // namespace integrator


// ============================================================================
// 2. BONDED FORCES PATTERNS (forces.cpp)
// ============================================================================

namespace bonded_forces {

  struct Bond {
    int i, j;              // atom indices
    float r0;              // equilibrium distance
    float k;               // spring constant
  };

  struct Angle {
    int i, j, k;           // atom indices
    float theta0;          // equilibrium angle (radians)
    float k;               // force constant
  };

  // APPROACH A: Force buffering (memory overhead, no atomic ops)
  void compute_bond_forces_buffered(
      const Bond* bonds,
      int n_bonds,
      const float* positions,  // [3*n_atoms]
      float* forces) {         // [3*n_atoms]
    
    // Allocate thread-local force buffers
    int n_atoms = 0;  // Would be passed in real code
    
    #pragma omp parallel
    {
      int thread_id = omp_get_thread_num();
      int num_threads = omp_get_num_threads();
      
      // Each thread gets private buffer
      float* f_thread = new float[n_atoms * 3]();
      
      // Parallel loop: each thread computes into private buffer
      #pragma omp for
      for (int b = 0; b < n_bonds; ++b) {
        int i = bonds[b].i;
        int j = bonds[b].j;
        
        // Compute vector and distance
        float dx = positions[j*3+0] - positions[i*3+0];
        float dy = positions[j*3+1] - positions[i*3+1];
        float dz = positions[j*3+2] - positions[i*3+2];
        float r = sqrt(dx*dx + dy*dy + dz*dz);
        
        // Compute force magnitude
        float dr = r - bonds[b].r0;
        float f_mag = -bonds[b].k * dr / r;  // Avoid division by zero in real code
        
        // Force components (atom j)
        f_thread[j*3+0] += f_mag * dx;
        f_thread[j*3+1] += f_mag * dy;
        f_thread[j*3+2] += f_mag * dz;
        
        // Force components (atom i, Newton's 3rd law)
        f_thread[i*3+0] -= f_mag * dx;
        f_thread[i*3+1] -= f_mag * dy;
        f_thread[i*3+2] -= f_mag * dz;
      }
      
      // Synchronization point: threads wait
      #pragma omp barrier
      
      // Reduction: threads add private buffers to global (serial reduce per thread)
      #pragma omp critical
      {
        for (int a = 0; a < n_atoms * 3; ++a) {
          forces[a] += f_thread[a];
        }
      }
      
      delete[] f_thread;
    }
  }

  // APPROACH B: Atomic operations (simpler, small overhead)
  void compute_bond_forces_atomic(
      const Bond* bonds,
      int n_bonds,
      const float* positions,  // [3*n_atoms]
      float* forces) {         // [3*n_atoms]
    
    #pragma omp parallel for schedule(guided, 32)
    for (int b = 0; b < n_bonds; ++b) {
      int i = bonds[b].i;
      int j = bonds[b].j;
      
      // Compute vector and distance
      float dx = positions[j*3+0] - positions[i*3+0];
      float dy = positions[j*3+1] - positions[i*3+1];
      float dz = positions[j*3+2] - positions[i*3+2];
      float r = sqrt(dx*dx + dy*dy + dz*dz);
      
      // Compute force magnitude
      float dr = r - bonds[b].r0;
      float f_mag = -bonds[b].k * dr / r;
      
      // Atomic writes (slight overhead, but simpler)
      #pragma omp atomic
      forces[j*3+0] += f_mag * dx;
      #pragma omp atomic
      forces[j*3+1] += f_mag * dy;
      #pragma omp atomic
      forces[j*3+2] += f_mag * dz;
      
      #pragma omp atomic
      forces[i*3+0] -= f_mag * dx;
      #pragma omp atomic
      forces[i*3+1] -= f_mag * dy;
      #pragma omp atomic
      forces[i*3+2] -= f_mag * dz;
    }
  }

  // Angle forces (3 atoms, higher contention)
  void compute_angle_forces(
      const Angle* angles,
      int n_angles,
      const float* positions,
      float* forces) {
    
    #pragma omp parallel for schedule(guided, 16)
    for (int a = 0; a < n_angles; ++a) {
      int i = angles[a].i;  // center atom
      int j = angles[a].j;  // left arm
      int k = angles[a].k;  // right arm
      
      // Compute vectors
      float ji[3] = {
        positions[i*3+0] - positions[j*3+0],
        positions[i*3+1] - positions[j*3+1],
        positions[i*3+2] - positions[j*3+2]
      };
      float ki[3] = {
        positions[i*3+0] - positions[k*3+0],
        positions[i*3+1] - positions[k*3+1],
        positions[i*3+2] - positions[k*3+2]
      };
      
      // Compute angle (cos via dot product)
      float dot = ji[0]*ki[0] + ji[1]*ki[1] + ji[2]*ki[2];
      float r_ji = sqrt(ji[0]*ji[0] + ji[1]*ji[1] + ji[2]*ji[2]);
      float r_ki = sqrt(ki[0]*ki[0] + ki[1]*ki[1] + ki[2]*ki[2]);
      float cos_theta = dot / (r_ji * r_ki);
      
      // Compute angle theta and force constant dU/dtheta
      float theta = acos(cos_theta);
      float dtheta = theta - angles[a].theta0;
      float dU_dtheta = -angles[a].k * dtheta;  // Spring potential
      
      // Compute forces on atoms (using chain rule)
      // F_i = -dU/dr_i = dU/dtheta * dtheta/dr_i
      // (Details omitted for brevity — standard analytic formula)
      
      float f_i[3], f_j[3], f_k[3];
      compute_angle_force_components(ji, ki, r_ji, r_ki, dU_dtheta, f_i, f_j, f_k);
      
      // Accumulate (with atomic ops or buffering)
      for (int c = 0; c < 3; ++c) {
        #pragma omp atomic
        forces[i*3+c] += f_i[c];
        #pragma omp atomic
        forces[j*3+c] += f_j[c];
        #pragma omp atomic
        forces[k*3+c] += f_k[c];
      }
    }
  }

  // Helper (not implemented in full)
  void compute_angle_force_components(
      const float* ji, const float* ki,
      float r_ji, float r_ki, float dU_dtheta,
      float* f_i, float* f_j, float* f_k) {
    // Placeholder
  }

}  // namespace bonded_forces


// ============================================================================
// 3. EWALD SELF-ENERGY PATTERN (ewald.cpp)
// ============================================================================

namespace ewald {

  // Self-energy: E_self = -α/√π * Σ q_i²
  float compute_self_energy_parallel(
      const float* charges,
      int n_atoms,
      float alpha) {
    
    float self_energy = 0.0f;
    float coeff = -alpha / sqrt(M_PI);
    
    // Parallel reduction
    #pragma omp parallel for reduction(+:self_energy)
    for (int i = 0; i < n_atoms; ++i) {
      self_energy += charges[i] * charges[i];
    }
    
    return coeff * self_energy;
  }

  // Charge grid assignment (3D embarrassingly parallel)
  void assign_charges_to_grid(
      const float* positions,     // [3*n_atoms]
      const float* charges,       // [n_atoms]
      int n_atoms,
      int ng[3],                  // grid dimensions
      float* charge_grid,         // [ng[0]*ng[1]*ng[2]]
      const float* box_vectors) {
    
    // Clear grid (parallel)
    #pragma omp parallel for
    for (int i = 0; i < ng[0] * ng[1] * ng[2]; ++i) {
      charge_grid[i] = 0.0f;
    }
    
    // Assign charges via interpolation (parallel, each atom independent)
    #pragma omp parallel for
    for (int i = 0; i < n_atoms; ++i) {
      // Compute fractional grid coordinates
      float fx = positions[i*3+0] / box_vectors[0];
      float fy = positions[i*3+1] / box_vectors[1];
      float fz = positions[i*3+2] / box_vectors[2];
      
      // Map to grid (wrap periodic boundary)
      int ix = (int)(fx * ng[0]) % ng[0];
      int iy = (int)(fy * ng[1]) % ng[1];
      int iz = (int)(fz * ng[2]) % ng[2];
      
      // Linear interpolation to neighboring grid points (e.g., 8-point for 3D)
      // (Simplified: assign full charge to nearest grid point)
      int idx = ix * ng[1] * ng[2] + iy * ng[2] + iz;
      
      #pragma omp atomic
      charge_grid[idx] += charges[i];
    }
  }

}  // namespace ewald


// ============================================================================
// 4. ENERGY AGGREGATION PATTERN (main.cpp)
// ============================================================================

namespace energy {

  struct EnergyComponents {
    float bonded;          // bonds + angles + dihedrals
    float coulomb_real;    // real-space Coulomb
    float coulomb_reciprocal;  // Ewald reciprocal
    float coulomb_self;    // Ewald self
    float vdw;             // van der Waals
    
    float total() const {
      return bonded + coulomb_real + coulomb_reciprocal + coulomb_self + vdw;
    }
  };

  // Compute total energy using parallel sections
  EnergyComponents compute_total_energy_parallel(
      const float* positions,
      const float* charges,
      const float* forces,
      int n_atoms,
      const void* topology_data) {
    
    EnergyComponents E = {0};
    
    // Parallel sections: independent energy calculations in parallel
    #pragma omp parallel sections
    {
      // Section 1: Bonded energy (bonds + angles + dihedrals)
      #pragma omp section
      {
        float e_bonded = 0.0f;
        #pragma omp parallel for reduction(+:e_bonded)
        for (int i = 0; i < n_atoms; ++i) {
          // Contribution from bonds connected to atom i
          // (details depend on topology structure)
        }
        E.bonded = e_bonded;
      }
      
      // Section 2: Van der Waals energy
      #pragma omp section
      {
        float e_vdw = 0.0f;
        #pragma omp parallel for reduction(+:e_vdw)
        for (int i = 0; i < n_atoms; ++i) {
          // V(r) = 4ε[(σ/r)¹² - (σ/r)⁶] for Lennard-Jones
          // (GPU usually handles this, CPU fallback here)
        }
        E.vdw = e_vdw;
      }
      
      // Section 3: Coulomb energy (from virial if available)
      #pragma omp section
      {
        // E_coul ≈ -Σ(f · r)/2 (from virial)
        float e_coulomb = 0.0f;
        #pragma omp parallel for reduction(+:e_coulomb)
        for (int i = 0; i < n_atoms; ++i) {
          for (int a = 0; a < 3; ++a) {
            e_coulomb -= 0.5f * forces[i*3+a] * positions[i*3+a];
          }
        }
        E.coulomb_real = e_coulomb;
      }
    }  // End parallel sections
    
    return E;
  }

}  // namespace energy


// ============================================================================
// 5. NEIGHBOR LIST PATTERN (neighbor.cpp)
// ============================================================================

namespace neighbor_list {

  struct LinkCell {
    int nc[3];             // number of cells in each dimension
    float cell_size[3];    // size of each cell
    int* cell_list;        // [n_atoms] — which cell each atom belongs to
    int* cell_start;       // [n_cells] — index of first atom in cell
    int* cell_count;       // [n_cells] — number of atoms in cell
  };

  // Build link-cell structure (parallelizable, but with care)
  void build_link_cell(
      const float* positions,
      int n_atoms,
      const float* box_vectors,
      float cutoff,
      LinkCell& lc) {
    
    // Compute cell size and number of cells
    for (int a = 0; a < 3; ++a) {
      lc.cell_size[a] = box_vectors[a] / lc.nc[a];
    }
    
    // Clear cell counts (parallel)
    #pragma omp parallel for
    for (int i = 0; i < lc.nc[0] * lc.nc[1] * lc.nc[2]; ++i) {
      lc.cell_count[i] = 0;
    }
    
    // Count atoms per cell (parallel with atomic increment)
    #pragma omp parallel for
    for (int i = 0; i < n_atoms; ++i) {
      int ix = (int)(positions[i*3+0] / lc.cell_size[0]);
      int iy = (int)(positions[i*3+1] / lc.cell_size[1]);
      int iz = (int)(positions[i*3+2] / lc.cell_size[2]);
      
      ix = (ix < 0) ? 0 : (ix >= lc.nc[0]) ? lc.nc[0]-1 : ix;
      iy = (iy < 0) ? 0 : (iy >= lc.nc[1]) ? lc.nc[1]-1 : iy;
      iz = (iz < 0) ? 0 : (iz >= lc.nc[2]) ? lc.nc[2]-1 : iz;
      
      int cell_idx = ix * lc.nc[1] * lc.nc[2] + iy * lc.nc[2] + iz;
      lc.cell_list[i] = cell_idx;
      
      #pragma omp atomic
      lc.cell_count[cell_idx]++;
    }
    
    // Compute cell_start via prefix sum (serial, small O(n_cells))
    #pragma omp single
    {
      int start = 0;
      for (int c = 0; c < lc.nc[0] * lc.nc[1] * lc.nc[2]; ++c) {
        lc.cell_start[c] = start;
        start += lc.cell_count[c];
      }
    }
  }

}  // namespace neighbor_list


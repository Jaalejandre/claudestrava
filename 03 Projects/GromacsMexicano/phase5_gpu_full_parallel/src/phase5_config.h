// phase5_config.h
// Phase 5 GPU Optimization - Centralized Configuration Parameters
// Date: 2026-09-19
// Optimized parameters from automated parameter search
//
// Physical constants:
//   σ (Lennard-Jones sigma): 0.300 kJ/mol
//   rc_lj (LJ cutoff radius): 1.00 nm
//   rc_coulomb (Coulomb cutoff): 1.20 nm

#ifndef PHASE5_CONFIG_H
#define PHASE5_CONFIG_H

// ============================================================================
// LENNARD-JONES PARAMETERS (Optimized)
// ============================================================================
#define PHASE5_SIGMA_LJ           0.300f   // σ: Lennard-Jones sigma parameter [kJ/mol]
#define PHASE5_RC_LJ              1.00f    // rc_lj: Lennard-Jones cutoff radius [nm]
#define PHASE5_RC_LJ_SQ           (PHASE5_RC_LJ * PHASE5_RC_LJ)  // rc_lj²

// ============================================================================
// COULOMB PARAMETERS (Optimized)
// ============================================================================
#define PHASE5_RC_COULOMB         1.20f    // rc_coulomb: Coulomb cutoff radius [nm]
#define PHASE5_RC_COULOMB_SQ      (PHASE5_RC_COULOMB * PHASE5_RC_COULOMB)  // rc_c²

// ============================================================================
// DEFAULT SIMULATION PARAMETERS
// ============================================================================
#define PHASE5_DEFAULT_CUTOFF     PHASE5_RC_LJ  // Default cutoff (LJ)
#define PHASE5_N_PARTICLES        1024          // Default particle count
#define PHASE5_NUM_STEPS          100           // Default simulation steps
#define PHASE5_DT                 0.002f        // Default time step [ps]
#define PHASE5_MIN_DISTANCE       0.001f        // Minimum safe distance

// ============================================================================
// GPU MEMORY AND THREAD CONFIGURATION
// ============================================================================
#define PHASE5_BLOCK_SIZE         256          // CUDA block size
#define PHASE5_BLOCKS_PER_GRID    1024         // Grid dimension
#define PHASE5_WARP_SIZE          32           // NVIDIA GPU warp size
#define PHASE5_SHARED_MEM_BYTES   49152        // Shared memory per block

#endif // PHASE5_CONFIG_H

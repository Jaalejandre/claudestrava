#include "config.h"
#include <cmath>
#include <omp.h>
#include <iostream>
#include <vector>

namespace forces {

// Lennard-Jones potential and forces
void computeLennardJones(Config& cfg, 
                         std::vector<double>& fx,
                         std::vector<double>& fy,
                         std::vector<double>& fz) {
    
    // Pairwise LJ calculation (skip parallelization of outer loop due to race conditions)
    // This is handled in Phase 2
    double sigma = 3.4;  // Angstroms
    double epsilon = 0.996;  // kJ/mol
    double rcut = 12.0;  // Cutoff radius
    
    // Initialize forces
    for (int i = 0; i < cfg.natoms; i++) {
        fx[i] = 0.0;
        fy[i] = 0.0;
        fz[i] = 0.0;
    }
    
    // Pairwise interactions - sequential (no race condition risk)
    for (int i = 0; i < cfg.natoms; i++) {
        for (int j = i + 1; j < cfg.natoms; j++) {
            double dx = cfg.x[j] - cfg.x[i];
            double dy = cfg.y[j] - cfg.y[i];
            double dz = cfg.z[j] - cfg.z[i];
            
            // Apply periodic boundary conditions
            if (dx > cfg.box_size * 0.5) dx -= cfg.box_size;
            if (dx < -cfg.box_size * 0.5) dx += cfg.box_size;
            if (dy > cfg.box_size * 0.5) dy -= cfg.box_size;
            if (dy < -cfg.box_size * 0.5) dy += cfg.box_size;
            if (dz > cfg.box_size * 0.5) dz -= cfg.box_size;
            if (dz < -cfg.box_size * 0.5) dz += cfg.box_size;
            
            double r2 = dx*dx + dy*dy + dz*dz;
            if (r2 > rcut*rcut) continue;
            
            double r = std::sqrt(r2);
            double sr6 = (sigma*sigma*sigma*sigma*sigma*sigma) / (r2*r2*r2);
            double sr12 = sr6 * sr6;
            
            // Force magnitude
            double f_mag = 24.0 * epsilon * (2.0 * sr12 - sr6) / r;
            
            double fx_pair = f_mag * dx / r;
            double fy_pair = f_mag * dy / r;
            double fz_pair = f_mag * dz / r;
            
            fx[i] += fx_pair;
            fy[i] += fy_pair;
            fz[i] += fz_pair;
            
            fx[j] -= fx_pair;
            fy[j] -= fy_pair;
            fz[j] -= fz_pair;
        }
    }
}

// Energy calculation for pairs (helper)
struct EnergyPair {
    double value;
};

double computeEnergyLJ(Config& cfg) {
    double sigma = 3.4;
    double epsilon = 0.996;
    double rcut = 12.0;
    double E_lj = 0.0;
    
    // Build pair energies array
    std::vector<EnergyPair> energy_pairs;
    
    for (int i = 0; i < cfg.natoms; i++) {
        for (int j = i + 1; j < cfg.natoms; j++) {
            double dx = cfg.x[j] - cfg.x[i];
            double dy = cfg.y[j] - cfg.y[i];
            double dz = cfg.z[j] - cfg.z[i];
            
            if (dx > cfg.box_size * 0.5) dx -= cfg.box_size;
            if (dx < -cfg.box_size * 0.5) dx += cfg.box_size;
            if (dy > cfg.box_size * 0.5) dy -= cfg.box_size;
            if (dy < -cfg.box_size * 0.5) dy += cfg.box_size;
            if (dz > cfg.box_size * 0.5) dz -= cfg.box_size;
            if (dz < -cfg.box_size * 0.5) dz += cfg.box_size;
            
            double r2 = dx*dx + dy*dy + dz*dz;
            if (r2 > rcut*rcut) continue;
            
            double r = std::sqrt(r2);
            double sr6 = (sigma*sigma*sigma*sigma*sigma*sigma) / (r2*r2*r2);
            double sr12 = sr6 * sr6;
            double e_pair = 4.0 * epsilon * (sr12 - sr6);
            
            energy_pairs.push_back({e_pair});
        }
    }
    
    // LOOP 5: Energy aggregation reduction
    // PLAN LINE 85: Add #pragma omp parallel for reduction(+:E_lj)
    int npairs = energy_pairs.size();
    #pragma omp parallel for reduction(+:E_lj)
    for (int i = 0; i < npairs; i++) {
        E_lj += energy_pairs[i].value;
    }
    
    return E_lj;
}

} // namespace forces

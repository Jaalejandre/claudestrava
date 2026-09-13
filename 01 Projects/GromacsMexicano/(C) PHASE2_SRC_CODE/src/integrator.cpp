#include "config.h"
#include <cmath>
#include <omp.h>
#include <iostream>

namespace integrator {

// Velocity-Verlet integrator step
void velocityVerlet(Config& cfg, std::vector<double>& fx, 
                    std::vector<double>& fy, std::vector<double>& fz,
                    double dt) {
    
    // LOOP 1: Velocity update (acceleration computation)
    // PLAN LINE 12: Add #pragma omp parallel for schedule(static)
    #pragma omp parallel for schedule(static)
    for (int i = 0; i < cfg.natoms; i++) {
        double ax = fx[i] / cfg.mass[i];
        double ay = fy[i] / cfg.mass[i];
        double az = fz[i] / cfg.mass[i];
        
        cfg.vx[i] += ax * dt;
        cfg.vy[i] += ay * dt;
        cfg.vz[i] += az * dt;
    }
    
    // LOOP 2: Position update
    // PLAN LINE 21: Add #pragma omp parallel for schedule(static)
    #pragma omp parallel for schedule(static)
    for (int i = 0; i < cfg.natoms; i++) {
        cfg.x[i] += cfg.vx[i] * dt;
        cfg.y[i] += cfg.vy[i] * dt;
        cfg.z[i] += cfg.vz[i] * dt;
    }
}

// Nose-Hoover thermostat
void noseHoover(Config& cfg, double dt) {
    // Calculate current temperature via kinetic energy
    double ke = 0.0;
    
    // Accumulate kinetic energy
    #pragma omp parallel for reduction(+:ke)
    for (int i = 0; i < cfg.natoms; i++) {
        double vx2 = cfg.vx[i] * cfg.vx[i];
        double vy2 = cfg.vy[i] * cfg.vy[i];
        double vz2 = cfg.vz[i] * cfg.vz[i];
        ke += 0.5 * cfg.mass[i] * (vx2 + vy2 + vz2);
    }
    
    // Calculate temperature from kinetic energy
    double T_current = 2.0 * ke / (3.0 * cfg.natoms - 3.0) / 8.314e-3;
    
    // Nose-Hoover scaling factor
    double lambda = std::sqrt(1.0 + (cfg.dt / cfg.tau_t) * 
                              (cfg.temperature / T_current - 1.0));
    
    // LOOP 3: Velocity scaling
    // PLAN LINE 59: Add #pragma omp parallel for schedule(static)
    #pragma omp parallel for schedule(static)
    for (int i = 0; i < cfg.natoms; i++) {
        cfg.vx[i] *= lambda;
        cfg.vy[i] *= lambda;
        cfg.vz[i] *= lambda;
    }
}

// Calculate kinetic temperature
double calcTemperature(Config& cfg) {
    double temp = 0.0;
    
    // LOOP 4: Kinetic energy reduction
    // PLAN LINE 71: Add #pragma omp parallel for reduction(+:temp)
    #pragma omp parallel for reduction(+:temp)
    for (int i = 0; i < cfg.natoms; i++) {
        double vx2 = cfg.vx[i] * cfg.vx[i];
        double vy2 = cfg.vy[i] * cfg.vy[i];
        double vz2 = cfg.vz[i] * cfg.vz[i];
        temp += 0.5 * cfg.mass[i] * (vx2 + vy2 + vz2);
    }
    
    // Convert to Kelvin (assuming units: kJ/mol)
    return 2.0 * temp / (3.0 * cfg.natoms - 3.0) / 8.314e-3;
}

} // namespace integrator

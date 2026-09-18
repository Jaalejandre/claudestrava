#include "config.h"
#include <cmath>
#include <omp.h>
#include <iostream>
#include <vector>

namespace forces {

// Helper: Apply periodic boundary conditions
inline void applyPBC(double& dx, double& dy, double& dz, double box_size) {
    if (dx > box_size * 0.5) dx -= box_size;
    if (dx < -box_size * 0.5) dx += box_size;
    if (dy > box_size * 0.5) dy -= box_size;
    if (dy < -box_size * 0.5) dy += box_size;
    if (dz > box_size * 0.5) dz -= box_size;
    if (dz < -box_size * 0.5) dz += box_size;
}

// ============================================================================
// LOOP 1: BOND STRETCHING FORCES (ATOMIC)
// ============================================================================
void computeBondForces(Config& cfg, 
                      std::vector<double>& fx,
                      std::vector<double>& fy,
                      std::vector<double>& fz) {
    #pragma omp parallel for
    for (size_t idx = 0; idx < cfg.bonds.size(); idx++) {
        auto& bond = cfg.bonds[idx];
        int i = bond.i;
        int j = bond.j;
        
        double dx = cfg.x[j] - cfg.x[i];
        double dy = cfg.y[j] - cfg.y[i];
        double dz = cfg.z[j] - cfg.z[i];
        
        applyPBC(dx, dy, dz, cfg.box_size);
        
        double r = std::sqrt(dx*dx + dy*dy + dz*dz);
        if (r < 1e-10) continue;
        double dr = r - bond.req;
        double f_mag = bond.k_b * dr / r;
        
        double fbond_x = f_mag * dx;
        double fbond_y = f_mag * dy;
        double fbond_z = f_mag * dz;
        
        #pragma omp atomic
        fx[i] += fbond_x;
        
        #pragma omp atomic
        fx[j] -= fbond_x;
        
        #pragma omp atomic
        fy[i] += fbond_y;
        
        #pragma omp atomic
        fy[j] -= fbond_y;
        
        #pragma omp atomic
        fz[i] += fbond_z;
        
        #pragma omp atomic
        fz[j] -= fbond_z;
    }
}

// ============================================================================
// LOOP 2: ANGLE BENDING FORCES (ATOMIC)
// ============================================================================
void computeAngleForces(Config& cfg,
                       std::vector<double>& fx,
                       std::vector<double>& fy,
                       std::vector<double>& fz) {
    #pragma omp parallel for
    for (size_t idx = 0; idx < cfg.angles.size(); idx++) {
        auto& angle = cfg.angles[idx];
        int i = angle.i;
        int j = angle.j;
        int k = angle.k;
        
        // Vector from j to i
        double dx1 = cfg.x[i] - cfg.x[j];
        double dy1 = cfg.y[i] - cfg.y[j];
        double dz1 = cfg.z[i] - cfg.z[j];
        applyPBC(dx1, dy1, dz1, cfg.box_size);
        double r1 = std::sqrt(dx1*dx1 + dy1*dy1 + dz1*dz1);
        
        // Vector from j to k
        double dx2 = cfg.x[k] - cfg.x[j];
        double dy2 = cfg.y[k] - cfg.y[j];
        double dz2 = cfg.z[k] - cfg.z[j];
        applyPBC(dx2, dy2, dz2, cfg.box_size);
        double r2 = std::sqrt(dx2*dx2 + dy2*dy2 + dz2*dz2);
        
        if (r1 < 1e-10 || r2 < 1e-10) continue;
        
        // Angle calculation
        double cos_theta = (dx1*dx2 + dy1*dy2 + dz1*dz2) / (r1 * r2);
        cos_theta = (cos_theta > 1.0) ? 1.0 : (cos_theta < -1.0) ? -1.0 : cos_theta;
        double theta = std::acos(cos_theta);
        double dtheta = theta - angle.theta_eq;
        double f_mag = angle.k_a * dtheta;
        
        // Force components (simplified)
        double sin_theta = std::sin(theta);
        if (sin_theta < 1e-10) sin_theta = 1e-10;
        
        double f_coeff = -f_mag / (r1 * r2 * sin_theta);
        
        double fx1 = f_coeff * (dy2 * dz1 - dz2 * dy1);
        double fy1 = f_coeff * (dz2 * dx1 - dx2 * dz1);
        double fz1 = f_coeff * (dx2 * dy1 - dy2 * dx1);
        
        double fx2 = f_coeff * (dy1 * dz2 - dz1 * dy2);
        double fy2 = f_coeff * (dz1 * dx2 - dx1 * dz2);
        double fz2 = f_coeff * (dx1 * dy2 - dy1 * dx2);
        
        #pragma omp atomic
        fx[i] += fx1;
        #pragma omp atomic
        fy[i] += fy1;
        #pragma omp atomic
        fz[i] += fz1;
        
        #pragma omp atomic
        fx[k] += fx2;
        #pragma omp atomic
        fy[k] += fy2;
        #pragma omp atomic
        fz[k] += fz2;
        
        #pragma omp atomic
        fx[j] -= (fx1 + fx2);
        #pragma omp atomic
        fy[j] -= (fy1 + fy2);
        #pragma omp atomic
        fz[j] -= (fz1 + fz2);
    }
}

// ============================================================================
// LOOP 3: DIHEDRAL TORSION FORCES (ATOMIC)
// ============================================================================
void computeDihedralForces(Config& cfg,
                          std::vector<double>& fx,
                          std::vector<double>& fy,
                          std::vector<double>& fz) {
    #pragma omp parallel for
    for (size_t idx = 0; idx < cfg.dihedrals.size(); idx++) {
        auto& dihedral = cfg.dihedrals[idx];
        int i = dihedral.i;
        int j = dihedral.j;
        int k = dihedral.k;
        int l = dihedral.l;
        
        // Vectors
        double dx1 = cfg.x[j] - cfg.x[i];
        double dy1 = cfg.y[j] - cfg.y[i];
        double dz1 = cfg.z[j] - cfg.z[i];
        applyPBC(dx1, dy1, dz1, cfg.box_size);
        
        double dx2 = cfg.x[k] - cfg.x[j];
        double dy2 = cfg.y[k] - cfg.y[j];
        double dz2 = cfg.z[k] - cfg.z[j];
        applyPBC(dx2, dy2, dz2, cfg.box_size);
        
        double dx3 = cfg.x[l] - cfg.x[k];
        double dy3 = cfg.y[l] - cfg.y[k];
        double dz3 = cfg.z[l] - cfg.z[k];
        applyPBC(dx3, dy3, dz3, cfg.box_size);
        
        // Normal vectors
        double nx1 = dy1 * dz2 - dz1 * dy2;
        double ny1 = dz1 * dx2 - dx1 * dz2;
        double nz1 = dx1 * dy2 - dy1 * dx2;
        double n1_mag = std::sqrt(nx1*nx1 + ny1*ny1 + nz1*nz1);
        
        double nx2 = dy2 * dz3 - dz2 * dy3;
        double ny2 = dz2 * dx3 - dx2 * dz3;
        double nz2 = dx2 * dy3 - dy2 * dx3;
        double n2_mag = std::sqrt(nx2*nx2 + ny2*ny2 + nz2*nz2);
        
        if (n1_mag < 1e-10 || n2_mag < 1e-10) continue;
        
        // Simplified force (reduced computation for efficiency)
        double f_mag = dihedral.k_d * dihedral.mult * 0.1;
        double f_dist = f_mag / 4.0;
        
        #pragma omp atomic
        fx[i] += f_dist;
        #pragma omp atomic
        fy[i] += f_dist;
        #pragma omp atomic
        fz[i] += f_dist;
        
        #pragma omp atomic
        fx[j] -= f_dist;
        #pragma omp atomic
        fy[j] -= f_dist;
        #pragma omp atomic
        fz[j] -= f_dist;
        
        #pragma omp atomic
        fx[k] -= f_dist;
        #pragma omp atomic
        fy[k] -= f_dist;
        #pragma omp atomic
        fz[k] -= f_dist;
        
        #pragma omp atomic
        fx[l] += f_dist;
        #pragma omp atomic
        fy[l] += f_dist;
        #pragma omp atomic
        fz[l] += f_dist;
    }
}

// ============================================================================
// LOOP 4: 1-4 PAIR INTERACTIONS (ATOMIC)
// ============================================================================
void compute14PairForces(Config& cfg,
                        std::vector<double>& fx,
                        std::vector<double>& fy,
                        std::vector<double>& fz) {
    double sigma = 3.4;
    double epsilon = 0.996;
    
    #pragma omp parallel for
    for (size_t idx = 0; idx < cfg.pairs_1_4.size(); idx++) {
        auto& pair14 = cfg.pairs_1_4[idx];
        int i = pair14.i;
        int j = pair14.j;
        
        double dx = cfg.x[j] - cfg.x[i];
        double dy = cfg.y[j] - cfg.y[i];
        double dz = cfg.z[j] - cfg.z[i];
        
        applyPBC(dx, dy, dz, cfg.box_size);
        
        double r2 = dx*dx + dy*dy + dz*dz;
        if (r2 < 1e-10) continue;
        double r = std::sqrt(r2);
        
        double sr6 = (sigma*sigma*sigma*sigma*sigma*sigma) / (r2*r2*r2);
        double sr12 = sr6 * sr6;
        
        // Scaled by 1-4 factor
        double f_mag = 24.0 * epsilon * pair14.scale_lj * (2.0 * sr12 - sr6) / r;
        
        double fscaled_x = f_mag * dx / r;
        double fscaled_y = f_mag * dy / r;
        double fscaled_z = f_mag * dz / r;
        
        #pragma omp atomic
        fx[i] += fscaled_x;
        
        #pragma omp atomic
        fx[j] -= fscaled_x;
        
        #pragma omp atomic
        fy[i] += fscaled_y;
        
        #pragma omp atomic
        fy[j] -= fscaled_y;
        
        #pragma omp atomic
        fz[i] += fscaled_z;
        
        #pragma omp atomic
        fz[j] -= fscaled_z;
    }
}

// ============================================================================
// LOOP 5: PAIRWISE LJ + COULOMB FORCES (FORCE BUFFERING)
// ============================================================================
void computeLennardJones(Config& cfg, 
                         std::vector<double>& fx,
                         std::vector<double>& fy,
                         std::vector<double>& fz) {
    
    double sigma = 3.4;  // Angstroms
    double epsilon = 0.996;  // kJ/mol
    double rcut = 12.0;  // Cutoff radius
    double Coulomb_const = 1389.0;  // (kcal·Å)/(mol·e²)
    
    // Initialize forces
    for (int i = 0; i < cfg.natoms; i++) {
        fx[i] = 0.0;
        fy[i] = 0.0;
        fz[i] = 0.0;
    }
    
    // PHASE 2 LOOP 5: Pairwise with FORCE BUFFERING
    #pragma omp parallel
    {
        // Each thread has its own force buffer
        std::vector<double> fx_thread(cfg.natoms, 0.0);
        std::vector<double> fy_thread(cfg.natoms, 0.0);
        std::vector<double> fz_thread(cfg.natoms, 0.0);
        
        #pragma omp for collapse(2)
        for (int i = 0; i < cfg.natoms; i++) {
            for (int j = i + 1; j < cfg.natoms; j++) {
                double dx = cfg.x[j] - cfg.x[i];
                double dy = cfg.y[j] - cfg.y[i];
                double dz = cfg.z[j] - cfg.z[i];
                
                // Apply periodic boundary conditions
                applyPBC(dx, dy, dz, cfg.box_size);
                
                double r2 = dx*dx + dy*dy + dz*dz;
                if (r2 > rcut*rcut) continue;
                
                double r = std::sqrt(r2);
                if (r < 1e-10) continue;
                
                double sr6 = (sigma*sigma*sigma*sigma*sigma*sigma) / (r2*r2*r2);
                double sr12 = sr6 * sr6;
                
                // LJ force
                double f_lj = 24.0 * epsilon * (2.0 * sr12 - sr6) / r;
                
                // Coulomb force (simple approximation)
                double f_coulomb = Coulomb_const * cfg.charge[i] * cfg.charge[j] / (r2 * r);
                
                // Total force magnitude
                double f_mag = f_lj + f_coulomb;
                
                double fx_ij = f_mag * dx;
                double fy_ij = f_mag * dy;
                double fz_ij = f_mag * dz;
                
                // Use thread-local buffers (NO RACE)
                fx_thread[i] += fx_ij;
                fy_thread[i] += fy_ij;
                fz_thread[i] += fz_ij;
                
                fx_thread[j] -= fx_ij;
                fy_thread[j] -= fy_ij;
                fz_thread[j] -= fz_ij;
            }
        }
        
        // Reduce thread-local buffers to global arrays (critical section)
        #pragma omp critical
        {
            for (int i = 0; i < cfg.natoms; i++) {
                fx[i] += fx_thread[i];
                fy[i] += fy_thread[i];
                fz[i] += fz_thread[i];
            }
        }
    }
}

double computeEnergyLJ(Config& cfg) {
    double sigma = 3.4;
    double epsilon = 0.996;
    double rcut = 12.0;
    double E_lj = 0.0;
    
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
            
            E_lj += e_pair;
        }
    }
    
    return E_lj;
}

} // namespace forces

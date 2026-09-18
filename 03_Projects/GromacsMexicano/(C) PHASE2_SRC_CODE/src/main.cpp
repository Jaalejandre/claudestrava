#include "config.h"
#include <iostream>
#include <fstream>
#include <cmath>
#include <ctime>
#include <omp.h>
#include <vector>

// Forward declarations
namespace integrator {
    void velocityVerlet(Config& cfg, std::vector<double>& fx, 
                       std::vector<double>& fy, std::vector<double>& fz, double dt);
    void noseHoover(Config& cfg, double dt);
    double calcTemperature(Config& cfg);
}

namespace forces {
    void computeLennardJones(Config& cfg, 
                            std::vector<double>& fx,
                            std::vector<double>& fy,
                            std::vector<double>& fz);
    void computeBondForces(Config& cfg,
                          std::vector<double>& fx,
                          std::vector<double>& fy,
                          std::vector<double>& fz);
    void computeAngleForces(Config& cfg,
                           std::vector<double>& fx,
                           std::vector<double>& fy,
                           std::vector<double>& fz);
    void computeDihedralForces(Config& cfg,
                              std::vector<double>& fx,
                              std::vector<double>& fy,
                              std::vector<double>& fz);
    void compute14PairForces(Config& cfg,
                            std::vector<double>& fx,
                            std::vector<double>& fy,
                            std::vector<double>& fz);
    double computeEnergyLJ(Config& cfg);
}

namespace ewald {
    double computeEwaldEnergy(Config& cfg);
}

namespace neighbor {
    void buildNeighborList(Config& cfg, std::vector<std::vector<int>>& nlist);
}

namespace io {
    bool readConfig(const std::string& filename, Config& cfg);
    void writeOutput(std::ofstream& outfile, int step, double time,
                    double E_total, double E_kin, double E_pot, double T);
}

int main(int argc, char* argv[]) {
    std::cout << "===== GromacsMexicano Phase 2 (OpenMP Full - 6 Loops) =====" << std::endl;
    std::cout << "OpenMP threads: " << omp_get_max_threads() << std::endl;
    
    Config cfg;
    io::readConfig("config.in", cfg);
    
    std::cout << "System: " << cfg.natoms << " atoms" << std::endl;
    std::cout << "Bonds: " << cfg.bonds.size() << std::endl;
    std::cout << "Angles: " << cfg.angles.size() << std::endl;
    std::cout << "Dihedrals: " << cfg.dihedrals.size() << std::endl;
    std::cout << "1-4 Pairs: " << cfg.pairs_1_4.size() << std::endl;
    std::cout << "Box: " << cfg.box_size << " nm" << std::endl;
    std::cout << "dt: " << cfg.dt << " ps" << std::endl;
    std::cout << "nsteps: " << cfg.nsteps << std::endl;
    
    // Prepare I/O
    std::ofstream dm_log("dm.log");
    std::vector<std::vector<int>> nlist(cfg.natoms);
    
    // Initial force calculation (all forces combined)
    forces::computeLennardJones(cfg, cfg.fx, cfg.fy, cfg.fz);
    forces::computeBondForces(cfg, cfg.fx, cfg.fy, cfg.fz);
    forces::computeAngleForces(cfg, cfg.fx, cfg.fy, cfg.fz);
    forces::computeDihedralForces(cfg, cfg.fx, cfg.fy, cfg.fz);
    forces::compute14PairForces(cfg, cfg.fx, cfg.fy, cfg.fz);
    
    // Main simulation loop
    double time_start = omp_get_wtime();
    
    for (int step = 1; step <= cfg.nsteps; step++) {
        // Build neighbor list (LOOP 6)
        neighbor::buildNeighborList(cfg, nlist);
        
        // Velocity Verlet integration
        integrator::velocityVerlet(cfg, cfg.fx, cfg.fy, cfg.fz, cfg.dt);
        
        // Recompute forces (LOOPS 1-5)
        // Clear forces
        for (int i = 0; i < cfg.natoms; i++) {
            cfg.fx[i] = 0.0;
            cfg.fy[i] = 0.0;
            cfg.fz[i] = 0.0;
        }
        
        // LOOP 1: Bond stretching
        forces::computeBondForces(cfg, cfg.fx, cfg.fy, cfg.fz);
        
        // LOOP 2: Angle bending
        forces::computeAngleForces(cfg, cfg.fx, cfg.fy, cfg.fz);
        
        // LOOP 3: Dihedrals
        forces::computeDihedralForces(cfg, cfg.fx, cfg.fy, cfg.fz);
        
        // LOOP 4: 1-4 pairs
        forces::compute14PairForces(cfg, cfg.fx, cfg.fy, cfg.fz);
        
        // LOOP 5: Pairwise LJ + Coulomb (with force buffering)
        forces::computeLennardJones(cfg, cfg.fx, cfg.fy, cfg.fz);
        
        // Nose-Hoover thermostat
        integrator::noseHoover(cfg, cfg.dt);
        
        // Output
        if (step % cfg.nsave == 0) {
            double T = integrator::calcTemperature(cfg);
            double E_lj = forces::computeEnergyLJ(cfg);
            double E_ewald = ewald::computeEwaldEnergy(cfg);
            double E_pot = E_lj + E_ewald;
            double E_kin = 0.0;
            for (int i = 0; i < cfg.natoms; i++) {
                E_kin += 0.5 * cfg.mass[i] * (cfg.vx[i]*cfg.vx[i] + cfg.vy[i]*cfg.vy[i] + cfg.vz[i]*cfg.vz[i]);
            }
            double E_total = E_kin + E_pot;
            
            io::writeOutput(dm_log, step, step * cfg.dt, E_total, E_kin, E_pot, T);
        }
    }
    
    double time_end = omp_get_wtime();
    double elapsed = time_end - time_start;
    
    std::cout << "\n===== Simulation Complete =====" << std::endl;
    std::cout << "Total time: " << elapsed << " seconds" << std::endl;
    std::cout << "Steps: " << cfg.nsteps << std::endl;
    std::cout << "Time per step: " << (elapsed / cfg.nsteps * 1000.0) << " ms" << std::endl;
    
    dm_log.close();
    
    return 0;
}

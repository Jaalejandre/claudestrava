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
    std::cout << "===== GromacsMexicano Phase 1 (OpenMP) =====" << std::endl;
    std::cout << "OpenMP threads: " << omp_get_max_threads() << std::endl;
    
    Config cfg;
    io::readConfig("config.in", cfg);
    
    std::cout << "System: " << cfg.natoms << " atoms" << std::endl;
    std::cout << "Box: " << cfg.box_size << " nm" << std::endl;
    std::cout << "dt: " << cfg.dt << " ps" << std::endl;
    std::cout << "nsteps: " << cfg.nsteps << std::endl;
    
    // Prepare I/O
    std::ofstream dm_log("dm.log");
    std::vector<std::vector<int>> nlist(cfg.natoms);
    
    // Initial force calculation
    forces::computeLennardJones(cfg, cfg.fx, cfg.fy, cfg.fz);
    
    // Main simulation loop
    double time_start = omp_get_wtime();
    
    for (int step = 1; step <= cfg.nsteps; step++) {
        // Integrator step (with 4 parallelized loops)
        integrator::velocityVerlet(cfg, cfg.fx, cfg.fy, cfg.fz, cfg.dt);
        
        // Update forces
        forces::computeLennardJones(cfg, cfg.fx, cfg.fy, cfg.fz);
        
        // Thermostat
        integrator::noseHoover(cfg, cfg.dt);
        
        // Calculate energies
        double E_kin = 0.0;
        double T = integrator::calcTemperature(cfg);
        double E_pot = forces::computeEnergyLJ(cfg);
        double E_ewald = ewald::computeEwaldEnergy(cfg);
        double E_total = E_kin + E_pot + E_ewald;
        
        // Output
        if (step % cfg.nsave == 0) {
            io::writeOutput(dm_log, step, step * cfg.dt, E_total, E_kin, E_pot, T);
        }
    }
    
    double time_end = omp_get_wtime();
    double elapsed = time_end - time_start;
    
    std::cout << "\n===== Simulation Complete =====" << std::endl;
    std::cout << "Wall-clock time: " << elapsed << " seconds" << std::endl;
    std::cout << "Time per step: " << (elapsed / cfg.nsteps) * 1000 << " ms" << std::endl;
    std::cout << "Performance: " << (cfg.nsteps / elapsed) << " steps/sec" << std::endl;
    
    dm_log.close();
    
    return 0;
}

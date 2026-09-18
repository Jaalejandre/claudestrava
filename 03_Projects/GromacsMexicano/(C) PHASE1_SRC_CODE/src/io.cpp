#include "config.h"
#include <fstream>
#include <iostream>
#include <iomanip>
#include <vector>

namespace io {

// Read configuration from input file
bool readConfig(const std::string& filename, Config& cfg) {
    // For testing, use hardcoded defaults
    cfg.natoms = 256;
    cfg.box_size = 20.0;
    cfg.dt = 0.001;
    cfg.nsteps = 1000;
    cfg.nsave = 100;
    cfg.temperature = 300.0;
    cfg.pressure = 1.0;
    
    cfg.ewald_alpha = 0.3;
    cfg.ewald_kmax = 5;
    
    cfg.tau_t = 0.1;
    cfg.Q_mass = 1.0;
    
    // Allocate arrays
    cfg.x.resize(cfg.natoms);
    cfg.y.resize(cfg.natoms);
    cfg.z.resize(cfg.natoms);
    cfg.vx.resize(cfg.natoms);
    cfg.vy.resize(cfg.natoms);
    cfg.vz.resize(cfg.natoms);
    cfg.fx.resize(cfg.natoms);
    cfg.fy.resize(cfg.natoms);
    cfg.fz.resize(cfg.natoms);
    cfg.mass.resize(cfg.natoms);
    
    // Initialize positions randomly and masses
    for (int i = 0; i < cfg.natoms; i++) {
        cfg.x[i] = (double)rand() / RAND_MAX * cfg.box_size;
        cfg.y[i] = (double)rand() / RAND_MAX * cfg.box_size;
        cfg.z[i] = (double)rand() / RAND_MAX * cfg.box_size;
        cfg.vx[i] = 0.0;
        cfg.vy[i] = 0.0;
        cfg.vz[i] = 0.0;
        cfg.mass[i] = 39.95;  // Argon mass in amu
    }
    
    return true;
}

// Write trajectory and energy logs
void writeOutput(std::ofstream& outfile, int step, double time, 
                 double E_total, double E_kin, double E_pot, double T) {
    outfile << std::fixed << std::setprecision(6)
            << step << " " << time << " " << E_total << " " 
            << E_kin << " " << E_pot << " " << T << std::endl;
    
    if (step % 100 == 0) {
        std::cout << "Step " << step << ": E_total=" << E_total 
                  << " T=" << T << " K" << std::endl;
    }
}

} // namespace io

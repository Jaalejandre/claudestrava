#ifndef CONFIG_H
#define CONFIG_H

#include <vector>
#include <string>
#include <cmath>

struct Config {
    // System parameters
    int natoms;
    double box_size;
    double dt;
    int nsteps;
    int nsave;
    double temperature;
    double pressure;
    
    // Arrays (allocate dynamically based on natoms)
    std::vector<double> x, y, z;      // positions
    std::vector<double> vx, vy, vz;   // velocities
    std::vector<double> fx, fy, fz;   // forces
    std::vector<double> mass;         // atomic masses
    
    // Ewald parameters
    double ewald_alpha;
    int ewald_kmax;
    
    // Thermostat
    double tau_t;
    double Q_mass;
};

#endif // CONFIG_H

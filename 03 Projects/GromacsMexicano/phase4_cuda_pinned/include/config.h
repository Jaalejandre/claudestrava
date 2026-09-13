#ifndef CONFIG_H
#define CONFIG_H

#include <vector>
#include <string>
#include <cmath>

// Atom type structure
struct AtomType {
    std::string name;
    double mass;
    double charge;
    double sigma;
    double epsilon;
};

// Bonded force structures
struct Bond {
    int i, j;
    double req;      // equilibrium distance
    double k_b;      // force constant
};

struct Angle {
    int i, j, k;
    double theta_eq; // equilibrium angle
    double k_a;      // force constant
};

struct Dihedral {
    int i, j, k, l;
    double phi_eq;   // equilibrium dihedral
    double k_d;      // force constant
    int mult;        // multiplicity
};

struct Pair14 {
    int i, j;
    double scale_lj;      // LJ scaling factor
    double scale_coulomb; // Coulomb scaling factor
};

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
    std::vector<double> charge;       // atomic charges (for Coulomb)
    
    // Bonded interactions
    std::vector<Bond> bonds;
    std::vector<Angle> angles;
    std::vector<Dihedral> dihedrals;
    std::vector<Pair14> pairs_1_4;
    
    // Ewald parameters
    double ewald_alpha;
    int ewald_kmax;
    
    // Thermostat
    double tau_t;
    double Q_mass;
};

#endif // CONFIG_H

// CUDA Error Checking Macro
#define CUDA_CHECK(call) { \
  cudaError_t err = call; \
  if (err != cudaSuccess) { \
    fprintf(stderr, "CUDA error at %s:%d: %s\n", __FILE__, __LINE__, cudaGetErrorString(err)); \
    exit(EXIT_FAILURE); \
  } \
}

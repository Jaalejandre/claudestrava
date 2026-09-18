#pragma once
#include <vector>
#include <string>
#include <cuda_runtime.h>

struct SlabSystem {
    int natoms;
    int nmol;
    double boxx;
    double boxy;
    double boxz;
    std::vector<double> x, y, z;
    std::vector<double> vx, vy, vz;
    std::vector<double> charge;
    std::vector<double> mass;
    std::vector<int> types;
};

// Generates an elongated liquid-vapor slab system (Lx = Ly = L, Lz = 3L)
SlabSystem generate_liquid_vapor_slab(int n_per_side = 7, double step = 0.500, double z_vacuum_factor = 3.0);

// Surface tension and dielectric constant results
struct PhysicalProperties {
    double gamma_mN_m;          // Surface tension (mN/m or dyn/cm)
    double dielectric_constant;  // Static relative permittivity eps_r
    double p_normal_bar;        // Normal pressure Pzz
    double p_tangential_bar;    // Tangential pressure (Pxx + Pyy)/2
    double liquid_density_g_cm3;// Central slab liquid density
};

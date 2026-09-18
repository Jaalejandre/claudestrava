#include "surface_tension.h"
#include <cmath>
#include <iostream>
#include <vector>

SlabSystem generate_liquid_vapor_slab(int n_per_side, double step, double z_vacuum_factor) {
    SlabSystem slab;
    slab.nmol = n_per_side * n_per_side * n_per_side;
    slab.natoms = slab.nmol * 3;
    
    slab.boxx = n_per_side * step;
    slab.boxy = n_per_side * step;
    slab.boxz = slab.boxx * z_vacuum_factor; // Elongated Z axis
    
    slab.x.resize(slab.natoms);
    slab.y.resize(slab.natoms);
    slab.z.resize(slab.natoms);
    slab.vx.resize(slab.natoms, 0.0);
    slab.vy.resize(slab.natoms, 0.0);
    slab.vz.resize(slab.natoms, 0.0);
    slab.charge.resize(slab.natoms);
    slab.mass.resize(slab.natoms);
    slab.types.resize(slab.natoms);
    
    double z_offset = (slab.boxz - slab.boxx) * 0.5; // Center liquid film in Z
    
    int gi = 0;
    for (int i = 0; i < n_per_side; i++) {
        double px = 0.250 + step * i;
        for (int j = 0; j < n_per_side; j++) {
            double py = 0.250 + step * j;
            for (int k = 0; k < n_per_side; k++) {
                double pz = z_offset + 0.250 + step * k;
                
                // Atom 1: Oxygen (OW)
                slab.x[gi] = px; slab.y[gi] = py; slab.z[gi] = pz;
                slab.charge[gi] = -0.8476; slab.mass[gi] = 16.000; slab.types[gi] = 0;
                gi++;
                
                // Atom 2: Hydrogen 1 (HW1)
                slab.x[gi] = px + 0.050; slab.y[gi] = py + 0.087; slab.z[gi] = pz;
                slab.charge[gi] = 0.4238; slab.mass[gi] = 1.008; slab.types[gi] = 1;
                gi++;
                
                // Atom 3: Hydrogen 2 (HW2)
                slab.x[gi] = px - 0.050; slab.y[gi] = py + 0.087; slab.z[gi] = pz;
                slab.charge[gi] = 0.4238; slab.mass[gi] = 1.008; slab.types[gi] = 1;
                gi++;
            }
        }
    }
    return slab;
}

#include "config.h"
#include <vector>
#include <cmath>
#include <iostream>

namespace neighbor {

// Build neighbor list (skip parallelization for phase 1 - requires thread-safe containers)
void buildNeighborList(Config& cfg, 
                       std::vector<std::vector<int>>& nlist) {
    double rcut = 12.0;
    double rskin = 2.0;
    double rcut_sq = (rcut + rskin) * (rcut + rskin);
    
    // Clear neighbor lists
    for (int i = 0; i < cfg.natoms; i++) {
        nlist[i].clear();
    }
    
    // Build neighbor list sequentially (phase 1)
    for (int i = 0; i < cfg.natoms; i++) {
        for (int j = i + 1; j < cfg.natoms; j++) {
            double dx = cfg.x[j] - cfg.x[i];
            double dy = cfg.y[j] - cfg.y[i];
            double dz = cfg.z[j] - cfg.z[i];
            
            // Periodic boundary conditions
            if (dx > cfg.box_size * 0.5) dx -= cfg.box_size;
            if (dx < -cfg.box_size * 0.5) dx += cfg.box_size;
            if (dy > cfg.box_size * 0.5) dy -= cfg.box_size;
            if (dy < -cfg.box_size * 0.5) dy += cfg.box_size;
            if (dz > cfg.box_size * 0.5) dz -= cfg.box_size;
            if (dz < -cfg.box_size * 0.5) dz += cfg.box_size;
            
            double r2 = dx*dx + dy*dy + dz*dz;
            if (r2 < rcut_sq) {
                nlist[i].push_back(j);
                nlist[j].push_back(i);
            }
        }
    }
}

} // namespace neighbor

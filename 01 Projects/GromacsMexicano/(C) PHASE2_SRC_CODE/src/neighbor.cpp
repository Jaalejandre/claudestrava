#include "config.h"
#include <vector>
#include <cmath>
#include <iostream>
#include <omp.h>
#include <algorithm>

namespace neighbor {

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
// LOOP 6: BUILD NEIGHBOR LIST WITH PER-THREAD MERGE
// ============================================================================
void buildNeighborList(Config& cfg, 
                       std::vector<std::vector<int>>& nlist) {
    double rcut = 12.0;
    double rskin = 2.0;
    double rcut_sq = (rcut + rskin) * (rcut + rskin);
    
    // Clear neighbor lists
    for (int i = 0; i < cfg.natoms; i++) {
        nlist[i].clear();
    }
    
    // PHASE 2 LOOP 6: Build neighbor list with PER-THREAD MERGE
    #pragma omp parallel
    {
        // Each thread maintains local neighbor list buffer
        std::vector<std::vector<int>> nlist_local(cfg.natoms);
        
        // Nested loop parallelization with collapse(2)
        #pragma omp for collapse(2)
        for (int i = 0; i < cfg.natoms; i++) {
            for (int j = i + 1; j < cfg.natoms; j++) {
                double dx = cfg.x[j] - cfg.x[i];
                double dy = cfg.y[j] - cfg.y[i];
                double dz = cfg.z[j] - cfg.z[i];
                
                // Periodic boundary conditions
                applyPBC(dx, dy, dz, cfg.box_size);
                
                double r2 = dx*dx + dy*dy + dz*dz;
                if (r2 < rcut_sq) {
                    nlist_local[i].push_back(j);
                    nlist_local[j].push_back(i);
                }
            }
        }
        
        // Critical merge: combine thread-local buffers into global list
        #pragma omp critical
        {
            for (int i = 0; i < cfg.natoms; i++) {
                for (int neighbor : nlist_local[i]) {
                    nlist[i].push_back(neighbor);
                }
            }
        }
    }
    
    // Remove duplicates from critical merge
    for (int i = 0; i < cfg.natoms; i++) {
        std::sort(nlist[i].begin(), nlist[i].end());
        nlist[i].erase(std::unique(nlist[i].begin(), nlist[i].end()), nlist[i].end());
    }
}

} // namespace neighbor

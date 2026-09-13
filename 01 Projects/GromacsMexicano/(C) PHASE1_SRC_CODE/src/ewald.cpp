#include "config.h"
#include <cmath>
#include <omp.h>
#include <iostream>
#include <complex>

namespace ewald {

// Ewald summation - reciprocal space energy
double computeEwaldReciprocal(Config& cfg) {
    double E_ewald = 0.0;
    double alpha = cfg.ewald_alpha;
    int kmax = cfg.ewald_kmax;
    double V = cfg.box_size * cfg.box_size * cfg.box_size;
    
    // Compute structure factor (charge density in k-space)
    // For simplicity, assume unit charges here
    std::vector<std::complex<double>> S_k;
    
    for (int kx = -kmax; kx <= kmax; kx++) {
        for (int ky = -kmax; ky <= kmax; ky++) {
            for (int kz = -kmax; kz <= kmax; kz++) {
                if (kx == 0 && ky == 0 && kz == 0) continue;
                
                std::complex<double> S(0.0, 0.0);
                double ksq = (kx*kx + ky*ky + kz*kz) * (2.0 * M_PI / cfg.box_size) * 
                             (2.0 * M_PI / cfg.box_size);
                
                // Sum over all atoms
                for (int i = 0; i < cfg.natoms; i++) {
                    double phase = 2.0 * M_PI * (kx * cfg.x[i] / cfg.box_size +
                                                  ky * cfg.y[i] / cfg.box_size +
                                                  kz * cfg.z[i] / cfg.box_size);
                    S += std::complex<double>(std::cos(phase), std::sin(phase));
                }
                
                S_k.push_back(S);
            }
        }
    }
    
    // Energy from k-space
    return E_ewald;
}

// Ewald summation - detailed k-space with parallelization
double computeEwaldEnergy(Config& cfg) {
    double E_ewald = 0.0;
    double alpha = cfg.ewald_alpha;
    int kmax = cfg.ewald_kmax;
    double V = cfg.box_size * cfg.box_size * cfg.box_size;
    double pi = M_PI;
    
    // Precompute structure factors
    int total_k = (2*kmax+1) * (2*kmax+1) * (2*kmax+1);
    std::vector<double> contribution(total_k, 0.0);
    
    int idx = 0;
    for (int kx = -kmax; kx <= kmax; kx++) {
        for (int ky = -kmax; ky <= kmax; ky++) {
            for (int kz = -kmax; kz <= kmax; kz++) {
                if (kx == 0 && ky == 0 && kz == 0) {
                    idx++;
                    continue;
                }
                
                double ksq = 4.0 * pi * pi * (kx*kx + ky*ky + kz*kz) / 
                            (cfg.box_size * cfg.box_size);
                
                // Structure factor S(k)
                double S_real = 0.0, S_imag = 0.0;
                for (int i = 0; i < cfg.natoms; i++) {
                    double phase = 2.0 * pi * (kx * cfg.x[i] / cfg.box_size +
                                               ky * cfg.y[i] / cfg.box_size +
                                               kz * cfg.z[i] / cfg.box_size);
                    S_real += std::cos(phase);
                    S_imag += std::sin(phase);
                }
                
                double Sk2 = S_real*S_real + S_imag*S_imag;
                
                // Energy contribution from this k-vector
                contribution[idx] = std::exp(-ksq / (4.0 * alpha * alpha)) * Sk2 / ksq;
                idx++;
            }
        }
    }
    
    // LOOP 6: Ewald energy aggregation with triple nested loop
    // PLAN LINE 45: Add #pragma omp parallel for collapse(3) reduction(+:E_ewald)
    double E_temp = 0.0;
    #pragma omp parallel for collapse(3) reduction(+:E_temp)
    for (int kx = -kmax; kx <= kmax; kx++) {
        for (int ky = -kmax; ky <= kmax; ky++) {
            for (int kz = -kmax; kz <= kmax; kz++) {
                if (kx == 0 && ky == 0 && kz == 0) continue;
                
                double ksq = 4.0 * pi * pi * (kx*kx + ky*ky + kz*kz) / 
                            (cfg.box_size * cfg.box_size);
                
                // Simplified contribution calculation
                double contrib = std::exp(-ksq / (4.0 * alpha * alpha)) / ksq;
                E_temp += contrib;
            }
        }
    }
    
    E_ewald = 2.0 * pi / V * E_temp;
    
    return E_ewald;
}

} // namespace ewald

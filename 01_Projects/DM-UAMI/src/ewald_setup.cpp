#include <cmath>
#include <iostream>
#include <vector>
#include "config.h"

// Port of kappa_coulomb.f
// Computes Ewald splitting parameter alpha from cutoff and tolerance
void kappa_coulomb(double error_coul, double& rkappa, double rcut) {
    const double inv_rcut = 1.0 / rcut;
    rkappa = 0.05;
    int niter = 0;
    while (true) {
        double errorc = erfc(rkappa * rcut) * inv_rcut;
        if (errorc <= error_coul || niter > 1000) break;
        rkappa += 0.02;
        niter++;
    }
    std::cout << "Valor de kappa en 1/nm " << rkappa << std::endl;
}

// Port of compute_kmax_ewald.f
// Computes kmax and alpha from box dimensions and tolerance
void compute_kmax_ewald(double boxx, double boxy, double boxz,
                        double rcut, double ewald_tol,
                        double& alfa, int& kmaxx, int& kmaxy, int& kmaxz) {
    const double pi = 4.0 * atan(1.0);
    const double twopi = 2.0 * pi;
    const double logtol = -log(ewald_tol);
    
    // If alfa is not set, compute from rcut
    if (alfa <= 0.0) {
        alfa = sqrt(logtol) / rcut;
    }
    
    // Physical cutoff in reciprocal space (nm^-1)
    double kcut = 2.0 * alfa * sqrt(logtol);
    
    // Compute kmax per dimension (minimum 5)
    kmaxx = std::max(5, (int)(boxx * kcut / twopi + 0.5));
    kmaxy = std::max(5, (int)(boxy * kcut / twopi + 0.5));
    kmaxz = std::max(5, (int)(boxz * kcut / twopi + 0.5));
    
    std::cout << "Kmax: " << kmaxx << " " << kmaxy << " " << kmaxz << std::endl;
    std::cout << "Alpha: " << alfa << std::endl;
}

// Computes total number of k-vectors for given kmax
int compute_nk(int kmaxx, int kmaxy, int kmaxz) {
    int kmax = kmaxx;
    if (kmaxy > kmax) kmax = kmaxy;
    if (kmaxz > kmax) kmax = kmaxz;
    int ksqmax = kmax * kmax;
    
    int totk = 0;
    for (int kx = 0; kx <= kmaxx; kx++) {
        for (int ky = -kmaxy; ky <= kmaxy; ky++) {
            for (int kz = -kmaxz; kz <= kmaxz; kz++) {
                int ksq = kx*kx + ky*ky + kz*kz;
                if (ksq <= ksqmax && ksq != 0) {
                    totk++;
                }
            }
        }
    }
    return totk;
}

// Setup Ewald parameters in cfg
void ewald_setup(Config& cfg, double rcut, double ewald_tol, double error_coul) {
    cfg.rcut_coulomb = rcut;
    cfg.ewald_alpha = -1.0;  // Force kappa to be computed
    
    // Compute kappa
    double rkappa = 0.0;
    kappa_coulomb(error_coul, rkappa, rcut);
    cfg.ewald_alpha = rkappa;
    
    // Compute kmax
    compute_kmax_ewald(cfg.boxx, cfg.boxy, cfg.boxz,
                       rcut, ewald_tol,
                       cfg.ewald_alpha, cfg.kmaxx, cfg.kmaxy, cfg.kmaxz);
    
    // Compute total k-vectors
    cfg.nk = compute_nk(cfg.kmaxx, cfg.kmaxy, cfg.kmaxz);
    std::cout << "Total k-vectors: " << cfg.nk << std::endl;
}

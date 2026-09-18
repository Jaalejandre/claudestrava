#ifndef EWALD_SETUP_H
#define EWALD_SETUP_H

#include "config.h"

void kappa_coulomb(double error_coul, double& rkappa, double rcut);
void compute_kmax_ewald(double boxx, double boxy, double boxz,
                        double rcut, double ewald_tol,
                        double& alfa, int& kmaxx, int& kmaxy, int& kmaxz);
int compute_nk(int kmaxx, int kmaxy, int kmaxz);
void ewald_setup(Config& cfg, double rcut, double ewald_tol, double error_coul);

#endif

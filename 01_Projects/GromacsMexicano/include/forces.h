#ifndef FORCES_H
#define FORCES_H

#include <cuda_runtime.h>

namespace forces {
 void launch_pairwise_forces(
 int natoms,
 double box_size, double boxx, double boxy, double boxz,
 const double* x, const double* y, const double* z,
 const int* types, const double* charges,
 const double* sigma, const double* eps,
 double* fx, double* fy, double* fz,
 double* ucoul,
 const int* nlist, const int* nlist_count, int max_neighbors,
 double rkappa, double rcut_coulomb,
 cudaStream_t stream
 );
}
#endif // FORCES_H

#ifndef GMX_TOPOLOGY_H
#define GMX_TOPOLOGY_H

#include <vector>
#include <string>
#include "config.h"  // Reutilizar structs existentes

struct GMXTopology {
    std::string systemName;
    int natoms;
    int nmol;
    
    std::vector<AtomType> atomTypes;
    std::vector<Bond> bonds;       // Usar struct Bond de config.h
    std::vector<Angle> angles;     // Usar struct Angle de config.h
    std::vector<Dihedral> dihedrals; // Usar struct Dihedral de config.h
};

#endif


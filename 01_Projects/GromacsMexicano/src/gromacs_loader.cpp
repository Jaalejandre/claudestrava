// ============================================================================
// LOADER - Usar GMXParser para cargar archivos de GROMACS
// ============================================================================

#include "config.h"
#include "GMXParser.h"
#include <iostream>

void initialize_from_gromacs(Config& cfg, const std::string& top_file, const std::string& gro_file) {
    std::cout << "Loading GROMACS topology from: " << top_file << std::endl;
    
    // Usar el parser para cargar la topología
    GMXTopology topology = GMXParser::parseTopologyFile(top_file);
    GMXParser::parseGROFile(gro_file, topology);
    
    cfg.natoms = topology.natoms;
    cfg.box_size = 10.0; // TODO: leer del archivo .mdp o .gro
    cfg.dt = 0.001;
    cfg.nsteps = 1000;
    cfg.nsave = 100;
    cfg.temperature = 300.0;
    cfg.tau_t = 0.1;
    cfg.Q_mass = 100.0 * cfg.natoms * 1.380649e-23 * cfg.temperature;
    
    // Redimensionar vectores
    cfg.x.resize(cfg.natoms);
    cfg.y.resize(cfg.natoms);
    cfg.z.resize(cfg.natoms);
    cfg.vx.resize(cfg.natoms, 0.0);
    cfg.vy.resize(cfg.natoms, 0.0);
    cfg.vz.resize(cfg.natoms, 0.0);
    cfg.fx.resize(cfg.natoms, 0.0);
    cfg.fy.resize(cfg.natoms, 0.0);
    cfg.fz.resize(cfg.natoms, 0.0);
    cfg.mass.resize(cfg.natoms);
    cfg.charge.resize(cfg.natoms);
    
    // Llenar masas y cargas desde la topología
    std::cout << "Mapping atom types to atoms..." << std::endl;
    int atom_type_idx = 0;
    for (int i = 0; i < cfg.natoms; i++) {
        // Ciclar entre tipos de átomos (simplista, mejorar según estructura real)
        if (atom_type_idx >= (int)topology.atomTypes.size()) {
            atom_type_idx = 0;
        }
        cfg.mass[i] = topology.atomTypes[atom_type_idx].mass;
        cfg.charge[i] = topology.atomTypes[atom_type_idx].charge;
        atom_type_idx++;
    }
    
    // TODO: Leer coordenadas del .gro y asignar a cfg.x, cfg.y, cfg.z
    std::cout << "System initialized with " << cfg.natoms << " atoms from GROMACS files." << std::endl;
}

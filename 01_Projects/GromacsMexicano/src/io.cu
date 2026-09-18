#include "config.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <cstring>
#include <stdexcept>
#include <map>

/**
 * readGRO: Parse GROMACS .gro format file
 * Format:
 *   Line 1: title
 *   Line 2: number of atoms
 *   Lines 3+: atom data in fixed-width columns
 *   Last line: box vectors
 */
void readGRO(const char* filename, Config& cfg) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error(std::string("Cannot open file: ") + filename);
    }

    std::string line;
    
    // Read title (line 1)
    if (!std::getline(file, line)) {
        throw std::runtime_error("File is empty");
    }
    std::cout << "GRO Title: " << line << std::endl;

    // Read number of atoms (line 2)
    if (!std::getline(file, line)) {
        throw std::runtime_error("Cannot read natoms line");
    }
    int natoms = std::stoi(line);
    cfg.natoms = natoms;
    
    // Resize coordinate and velocity vectors
    cfg.x.resize(natoms);
    cfg.y.resize(natoms);
    cfg.z.resize(natoms);
    cfg.vx.resize(natoms, 0.0);
    cfg.vy.resize(natoms, 0.0);
    cfg.vz.resize(natoms, 0.0);
    cfg.types.resize(natoms, -1);  // Initialize types from atom names
    
    std::cout << "Reading " << natoms << " atoms from GRO file" << std::endl;

    // Read atom positions (lines 3 to 2+natoms)
    int atoms_read = 0;
    while (std::getline(file, line) && atoms_read < natoms) {
        // Check if this looks like a box vector line (very short, or all numbers with decimals)
        // Box lines are typically short like "   10.0   10.0   10.0"
        if (line.length() < 30 && atoms_read > 0) {
            // This might be the box vector line
            std::istringstream test_iss(line);
            double test_val;
            int count = 0;
            while (test_iss >> test_val) count++;
            if (count == 3 || count <= 2) {
                // Likely a box vector, put it back for next read
                goto box_read;
            }
        }
        
        try {
            // Extract atom name from positions 10-15 of the line
            // .gro format: residue number (5 pos), residue name (5 pos), atom name (5 pos), atom number (5 pos), then x y z
            std::string atom_name;
            if (line.length() >= 15) {
                atom_name = line.substr(10, 5);
                // Trim whitespace from atom_name
                atom_name.erase(0, atom_name.find_first_not_of(" \t"));
                atom_name.erase(atom_name.find_last_not_of(" \t") + 1);
            }
            
            // Assign type based on atom name
            // OW = Oxygen (type 0), HW/H = Hydrogen (type 1)
            if (atom_name.find("OW") != std::string::npos || atom_name == "O") {
                cfg.types[atoms_read] = 0;
            } else if (atom_name.find("HW") != std::string::npos || atom_name.find("H") != std::string::npos) {
                cfg.types[atoms_read] = 1;
            } else {
                cfg.types[atoms_read] = 0;  // Default to type 0
            }
            
            // Parse coordinates using flexible parsing from position 20 onwards
            std::istringstream iss(line.substr(20));
            double x, y, z;
            if (!(iss >> x >> y >> z)) {
                // If we can't parse it, it might be the box vector line
                if (atoms_read == natoms) goto box_read;
                throw std::runtime_error("Cannot parse coordinates");
            }
            
            cfg.x[atoms_read] = x;
            cfg.y[atoms_read] = y;
            cfg.z[atoms_read] = z;
            
            // Try to read velocities if present
            if (iss >> cfg.vx[atoms_read] >> cfg.vy[atoms_read] >> cfg.vz[atoms_read]) {
                // Velocities were present, already read above
            } else {
                cfg.vx[atoms_read] = 0.0;
                cfg.vy[atoms_read] = 0.0;
                cfg.vz[atoms_read] = 0.0;
            }
            atoms_read++;
        } catch (const std::exception& e) {
            if (atoms_read == natoms) {
                // We've read all atoms, this must be the box vector line
                goto box_read;
            }
            throw;
        }
    }

    box_read:
    // Read box vectors (last line)
    if (std::getline(file, line)) {
        std::istringstream iss(line);
        double x, y, z;
        if (iss >> x >> y >> z) {
            cfg.box_size = x;  // Assume cubic box
            std::cout << "Box size: " << cfg.box_size << " nm" << std::endl;
        }
    }

    file.close();
    std::cout << "Successfully read " << atoms_read << " atoms from GRO file" << std::endl;
}

/**
 * readMDP: Parse GROMACS .mdp (molecular dynamics parameters) file
 */
void readMDP(const char* filename, Config& cfg) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error(std::string("Cannot open file: ") + filename);
    }

    std::string line;
    int linenum = 0;
    
    std::cout << "Reading MDP parameters from: " << filename << std::endl;

    while (std::getline(file, line)) {
        linenum++;
        
        // Remove comments
        size_t comment_pos = line.find(';');
        if (comment_pos != std::string::npos) {
            line = line.substr(0, comment_pos);
        }
        
        // Trim whitespace
        line.erase(0, line.find_first_not_of(" \t\r\n"));
        line.erase(line.find_last_not_of(" \t\r\n") + 1);
        if (line.empty()) continue;
        
        // Find equals sign
        size_t eq_pos = line.find('=');
        if (eq_pos == std::string::npos) continue;
        
        std::string key = line.substr(0, eq_pos);
        std::string value = line.substr(eq_pos + 1);
        
        // Trim key and value
        key.erase(key.find_last_not_of(" \t") + 1);
        value.erase(0, value.find_first_not_of(" \t"));
        value.erase(value.find_last_not_of(" \t") + 1);
        
        try {
            if (key == "dt") {
                cfg.dt = std::stod(value);
                std::cout << "  dt = " << cfg.dt << std::endl;
            } else if (key == "nsteps") {
                cfg.nsteps = std::stoi(value);
                std::cout << "  nsteps = " << cfg.nsteps << std::endl;
            } else if (key == "nsave" || key == "nstxout") {
                cfg.nsave = std::stoi(value);
                std::cout << "  nsave = " << cfg.nsave << std::endl;
            } else if (key == "temperature" || key == "ref_t") {
                cfg.temperature = std::stod(value);
                std::cout << "  temperature = " << cfg.temperature << std::endl;
            } else if (key == "tau_t") {
                cfg.tau_t = std::stod(value);
                std::cout << "  tau_t = " << cfg.tau_t << std::endl;
            } else if (key == "rcut" || key == "rcoulomb") {
                cfg.rcut_coulomb = std::stod(value);
                std::cout << "  rcoulomb = " << value << std::endl;
            }
        } catch (const std::exception& e) {
            std::cerr << "Error parsing line " << linenum << " (" << key << "): " 
                      << e.what() << std::endl;
        }
    }
    
    file.close();
}

/**
 * readTOP: Parse GROMACS .top (topology) file
 * Parses [atomtypes] section to extract sigma/epsilon parameters
 * Parses [atoms] section to extract atom types for each atom
 * Builds combined Lorentz-Berthelot matrices
 */
/**
 * readTOP: Parse GROMACS .top format file
 * TWO-PASS APPROACH:
 *   Pass 1: Read [atomtypes] section and build type_name_to_id map
 *   Pass 2: Read [atoms] section and assign type IDs to each atom
 * 
 * HANDLES #include DIRECTIVES: Processes included files to find [atomtypes]
 * This ensures the map is populated BEFORE we try to use it for atom type lookups.
 */

// Helper function to recursively process includes
static void processIncludeFile(const std::string& include_filename,
                               std::map<std::string, std::pair<double, double>>& atomtype_params,
                               std::map<std::string, int>& type_name_to_id,
                               std::vector<std::string>& atomtype_names) {
    std::ifstream include_file(include_filename);
    if (!include_file.is_open()) {
        std::cerr << "  Warning: Could not open included file: " << include_filename << std::endl;
        return;
    }
    
    std::cout << "  Processing included file: " << include_filename << std::endl;
    
    std::string line;
    bool in_atomtypes = false;
    
    while (std::getline(include_file, line)) {
        // Remove comments
        size_t comment_pos = line.find(';');
        if (comment_pos != std::string::npos) {
            line = line.substr(0, comment_pos);
        }
        
        // Trim whitespace
        line.erase(0, line.find_first_not_of(" \t\r\n"));
        line.erase(line.find_last_not_of(" \t\r\n") + 1);
        if (line.empty()) continue;
        
        // Detect [atomtypes] section header
        if (line[0] == '[' && line[line.length()-1] == ']') {
            std::string section = line.substr(1, line.length() - 2);
            section.erase(0, section.find_first_not_of(" \t"));
            section.erase(section.find_last_not_of(" \t") + 1);
            
            if (section == "atomtypes") {
                std::cout << "    Found [atomtypes] in included file" << std::endl;
                in_atomtypes = true;
            } else {
                in_atomtypes = false;
            }
            continue;
        }
        
        // Parse [atomtypes] section
        // Format: name mass charge ptype sigma epsilon (from forcefield.itp)
        if (in_atomtypes) {
            std::istringstream iss(line);
            std::string name, ptype;
            double mass, charge, sigma, epsilon;
            
            if (iss >> name >> mass >> charge >> ptype >> sigma >> epsilon) {
                int type_id = atomtype_names.size();
                if (type_id < 10) {
                    type_name_to_id[name] = type_id;
                    atomtype_names.push_back(name);
                    atomtype_params[name] = std::make_pair(sigma, epsilon);
                    std::cout << "      Atomtype: " << name << " (id=" << type_id 
                              << ") sigma=" << sigma << " epsilon=" << epsilon << std::endl;
                }
            }
        }
    }
    include_file.close();
}

void readTOP(const char* filename, Config& cfg) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error(std::string("Cannot open file: ") + filename);
    }

    std::string line;
    int linenum = 0;
    
    // Map to store atomtype name -> (sigma, epsilon) pairs
    std::map<std::string, std::pair<double, double>> atomtype_params;
    std::map<std::string, int> type_name_to_id;  // type name -> index (0-9)
    std::vector<std::string> atomtype_names;  // preserve order
    
    std::cout << "Reading topology from: " << filename << std::endl;

    // Ensure masses and charges vectors are sized
    if (cfg.natoms > 0) {
        if (cfg.mass.empty()) {
            cfg.mass.resize(cfg.natoms, 18.01);  // Water molecule mass
        }
        if (cfg.charge.empty()) {
            cfg.charge.resize(cfg.natoms, 0.0);
        }
        if (cfg.types.empty()) {
            cfg.types.resize(cfg.natoms, -1);  // Will be filled from [atoms]
        }
    }

    // ===== PASS 0: Process #include directives =====
    std::cout << "\n--- PASS 0: Processing #include directives ---\n";
    file.clear();
    file.seekg(0);
    linenum = 0;
    
    while (std::getline(file, line)) {
        linenum++;
        
        // Check for #include directive
        if (line.find("#include") != std::string::npos) {
            // Extract filename from #include "filename" or #include <filename>
            size_t quote_start = line.find('"');
            size_t quote_end = line.rfind('"');
            
            if (quote_start != std::string::npos && quote_end != std::string::npos && quote_start < quote_end) {
                std::string include_file = line.substr(quote_start + 1, quote_end - quote_start - 1);
                processIncludeFile(include_file, atomtype_params, type_name_to_id, atomtype_names);
            }
        }
    }

    // ===== PASS 1: Read [atomtypes] section =====
    std::cout << "\n--- PASS 1: Building atom type map from [atomtypes] ---\n";
    
    file.clear();
    file.seekg(0);
    linenum = 0;
    bool in_atomtypes = false;
    
    while (std::getline(file, line)) {
        linenum++;
        
        // Remove comments
        size_t comment_pos = line.find(';');
        if (comment_pos != std::string::npos) {
            line = line.substr(0, comment_pos);
        }
        
        // Trim whitespace
        line.erase(0, line.find_first_not_of(" \t\r\n"));
        line.erase(line.find_last_not_of(" \t\r\n") + 1);
        if (line.empty()) continue;
        
        // Detect [atomtypes] section header
        if (line[0] == '[' && line[line.length()-1] == ']') {
            std::string section = line.substr(1, line.length() - 2);
            section.erase(0, section.find_first_not_of(" \t"));
            section.erase(section.find_last_not_of(" \t") + 1);
            
            if (section == "atomtypes") {
                std::cout << "  Detected [atomtypes] section at line " << linenum << std::endl;
                in_atomtypes = true;
            } else {
                in_atomtypes = false;
            }
            continue;
        }
        
        // Parse [atomtypes] section
        // Format: name at.num mass charge ptype sigma epsilon
        // Example: OW     8       15.99940   0.000   A      0.31880    0.65000
        if (in_atomtypes) {
            std::istringstream iss(line);
            std::string name, ptype;
            int at_num;
            double mass, charge, sigma, epsilon;
            
            if (iss >> name >> at_num >> mass >> charge >> ptype >> sigma >> epsilon) {
                int type_id = atomtype_names.size();
                if (type_id < 10) {  // Max 10 types for 10x10 matrix
                    type_name_to_id[name] = type_id;
                    atomtype_names.push_back(name);
                    atomtype_params[name] = std::make_pair(sigma, epsilon);
                    
                    std::cout << "    Atomtype: " << name 
                              << " (id=" << type_id << ") sigma=" << sigma 
                              << " epsilon=" << epsilon << std::endl;
                }
            }
        }
    }
    
    std::cout << "  Total atom types found: " << atomtype_names.size() << std::endl;
    
    // ===== PASS 2: Read [atoms] section =====
    std::cout << "\n--- PASS 2: Assigning types from [atoms] section ---\n";
    
    file.clear();
    file.seekg(0);
    linenum = 0;
    bool in_atoms = false;
    int atoms_assigned = 0;
    
    while (std::getline(file, line)) {
        linenum++;
        
        // Remove comments
        size_t comment_pos = line.find(';');
        if (comment_pos != std::string::npos) {
            line = line.substr(0, comment_pos);
        }
        
        // Trim whitespace
        line.erase(0, line.find_first_not_of(" \t\r\n"));
        line.erase(line.find_last_not_of(" \t\r\n") + 1);
        if (line.empty()) continue;
        
        // Detect [atoms] section header
        if (line[0] == '[' && line[line.length()-1] == ']') {
            std::string section = line.substr(1, line.length() - 2);
            section.erase(0, section.find_first_not_of(" \t"));
            section.erase(section.find_last_not_of(" \t") + 1);
            
            if (section == "atoms") {
                std::cout << "  Detected [atoms] section at line " << linenum << std::endl;
                in_atoms = true;
            } else {
                in_atoms = false;
            }
            continue;
        }
        
        // Parse [atoms] section
        // Format: nr type resnr residue name cgnr charge [mass]
        // Example: 1   OW   1    SOL   OW   1  -0.8476
        if (in_atoms) {
            std::istringstream iss(line);
            int atom_nr, resnr, cgnr;
            std::string type_name, residue, atom_name;
            double charge_val;
            
            // Read fields: nr type resnr residue name cgnr charge
            if (iss >> atom_nr >> type_name >> resnr >> residue >> atom_name >> cgnr >> charge_val) {
                int atom_idx = atom_nr - 1;  // Convert 1-based to 0-based indexing
                
                if (atom_idx >= 0 && atom_idx < cfg.natoms) {
                    // Map type_name to type ID
                    if (type_name_to_id.find(type_name) != type_name_to_id.end()) {
                        int type_id = type_name_to_id[type_name];
                        cfg.types[atom_idx] = type_id;
                        cfg.charge[atom_idx] = charge_val;
                        atoms_assigned++;
                        
                        // Print first 3 atoms for debug
                        if (atoms_assigned <= 3) {
                            std::cout << "    Atom " << atom_idx << ": type=" << type_name 
                                      << " (id=" << type_id << ") q=" << charge_val << std::endl;
                        }
                    } else {
                        std::cerr << "    ERROR: Unknown atom type in [atoms]: " << type_name << std::endl;
                    }
                }
            }
        }
    }
    
    std::cout << "  Atoms assigned types: " << atoms_assigned << " / " << cfg.natoms << std::endl;
    
    file.close();
    
    // ===== BUILD LJ MATRICES =====
    std::cout << "\nBuilding LJ matrices for " << atomtype_names.size() << " atom types\n";
    
    cfg.sigma_matrix.clear();
    cfg.eps_matrix.clear();
    cfg.sigma_matrix.resize(100, 0.0);
    cfg.eps_matrix.resize(100, 0.0);
    
    // Fill matrices using Lorentz-Berthelot combining rules
    for (size_t i = 0; i < atomtype_names.size(); i++) {
        for (size_t j = 0; j < atomtype_names.size(); j++) {
            std::string type_i = atomtype_names[i];
            std::string type_j = atomtype_names[j];
            
            double sigma_i = atomtype_params[type_i].first;
            double sigma_j = atomtype_params[type_j].first;
            double eps_i = atomtype_params[type_i].second;
            double eps_j = atomtype_params[type_j].second;
            
            // Lorentz-Berthelot: sigma[i][j] = (sigma_i + sigma_j) / 2
            double sigma_ij = (sigma_i + sigma_j) / 2.0;
            // Lorentz-Berthelot: epsilon[i][j] = sqrt(epsilon_i * epsilon_j)
            double eps_ij = std::sqrt(eps_i * eps_j);
            
            int ind = i + j * 10;  // Flat index for 10x10 matrix
            if (ind < 100) {
                cfg.sigma_matrix[ind] = sigma_ij;
                cfg.eps_matrix[ind] = eps_ij;
                
                if (i == 0 && j == 0) {
                    std::cout << "    Matrix[0][0] (ind=0): sigma=" << sigma_ij 
                              << " eps=" << eps_ij << std::endl;
                }
            }
        }
    }
    
    std::cout << "  LJ matrices initialized (100 elements each)\n\n";
    
    // ===== FIX: If matrices empty, use default LJ params for water =====
    if (cfg.sigma_matrix.empty() || cfg.eps_matrix.empty()) {
        std::cout << "WARNING: sigma/eps matrices empty! Applying default water LJ params...\n";
        cfg.sigma_matrix.clear();
        cfg.eps_matrix.clear();
        cfg.sigma_matrix.resize(100, 0.0);
        cfg.eps_matrix.resize(100, 0.0);
        
        // Default water params: sigma=0.31880 nm, epsilon=0.65000 kJ/mol
        double sigma_default = 0.31880;
        double eps_default = 0.65000;
        
        // Fill 10x10 matrices with defaults (all atoms are water/same type)
        for (int i = 0; i < 10; i++) {
            for (int j = 0; j < 10; j++) {
                int ind = i + j * 10;
                cfg.sigma_matrix[ind] = sigma_default;
                cfg.eps_matrix[ind] = eps_default;
            }
        }
        
        // Also ensure all atom types are set to 0 if still -1
        for (int i = 0; i < cfg.natoms; i++) {
            if (cfg.types[i] < 0) {
                cfg.types[i] = 0;  // Assign all atoms to type 0
            }
        }
        
        std::cout << "  ✓ Default LJ params applied: sigma=" << sigma_default 
                  << " epsilon=" << eps_default << std::endl;
    }
    
    // ===== VALIDATION =====
    int types_filled = 0;
    for (const auto& t : cfg.types) {
        if (t >= 0) types_filled++;
    }
    
    std::cout << "=== TYPES VALIDATION ===" << std::endl;
    std::cout << "Total atoms (cfg.natoms): " << cfg.natoms << std::endl;
    std::cout << "Types vector size (cfg.types.size()): " << cfg.types.size() << std::endl;
    std::cout << "Types successfully filled: " << types_filled << std::endl;
    
    if (cfg.types.size() == cfg.natoms && types_filled == cfg.natoms) {
        std::cout << "✓ VALIDATION PASSED: cfg.types.size() == cfg.natoms" << std::endl;
    } else {
        std::cout << "✗ VALIDATION FAILED: Mismatch in types vector" << std::endl;
    }
    
    // Print first 10 atoms and their types
    std::cout << "\n=== FIRST 10 ATOMS AND TYPES ===" << std::endl;
    std::cout << "Idx | Type ID | Type Name" << std::endl;
    std::cout << "----+---------+-----------" << std::endl;
    int show_count = std::min(10, cfg.natoms);
    for (int i = 0; i < show_count; i++) {
        if (i < cfg.types.size() && cfg.types[i] >= 0 && cfg.types[i] < atomtype_names.size()) {
            std::cout << i << "   | " << cfg.types[i] << "       | " 
                      << atomtype_names[cfg.types[i]] << std::endl;
        }
    }
    
    std::cout << "\nTopology file parsed successfully" << std::endl;
}

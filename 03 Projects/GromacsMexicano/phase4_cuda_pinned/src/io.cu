#include "config.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <cstring>
#include <stdexcept>

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
            std::cerr << "Warning: Error parsing atom " << atoms_read << ": " << e.what() << std::endl;
            // Continue with zero coordinates
            cfg.x[atoms_read] = cfg.y[atoms_read] = cfg.z[atoms_read] = 0.0;
            atoms_read++;
        }
    }

    box_read:
    // Read box vectors if we haven't yet
    if (!line.empty()) {
        std::istringstream iss(line);
        double box_x, box_y, box_z;
        if (iss >> box_x >> box_y >> box_z) {
            cfg.box_size = box_x; // Assume cubic box for simplicity
        } else {
            cfg.box_size = 10.0;  // Default box size
        }
    } else {
        cfg.box_size = 10.0;
    }
    
    std::cout << "Box size: " << cfg.box_size << " nm" << std::endl;
    
    file.close();
}

/**
 * readMDP: Parse GROMACS .mdp (parameter) file
 * Format: key = value pairs with optional comments (#)
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
        
        if (line.empty() || line[0] == '#') continue;
        
        // Parse key = value
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
                // Set cutoff radius - not directly stored in Config, but could be
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
 * readTOP: Parse GROMACS .top (topology) file (simplified)
 * This is a minimalist parser that just reads and ignores most sections
 */
void readTOP(const char* filename, Config& cfg) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        throw std::runtime_error(std::string("Cannot open file: ") + filename);
    }

    std::string line;
    int linenum = 0;
    
    std::cout << "Reading topology from: " << filename << std::endl;

    // Ensure masses vector is sized
    if (cfg.natoms > 0) {
        if (cfg.mass.empty()) {
            cfg.mass.resize(cfg.natoms, 18.01);  // Water molecule mass
        }
        if (cfg.charge.empty()) {
            cfg.charge.resize(cfg.natoms, 0.0);
        }
    }

    while (std::getline(file, line)) {
        linenum++;
        
        // Remove comments
        size_t comment_pos = line.find(';');
        if (comment_pos != std::string::npos) {
            line = line.substr(0, comment_pos);
        }
        
        // Trim whitespace
        line.erase(0, line.find_first_not_of(" \t\r\n"));
        if (line.empty()) continue;
        
        // Skip section headers - just for reading
        if (line[0] == '[' && line[line.length()-1] == ']') {
            std::cout << "  [Skipping section]" << std::endl;
            continue;
        }
    }
    
    std::cout << "  Topology read (simplified)" << std::endl;
    
    file.close();
}

#include "GMXParser.h"
#include <fstream>
#include <sstream>
#include <algorithm>
#include <stdexcept>
#include <iostream>
#include <cctype>

// ============================================================================
// MÉTODOS PRIVADOS (HELPER)
// ============================================================================

std::string GMXParser::sanitizeLine(const std::string& line) {
    // 1. Remover comentarios (todo después de ';')
    std::string result = line;
    size_t commentPos = result.find(';');
    if (commentPos != std::string::npos) {
        result = result.substr(0, commentPos);
    }

    // 2. Trim izquierda
    result.erase(0, result.find_first_not_of(" \t\r\n"));
    
    // 3. Trim derecha
    size_t lastNonWs = result.find_last_not_of(" \t\r\n");
    if (lastNonWs != std::string::npos) {
        result = result.substr(0, lastNonWs + 1);
    } else {
        result = "";
    }

    return result;
}

std::vector<std::string> GMXParser::readSection(
    const std::vector<std::string>& allLines,
    const std::string& sectionName) 
{
    std::vector<std::string> lines;
    bool foundSection = false;
    size_t sectionStart = 0;

    // Buscar la sección
    for (size_t i = 0; i < allLines.size(); ++i) {
        // Las líneas vacías se ignoran, solo comparar no-vacías
        if (allLines[i] == sectionName) {
            foundSection = true;
            sectionStart = i + 1;
            break;
        }
    }

    if (!foundSection) {
        return lines; // Retorna vacío si no encontró la sección
    }

    // Leer líneas hasta la siguiente sección o fin de archivo
    for (size_t i = sectionStart; i < allLines.size(); ++i) {
        const std::string& cleaned = allLines[i];
        
        // Detectar siguiente sección
        if (!cleaned.empty() && cleaned[0] == '[') {
            break;
        }

        // Ignorar líneas vacías
        if (cleaned.empty()) {
            continue;
        }

        lines.push_back(cleaned);
    }

    return lines;
}

AtomType* GMXParser::parseAtomTypeLine(const std::string& line) {
    std::stringstream ss(line);
    std::string name;
    int atomNum;
    double mass, charge;
    std::string ptype;
    double sigma, epsilon;

    if (!(ss >> name >> atomNum >> mass >> charge >> ptype >> sigma >> epsilon)) {
        return nullptr; // No pudo parsear
    }

    // Crear y retornar novo AtomType
    return new AtomType{name, mass, charge, sigma, epsilon};
}

Bond* GMXParser::parseBondLine(const std::string& line) {
    std::stringstream ss(line);
    int atom1, atom2, func;
    double r0, kb;

    if (!(ss >> atom1 >> atom2 >> func >> r0 >> kb)) {
        return nullptr; // No pudo parsear
    }

    // En GROMACS, los índices en el archivo .top son 1-based
    // Convertir a 0-based para C++ interno
    return new Bond{atom1 - 1, atom2 - 1, r0, kb};
}

std::string GMXParser::readSystemName(const std::vector<std::string>& allLines) {
    std::vector<std::string> systemLines = readSection(allLines, "[system]");
    
    if (systemLines.empty()) {
        return "Unknown System";
    }

    // Primera línea no vacía después de [system]
    return systemLines[0];
}

int GMXParser::readMoleculeCount(const std::vector<std::string>& allLines) {
    std::vector<std::string> moleculeLines = readSection(allLines, "[molecules]");
    
    int totalMoles = 0;
    for (const auto& line : moleculeLines) {
        std::stringstream ss(line);
        std::string molName;
        int count;
        
        if (ss >> molName >> count) {
            totalMoles += count;
        }
    }

    return totalMoles;
}

int GMXParser::readGROHeader(std::ifstream& file) {
    std::string title;
    std::string natoms_str;
    int natoms = 0;

    // Primera línea: título
    if (!std::getline(file, title)) {
        throw std::runtime_error("GRO file appears to be empty");
    }

    // Segunda línea: número de átomos
    if (!std::getline(file, natoms_str)) {
        throw std::runtime_error("GRO file missing atom count");
    }

    std::stringstream ss(natoms_str);
    if (!(ss >> natoms)) {
        throw std::runtime_error("Could not parse atom count from GRO file");
    }

    return natoms;
}

// ============================================================================
// MÉTODOS PÚBLICOS
// ============================================================================

GMXTopology GMXParser::parseTopologyFile(const std::string& filepath) {
    GMXTopology topology;
    std::ifstream file(filepath);

    if (!file.is_open()) {
        throw std::runtime_error("Cannot open topology file: " + filepath);
    }

    // Lee TODO el archivo en memoria para múltiples pasadas
    std::vector<std::string> allLines;
    std::string line;
    while (std::getline(file, line)) {
        std::string cleaned = sanitizeLine(line);
        allLines.push_back(cleaned);
    }
    file.close();

    // ========== Parsear [atomtypes] ==========
    std::vector<std::string> atomTypeLines = readSection(allLines, "[atomtypes]");
    for (const auto& line : atomTypeLines) {
        AtomType* atom = parseAtomTypeLine(line);
        if (atom != nullptr) {
            topology.atomTypes.push_back(*atom);
            delete atom;
        }
    }

    // ========== Parsear [bonds] ==========
    std::vector<std::string> bondLines = readSection(allLines, "[bonds]");
    for (const auto& line : bondLines) {
        Bond* bond = parseBondLine(line);
        if (bond != nullptr) {
            topology.bonds.push_back(*bond);
            delete bond;
        }
    }

    // ========== Parsear [system] ==========
    topology.systemName = readSystemName(allLines);

    // ========== Parsear [atoms] para contar átomos por molécula ==========
    std::vector<std::string> atomLines = readSection(allLines, "[atoms]");
    int atomsPerMolecule = atomLines.size();

    // ========== Parsear [molecules] para contar moléculas ==========
    int nmol = readMoleculeCount(allLines);

    // Calcular total de átomos
    topology.natoms = atomsPerMolecule * nmol;
    topology.nmol = nmol;

    // Logging/verificación
    std::cout << "========================================\n";
    std::cout << "TOPOLOGY PARSING COMPLETE\n";
    std::cout << "========================================\n";
    std::cout << "System: " << topology.systemName << "\n";
    std::cout << "Atoms per molecule: " << atomsPerMolecule << "\n";
    std::cout << "Number of molecules: " << nmol << "\n";
    std::cout << "Total atoms: " << topology.natoms << "\n";
    std::cout << "Total bonds (unique per molecule): " << topology.bonds.size() << "\n";
    std::cout << "Atom types defined: " << topology.atomTypes.size() << "\n";
    std::cout << "========================================\n";

    return topology;
}

bool GMXParser::parseGROFile(const std::string& filepath, GMXTopology& topology) {
    std::ifstream file(filepath);

    if (!file.is_open()) {
        throw std::runtime_error("Cannot open GRO file: " + filepath);
    }

    int groNatoms = readGROHeader(file);
    
    std::cout << "\nGRO File Parsing:\n";
    std::cout << "  Atoms in .gro file: " << groNatoms << "\n";
    std::cout << "  Atoms in topology: " << topology.natoms << "\n";

    file.close();
    return validateTopologyConsistency(topology, groNatoms);
}

bool GMXParser::validateTopologyConsistency(const GMXTopology& topology, int groNatoms) {
    if (topology.natoms != groNatoms) {
        std::cerr << "ERROR: Atom count mismatch!\n";
        std::cerr << "  Topology reports: " << topology.natoms << " atoms\n";
        std::cerr << "  GRO file reports: " << groNatoms << " atoms\n";
        return false;
    }

    if (topology.natoms <= 0) {
        std::cerr << "ERROR: Invalid topology - no atoms loaded!\n";
        return false;
    }

    std::cout << "  ✓ Validation PASSED\n";
    return true;
}

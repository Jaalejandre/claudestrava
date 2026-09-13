#include "GMXParser.h"
#include <iostream>
#include <iomanip>

int main(int argc, char* argv[]) {
    try {
        std::cout << "\n╔════════════════════════════════════════════════════════════╗\n";
        std::cout << "║      GROMACS Topology Parser - C++ Implementation         ║\n";
        std::cout << "║         (Ported from Fortran top_gmx.f95)                 ║\n";
        std::cout << "╚════════════════════════════════════════════════════════════╝\n\n";

        // Rutas de prueba (ajustables por argumentos)
        std::string topologyFile = "/root/phase4_cuda_pinned/data/file.top";
        std::string groFile = "/root/UAMI_Source/file.gro";

        if (argc > 1) {
            topologyFile = argv[1];
        }
        if (argc > 2) {
            groFile = argv[2];
        }

        // ===== Paso 1: Parsear Topología =====
        std::cout << "Step 1: Parsing topology file: " << topologyFile << "\n\n";
        GMXTopology topology = GMXParser::parseTopologyFile(topologyFile);

        // ===== Paso 2: Validar con archivo GRO =====
        std::cout << "\nStep 2: Validating against GRO file: " << groFile << "\n\n";
        bool validationOk = GMXParser::parseGROFile(groFile, topology);

        // ===== Paso 3: Resumen Final =====
        std::cout << "\n════════════════════════════════════════════════════════════\n";
        std::cout << "FINAL SUMMARY\n";
        std::cout << "════════════════════════════════════════════════════════════\n\n";

        std::cout << "✓ System loaded: " << topology.systemName << "\n";
        std::cout << "✓ Total atoms: " << topology.natoms << "\n";
        std::cout << "✓ Total molecules: " << topology.nmol << "\n";
        std::cout << "✓ Bond definitions: " << topology.bonds.size() << "\n";
        std::cout << "✓ Atom types defined: " << topology.atomTypes.size() << "\n\n";

        std::cout << "Atom Types:\n";
        std::cout << "───────────────────────────────────────────\n";
        for (size_t i = 0; i < topology.atomTypes.size(); ++i) {
            const auto& at = topology.atomTypes[i];
            std::cout << "  " << std::setw(3) << (i + 1) << ". " 
                      << std::setw(8) << at.name 
                      << " | mass=" << std::fixed << std::setprecision(3) << at.mass
                      << " | charge=" << std::setprecision(3) << at.charge << "\n";
        }

        if (!topology.bonds.empty()) {
            std::cout << "\nBonds (first 10):\n";
            std::cout << "───────────────────────────────────────────\n";
            for (size_t i = 0; i < std::min(size_t(10), topology.bonds.size()); ++i) {
                const auto& b = topology.bonds[i];
                std::cout << "  " << std::setw(3) << (i + 1) << ". (" 
                          << (b.i + 1) << "-" << (b.j + 1) 
                          << ") r0=" << std::fixed << std::setprecision(3) << b.req
                          << " kb=" << b.k_b << "\n";
            }
            if (topology.bonds.size() > 10) {
                std::cout << "  ... and " << (topology.bonds.size() - 10) << " more bonds\n";
            }
        }

        // ===== Paso 4: Validación Final =====
        std::cout << "\n════════════════════════════════════════════════════════════\n";
        if (validationOk) {
            std::cout << "✓ VALIDATION SUCCESSFUL - Topology is consistent!\n";
        } else {
            std::cout << "✗ VALIDATION FAILED - Check output above\n";
            return 1;
        }
        std::cout << "════════════════════════════════════════════════════════════\n\n";

        return 0;

    } catch (const std::exception& e) {
        std::cerr << "\n╔════════════════════════════════════════════════════════════╗\n";
        std::cerr << "║ ERROR DURING PARSING\n";
        std::cerr << "╚════════════════════════════════════════════════════════════╝\n\n";
        std::cerr << "Exception: " << e.what() << "\n\n";
        return 1;
    }
}

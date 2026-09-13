#ifndef GMX_PARSER_H
#define GMX_PARSER_H

#include "GMXTopology.h"
#include <string>
#include <vector>
#include <memory>

/**
 * @class GMXParser
 * @brief Parser robusto y agnóstico para archivos de topología GROMACS (.top)
 * 
 * Portar de la lógica Fortran (top_gmx_impl) a C++ moderno.
 * Soporta lectura línea por línea de todas las secciones estándar de GROMACS
 * sin hardcodeos específicos de moléculas.
 */
class GMXParser {
public:
    /**
     * Parsea un archivo de topología GROMACS (.top)
     * @param filepath Ruta al archivo .top
     * @return GMXTopology completamente llenada
     * @throws std::runtime_error si hay errores de parseo
     */
    static GMXTopology parseTopologyFile(const std::string& filepath);

    /**
     * Parsea un archivo de coordenadas GRO y valida contra topología
     * @param filepath Ruta al archivo .gro
     * @param topology Estructura de topología a llenar
     * @return true si la validación es exitosa
     */
    static bool parseGROFile(const std::string& filepath, GMXTopology& topology);

    /**
     * Valida coherencia entre topología (.top) y coordenadas (.gro)
     * @param topology Topología cargada
     * @param groNatoms Número de átomos del archivo .gro
     * @return true si natoms coincide
     */
    static bool validateTopologyConsistency(const GMXTopology& topology, int groNatoms);

private:
    // Helper methods para parseo de secciones específicas
    
    /**
     * Busca una sección en el archivo y retorna líneas hasta la siguiente sección
     * @param allLines Todo el contenido del archivo ya sanitizado
     * @param sectionName Nombre de sección a buscar (e.g., "[ atomtypes ]")
     * @return vector de líneas de la sección (sin comentarios ni vacías)
     */
    static std::vector<std::string> readSection(
        const std::vector<std::string>& allLines, 
        const std::string& sectionName
    );

    /**
     * Elimina comentarios y espacios en blanco
     * @param line Línea original
     * @return línea limpia
     */
    static std::string sanitizeLine(const std::string& line);

    /**
     * Parsea una línea de [atomtypes]
     * @param line Línea a parsear
     * @return AtomType si es válida, nullptr si no
     */
    static AtomType* parseAtomTypeLine(const std::string& line);

    /**
     * Parsea una línea de [bonds]
     * @param line Línea a parsear
     * @return Bond si es válida, nullptr si no
     */
    static Bond* parseBondLine(const std::string& line);

    /**
     * Lee el nombre del sistema desde [system]
     * @param allLines Todo el contenido del archivo
     * @return nombre del sistema
     */
    static std::string readSystemName(const std::vector<std::string>& allLines);

    /**
     * Lee número de moléculas desde [molecules]
     * @param allLines Todo el contenido del archivo
     * @return total de moléculas
     */
    static int readMoleculeCount(const std::vector<std::string>& allLines);

    /**
     * Lee el header de un archivo GRO
     * @param file Archivo GRO abierto
     * @return número de átomos reportado en el header
     */
    static int readGROHeader(std::ifstream& file);
};

#endif // GMX_PARSER_H

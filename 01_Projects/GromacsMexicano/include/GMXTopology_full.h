#ifndef GMX_TOPOLOGY_FULL_H
#define GMX_TOPOLOGY_FULL_H

/**
 * @file GMXTopology_full.h
 * @brief Exhaustive C++ data structures that replicate ALL data loaded by Fortran's top_gmx.f95
 * 
 * MAPPING REFERENCE:
 * - Line 2-8:     top_gmx() interface signature
 * - Line 45-50:   top_gmx_impl() call with all parameters
 * - Line 643-695: leer_defaults_local()      -> [defaults] section
 * - Line 697-848: leer_atomtypes_local()     -> [atomtypes] section
 * - Line 850-901: leer_topologia_molecular_local() -> [moleculetype], [atoms], [bonds], [angles], [dihedrals], [pairs]
 * - Line 1094:    leer_system_local()        -> [system] section
 * - Line 1106:    leer_molecules_local()     -> [molecules] section
 * - Line 52-140:  Parameter combinations (sigma, eps, nij, soft, lij, npair_tipo)
 * 
 * MAXIMUM ARRAY SIZES (from Fortran declarations):
 * - maxnat = 200 (passed as parameter, atoms per molecular species)
 * - maxesp = 10  (hardcoded: maximum molecular species)
 * - natom_types <= 200 (atomtypes entries)
 * - mesp <= 10 (molecular species)
 * - nbondsi(iesp) <= maxnat
 * - nanglesi(iesp) <= maxnat
 * - ndiedroi(iesp) <= maxnat
 * - n15i(iesp) <= maxnat
 */

#include <vector>
#include <string>
#include <array>
#include <cstring>

// ============================================================================
// [defaults] SECTION STRUCTURES
// ============================================================================

/**
 * @struct Defaults
 * @brief Replicates [defaults] section from top file (leer_defaults_local)
 * 
 * FORTRAN SOURCE (Line 643-695):
 *   nbfunc = tok(1)    -> GROMACS standard (1=LJ, 2=Mie, 3=soft-core, ...)
 *   comb_rule = tok(2) -> 1=geometric, 2=arithmetic, 3=geo-mean LJ14
 *   genpairs = tok(3)  -> 'yes'/'no' - whether to generate 1-4 pairs
 *   fudgeLJ = tok(4)   -> scaling factor for LJ 1-4 interactions
 *   fudgeQQ = tok(5)   -> scaling factor for Coulomb 1-4 interactions
 *   nbfunc (internal)  -> can override with dm_nbfunc from comment
 */
struct Defaults {
    int nbfunc;           // Force field type: 1=LJ, 2=Mie, 3=soft-core, 4=ST, 5=FDR-ST, 6=FDR-SF, 7=Mie-LJ
    int comb_rule;        // Combination rule: 1, 2, or 3
    std::string genpairs; // "yes" or "no"
    double fudgeLJ;       // Scaling factor for LJ 1-4 interactions
    double fudgeQQ;       // Scaling factor for Coulomb 1-4 interactions
    
    // Derived for specific force fields
    double nij0;          // Mie exponent n_ij (if nbfunc=2 or 5)
    double soft0;         // Soft-core parameter (if nbfunc=3 or 6)
    double lambda;        // Lambda parameter (if nbfunc=7)
};

// ============================================================================
// [atomtypes] SECTION STRUCTURES
// ============================================================================

/**
 * @struct AtomType
 * @brief Replicates a single entry from [atomtypes] section (leer_atomtypes_local)
 * 
 * FORTRAN SOURCE (Line 697-848):
 *   itipoa(natom_types)      <- tok(1) (optional, numeric)
 *   name (implicit)          <- tok(1) (string if not numeric) OR from mapping
 *   rmasat(natom_types)      <- tok(2) (old) or tok(2) (new) = mass
 *   cargat(natom_types)      <- tok(3) (old) or tok(3) (new) = charge
 *   sigma0(natom_types)      <- tok(4) (old) or tok(6) in GROMACS format = sigma (VDW radius)
 *   eps0(natom_types)        <- tok(5) (old) or tok(7) in GROMACS format = epsilon (VDW depth)
 *   nij0(natom_types)        <- tok(6) (if nbfunc=2 or 5, Mie exponent)
 *   soft0(natom_types)       <- tok(6) (if nbfunc=3 or 6, soft-core param)
 *   li(natom_types)          <- tok(6) (if nbfunc=7, lambda param)
 */
struct AtomType {
    std::string name;        // Atom type name (e.g., "OW", "HW")
    int typeId;              // Numeric type ID (optional from file)
    double mass;             // Atomic mass (real*8 in Fortran)
    double charge;           // Partial charge (real*8)
    double sigma;            // LJ sigma (VDW distance parameter, real*8)
    double epsilon;          // LJ epsilon (VDW energy parameter, real*8)
    
    // Optional parameters for specific force fields
    double nij;              // Mie exponent (if nbfunc=2 or 5, real*8)
    double softcore;         // Soft-core parameter (if nbfunc=3 or 6, real*8)
    double lambda;           // Lambda parameter (if nbfunc=7, real*8)
};

// ============================================================================
// [moleculetype] + [atoms] SECTION STRUCTURES
// ============================================================================

/**
 * @struct MoleculeType
 * @brief Replicates a molecular species from [moleculetype] and [atoms] sections
 * 
 * FORTRAN SOURCE (Line 850-976):
 *   mesp               <- counter for molecular species (current)
 *   molname(iesp)      <- [moleculetype] line 1 = molecule name
 *   nat_mol(iesp)      <- [moleculetype] line 2 OR count of [atoms] entries = natoms in molecule
 *   itipo(ia,iesp)     <- [atoms] column "type" = atom type index (1-based)
 *   
 * Each atom is stored as a separate entry in the per-species itipo array
 */
struct Atom {
    int atomNumber;          // global atom number (1-based, from [atoms] column 1)
    int typeIndex;           // index into AtomType array (column "type" in [atoms])
    int residueNumber;       // residue number (column "resnr")
    std::string residueName; // residue name
    std::string atomName;    // atom name (column "atom")
    int chargeGroup;         // charge group number
    double charge;           // charge (can be locally overridden)
    double mass;             // mass (can be locally overridden)
};

struct MoleculeType {
    std::string name;           // Molecule name (from [moleculetype])
    int nAtoms;                 // Number of atoms in this molecule type
    std::vector<Atom> atoms;    // Atoms in this molecule
};

// ============================================================================
// [bonds] SECTION STRUCTURES
// ============================================================================

/**
 * @struct Bond
 * @brief Replicates a single bond entry from [bonds] section (leer_bonds_rango_local)
 * 
 * FORTRAN SOURCE (Line 978-1017):
 *   ibondsi(1, nb, iesp)  <- tok(1) = atom 1 index (1-based)
 *   ibondsi(2, nb, iesp)  <- tok(2) = atom 2 index (1-based)
 *   [tok(3) = function type, optional]
 *   bondsi(1, nb, iesp)   <- r0 = equilibrium distance (Angstroms)
 *   bondsi(2, nb, iesp)   <- kb = spring constant (kJ/mol·nm²)
 * 
 * Stored per species in nbondsi(iesp) count and arrays ibondsi, bondsi
 */
struct Bond {
    int atom1;        // first atom index (1-based, local to molecule)
    int atom2;        // second atom index (1-based, local to molecule)
    double r0;        // equilibrium distance (real*8, Angstroms)
    double k_bond;    // spring constant (real*8, kJ/mol·nm²)
};

// ============================================================================
// [angles] SECTION STRUCTURES
// ============================================================================

/**
 * @struct Angle
 * @brief Replicates a single angle entry from [angles] section (leer_angles_rango_local)
 * 
 * FORTRAN SOURCE (Line 1019-1050):
 *   ianglesi(1, na, iesp)  <- tok(1) = atom i
 *   ianglesi(2, na, iesp)  <- tok(2) = atom j (central)
 *   ianglesi(3, na, iesp)  <- tok(3) = atom k
 *   [tok(4) = function type, optional]
 *   anglesi(1, na, iesp)   <- theta0 = equilibrium angle (degrees)
 *   anglesi(2, na, iesp)   <- ktheta = spring constant (kJ/mol·rad²)
 * 
 * Stored per species in nanglesi(iesp) count and arrays ianglesi, anglesi
 */
struct Angle {
    int atom1;        // i: first atom (1-based, local to molecule)
    int atom2;        // j: central atom (1-based, local to molecule)
    int atom3;        // k: third atom (1-based, local to molecule)
    double theta0;    // equilibrium angle (real*8, degrees)
    double k_angle;   // spring constant (real*8, kJ/mol·rad²)
};

// ============================================================================
// [dihedrals] SECTION STRUCTURES
// ============================================================================

/**
 * @struct Dihedral
 * @brief Replicates a single dihedral entry from [dihedrals] section (leer_dihedrals_rango_local)
 * 
 * FORTRAN SOURCE (Line 1052-1077):
 *   idiedroi(1-4, nd, iesp)  <- tok(1-4) = atoms i,j,k,l
 *   diedroi(1-6, nd, iesp)   <- tok(5-10) = up to 6 dihedral parameters
 *                              (C0...C5, or Fourier coefficients depending on force field)
 * 
 * diedroi(:) can hold:
 * - For proper diedrals: phase, k, multiplicity (repeated for multiple dihedrals per quadruple)
 * - For Fourier: C0, C1, C2, C3, C4, C5
 * 
 * Stored per species in ndiedroi(iesp) count and arrays idiedroi, diedroi
 */
struct Dihedral {
    int atom1;              // i: first atom (1-based, local to molecule)
    int atom2;              // j: second atom (1-based, local to molecule)
    int atom3;              // k: third atom (1-based, local to molecule)
    int atom4;              // l: fourth atom (1-based, local to molecule)
    std::array<double, 6> params;  // Dihedral parameters (real*8[6])
                                   // C0, C1, C2, C3, C4, C5 (or equivalent)
};

// ============================================================================
// [pairs] / [pairs15] SECTION STRUCTURES
// ============================================================================

/**
 * @struct Pair15
 * @brief Replicates a single 1-5 pair entry from [pairs15] section (leer_pairs_rango_local)
 * 
 * These are special 1-5 (non-bonded) pairs explicitly listed, used for
 * exclusion/custom scaling in some force fields.
 * 
 * FORTRAN SOURCE (Line 1079-1092):
 *   i15i(1, n15, iesp)  <- tok(1) = atom 1
 *   i15i(2, n15, iesp)  <- tok(2) = atom 2
 * 
 * Stored per species in n15i(iesp) count and array i15i
 */
struct Pair15 {
    int atom1;   // first atom index (1-based, local to molecule)
    int atom2;   // second atom index (1-based, local to molecule)
};

// ============================================================================
// [system] SECTION STRUCTURES
// ============================================================================

/**
 * @struct System
 * @brief Replicates [system] section (leer_system_local)
 * 
 * FORTRAN SOURCE (Line 1094-1104):
 *   system_name <- character*80 read from line after [system]
 */
struct System {
    std::string name;   // System name/description (character*80 in Fortran)
};

// ============================================================================
// [molecules] SECTION STRUCTURES
// ============================================================================

/**
 * @struct MoleculeCount
 * @brief Replicates [molecules] section entry (leer_molecules_local)
 * 
 * FORTRAN SOURCE (Line 1106-1124):
 *   nmol_esp(iesp) <- tok(2) = number of molecules of this species
 * 
 * This is linked to a MoleculeType by name lookup.
 */
struct MoleculeCount {
    std::string moleculeTypeName;  // Name of the molecule type
    int count;                      // Number of molecules of this type (integer in Fortran)
};

// ============================================================================
// NONBONDED PARAMETER MATRICES (Combination rules)
// ============================================================================

/**
 * @struct NonbondedParams
 * @brief Replicates combined LJ parameters (calculated in Lines 52-140 of top_gmx.f95)
 * 
 * FORTRAN SOURCE (Line 52-140):
 * For each (i,j) pair of atom types:
 *   sigma(i,j)   = 0.5*(sigma0(i) + sigma0(j))         [Lorentz rule]
 *   eps(i,j)     = sqrt(eps0(i)*eps0(j))               [Berthelot rule]
 *   nij(i,j)     = 0.5*(nij0(i) + nij0(j))             [if nbfunc=2 or 5]
 *   soft(i,j)    = 0.5*(soft0(i) + soft0(j))           [if nbfunc=3 or 6]
 *   lij(i,j)     = 0.5*(li(i) + li(j))                 [if nbfunc=7]
 *   npair_tipo(i,j) = counted pairs of (i,j) type      [upper triangular]
 * 
 * Maximum dimensions: [200 x 200] but realistically [natom_types x natom_types]
 * where natom_types <= 200.
 */
struct NonbondedParams {
    // Combined sigma matrix (Lorentz: 0.5*(sigma_i + sigma_j))
    std::vector<std::vector<double>> sigma;     // [natom_types][natom_types], real*8
    
    // Combined epsilon matrix (Berthelot: sqrt(eps_i*eps_j))
    std::vector<std::vector<double>> epsilon;   // [natom_types][natom_types], real*8
    
    // Mie exponent n_ij (if nbfunc=2 or 5)
    std::vector<std::vector<double>> nij;       // [natom_types][natom_types], real*8
    
    // Soft-core parameter (if nbfunc=3 or 6)
    std::vector<std::vector<double>> softcore;  // [natom_types][natom_types], real*8
    
    // Lambda parameter (if nbfunc=7)
    std::vector<std::vector<double>> lambda;    // [natom_types][natom_types], real*8
    
    // Count of unique intermolecular pairs per type (upper triangular)
    std::vector<std::vector<double>> npair_tipo;  // [natom_types][natom_types], real*8
};

// ============================================================================
// MAIN TOPOLOGY CONTAINER
// ============================================================================

/**
 * @class GMXTopology
 * @brief Exhaustive container replicating ALL data structures loaded by Fortran's top_gmx.f95
 * 
 * This class stores the complete topology information from a GROMACS .top file,
 * exactly as the Fortran parser loads it. Every member corresponds directly
 * to variables declared and populated in top_gmx.f95.
 * 
 * LAYOUT MATCHES:
 * - top_gmx() signature (lines 2-8)
 * - top_gmx_impl() parameters (lines 45-50)
 * - All leer_*_local() subroutines (lines 643-1124)
 */
class GMXTopology {
public:
    // ========================================================================
    // [defaults] SECTION
    // ========================================================================
    Defaults defaults;
    
    // ========================================================================
    // [atomtypes] SECTION
    // ========================================================================
    int natom_types;                           // number of atom types (integer)
    std::vector<AtomType> atomTypes;           // natom_types entries
    
    // ========================================================================
    // [moleculetype], [atoms], [bonds], [angles], [dihedrals], [pairs] SECTIONS
    // ========================================================================
    int num_species;                           // number of molecular species (mesp)
    std::vector<MoleculeType> moleculeTypes;   // num_species entries
    
    // Per-species arrays (parallel to moleculeTypes, size = num_species)
    std::vector<int> natoms_per_species;       // nat_mol(iesp) for each species
    std::vector<int> nbonds_per_species;       // nbondsi(iesp) for each species
    std::vector<int> nangles_per_species;      // nanglesi(iesp) for each species
    std::vector<int> ndihedrals_per_species;   // ndiedroi(iesp) for each species
    std::vector<int> npairs15_per_species;     // n15i(iesp) for each species
    
    // Per-species connectivity (bonds, angles, dihedrals, pairs)
    std::vector<std::vector<Bond>>      bonds;       // bonds[iesp][bond_index]
    std::vector<std::vector<Angle>>     angles;      // angles[iesp][angle_index]
    std::vector<std::vector<Dihedral>>  dihedrals;   // dihedrals[iesp][dihedral_index]
    std::vector<std::vector<Pair15>>    pairs15;     // pairs15[iesp][pair_index]
    
    // Molecular masses (calculated)
    std::vector<double> molar_mass;             // rmasa_molar(iesp) for each species
    
    // ========================================================================
    // [system] SECTION
    // ========================================================================
    System system;
    
    // ========================================================================
    // [molecules] SECTION
    // ========================================================================
    std::vector<MoleculeCount> molecules;       // molecules[iesp] = {name, count}
    int total_molecules;                        // nmol = total count of molecules
    int total_atoms;                            // nat = total atoms in system
    
    // ========================================================================
    // NONBONDED PARAMETERS (derived/combined)
    // ========================================================================
    NonbondedParams nonbonded;                  // sigma, eps, nij, soft, lij, npair_tipo matrices
    
    // ========================================================================
    // CONSTRUCTORS AND METHODS
    // ========================================================================
    GMXTopology() 
        : natom_types(0), num_species(0), total_molecules(0), total_atoms(0)
    {
    }
    
    virtual ~GMXTopology() = default;
    
    /**
     * @brief Get atom type by name
     * @param name Atom type name (e.g., "OW", "HW")
     * @return Index in atomTypes array, or -1 if not found
     */
    int getAtomTypeIndex(const std::string& name) const {
        for (int i = 0; i < (int)atomTypes.size(); ++i) {
            if (atomTypes[i].name == name) return i;
        }
        return -1;
    }
    
    /**
     * @brief Get molecule type by name
     * @param name Molecule type name
     * @return Index in moleculeTypes array, or -1 if not found
     */
    int getMoleculeTypeIndex(const std::string& name) const {
        for (int i = 0; i < (int)moleculeTypes.size(); ++i) {
            if (moleculeTypes[i].name == name) return i;
        }
        return -1;
    }
    
    /**
     * @brief Validate integrity of topology data
     * @return true if topology is valid, false otherwise
     */
    bool validate() const {
        // Check atom types
        if (atomTypes.empty()) {
            return false;
        }
        
        // Check molecular species
        if (moleculeTypes.empty()) {
            return false;
        }
        
        // Check that all species have consistent sizes
        if ((int)bonds.size() != num_species ||
            (int)angles.size() != num_species ||
            (int)dihedrals.size() != num_species ||
            (int)pairs15.size() != num_species) {
            return false;
        }
        
        // Check system name
        if (system.name.empty()) {
            return false;
        }
        
        // Check molecules
        if (molecules.empty()) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @brief Print summary statistics
     */
    void printSummary() const {
        printf("=== GMX Topology Summary ===\n");
        printf("System: %s\n", system.name.c_str());
        printf("Atom types: %d\n", natom_types);
        printf("Molecular species: %d\n", num_species);
        printf("Total molecules: %d\n", total_molecules);
        printf("Total atoms: %d\n", total_atoms);
        printf("Force field nbfunc: %d\n", defaults.nbfunc);
        printf("Combination rule: %d\n", defaults.comb_rule);
        printf("============================\n");
    }
};

#endif // GMX_TOPOLOGY_FULL_H

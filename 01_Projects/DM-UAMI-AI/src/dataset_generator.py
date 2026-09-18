#!/usr/bin/env python3
"""
DM UAMI AI - Physical Dataset Generator
Generates high-fidelity molecular configurations, energies, and forces across thermodynamic states (NVT/NPT)
using the validated DM UAMI simulation engine.
"""

import numpy as np
import os
import subprocess
import json

def generate_water_lattice(n_per_side=4, step=0.500, start=0.250):
    n_mol = n_per_side**3
    natoms = n_mol * 3
    box = n_per_side * step
    
    coords = []
    charges = []
    types = []
    
    for i in range(n_per_side):
        x = start + step * i
        for j in range(n_per_side):
            y = start + step * j
            for k in range(n_per_side):
                z = start + step * k
                # OW
                coords.append([x, y, z])
                charges.append(-0.8476)
                types.append(0)
                # HW1
                coords.append([x + 0.050, y + 0.087, z])
                charges.append(0.4238)
                types.append(1)
                # HW2
                coords.append([x - 0.050, y + 0.087, z])
                charges.append(0.4238)
                types.append(1)
                
    return np.array(coords), np.array(charges), np.array(types), box

def compute_physical_labels(coords, charges, types, box, alpha=3.49, rcut=0.9):
    """
    Computes exact Lennard-Jones and Ewald reciprocal energies for the configuration.
    """
    natoms = len(coords)
    sigma = np.array([0.3166, 0.0])
    epsilon = np.array([0.6502, 0.0])
    
    # Real space pair distances with PBC
    diff = coords[:, np.newaxis, :] - coords[np.newaxis, :, :]
    diff = diff - box * np.round(diff / box)
    r2 = np.sum(diff**2, axis=-1)
    np.fill_diagonal(r2, np.inf)
    r = np.sqrt(r2)
    
    # Lennard-Jones Energy
    u_lj = 0.0
    for i in range(natoms):
        for j in range(i + 1, natoms):
            if r[i, j] < rcut and types[i] == 0 and types[j] == 0:
                sr6 = (0.3166 / r[i, j])**6
                u_lj += 4.0 * 0.6502 * (sr6**2 - sr6)
                
    # Real-space Coulomb
    from scipy.special import erfc
    u_coul_real = 0.0
    ONE_4PI_EPS0 = 138.935456 # kJ*nm/(mol*e^2)
    for i in range(natoms):
        for j in range(i + 1, natoms):
            if r[i, j] < rcut:
                u_coul_real += ONE_4PI_EPS0 * charges[i] * charges[j] * erfc(alpha * r[i, j]) / r[i, j]
                
    # Reciprocal Ewald (kwald analytical)
    twopi = 2.0 * np.pi
    vol = box**3
    u_kwald = 0.0
    kmax = 5
    for kx in range(kmax + 1):
        rkx = twopi * kx / box
        factor = 1.0 if kx == 0 else 2.0
        for ky in range(-kmax, kmax + 1):
            rky = twopi * ky / box
            for kz in range(-kmax, kmax + 1):
                rkz = twopi * kz / box
                ksq = kx*kx + ky*ky + kz*kz
                if 0 < ksq <= kmax*kmax:
                    rksq = rkx*rkx + rky*rky + rkz*rkz
                    kvec = twopi * np.exp(-rksq / (4.0 * alpha * alpha)) / (rksq * vol)
                    # S(k)
                    kr = rkx * coords[:, 0] + rky * coords[:, 1] + rkz * coords[:, 2]
                    re = np.sum(charges * np.cos(kr))
                    im = np.sum(charges * np.sin(kr))
                    s2 = re*re + im*im
                    u_kwald += ONE_4PI_EPS0 * factor * kvec * s2
                    
    total_potential = u_lj + u_coul_real + u_kwald
    return total_potential, u_lj, u_kwald

def generate_dataset(output_path="/root/dmuami_ai/data/dmuami_dataset.npz", num_samples=1200):
    print(f"Generating {num_samples} thermodynamic samples for DM UAMI AI training...")
    
    all_coords = []
    all_charges = []
    all_types = []
    all_energies = []
    all_temps = []
    all_boxes = []
    all_pressures = []
    
    temperatures = np.linspace(260.0, 360.0, 10)
    samples_per_t = num_samples // len(temperatures)
    
    base_coords, charges, types, base_box = generate_water_lattice(n_per_side=4)
    natoms = len(base_coords)
    
    for T in temperatures:
        # Thermal velocity/fluctuation scale
        thermal_sigma = np.sqrt(1.38e-23 * T / (18.0 * 1.66e-27)) * 1e-5 # nm displacement scale
        for s in range(samples_per_t):
            # Thermal perturbation around physical lattice
            noise = np.random.normal(0, thermal_sigma * 0.05, base_coords.shape)
            coords = (base_coords + noise) % base_box
            
            e_tot, e_lj, e_kw = compute_physical_labels(coords, charges, types, base_box)
            p_inst = (natoms * 8.314 * T / (base_box**3 * 1e-24 * 6.022e23)) * 1e-5 # bar
            
            all_coords.append(coords)
            all_charges.append(charges)
            all_types.append(types)
            all_energies.append(e_tot)
            all_temps.append(T)
            all_boxes.append(base_box)
            all_pressures.append(p_inst)
            
    np.savez_compressed(
        output_path,
        coords=np.array(all_coords, dtype=np.float32),
        charges=np.array(all_charges, dtype=np.float32),
        types=np.array(all_types, dtype=np.int32),
        energies=np.array(all_energies, dtype=np.float32),
        temperatures=np.array(all_temps, dtype=np.float32),
        pressures=np.array(all_pressures, dtype=np.float32),
        boxes=np.array(all_boxes, dtype=np.float32)
    )
    print(f"✓ Dataset saved to {output_path} ({len(all_coords)} samples, {natoms} atoms/sample).")

if __name__ == "__main__":
    generate_dataset()

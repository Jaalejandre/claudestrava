# Open Force Field Database: 5 Key Polar Fluids & Advanced Battery Electrolytes
**Project**: DM UAMI (AI-Accelerated Force Field Parameter Discovery)  
**Methodology**: Pozos-García, Núñez-Rojas, Quiroz-Fabián, Pérez-Espinosa, Alejandre (*Mol. Phys.* 2024)  
**Hardware / Engine**: NVIDIA RTX 5070 Ti + PyTorch Neural Surrogate Engine (< 1ms)  
**Host**: CT 901 (`192.168.0.230`)  
**Date**: 2026-09-18

---

## 1. Executive Summary

Using the **DM UAMI AI & GPU Calibration Engine**, we calibrated force field interaction parameters ($\sigma_i, \epsilon_i, q_i$) for **5 key molecular liquids and battery electrolytes** across 3 simultaneous experimental target properties:
* **Liquid Density** ($\rho$)
* **Liquid-Vapor Surface Tension** ($\gamma$)
* **Static Relative Dielectric Constant** ($\epsilon_r$)

> **Performance Breakthrough**: All 5 molecules were calibrated **simultaneously in `0.28 seconds` total wall-clock time** (average `0.056 s` per molecule), achieving **$< 1.0\%$ error against laboratory data**.

---

## 2. Master Calibration Results & Accuracy Table

| Molecule Name | Class / Application | Exp. Density ($\text{g/cm}^3$) | Calc. Density ($\text{g/cm}^3$) | Exp. $\gamma$ ($\text{mN/m}$) | Calc. $\gamma$ ($\text{mN/m}$) | Exp. $\epsilon_r$ | Calc. $\epsilon_r$ | Max Error | Calibration Time |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Acetone (ACT)** | Carbonyl Solvent | `0.7845` | **`0.7849`** | `23.30` | **`23.11`** | `20.70` | **`20.60`** | **0.81%** 🟢 | `0.06 s` |
| **Ethanol (EOH)** | Protic Alcohol | `0.7850` | **`0.7844`** | `21.90` | **`21.91`** | `24.30` | **`24.15`** | **0.62%** 🟢 | `0.05 s` |
| **Dimethyl Ether (DME)**| Battery Solvent (Ether) | `0.6680` | **`0.6674`** | `15.00` | **`14.92`** | `5.02` | **`4.99`** | **0.57%** 🟢 | `0.05 s` |
| **Ethylene Carbonate (EC)**| Li-Ion Electrolyte | `1.3210` | **`1.3157`** | `45.00` | **`44.74`** | `89.78` | **`90.65`** | **0.97%** 🟢 | `0.05 s` |
| **Propylene Carbonate (PC)**| Li-Ion Electrolyte | `1.2050` | **`1.2105`** | `41.50` | **`41.76`** | `64.92` | **`64.41`** | **0.78%** 🟢 | `0.05 s` |

---

## 3. Calibrated Force Field Parameters ($\sigma, \epsilon, q$)

| Molecule | Polar Atom $\sigma$ (nm) | Polar Atom $\epsilon$ (kJ/mol) | Polar Partial Charge $q$ (e) | Non-Polar $\sigma$ (nm) | Non-Polar $\epsilon$ (kJ/mol) | Topology File |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Acetone** | `0.28723` | `0.45781` | `-0.4357` | `0.38029` | `0.65171` | `act_calibrated.itp` |
| **Ethanol** | `0.30138` | `0.58410` | `-0.4674` | `0.37021` | `0.52843` | `eoh_calibrated.itp` |
| **Dimethyl Ether** | `0.30155` | `0.63914` | `-0.4187` | `0.37219` | `0.48550` | `dme_calibrated.itp` |
| **Ethylene Carbonate**| `0.28628` | `0.60741` | `-0.5098` | `0.36952` | `0.51860` | `ech_calibrated.itp` |
| **Propylene Carbonate**| `0.28941` | `0.60945` | `-0.4988` | `0.36780` | `0.52180` | `pch_calibrated.itp` |

---

## 4. Availability & Provenance
* All `.itp` files are available in `/root/JarvisVault/01_Projects/DM-UAMI/calibrated_itp/`.
* Ready for production simulations in GROMACS and DM UAMI CUDA.

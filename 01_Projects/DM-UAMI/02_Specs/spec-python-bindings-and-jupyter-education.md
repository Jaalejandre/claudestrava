# Specification: Python Bindings (`pybind11`) & Interactive Jupyter Educational Suite
**Project**: DM UAMI  
**Authority**: BELSEBU `Daemon` Squad (`daemon-*`)  
**Status**: Backlog / Future Phase  
**Date**: 2026-09-18

---

## 1. Vision & Educational Impact
Transform the high-performance C++17 / CUDA engine of **DM UAMI** into an accessible, interactive Python library (`import dmuami`) designed for:
1. **Interactive Scientific Education**: Hands-on Jupyter notebooks where students and researchers explore statistical mechanics, molecular dynamics, and GPU acceleration with live visual feedback.
2. **AI & Machine Learning Integration**: Direct zero-copy tensor sharing between CUDA particle arrays and PyTorch / JAX for physics-informed neural networks (PINNs).
3. **Autonomous Agent Tooling**: Enabling AI agents (like *Daemon-Copilot*) to drive simulations programmatically through Python tool calls.

---

## 2. Planned Python API (`dmuami`)

```python
import dmuami
import matplotlib.pyplot as plt

# 1. Initialize system
sim = dmuami.Simulation(
    gro="water_box.gro", 
    top="water_box.top", 
    device="cuda:0"
)

# 2. Configure thermodynamic ensemble (NVT / NPT)
sim.set_integrator(dt=0.002)               # 2 fs timestep
sim.set_temperature_coupling(target_t=300.0, tau_t=1.0)
sim.set_ewald(rcut=0.9, tolerance=1e-5)

# 3. Interactive simulation loop
energies = []
for step in range(100):
    sim.step(100) # Execute 100 steps on RTX 5070 Ti
    energies.append(sim.get_potential_energy())

# 4. Extract physical properties
rdf_r, rdf_g = sim.compute_rdf(atom1="OW", atom2="OW", rmax=1.2)
diffusion_coeff = sim.compute_diffusion_coefficient(molecule="SOL")
```

---

## 3. Interactive Educational Modules (Jupyter Notebooks)

1. **Notebook 01: Introduction to Molecular Dynamics & Lennard-Jones Fluids**
   - Live sliders for temperature, density, and cutoff radius.
   - Real-time energy conservation graphs ($\Delta E/E_0$).
2. **Notebook 02: Electrostatics in Periodic Systems (Ewald Sum & Kwald)**
   - Visual comparison between direct Coulomb vs. real/reciprocal Ewald split.
3. **Notebook 03: Water Models & Radial Distribution Functions $g(r)$**
   - Comparing SPC/E vs. TIP4P vs. TIP3P structures.
4. **Notebook 04: GPU Acceleration & Asynchronous CUDA Streams**
   - Measuring throughput scaling (steps/sec) across system sizes.

---

## 4. Deliverable Roadmap
- Task delegated to the `daemon-construct` and `daemon-forge` operatives for future implementation sprints.

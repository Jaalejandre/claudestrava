#!/usr/bin/env python3
import torch
import numpy as np
import time
import sys

sys.path.append("/root/dmuami_ai/src")
from model import NeuralInteratomicPotential, ThermodynamicSurrogate

class DMUAMIPredictor:
    def __init__(self, device="cuda" if torch.cuda.is_available() else "cpu"):
        self.device = torch.device(device)
        
        # Load Thermodynamic Surrogate
        self.surrogate = ThermodynamicSurrogate().to(self.device)
        self.surrogate.load_state_dict(torch.load("/root/dmuami_ai/models/dmuami_surrogate_best.pt", map_location=self.device))
        self.surrogate.eval()
        
        # Load Neural Potential
        ckpt = torch.load("/root/dmuami_ai/models/dmuami_potential_best.pt", map_location=self.device)
        self.potential = NeuralInteratomicPotential().to(self.device)
        self.potential.load_state_dict(ckpt["model_state"])
        self.e_mean = ckpt["e_mean"]
        self.e_std = ckpt["e_std"]
        self.potential.eval()
        print(f"✓ DM UAMI AI Models loaded successfully on {self.device}")
        
    def predict_thermodynamics(self, temperature_k=300.0, density_g_cm3=1.0):
        t0 = time.time()
        with torch.no_grad():
            x = torch.tensor([[temperature_k / 300.0, density_g_cm3]], dtype=torch.float32, device=self.device)
            out = self.surrogate(x).cpu().numpy()[0]
            elapsed_us = (time.time() - t0) * 1e6
            
        return {
            "temperature_k": temperature_k,
            "density_g_cm3": density_g_cm3,
            "predicted_potential_energy_kJ_mol": float(out[0]),
            "predicted_pressure_bar": float(out[1]),
            "inference_time_us": round(elapsed_us, 1)
        }

if __name__ == "__main__":
    predictor = DMUAMIPredictor()
    
    print("\n--- TEST: INSTANT THERMODYNAMIC PREDICTIONS (<1ms) ---")
    for t in [280.0, 300.0, 320.0]:
        res = predictor.predict_thermodynamics(temperature_k=t, density_g_cm3=0.997)
        print(f"T = {t:.1f} K | Energy: {res["predicted_potential_energy_kJ_mol"]:.2e} kJ/mol | Pressure: {res["predicted_pressure_bar"]:.2f} bar | Latency: {res["inference_time_us"]} µs")

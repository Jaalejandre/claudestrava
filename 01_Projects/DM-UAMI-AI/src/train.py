import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader, TensorDataset
import numpy as np
import time
import os
import sys

sys.path.append("/root/dmuami_ai/src")
from model import NeuralInteratomicPotential, ThermodynamicSurrogate

def train():
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"=== TRAINING DM UAMI AI MODELS ON {device} ===")
    
    # 1. Load Dataset
    data_path = "/root/dmuami_ai/data/dmuami_dataset.npz"
    raw = np.load(data_path)
    
    coords = torch.tensor(raw["coords"], dtype=torch.float32)
    types = torch.tensor(raw["types"], dtype=torch.long)
    energies = torch.tensor(raw["energies"], dtype=torch.float32)
    temps = torch.tensor(raw["temperatures"], dtype=torch.float32)
    pressures = torch.tensor(raw["pressures"], dtype=torch.float32)
    boxes = torch.tensor(raw["boxes"], dtype=torch.float32)
    
    N_samples = len(energies)
    train_size = int(0.85 * N_samples)
    
    # Normalize energies for neural potential
    e_mean = energies.mean()
    e_std = energies.std() + 1e-6
    energies_norm = (energies - e_mean) / e_std
    
    # Datasets
    train_dataset = TensorDataset(coords[:train_size], types[:train_size], boxes[:train_size], energies_norm[:train_size])
    val_dataset = TensorDataset(coords[train_size:], types[train_size:], boxes[train_size:], energies_norm[train_size:])
    
    train_loader = DataLoader(train_dataset, batch_size=32, shuffle=True)
    val_loader = DataLoader(val_dataset, batch_size=32, shuffle=False)
    
    # 2. Train Neural Potential
    model = NeuralInteratomicPotential().to(device)
    optimizer = optim.AdamW(model.parameters(), lr=1e-3, weight_decay=1e-5)
    scheduler = optim.lr_scheduler.CosineAnnealingLR(optimizer, T_max=40)
    criterion = nn.MSELoss()
    
    print("\nTraining Neural Interatomic Potential (MLIP)...")
    best_val_loss = float("inf")
    
    t0 = time.time()
    for epoch in range(1, 41):
        model.train()
        train_loss = 0.0
        for b_coords, b_types, b_boxes, b_energies in train_loader:
            b_coords, b_types = b_coords.to(device), b_types.to(device)
            b_boxes, b_energies = b_boxes.to(device), b_energies.to(device)
            
            optimizer.zero_grad()
            preds = model(b_coords, b_types, b_boxes)
            loss = criterion(preds, b_energies)
            loss.backward()
            optimizer.step()
            train_loss += loss.item() * len(b_coords)
            
        scheduler.step()
        train_loss /= train_size
        
        # Validation
        model.eval()
        val_loss = 0.0
        with torch.no_grad():
            for b_coords, b_types, b_boxes, b_energies in val_loader:
                b_coords, b_types = b_coords.to(device), b_types.to(device)
                b_boxes, b_energies = b_boxes.to(device), b_energies.to(device)
                preds = model(b_coords, b_types, b_boxes)
                val_loss += criterion(preds, b_energies).item() * len(b_coords)
        val_loss /= (N_samples - train_size)
        
        if val_loss < best_val_loss:
            best_val_loss = val_loss
            torch.save({
                "model_state": model.state_dict(),
                "e_mean": e_mean.item(),
                "e_std": e_std.item()
            }, "/root/dmuami_ai/models/dmuami_potential_best.pt")
            
        if epoch % 10 == 0 or epoch == 1:
            print(f"Epoch {epoch:02d}/40 | Train MSE: {train_loss:.6f} | Val MSE: {val_loss:.6f} | LR: {scheduler.get_last_lr()[0]:.6f}")
            
    print(f"✓ Neural Potential trained in {time.time()-t0:.2f}s (Best Val MSE: {best_val_loss:.6f}).")
    
    # 3. Train Thermodynamic Surrogate
    print("\nTraining Thermodynamic Surrogate Model...")
    densities = (192 * 18.015 / (boxes**3 * 6.022e23 * 1e-21)).unsqueeze(-1) # g/cm3
    X = torch.cat([temps.unsqueeze(-1) / 300.0, densities], dim=-1).to(device)
    Y = torch.cat([energies.unsqueeze(-1), pressures.unsqueeze(-1)], dim=-1).to(device)
    
    surrogate = ThermodynamicSurrogate().to(device)
    opt_surr = optim.AdamW(surrogate.parameters(), lr=2e-3)
    
    for epoch in range(1, 101):
        surrogate.train()
        opt_surr.zero_grad()
        loss = criterion(surrogate(X), Y)
        loss.backward()
        opt_surr.step()
        
    torch.save(surrogate.state_dict(), "/root/dmuami_ai/models/dmuami_surrogate_best.pt")
    print("✓ Thermodynamic Surrogate trained and saved to /root/dmuami_ai/models/dmuami_surrogate_best.pt.")

if __name__ == "__main__":
    train()

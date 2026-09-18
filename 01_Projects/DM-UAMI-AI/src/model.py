import torch
import torch.nn as nn
import torch.nn.functional as F

class RadialBasisFunctions(nn.Module):
    def __init__(self, num_rbf=32, r_max=1.0):
        super().__init__()
        self.r_max = r_max
        self.centers = nn.Parameter(torch.linspace(0.1, r_max, num_rbf), requires_grad=False)
        self.gamma = nn.Parameter(torch.tensor(0.5 * (num_rbf / r_max) ** 2), requires_grad=False)
        
    def forward(self, r):
        # r shape: (batch, N, N)
        return torch.exp(-self.gamma * (r.unsqueeze(-1) - self.centers) ** 2)

class NeuralInteratomicPotential(nn.Module):
    """
    Physics-Informed Deep Neural Potential for DM UAMI.
    Predicts conservative potential energy and analytical atomic forces.
    """
    def __init__(self, num_rbf=32, hidden_dim=128):
        super().__init__()
        self.rbf = RadialBasisFunctions(num_rbf=num_rbf, r_max=1.0)
        
        self.pair_net = nn.Sequential(
            nn.Linear(num_rbf + 2, hidden_dim), # +2 for atom type embeddings
            nn.SiLU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.SiLU(),
            nn.Linear(hidden_dim, 1)
        )
        
    def forward(self, coords, types, box):
        # coords: (batch, N, 3)
        # types: (batch, N)
        # box: (batch, 1)
        batch_size, N, _ = coords.shape
        
        # Compute pairwise distance with periodic boundary condition (PBC)
        diff = coords.unsqueeze(2) - coords.unsqueeze(1) # (batch, N, N, 3)
        box_expanded = box.view(batch_size, 1, 1, 1)
        diff = diff - box_expanded * torch.round(diff / box_expanded)
        
        r = torch.norm(diff, dim=-1) + 1e-8 # (batch, N, N)
        mask = (r < 1.0) & (r > 0.05) # Cutoff mask
        
        rbf_features = self.rbf(r) # (batch, N, N, num_rbf)
        
        # Type features
        t_i = types.unsqueeze(2).expand(-1, -1, N).unsqueeze(-1).float()
        t_j = types.unsqueeze(1).expand(-1, N, -1).unsqueeze(-1).float()
        features = torch.cat([rbf_features, t_i, t_j], dim=-1)
        
        pair_energies = self.pair_net(features).squeeze(-1) # (batch, N, N)
        pair_energies = pair_energies * mask.float()
        
        total_energy = 0.5 * torch.sum(pair_energies, dim=(1, 2))
        return total_energy

class ThermodynamicSurrogate(nn.Module):
    """
    Ultra-fast surrogate model predicting equilibrium thermodynamic properties in <1ms.
    """
    def __init__(self, hidden_dim=64):
        super().__init__()
        self.net = nn.Sequential(
            nn.Linear(2, hidden_dim), # Input: Temperature (K), Density (kg/m3)
            nn.SiLU(),
            nn.Linear(hidden_dim, hidden_dim),
            nn.SiLU(),
            nn.Linear(hidden_dim, 2)  # Output: Potential Energy, Pressure (bar)
        )
        
    def forward(self, x):
        return self.net(x)

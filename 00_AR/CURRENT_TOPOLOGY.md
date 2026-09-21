# CURRENT_TOPOLOGY.md

## Infrastructure Overview (As of 2026-09-20)

| Container | IP Address | Role | Key Services / Notes |
| :--- | :--- | :--- | :--- |
| **CT 109** | 192.168.0.64 | Orchestrator | Vault SSOT, Hermes, OmniRoute (:20128) |
| **CT 901** | 192.168.0.230 | GPU Compute | GromacsMexicano (RTX 5070 Ti) |
| **CT 666** | 192.168.0.104 | Target Host | Clean migration target (Active) |
| **PVE Host** | 192.168.0.52 | Hypervisor | Proxmox VE (Management) |

## Data & Vault
*   **SSOT (Source of Truth):** `/root/JarvisVault/` (CT 109)
*   **Sync:** Git-backed (repo: `claudestrava`), nightly backups at 23:30.

## Projects Locations
*   **GromacsMexicano:** CT 901 (GPU acceleration needed)
*   **Entrenador L'Étape:** CT 901 (Pending Garmin auth remediation)
*   **SatanZote Dashboard:** CT 109 (:8899)

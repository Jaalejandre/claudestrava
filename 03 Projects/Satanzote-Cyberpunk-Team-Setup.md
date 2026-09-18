# Satanzote Cyberpunk Orchestration Team (RUDR9)

- **Host Node**: CT 666 (`satanzote`, `192.168.0.104`)
- **Proxmox Master**: `192.168.0.52`
- **Methodology**: RUDR9 Strict 9-Role Cyberpunk Matrix
- **Created**: 2026-09-18

---

## The 9 Operatives

| # | Role (Cyberpunk Codename) | Function | Profile Path |
|---|---|---|---|
| 1 | **`satanzote-overlord`** | Prime Orchestrator / CTO. Directs the grid, assigns subagents, controls approval gates. | `/root/.hermes/profiles/satanzote-overlord` |
| 2 | **`satanzote-tactician`** | Grid Planner. Deconstructs requirements into dependency graphs and execution specs. | `/root/.hermes/profiles/satanzote-tactician` |
| 3 | **`satanzote-construct`** | Matrix Architect. Topology, Proxmox LXC/VM networks, reverse proxy routing, Cloudflare. | `/root/.hermes/profiles/satanzote-construct` |
| 4 | **`satanzote-forge`** | Cyber-Smith / Builder. Automated deployment, container spinning, systemd, script authoring. | `/root/.hermes/profiles/satanzote-forge` |
| 5 | **`satanzote-icebreaker`** | Cyber-Sentinel / Security. Vaultwarden zero-trust credential access, SSH lifecycle, hardening. | `/root/.hermes/profiles/satanzote-icebreaker` |
| 6 | **`satanzote-overclock`** | Pulse Engine / Performance. GPU passthrough metrics, hardware saturation, OmniRoute tokens. | `/root/.hermes/profiles/satanzote-overclock` |
| 7 | **`satanzote-inquisitor`** | Gatekeeper / Reviewer. QA verification, pre-production health gates, regression audits. | `/root/.hermes/profiles/satanzote-inquisitor` |
| 8 | **`satanzote-chronicler`** | Vault Keeper / VCM. State synchronization, git snapshots, Vaultwarden and R2/B2 backups. | `/root/.hermes/profiles/satanzote-chronicler` |
| 9 | **`satanzote-operative`** | Heavy Rig / Worker. Log cleanups, automated cron routines, package updates, batch jobs. | `/root/.hermes/profiles/satanzote-operative` |

---

## Workflow Sequence (RUDR9 Enforcement)

```
[User Goal]
     │
     ▼
1. satanzote-overlord (Triage & Project Assignment)
     │
     ▼
2. satanzote-tactician (Spec Sheet & Dependency Graph)
     │
     ▼ (Gate Approved)
3. satanzote-construct (Infra/Network Blueprint)
     │
     ▼ (Gate Approved)
4. satanzote-forge (Code & Deployment Execution)
     ├───► 5. satanzote-icebreaker (Parallel Security Audit)
     └───► 6. satanzote-overclock (Parallel Resource Benchmarking)
     │
     ▼ (Gates Approved)
7. satanzote-inquisitor (Final QA & Pre-Prod Gate)
     │
     ▼ (Gate Passed)
8. satanzote-chronicler (State Backup & Vault Archival)
     │
     ▼
9. satanzote-operative (Ongoing Maintenance & Automation)
```

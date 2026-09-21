# ARCHITECTURE_MANIFEST.md

## Global Architecture

SatanZote AI is a multi-node agent ecosystem orchestrated by Hermes (CT 109).

### Core Components
1.  **Hermes Orchestrator:** Hub for task delegation, vault management, and infra auditing.
2.  **GPU Swarm:** Distributed compute across CT 901 (local RTX 5070 Ti) and remote nodes.
3.  **OmniRoute Gateway:** Intelligent model routing and API abstraction.

### Delegation Flow
1.  **Request:** User inputs task (Telegram/Terminal).
2.  **Orchestrator:** Hermes parses task, checks Kanban (`kanban.db`), and delegates to appropriate subagent/skill.
3.  **Execution:** Subagent executes task, validating against `SWARM_PROTOCOL`.
4.  **Audit:** Final artifact verification against Vault specs, followed by Git commit/backup.

### Key Protocols
*   **ACP (Agent-Config Protocol):** Configurations codified in `/root/JarvisVault/00_Infra/`.
*   **Vault-SSOT:** No configuration exists unless it is in the Vault.

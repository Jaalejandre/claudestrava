# DEPENDENCIES.md

## Dependency Mapping

| Project | Dependency | Impact of Failure |
| :--- | :--- | :--- |
| **GromacsMexicano** | Fortran Reference (Programa_DM) | Loss of ground truth for C++ port |
| **SatanZote Dashboard** | OmniRoute Service (:20128) | Loss of LLM routing and agent control |
| **Hermes Agent** | Vault (`/root/JarvisVault`) | Inability to access skills/history/config |
| **Swarm Agents** | Kanban Board (`kanban.db`) | Loss of task tracking/orchestration state |

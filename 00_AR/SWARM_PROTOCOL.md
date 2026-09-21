# SWARM_PROTOCOL.md

## Rules of Engagement (Gold Standards)

1.  **Vault is SSOT:** Absolutely no manual changes to infrastructure without reflecting them in `/root/JarvisVault/00_Infra/` or `CLAUDE.md`.
2.  **No Manual Execution:** All tasks must be run through Hermes agents or codified scripts. Manual `ssh` or CLI commands are for debugging only and must be audited immediately.
3.  **Audit First:** Every change must be validated against known benchmarks or protocols before final integration.
4.  **AI-Generated Files:** Prefix all generated files with `(C)`.
5.  **Git Backup:** All work must be backed up to the `claudestrava` Git repo (nightly cron).
6.  **Physics-Lock (Simulation):** Any modification to molecular dynamics parameters requires validation runs before long-duration simulations.
7.  **Communication:** Urgency to Telegram; routine to Slack; infra alerts to ntfy.

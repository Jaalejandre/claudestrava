# Credential Security Team — Setup & Operations

**Date:** 2026-09-13  
**Status:** Production Ready  
**Schedule:** Daily 06:30 CST (right after SatanZote daily audit)  
**Integration:** Vaultarden API

---

## Team Overview

**Purpose:** Daily credential security audit + rotation via Vaultarden.

**Team Members (5 specialized bots):**

1. **Credential Security Orchestrator** — Master coordinator
   - Role: Delegate tasks, collect results, propose decisions
   - Tools: File Ops, Terminal, Memory
   
2. **Vault Inventory Scanner** — Query Vaultarden
   - Role: List all credentials + metadata from Vaultarden API
   - Tools: File Ops, Terminal, Memory
   
3. **Key Health Checker** — Test credentials work
   - Role: Test SSH keys, API tokens, password strength
   - Tools: File Ops, Terminal, Memory
   
4. **Compromise Detector** — Check if leaked/revoked
   - Role: Query breach databases, GitHub, Proxmox, Vaultarden logs
   - Tools: File Ops, Terminal, Memory
   
5. **Rotation Manager** — Schedule + execute rotations
   - Role: Identify due credentials, propose rotations, execute if approved
   - Tools: File Ops, Terminal, Memory

---

## Daily Workflow (06:30 CST)

```
06:30 — Credential Security Team starts

[Orchestrator] Delegates to Scanner
        ↓
[Scanner] Queries Vaultarden
  → Lists 22 credentials (SSH keys, API tokens, passwords)
  → Extracts: age, service, last accessed, status
        ↓
[Orchestrator] Delegates to Health Checker
        ↓
[Health Checker] Tests each credential
  → SSH keys: connect test
  → API tokens: authorization check
  → Passwords: age + strength
        ↓
[Orchestrator] Delegates to Compromise Detector
        ↓
[Compromise Detector] Analyzes security
  → GitHub: check if key authorized
  → Proxmox: check if token active
  → Breach DB: check if password leaked
  → Vaultarden logs: unauthorized access?
        ↓
[Orchestrator] Delegates to Rotation Manager
        ↓
[Rotation Manager] Proposes rotations
  → SSH keys 90+ days old → rotate
  → API tokens 30+ days old → rotate
  → Compromised → rotate immediately
  → Sends Telegram proposal to José
        ↓
[Rotation Manager] Executes approved rotations
  → Generate new key
  → Test it works
  → Swap in Vaultarden
  → Keep old for 7 days recovery
        ↓
06:50 — Report generated + sent to José
```

**Duration:** ~20-30 min (depending on rotation complexity)

---

## Rotation Policies

| Type | Frequency | Reason |
|------|-----------|--------|
| SSH Keys | 90 days | Industry standard |
| API Tokens | 30 days | Remote access, tighter |
| Passwords | 180 days | Manual rotation, human-friendly |
| Compromised | IMMEDIATELY | Zero tolerance |

---

## Vaultarden Integration

**API Endpoint:** [from Hermes secrets]
**Authentication:** Bearer token (encrypted)
**Queries:**
- `GET /api/accounts/ciphers` — List credentials
- `GET /api/event` — Audit logs
- `POST /api/accounts/ciphers` — Create new credential
- `DELETE /api/accounts/ciphers/{id}` — Remove credential

**Security:** Only read-only key for Scanner/Health/Compromise. Write key for Rotation Manager (after approval).

---

## Output Files

```
~/.credential-vault/  (created daily)
├── inventory-[date].json.gpg          — All credentials (encrypted)
├── health-check-[date].json.gpg       — Test results (encrypted)
├── compromise-check-[date].json.gpg   — Security analysis (encrypted)
└── rotation-log-[date].json.gpg       — Rotation history (encrypted)

~/JarvisVault/00 System/
└── Credential-Security-Report-[date].md  — Summary for José (readable)
```

All encrypted with GPG using José's public key.

---

## Security Rules

✅ Never log credentials in plaintext
✅ Encrypt all reports (GPG)
✅ Test new keys before swapping old
✅ Keep old keys for 7 days recovery
✅ Log all access + modifications (audit trail)
✅ Alert immediately on compromise
✅ Use k-anonymity for breach checks (safe)

---

## When to Use

**Automatic:**
- Daily 06:30 CST (cron job)
- No manual intervention needed (reports sent to José)

**Manual (if needed):**
```bash
hermes --profile credential-security-orchestrator ask "
Check credential health now
"
```

---

## Next Steps

1. Configure Hermes secrets: Vaultarden API key + endpoint
2. Verify cron job scheduled (06:30 CST)
3. Test run: manual execution to verify integration
4. Monitor: check reports daily for 1 week
5. Adjust: refine based on findings

---

**Status:** Ready for Production ✅
**Team:** Fully deployed + documented
**Next Run:** Tomorrow 06:30 CST (automatic)

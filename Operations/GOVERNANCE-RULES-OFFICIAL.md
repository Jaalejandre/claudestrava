# INFRASTRUCTURE GOVERNANCE RULES
**OFFICIAL POLICY DOCUMENT**  
**Approved by:** Governance Team (2026-09-13)  
**Effective:** 2026-09-14 06:00 CST  
**Status:** 🟢 ACTIVE  

---

## **RULE 1: CONTAINER SEGREGATION (HARD RULE)**

### **CT 109 (claude-dev) = DEVELOPMENT ONLY**

**✅ ALLOWED:**
- Prototypes (web, CLI, AI experiments)
- Agent testing + development
- Machine learning experiments
- Integration testing
- Documentation + knowledge base
- Small data sets (< 1 GB)
- Exploratory code (unsanitized)

**❌ PROHIBITED:**
- Production databases
- Live customer/user services
- Real financial calculations
- Sensitive personal data
- Long-running batch jobs (> 1 hour)
- Hardcoded secrets/credentials
- Production-grade services without Security review

**ENFORCEMENT:** governance-enforcer bot (automatic on every deploy request to CT 109)

**CONSEQUENCE IF VIOLATED:**
- Deploy request: ❌ REJECTED
- Reason: "This container is restricted to development only"
- Suggestion: "Move to CT 901 after full testing + checklist completion"

---

### **CT 901 (ubuntu) = PRODUCTION ONLY**

**✅ ALLOWED:**
- GromacsMexicano (molecular dynamics - LIVE)
- EntrenadorLetape (L'Étape training - LIVE)
- Phase 5 GPU optimization work (LIVE)
- Production-grade databases
- Long-running GPU computations
- Sensitive scientific calculations
- Vetted + tested code only

**❌ PROHIBITED:**
- Experimental/untested code
- Unvetted third-party packages
- Development tools (Jupyter, debugging, verbose logging)
- Testing frameworks (except minimal unit tests)
- Debug mode enabled
- Temporary/throwaway code
- Anything not explicitly approved

**ENFORCEMENT:** governance-enforcer bot (automatic on every deploy request to CT 901)

**CONSEQUENCE IF VIOLATED:**
- Deploy request: ❌ REJECTED
- Reason: "This container is restricted to production-grade, tested code only"
- Suggestion: "Test first in CT 109, then submit with full checklist"

---

## **RULE 2: DEPLOYMENT CHECKLIST ENFORCEMENT (HARD RULE)**

All deployments to CT 901 require checklist completion. NO EXCEPTIONS.

### **PROTOTYPE → CT 109 (Fast Track — 4 items)**

Approval timeline: **IMMEDIATE** (if all checked)

```
□ Code compiles/runs without errors
□ README with purpose + usage instructions
□ No hardcoded credentials/secrets/API keys
□ Developer sign-off (self)

Approval: Automatic ✅ if all checked
```

---

### **APP → CT 901 (Full Verification — 9 items)**

Approval timeline: **AFTER ALL ITEMS CHECKED + José sign-off**

```
□ Unit tests: ✅ PASS (100% coverage for critical paths)
□ Integration tests: ✅ PASS (end-to-end validation)
□ Code review: ✅ 2+ approvals from team
□ Security audit: ✅ PASS (no CVEs, no hardcoded secrets)
□ Documentation: ✅ Complete
   - README (what it does + why)
   - Deployment guide (step-by-step)
   - Rollback procedure (if deploy fails)
□ Performance: ✅ Benchmarked (if applicable)
   - Baseline established
   - Regression tested
□ Backup strategy: ✅ Data preservation confirmed
□ Monitoring: ✅ Logging + alerting configured
   - Error logs enabled
   - Performance metrics tracked
   - Alerts for failure modes
□ Rollback tested: ✅ Previous version is accessible + verified working

Final approval: José signature required
```

Approval timeline: **BLOCKED until all items checked + José approves**

---

### **EMERGENCY HOTFIX (Expedited — 6 items)**

Approval timeline: **FAST-TRACK** (if critical + José approves)

```
□ Critical issue documented (why emergency?)
□ Fix tested (minimal but verified)
□ Risk assessment: Documented (what could break?)
□ Rollback ready: Previous version backed up + accessible
□ José emergency approval: Explicit sign-off required
□ Post-deployment review: Full 9-item checklist within 24h

Approval: IF critical + José approves + rollback ready
```

---

## **RULE 3: SECURITY GATE (MANDATORY)**

Every CT 901 deployment must pass Security Team review.

### **Security Checklist:**
```
□ No hardcoded credentials
□ Dependencies: All packages audited for CVEs
□ SSL/TLS: Valid certificates (if network service)
□ Permissions: Correct file/directory permissions
□ Secrets: Stored in environment vars only (never in code)
□ Encryption: Sensitive data encrypted at rest (if applicable)
□ Access control: Who can access? Documented.
```

**ENFORCEMENT:** security-auditor bot runs before approval

**CONSEQUENCE IF FAILED:**
- Deploy request: ❌ BLOCKED
- Reason: "Security issues found"
- Action: "Fix issues + resubmit"

---

## **RULE 4: GIT TAGGING & VERSIONING (MANDATORY)**

Every CT 901 deployment must be tagged in git.

### **Tag Format:**
```
CT901-PROD-[YYYY-MM-DD]-v[N]

Example: CT901-PROD-2026-09-15-v1.2.1
```

### **Tag Contents:**
```
Annotated tag with message:
  "Deploy [app] v[version]
   Date: [date]
   Checklist: [status]
   Approver: José
   Rollback: [git commit hash]"
```

**ENFORCEMENT:** deployment-validator bot verifies tag before approval

**CONSEQUENCE IF MISSING:**
- Deploy request: ❌ BLOCKED
- Reason: "Missing git tag"
- Action: "Create tag: git tag -a CT901-PROD-[date]-v[version] -m '[message]'"

---

## **RULE 5: AUDIT TRAIL (MANDATORY)**

Every deployment decision logged to official audit trail.

### **Audit Log Format:**

```
| Timestamp | Request | Container | Status | Reason | Approver | Git Tag |
|-----------|---------|-----------|--------|--------|----------|---------|
| 2026-09-14 08:15 | Deploy Phase5a v1.2 | CT 901 | APPROVED | Checklist passed | José | CT901-PROD-2026-09-14-v1.2 |
| 2026-09-14 09:30 | Install debug-tools | CT 901 | REJECTED | Not prod-ready | governance | N/A |
| 2026-09-14 10:00 | Deploy prototype-v3 | CT 109 | APPROVED | Fast-track OK | dev | N/A |
```

**STORAGE:** `~/JarvisVault/Operations/Governance-Audit-Log.md`

**RETENTION:** 12 months (auto-archive monthly)

**ENFORCEMENT:** audit-logger bot (automatic on every decision)

---

## **RULE 6: ROLLBACK VERIFICATION (MANDATORY)**

Every deployment must have a tested rollback plan.

### **Rollback Requirements:**
```
□ Previous version accessible in git
□ Rollback procedure documented (step-by-step)
□ Rollback tested (actually reversed, not just planned)
□ Estimated rollback time: < 5 minutes
□ Data migration: Reversible (if any)
```

**ENFORCEMENT:** deployment-validator bot checks before approval

**CONSEQUENCE IF MISSING:**
- Deploy request: ❌ BLOCKED
- Reason: "Rollback not tested"
- Action: "Test rollback to previous version, document + resubmit"

---

## **RULE 7: DEPENDENCY UPDATES (SECURITY)**

All packages used in CT 901 must be current + security-patched.

### **Policy:**
```
✅ ALLOWED: Latest stable versions
✅ ALLOWED: Security patches (always)
❌ PROHIBITED: EOL (end-of-life) versions
❌ PROHIBITED: Known vulnerabilities (CVE)
```

### **Update Timeline:**
```
CRITICAL CVE: Patch within 24 hours
HIGH CVE: Patch within 7 days
MEDIUM CVE: Patch within 30 days
```

**ENFORCEMENT:** dependency-monitor bot (daily scan, 07:35 CST)

**CONSEQUENCE IF VIOLATED:**
- Alert: "Outdated/vulnerable packages detected"
- Action: "Update + retest + redeploy"

---

## **RULE 8: MONITORING & ALERTS (MANDATORY)**

Every CT 901 service must have monitoring configured.

### **Minimum Monitoring:**
```
□ Application logs: Captured + searchable
□ Error rates: Tracked + alerted if > threshold
□ Performance: CPU/memory/disk monitored
□ Availability: Uptime tracked (99%+ target)
□ Security: Failed auth attempts logged
```

**ENFORCEMENT:** audit-logger bot verifies during deployment

**CONSEQUENCE IF MISSING:**
- Deploy request: ❌ BLOCKED
- Reason: "Monitoring not configured"
- Action: "Set up logs, alerts, dashboards + resubmit"

---

## **RULE 9: CONTAINER ISOLATION (ABSOLUTE)**

NO cross-container interference. Code stays in assigned container.

### **Policy:**
```
CT 109 code: ❌ CANNOT write to CT 901
CT 901 code: ❌ CANNOT write to CT 109
CT 109 services: ❌ CANNOT call CT 901 production APIs
CT 901 services: ✅ CAN call CT 109 APIs (for research intake, etc.)
```

**ENFORCEMENT:** IP Monitor bot (hourly verification)

**CONSEQUENCE IF VIOLATED:**
- Alert: "Container boundary crossed"
- Action: "Isolate + investigate + remediate"

---

## **RULE 10: EXCEPTION PROCESS**

If you need to violate any rule, request EXCEPTION.

### **Exception Request Process:**
```
1. Submit: Why exception needed? What's the risk?
2. Governance Team: Reviews + assesses impact
3. José: Makes final decision (APPROVE/REJECT)
4. If approved: Document exception + timeline for remediation
5. If rejected: Use standard process instead
```

### **Exception Form:**
```
Request: [Specific rule to violate]
Reason: [Why necessary?]
Risk: [What could go wrong?]
Mitigation: [How to minimize risk?]
Duration: [How long is exception valid?]
Rollback: [If it fails, how do we recover?]
Approver: José
```

**Exceptions logged in:** `~/JarvisVault/Operations/Governance-Exceptions.md`

---

## **SUMMARY: THE 3 PILLARS**

| Pillar | Rule | Enforcement |
|--------|------|-------------|
| **ISOLATION** | CT 109 = DEV only / CT 901 = PROD only | governance-enforcer (auto) |
| **QUALITY** | Checklists for all deployments | deployment-validator (auto) |
| **SECURITY** | Security gate on every deploy | security-auditor (auto) |

---

## **HOW TO DEPLOY**

### **Deploying to CT 109 (Dev):**
```
1. Code in CT 109
2. Test
3. Submit request: "Deploy prototype-v1 to CT 109"
4. Governance check: ✅ APPROVED (fast-track)
5. Deploy
6. Done
```

### **Deploying to CT 901 (Prod):**
```
1. Code tested in CT 109
2. Request deployment: "Deploy Phase5a v1.2 to CT 901"
3. Governance check: [9-item checklist]
4. Security check: [vulnerability scan]
5. José review: Approve/reject
6. If approved: Create git tag
7. Deploy
8. Verify rollback works
9. Logged in audit trail
10. Done
```

---

## **RULE EFFECTIVE DATE**

**2026-09-14 06:00 CST** (tomorrow morning, when orchestration starts)

All deployments from this point forward must follow these rules.

---

## **ENFORCEMENT BOTS**

These bots automatically enforce these rules:

- **governance-enforcer:** Checks container rules
- **deployment-validator:** Validates checklists
- **security-auditor:** Scans for vulnerabilities
- **audit-logger:** Logs all decisions
- **checklist-monitor:** Tracks checklist status
- **dependency-monitor:** Monitors package updates
- **certificate-monitor:** Checks SSL expiry
- **log-analyzer:** Watches for errors

---

## **SIGN-OFF**

**Governance Team:** ✅ Approved  
**Security Team:** ✅ Approved  
**Infrastructure Team:** ✅ Approved  
**José (Approver):** ⏳ Awaiting sign-off

---

**Policy Version:** 1.0  
**Created:** 2026-09-13  
**Effective:** 2026-09-14 06:00 CST

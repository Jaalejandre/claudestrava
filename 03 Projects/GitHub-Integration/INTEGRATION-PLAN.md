# GitHub MCP Integration Plan for José

## What GitHub MCP Enables

GitHub MCP Server connects Hermes AI agents to GitHub API via natural language:
- **Fetch**: repo code, PR diffs, issue history
- **Create**: issues, PRs, comments (with automatic Wizard gates)
- **Automate**: trigger CI workflows, merge PRs, manage releases
- **Analyze**: code scanning alerts, Dependabot security, commit patterns

## Integration Levels

### Level 1: Read-Only (Safe, No Approval Needed)
```
"List repos in Jaalejandre" → MCP fetches + reports
"Show recent commits in DM UAMI" → MCP fetches logs
"Get Phase 4 PR #47 diff" → MCP retrieves + display
```

### Level 2: Create (Approved by Wizard Phase 1)
```
"Create issue in DM UAMI: Phase 4 GPU convergence test" 
  → Wizard Phase 1: check template + requirements
  → MCP creates issue if approved
  → Auto-assign to reviewers
```

### Level 3: Merge (Gated by Wizard Phase 2)
```
"Merge Phase 4 GPU PR #47 to main"
  → Wizard Phase 1: requirements check (before dev)
  → Dev works, PR created
  → Wizard Phase 2: 3× convergence runs + energy check (after dev)
  → If all Phase 2 checks pass → MCP merges
  → GitHub release auto-generated
```

## Setup Checklist

- [ ] **Go installed:** `go version` (≥1.21)
- [ ] **Token scope:** GitHub Personal Access Token with repo + workflow scopes
- [ ] **Binary compiled:** `cd /root/mcp-github && go build -o bin/github-mcp-server ./cmd/github-mcp-server`
- [ ] **Hermes config updated:** MCP registered in config.yaml
- [ ] **Test command:** "List repos in Jaalejandre" → works?
- [ ] **Integration test:** Create test issue + Wizard Phase 1 gate

## For Phase 4 (DM UAMI)

**Workflow: GPU Kernel PR Review**

```
1. Issue created: "Phase 4 GPU Ewald kernel"
   → Wizard Phase 1: reference data OK? architecture clear?
   → Issue tagged with "needs-validation"

2. Developer implements kernel

3. PR created: "Add CUDA stream for Ewald reciprocal space"
   → GitHub MCP fetches diff + CI status
   → Wizard Phase 2: runs checklist
     - 3× convergence runs attached? ✓
     - Energy diff <0.1%? ✓
     - Speedup >15%? ✓
   → If all pass → MCP auto-merges PR
   → MCP creates GitHub release (v1.2.2)
   → Hermes posts completion message to Telegram
```

## For L'Étape (EntrenadorL'Étape)

**Workflow: Weekly Training Review**

```
1. Cron trigger: Sunday 19:00 CST
   → MCP fetches latest commits (sync status)
   → athlete-coach-lens fetches Garmin/Strava data
   → Generate weekly review markdown

2. Push to GitHub
   → MCP commits: "Training review week 36"
   → MCP creates GitHub Discussions for team feedback

3. Result: Automated weekly sync, transparent progress
```

## For All Code Reviews

**Wizard + GitHub MCP = Discipline Gates**

- **Phase 1 (before code):** Wizard checklist + MCP fetches context
- **Phase 2 (after code):** Wizard checklist + MCP posts review + auto-merge
- **Result:** No PRs merge without passing Wizard gates
- **Benefit:** Quality is enforced upfront, not retroactive

## Testing (After Setup)

```bash
# Test 1: List repos
hermes-agent ask "List public repos in Jaalejandre"

# Test 2: Create issue (Phase 1 gate)
hermes-agent ask "Create test issue in DM UAMI: title 'Test MCP'"
# Wizard Phase 1 checklist appears
# You approve or reject

# Test 3: Fetch PR data
hermes-agent ask "Show Phase 4 GPU PR status"
# MCP fetches diff, CI results, comments
```

## Risks & Mitigations

**Risk:** Token compromised → attacker can merge code
**Mitigation:** 
- Separate token for Hermes (not personal token)
- Gate merges with Phase 2 Wizard approval
- Audit token scopes monthly
- Revoke + regenerate quarterly

**Risk:** Unintended auto-merge
**Mitigation:**
- All destructive operations (merge, delete) require Wizard Phase 2 approval
- Phase 2 checklist is manual (not auto-triggered)
- Humans review before any merge

**Risk:** GitHub API rate limit
**Mitigation:**
- Monitor API usage (`curl -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/rate_limit`)
- Cache PR diffs + issue lists locally
- Batch requests when possible


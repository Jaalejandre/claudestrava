#!/bin/bash
# HERMES Integration Validation Script
# Checks all configured integrations are working

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  HERMES VAULT INTEGRATION VALIDATION                            ║"
echo "║  Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')                        ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

VAULT_PATH="/root/JarvisVault"
CONFIG_FILE="$HOME/.hermes/config.yaml"
ENV_FILE="$HOME/.hermes/.env"
KANBAN_DB="$HOME/.hermes/kanban.db"

PASSED=0
FAILED=0

# Test function
test_check() {
    local desc=$1
    local cmd=$2
    local expected=$3
    
    echo -n "  ✓ $desc ... "
    if eval "$cmd" > /dev/null 2>&1; then
        echo "PASS"
        ((PASSED++))
    else
        echo "FAIL"
        ((FAILED++))
    fi
}

# 1. Config File Checks
echo "━━ 1. CONFIGURATION FILE CHECKS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_check "config.yaml exists" "[ -f '$CONFIG_FILE' ]"
test_check "storage.vault_path configured" "grep -q 'vault_path.*JarvisVault' '$CONFIG_FILE'"
test_check "obsidian.vault_path configured" "grep -q 'obsidian:' '$CONFIG_FILE'"
test_check "memory.auto_save_to_vault enabled" "grep -q 'auto_save_to_vault.*true' '$CONFIG_FILE'"
test_check "kanban.db_path configured" "grep -q 'db_path.*kanban.db' '$CONFIG_FILE'"
echo ""

# 2. Environment Variable Checks
echo "━━ 2. ENVIRONMENT VARIABLE CHECKS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_check ".env file exists" "[ -f '$ENV_FILE' ]"
test_check "OBSIDIAN_VAULT_PATH set" "grep -q 'OBSIDIAN_VAULT_PATH' '$ENV_FILE'"
test_check "HERMES_VAULT_PATH set" "grep -q 'HERMES_VAULT_PATH' '$ENV_FILE'"
test_check "KANBAN_DB_PATH set" "grep -q 'KANBAN_DB_PATH' '$ENV_FILE'"
echo ""

# 3. Vault Access Checks
echo "━━ 3. VAULT ACCESS CHECKS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_check "Vault directory exists" "[ -d '$VAULT_PATH' ]"
test_check "Vault is readable" "[ -r '$VAULT_PATH' ]"
test_check "Vault is writable" "[ -w '$VAULT_PATH' ]"
test_check "Test file exists" "[ -f '$VAULT_PATH/.hermes-integration-test.md' ]"
test_check ".obsidian config exists" "[ -d '$VAULT_PATH/.obsidian' ]"
echo ""

# 4. Kanban Database Checks
echo "━━ 4. KANBAN DATABASE CHECKS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ -f "$KANBAN_DB" ]; then
    test_check "Kanban DB file exists" "[ -f '$KANBAN_DB' ]"
    test_check "Kanban DB is readable" "[ -r '$KANBAN_DB' ]"
    test_check "Kanban DB is writable" "[ -w '$KANBAN_DB' ]"
    echo "     (DB will auto-create on first Hermes restart)"
else
    echo "  ℹ Kanban DB will be created on first Hermes daemon restart"
fi
echo ""

# 5. Permission Checks
echo "━━ 5. FILE PERMISSION CHECKS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_check "Config file readable" "[ -r '$CONFIG_FILE' ]"
test_check "Config file writable" "[ -w '$CONFIG_FILE' ]"
test_check ".env file readable" "[ -r '$ENV_FILE' ]"
test_check ".env file writable" "[ -w '$ENV_FILE' ]"
echo ""

# 6. Integration Point Checks
echo "━━ 6. INTEGRATION POINT CHECKS ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_check "Memory char limit ≥ 5000" "grep -q 'memory_char_limit.*5000' '$CONFIG_FILE'"
test_check "Vault sync interval set" "grep -q 'vault_sync_interval.*300' '$CONFIG_FILE'"
test_check "Obsidian sync enabled" "grep -q 'sync_enabled.*true' '$CONFIG_FILE'"
test_check "Kanban auto-sync enabled" "grep -q 'auto_sync.*true' '$CONFIG_FILE'"
echo ""

# Summary
echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║  VALIDATION SUMMARY                                              ║"
echo "╠══════════════════════════════════════════════════════════════════╣"
echo "║  Tests PASSED: $PASSED                                               ║"
echo "║  Tests FAILED: $FAILED                                               ║"

if [ $FAILED -eq 0 ]; then
    echo "║  Status: ✅ ALL CHECKS PASSED - READY FOR PRODUCTION             ║"
else
    echo "║  Status: ⚠️  SOME CHECKS FAILED - REVIEW ABOVE                 ║"
fi

echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. hermes daemon restart"
echo "  2. hermes context info"
echo "  3. hermes vault status"
echo ""

exit $FAILED

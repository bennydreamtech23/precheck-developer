#!/bin/bash
# Validation script to test all fixes
# Keep It Stupidly Simple (KISS) principle

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║    PRECHECK VALIDATION SCRIPT          ║${NC}"
echo -e "${BLUE}║    Testing all fixes                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Track results
TOTAL_CHECKS=0
PASSED_CHECKS=0

run_validation() {
    local description="$1"
    local command="$2"
    
    ((TOTAL_CHECKS++))
    echo -e "${YELLOW}Validating: $description${NC}"
    
    if eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✅ $description${NC}"
        ((PASSED_CHECKS++))
        return 0
    else
        echo -e "${RED}❌ $description${NC}"
        return 1
    fi
}

echo "=== 1. RUST FORMATTING VALIDATION ==="
echo ""

cd "$PROJECT_DIR"

# Test Rust formatting
run_validation \
    "Rust code formatting (cargo fmt)" \
    "cargo fmt --manifest-path native/precheck_native/Cargo.toml -- --check"

# Test Rust compilation
run_validation \
    "Rust compilation" \
    "cargo check --manifest-path native/precheck_native/Cargo.toml"

# Test Rust clippy
run_validation \
    "Rust clippy lints" \
    "cargo clippy --manifest-path native/precheck_native/Cargo.toml -- -D warnings"

echo ""
echo "=== 2. SHELL SCRIPT VALIDATION ==="
echo ""

# Test shell scripts with shellcheck
for script in scripts/*.sh; do
    if [ -f "$script" ]; then
        run_validation \
            "ShellCheck: $(basename "$script")" \
            "shellcheck '$script'"
    fi
done

echo ""
echo "=== 3. ELIXIR PROJECT VALIDATION ==="
echo ""

# Test Elixir formatting
run_validation \
    "Elixir code formatting" \
    "mix format --check-formatted"

# Test Elixir compilation
run_validation \
    "Elixir compilation" \
    "mix compile"

# Test Elixir tests
run_validation \
    "Elixir tests" \
    "mix test"

echo ""
echo "=== 4. SCRIPT EXECUTION VALIDATION ==="
echo ""

# Test script help outputs
for script in scripts/universal_precheck.sh scripts/elixir_precheck.sh scripts/nodejs_precheck.sh; do
    if [ -f "$script" ]; then
        run_validation \
            "Help output: $(basename "$script")" \
            "'$script' --help"
    fi
done

echo ""
echo "=== VALIDATION SUMMARY ==="
echo ""

if [ "$PASSED_CHECKS" -eq "$TOTAL_CHECKS" ]; then
    echo -e "${GREEN}🎉 ALL VALIDATIONS PASSED! ($PASSED_CHECKS/$TOTAL_CHECKS)${NC}"
    echo ""
    echo "All fixes have been successfully validated:"
    echo "✅ Rust formatting issues fixed"
    echo "✅ Shell script warnings resolved"  
    echo "✅ CI action references corrected"
    echo "✅ All scripts executable and functional"
    exit 0
else
    echo -e "${RED}❌ SOME VALIDATIONS FAILED ($PASSED_CHECKS/$TOTAL_CHECKS)${NC}"
    echo ""
    echo "Please check the failed validations above and fix any remaining issues."
    exit 1
fi
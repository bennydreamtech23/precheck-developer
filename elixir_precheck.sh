#!/usr/bin/env bash
set -uo pipefail 

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

REPORT="elixir_report.txt"
: > "$REPORT"

# Test tracking with severity
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0
CRITICAL_FAILURES=0
HIGH_FAILURES=0
MEDIUM_FAILURES=0
LOW_FAILURES=0

declare -a FAILED_REASONS=()
declare -a CRITICAL_ISSUES=()
declare -a HIGH_ISSUES=()
declare -a MEDIUM_ISSUES=()
declare -a LOW_ISSUES=()

# Severity levels
SEVERITY_CRITICAL="CRITICAL"
SEVERITY_HIGH="HIGH"
SEVERITY_MEDIUM="MEDIUM"
SEVERITY_LOW="LOW"

log() {
  echo -e "$1" | tee -a "$REPORT"
}

section() {
  echo -e "\n${BLUE}=== $1 ===${NC}" | tee -a "$REPORT"
}

get_severity_color() {
  case "$1" in
    "$SEVERITY_CRITICAL") echo "$RED" ;;
    "$SEVERITY_HIGH") echo "$PURPLE" ;;
    "$SEVERITY_MEDIUM") echo "$YELLOW" ;;
    "$SEVERITY_LOW") echo "$CYAN" ;;
    *) echo "$NC" ;;
  esac
}

run_check() {
  local description="$1"
  local command="$2"
  local recommendation="${3:-}"
  local severity="${4:-$SEVERITY_MEDIUM}"
  
  ((TOTAL_TESTS++))
  section "$description"
  echo -e "${YELLOW}Running: $command${NC}" | tee -a "$REPORT"

  if eval "$command" >>"$REPORT" 2>&1; then
    echo -e "${GREEN}✅ $description passed${NC}" | tee -a "$REPORT"
    ((PASSED_TESTS++))
    return 0
  else
    local sev_color=$(get_severity_color "$severity")
    echo -e "${RED}❌ $description failed ${sev_color}[$severity]${NC}" | tee -a "$REPORT"
    ((FAILED_TESTS++))
    FAILED_REASONS+=("$description [$severity]")
    
    case "$severity" in
      "$SEVERITY_CRITICAL")
        ((CRITICAL_FAILURES++))
        CRITICAL_ISSUES+=("$description")
        ;;
      "$SEVERITY_HIGH")
        ((HIGH_FAILURES++))
        HIGH_ISSUES+=("$description")
        ;;
      "$SEVERITY_MEDIUM")
        ((MEDIUM_FAILURES++))
        MEDIUM_ISSUES+=("$description")
        ;;
      "$SEVERITY_LOW")
        ((LOW_FAILURES++))
        LOW_ISSUES+=("$description")
        ;;
    esac
    
    if [ -n "$recommendation" ]; then
      log "👉 $recommendation"
    fi
    return 1
  fi
}

run_optional_check() {
  local description="$1"
  local command="$2"
  local install_msg="$3"
  local severity="${4:-$SEVERITY_LOW}"
  
  ((TOTAL_TESTS++))
  section "$description"
  
  if eval "$command" >>"$REPORT" 2>&1; then
    echo -e "${GREEN}✅ $description passed${NC}" | tee -a "$REPORT"
    ((PASSED_TESTS++))
    return 0
  else
    local sev_color=$(get_severity_color "$severity")
    echo -e "${RED}❌ $description failed ${sev_color}[$severity]${NC}" | tee -a "$REPORT"
    ((FAILED_TESTS++))
    FAILED_REASONS+=("$description [$severity]")
    
    case "$severity" in
      "$SEVERITY_CRITICAL") ((CRITICAL_FAILURES++)); CRITICAL_ISSUES+=("$description") ;;
      "$SEVERITY_HIGH") ((HIGH_FAILURES++)); HIGH_ISSUES+=("$description") ;;
      "$SEVERITY_MEDIUM") ((MEDIUM_FAILURES++)); MEDIUM_ISSUES+=("$description") ;;
      "$SEVERITY_LOW") ((LOW_FAILURES++)); LOW_ISSUES+=("$description") ;;
    esac
    
    log "👉 $install_msg"
    return 1
  fi
}

print_summary() {
  echo -e "\n${CYAN}╔════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║         TEST SUMMARY                   ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
  
  local pass_rate=$((PASSED_TESTS * 100 / TOTAL_TESTS))
  
  echo -e "${BLUE}Total Tests:${NC} $TOTAL_TESTS" | tee -a "$REPORT"
  echo -e "${GREEN}Passed:${NC} $PASSED_TESTS" | tee -a "$REPORT"
  echo -e "${RED}Failed:${NC} $FAILED_TESTS" | tee -a "$REPORT"
  echo -e "${BLUE}Pass Rate:${NC} ${pass_rate}%" | tee -a "$REPORT"
  
  echo ""
  if [ $CRITICAL_FAILURES -gt 0 ]; then
    echo -e "${RED}🚨 CRITICAL Failures:${NC} $CRITICAL_FAILURES ${RED}(MUST FIX BEFORE PR)${NC}" | tee -a "$REPORT"
  fi
  if [ $HIGH_FAILURES -gt 0 ]; then
    echo -e "${PURPLE}⚠️  HIGH Priority:${NC} $HIGH_FAILURES ${PURPLE}(Should fix before PR)${NC}" | tee -a "$REPORT"
  fi
  if [ $MEDIUM_FAILURES -gt 0 ]; then
    echo -e "${YELLOW}⚠️  MEDIUM Priority:${NC} $MEDIUM_FAILURES ${YELLOW}(Recommended to fix)${NC}" | tee -a "$REPORT"
  fi
  if [ $LOW_FAILURES -gt 0 ]; then
    echo -e "${CYAN}ℹ️  LOW Priority:${NC} $LOW_FAILURES ${CYAN}(Optional improvements)${NC}" | tee -a "$REPORT"
  fi
  
  if [ $FAILED_TESTS -gt 0 ]; then
    echo ""
    if [ ${#CRITICAL_ISSUES[@]} -gt 0 ]; then
      echo -e "${RED}🚨 CRITICAL Issues (Block PR):${NC}" | tee -a "$REPORT"
      for issue in "${CRITICAL_ISSUES[@]}"; do
        echo -e "  ${RED}•${NC} $issue" | tee -a "$REPORT"
      done
      echo ""
    fi
    
    if [ ${#HIGH_ISSUES[@]} -gt 0 ]; then
      echo -e "${PURPLE}⚠️  HIGH Priority Issues:${NC}" | tee -a "$REPORT"
      for issue in "${HIGH_ISSUES[@]}"; do
        echo -e "  ${PURPLE}•${NC} $issue" | tee -a "$REPORT"
      done
      echo ""
    fi
    
    if [ ${#MEDIUM_ISSUES[@]} -gt 0 ]; then
      echo -e "${YELLOW}⚠️  MEDIUM Priority Issues:${NC}" | tee -a "$REPORT"
      for issue in "${MEDIUM_ISSUES[@]}"; do
        echo -e "  ${YELLOW}•${NC} $issue" | tee -a "$REPORT"
      done
      echo ""
    fi
    
    if [ ${#LOW_ISSUES[@]} -gt 0 ]; then
      echo -e "${CYAN}ℹ️  LOW Priority Issues:${NC}" | tee -a "$REPORT"
      for issue in "${LOW_ISSUES[@]}"; do
        echo -e "  ${CYAN}•${NC} $issue" | tee -a "$REPORT"
      done
      echo ""
    fi
  fi
  
  echo -e "${BLUE}Result: ${PASSED_TESTS}/${TOTAL_TESTS} tests passed${NC}" | tee -a "$REPORT"
  
  # PR Readiness Assessment
  echo ""
  if [ $CRITICAL_FAILURES -gt 0 ]; then
    echo -e "${RED}❌ NOT READY FOR PR - Critical issues must be fixed${NC}" | tee -a "$REPORT"
  elif [ $HIGH_FAILURES -gt 0 ]; then
    echo -e "${YELLOW}⚠️  PROCEED WITH CAUTION - High priority issues should be addressed${NC}" | tee -a "$REPORT"
  elif [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}✅ READY FOR PR - All checks passed!${NC}" | tee -a "$REPORT"
  else
    echo -e "${GREEN}✅ READY FOR PR - Only minor issues remaining${NC}" | tee -a "$REPORT"
  fi
}

auto_setup() {
  echo -e "\n${CYAN}╔════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║    AUTOMATIC PROJECT SETUP             ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════╝${NC}\n"
  
  section "Installing dependencies"
  if mix deps.get; then
    echo -e "${GREEN}✅ Dependencies installed${NC}"
  else
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    return 1
  fi
  
  section "Compiling project"
  if mix compile; then
    echo -e "${GREEN}✅ Project compiled${NC}"
  else
    echo -e "${RED}❌ Compilation failed${NC}"
    return 1
  fi
  
  # Check for Ecto and run migrations
  if grep -q "phoenix_ecto\|ecto_sql" mix.exs 2>/dev/null; then
    section "Database setup"
    if mix ecto.create 2>/dev/null || echo "Database may already exist"; then
      if mix ecto.migrate; then
        echo -e "${GREEN}✅ Database migrations complete${NC}"
      else
        echo -e "${YELLOW}⚠️  Database migrations failed (may be up to date)${NC}"
      fi
    fi
  fi
  
  # Check for Tailwind
  if grep -q "tailwind" mix.exs 2>/dev/null; then
    section "Installing Tailwind CSS"
    if mix tailwind.install; then
      echo -e "${GREEN}✅ Tailwind installed${NC}"
    else
      echo -e "${YELLOW}⚠️  Tailwind installation failed${NC}"
    fi
  fi
  
  # Check for esbuild
  if grep -q "esbuild" mix.exs 2>/dev/null; then
    section "Installing esbuild"
    if mix esbuild.install; then
      echo -e "${GREEN}✅ esbuild installed${NC}"
    else
      echo -e "${YELLOW}⚠️  esbuild installation failed${NC}"
    fi
  fi
  
  # Compile assets if Phoenix project
  if grep -q "phoenix" mix.exs 2>/dev/null; then
    section "Compiling assets"
    if mix assets.deploy 2>/dev/null || mix phx.digest 2>/dev/null; then
      echo -e "${GREEN}✅ Assets compiled${NC}"
    else
      echo -e "${YELLOW}⚠️  Asset compilation skipped${NC}"
    fi
  fi
  
  echo -e "\n${GREEN}✅ Auto-setup complete!${NC}\n"
}

# ============================================
# MAIN SCRIPT
# ============================================

echo -e "${BLUE}🔍 Elixir Pre-deployment Check${NC}" | tee -a "$REPORT"
echo "Project: $(basename "$(pwd)")" | tee -a "$REPORT"
echo "Date: $(date)" | tee -a "$REPORT"

# Parse arguments
RUN_SETUP=false
if [[ "${1:-}" == "--setup" ]] || [[ "${1:-}" == "-s" ]]; then
  RUN_SETUP=true
  auto_setup
  echo ""
fi

# === PRE-CHECKS ===
echo -e "\n${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         RUNNING CHECKS                 ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"

# 1. Naming Convention Check (MEDIUM)
run_check "Naming conventions" \
  "mix credo --checks-without-tag naming --format json 2>/dev/null | jq -e '.issues | length == 0' 2>/dev/null || mix credo --checks-without-tag naming 2>&1 | grep -q 'No issues'" \
  "Run: mix credo --checks-without-tag naming for details" \
  "$SEVERITY_MEDIUM"

# 2. Dependency Analysis (HIGH - security implications)
# Check if mix_audit is available, otherwise use hex.audit
if mix help deps.audit >/dev/null 2>&1; then
  run_check "Dependency security audit" \
    "mix deps.get && mix deps.audit" \
    "Run: mix deps.get && fix reported vulnerabilities" \
    "$SEVERITY_HIGH"
    
elif mix help hex.audit >/dev/null 2>&1; then
  run_check "Dependency security audit (Hex)" \
    "mix deps.get && mix hex.audit" \
    "Run: mix hex.audit and update vulnerable dependencies" \
    "$SEVERITY_HIGH"
else
  run_check "Dependency installation" \
    "mix deps.get" \
    "Run: mix deps.get && consider installing mix_audit for security checks" \
    "$SEVERITY_MEDIUM"
fi

run_check "Check for outdated dependencies" \
  "mix deps.outdated --all" \
  "Run: mix deps.update --all to update dependencies" \
  "$SEVERITY_LOW"

# 3. Unused Dependencies (LOW)
run_check "Unused dependencies check" \
  "mix deps.unlock --check-unused" \
  "Run: mix deps.clean --unused" \
  "$SEVERITY_LOW"

# 4. Code Formatting (HIGH - code quality standard)
run_check "Code formatting" \
  "mix format --check-formatted" \
  "Run: mix format" \
  "$SEVERITY_HIGH"

# 5. Static Analysis (HIGH - code quality)
run_check "Static analysis (Credo)" \
  "mix credo --strict" \
  "Run: mix credo --strict and fix issues" \
  "$SEVERITY_HIGH"

# 6. Compilation Warnings (CRITICAL - may cause runtime errors)
run_check "Compilation warnings check" \
  "mix compile --warnings-as-errors --force" \
  "Fix all compilation warnings before deployment" \
  "$SEVERITY_CRITICAL"

# 7. Test Suite (CRITICAL - core functionality)
run_check "Test suite" \
  "mix test --cover" \
  "Fix failing tests before deployment" \
  "$SEVERITY_CRITICAL"

# 8. Test Coverage (MEDIUM)
if grep -q "excoveralls" mix.exs 2>/dev/null; then
  run_check "Test coverage (>80%)" \
    "mix coveralls.json && jq -e '.coverage > 80' cover/excoveralls.json" \
    "Improve test coverage to at least 80%" \
    "$SEVERITY_MEDIUM"
fi

# 9. Dialyzer (MEDIUM - type safety)
if grep -q "dialyxir" mix.exs 2>/dev/null; then
  run_optional_check "Type checking (Dialyzer)" \
    "mix dialyzer --format short" \
    "Fix Dialyzer warnings or run: mix dialyzer --format short" \
    "$SEVERITY_MEDIUM"
fi

# 10. Production Compilation (CRITICAL - deployment blocker)
run_check "Production compilation" \
  "MIX_ENV=prod mix compile --force" \
  "Run: MIX_ENV=prod mix compile and fix errors" \
  "$SEVERITY_CRITICAL"

# 11. Security Analysis (HIGH - security vulnerabilities)
if mix help sobelow >/dev/null 2>&1; then
  run_optional_check "Security analysis (Sobelow)" \
    "mix sobelow --exit" \
    "Review Sobelow findings and address security issues" \
    "$SEVERITY_HIGH"
else
  run_optional_check "Security analysis (Sobelow)" \
    "false" \
    "Install Sobelow: mix archive.install hex sobelow" \
    "$SEVERITY_MEDIUM"
fi

# 12. Documentation Generation (LOW)
run_check "Documentation generation" \
  "mix docs" \
  "Fix documentation errors: mix docs" \
  "$SEVERITY_LOW"

# 13. Module Documentation Coverage (LOW)
run_check "Module documentation check" \
  "! grep -r '@moduledoc false' lib/ 2>/dev/null | grep -v test | grep -v _build | grep -q ." \
  "Add @moduledoc to all public modules" \
  "$SEVERITY_LOW"

# 14. Deprecated Function Usage (MEDIUM)
run_check "Deprecated functions check" \
  "! mix xref deprecated 2>&1 | grep -q 'Deprecated'" \
  "Replace deprecated function calls" \
  "$SEVERITY_MEDIUM"

# Print summary
print_summary

echo -e "\n${BLUE}📋 Report saved to $REPORT${NC}"

# Exit with appropriate code
if [ $CRITICAL_FAILURES -gt 0 ]; then
  echo -e "${RED}❌ CRITICAL failures detected. Must fix before PR.${NC}"
  exit 2
elif [ $HIGH_FAILURES -gt 0 ]; then
  echo -e "${YELLOW}⚠️  HIGH priority issues detected. Strongly recommended to fix.${NC}"
  exit 1
elif [ $FAILED_TESTS -gt 0 ]; then
  echo -e "${GREEN}✅ Minor issues only. Safe to proceed with PR.${NC}"
  exit 0
else
  echo -e "${GREEN}✅ All checks passed! Ready for deployment.${NC}"
  exit 0
fi
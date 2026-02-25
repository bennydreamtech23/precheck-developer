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
    local sev_color
    sev_color=$(get_severity_color "$severity")
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
    local sev_color
    sev_color=$(get_severity_color "$severity")
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

record_check_failure() {
  local description="$1"
  local recommendation="$2"
  local severity="${3:-$SEVERITY_MEDIUM}"
  local sev_color

  sev_color=$(get_severity_color "$severity")
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
}

run_outdated_dependencies_check() {
  local description="Outdated dependencies"
  local recommendation="Run: mix deps.update --all (review changes carefully)"
  local severity="$SEVERITY_LOW"
  local output
  local status=0

  ((TOTAL_TESTS++))
  section "$description"
  echo -e "${YELLOW}Running: mix hex.outdated --all${NC}" | tee -a "$REPORT"

  output=$(mix hex.outdated --all 2>&1) || status=$?
  echo "$output" >>"$REPORT"

  if echo "$output" | grep -q "All dependencies up to date"; then
    echo -e "${GREEN}✅ $description passed${NC}" | tee -a "$REPORT"
    ((PASSED_TESTS++))
    return 0
  fi

  if echo "$output" | grep -qE "Update available|major|minor"; then
    record_check_failure "$description" "$recommendation" "$severity"
    return 1
  fi

  # If we cannot determine outdated status reliably, use task exit status.
  if [ "$status" -eq 0 ]; then
    echo -e "${GREEN}✅ $description passed${NC}" | tee -a "$REPORT"
    ((PASSED_TESTS++))
    return 0
  fi

  record_check_failure "$description" "$recommendation" "$severity"
  return 1
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

# Check for required tools BEFORE any setup
check_required_tools() {
  local missing_tools=()
  
  if ! command -v elixir >/dev/null 2>&1; then
    missing_tools+=("elixir")
  fi
  
  if ! command -v mix >/dev/null 2>&1; then
    missing_tools+=("mix")
  fi
  
  if [ ${#missing_tools[@]} -gt 0 ]; then
    echo -e "\n${RED}❌ Missing required tools: ${missing_tools[*]}${NC}"
    echo ""
    echo "Install Elixir:"
    echo "  macOS:  brew install elixir"
    echo "  Ubuntu: sudo apt-get install elixir"
    echo "  Docs:   https://elixir-lang.org/install.html"
    echo ""
    exit 1
  fi
}

# Check and validate environment
check_environment() {
  echo -e "\n${CYAN}Checking environment configuration...${NC}"
  
  # Check for .env file
  if [ -f ".env.example" ] && [ ! -f ".env" ]; then
    echo -e "${RED}⚠️  Environment file missing!${NC}"
    echo -e "   Found .env.example but no .env file"
    echo -e "   ${YELLOW}Action required:${NC} cp .env.example .env"
    echo ""
    read -p "Create .env from .env.example now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      cp .env.example .env
      echo -e "${GREEN}✅ Created .env file${NC}"
      echo -e "${YELLOW}⚠️  Please configure required values in .env before starting${NC}"
      echo ""
    else
      echo -e "${YELLOW}⚠️  Project may fail to start without .env configuration${NC}"
      echo ""
    fi
  fi
  
  # Check for required environment variables in config
  if grep -r "System.get_env" config/ 2>/dev/null | grep -q "!"; then
    echo -e "${YELLOW}⚠️  Found required environment variables in config/${NC}"
    echo -e "   Make sure all required env vars are set"
    
    # List required env vars
    local required_vars
    required_vars=$(grep -r "System.get_env" config/ 2>/dev/null | grep "!" | sed 's/.*System.get_env("\([^"]*\)").*/\1/' | sort -u)
    if [ -n "$required_vars" ]; then
      echo -e "   ${CYAN}Required variables:${NC}"
      echo "$required_vars" | while read -r var; do
        if [ -f ".env" ] && grep -q "^${var}=" .env; then
          echo -e "     ✅ $var (configured)"
        else
          echo -e "     ❌ $var (MISSING)"
        fi
      done
      echo ""
    fi
  fi
}

# Run secrets and hardcoded credentials scan
run_security_scan() {
  echo -e "\n${CYAN}╔════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║     SECURITY SCAN                      ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════╝${NC}\n"
  
  local secrets_found=0
  
  # Check for hardcoded credentials in source files
  echo -e "${BLUE}Scanning for hardcoded credentials...${NC}"
  
  if grep -rn --include="*.ex" --include="*.exs" -E '(password|secret|api_key|token)\s*=\s*"[^"]+"' lib/ config/ 2>/dev/null | grep -v "test"; then
    echo -e "${RED}⚠️  Found hardcoded credentials in source files${NC}"
    secrets_found=$((secrets_found + 1))
  else
    echo -e "${GREEN}✅ No hardcoded credentials found${NC}"
  fi
  
  # Check for API keys and tokens
  echo -e "\n${BLUE}Scanning for API keys and tokens...${NC}"
  
  if grep -rn --include="*.ex" --include="*.exs" -E '(AKIA|ghp_|sk-|xox[baprs]-)[A-Za-z0-9_-]+' lib/ config/ 2>/dev/null; then
    echo -e "${RED}⚠️  Found potential API keys/tokens in source files${NC}"
    secrets_found=$((secrets_found + 1))
  else
    echo -e "${GREEN}✅ No API keys/tokens found${NC}"
  fi
  
  # Check for database URLs with credentials
  echo -e "\n${BLUE}Scanning for database URLs with credentials...${NC}"
  
  if grep -rn --include="*.ex" --include="*.exs" -E '(postgres|mysql|mongodb)://[^:]+:[^@]+@' lib/ config/ 2>/dev/null; then
    echo -e "${RED}⚠️  Found database URLs with credentials${NC}"
    secrets_found=$((secrets_found + 1))
  else
    echo -e "${GREEN}✅ No database URLs with credentials${NC}"
  fi
  
  # Check .gitignore for sensitive files
  echo -e "\n${BLUE}Checking .gitignore configuration...${NC}"
  
  if [ ! -f ".gitignore" ]; then
    echo -e "${RED}⚠️  No .gitignore file found${NC}"
    secrets_found=$((secrets_found + 1))
  else
    local sensitive_patterns=(".env" "*.pem" "*.key" "config/prod.secret.exs")
    local missing_patterns=()
    
    for pattern in "${sensitive_patterns[@]}"; do
      if ! grep -q "^${pattern}$" .gitignore 2>/dev/null; then
        missing_patterns+=("$pattern")
      fi
    done
    
    if [ ${#missing_patterns[@]} -gt 0 ]; then
      echo -e "${YELLOW}⚠️  .gitignore missing sensitive patterns:${NC}"
      for pattern in "${missing_patterns[@]}"; do
        echo -e "     $pattern"
      done
      secrets_found=$((secrets_found + 1))
    else
      echo -e "${GREEN}✅ .gitignore properly configured${NC}"
    fi
  fi
  
  # Summary
  echo ""
  if [ $secrets_found -gt 0 ]; then
    echo -e "${RED}⚠️  Security scan found $secrets_found issue(s)${NC}"
    echo -e "${YELLOW}Recommendations:${NC}"
    echo "  1. Remove hardcoded secrets from source code"
    echo "  2. Use System.get_env() for sensitive values"
    echo "  3. Add sensitive files to .gitignore"
    echo "  4. Use config/runtime.exs for production secrets"
    echo ""
  else
    echo -e "${GREEN}✅ Security scan passed - no issues found${NC}"
    echo ""
  fi
}

# Auto-setup with project start
auto_setup() {
  echo -e "\n${CYAN}╔════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║    AUTOMATIC PROJECT SETUP             ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════╝${NC}\n"
  
  # Check environment first
  check_environment
  
  # Install dependencies
  section "Installing dependencies"
  if mix deps.get; then
    echo -e "${GREEN}✅ Dependencies installed${NC}"
  else
    echo -e "${RED}❌ Failed to install dependencies${NC}"
    return 1
  fi
  
  # Compile project
  section "Compiling project"
  if mix compile; then
    echo -e "${GREEN}✅ Project compiled${NC}"
  else
    echo -e "${RED}❌ Compilation failed${NC}"
    return 1
  fi
  
  # Database setup for Phoenix/Ecto projects
  if grep -q "phoenix_ecto\|ecto_sql" mix.exs 2>/dev/null; then
    section "Database setup"
    
    # Check if database exists
    if mix ecto.create 2>/dev/null; then
      echo -e "${GREEN}✅ Database created${NC}"
    else
      echo -e "${YELLOW}⚠️  Database may already exist${NC}"
    fi
    
    # Run migrations
    if mix ecto.migrate; then
      echo -e "${GREEN}✅ Migrations complete${NC}"
    else
      echo -e "${YELLOW}⚠️  Migrations failed or up to date${NC}"
    fi
  fi
  
  # Setup assets for Phoenix projects
  if grep -q "phoenix" mix.exs 2>/dev/null; then
    if [ -d "assets" ]; then
      section "Installing frontend assets"
      cd assets || return 1
      if command -v npm >/dev/null 2>&1; then
        npm install
        echo -e "${GREEN}✅ Frontend assets installed${NC}"
      fi
      cd ..
    fi
  fi
  
  echo -e "\n${GREEN}✅ Setup complete!${NC}\n"
  
  # Ask to start the server
  if grep -q "phoenix" mix.exs 2>/dev/null; then
    echo -e "${CYAN}Phoenix project detected${NC}"
    read -p "Start Phoenix server now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${GREEN}Starting Phoenix server...${NC}"
      echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
      echo ""
      mix phx.server
    fi
  fi
}

# ============================================
# MAIN SCRIPT
# ============================================

echo -e "${BLUE}🔍 Elixir Pre-deployment Check${NC}" | tee -a "$REPORT"
echo "Project: $(basename "$(pwd)")" | tee -a "$REPORT"
echo "Date: $(date)" | tee -a "$REPORT"

# Check for required tools FIRST
check_required_tools


# Parse arguments
RUN_SETUP=false
if [[ "${1:-}" == "--setup" ]] || [[ "${1:-}" == "-s" ]]; then
  RUN_SETUP=true
  echo -e "${YELLOW}⚙️  Setup mode enabled - running full checks before automatic setup...${NC}"
  echo ""
fi

# Quick dependency check if not running setup
if [ "$RUN_SETUP" = false ]; then
  if [ ! -d "deps" ] || [ ! -f "mix.lock" ]; then
    echo -e "\n${YELLOW}⚠️  Dependencies not installed${NC}"
    echo -e "Run: ${CYAN}precheck --setup${NC} or ${CYAN}mix deps.get${NC}"
    echo ""
  fi
  
  # Quick environment check
  check_environment
fi

# Run security scan FIRST
run_security_scan

# === PRE-CHECKS ===
echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║         RUNNING CHECKS                 ║${NC}"
echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"

# 1. Naming Convention Check (MEDIUM)
run_check "Naming conventions" \
  "mix credo --checks-without-tag naming" \
  "Run: mix credo --checks-without-tag naming for details" \
  "$SEVERITY_MEDIUM"

# 2. Dependency Security (HIGH)
if mix help deps.audit >/dev/null 2>&1; then
  run_check "Dependency security audit" \
    "mix deps.audit" \
    "Fix reported vulnerabilities" \
    "$SEVERITY_HIGH"
elif mix help hex.audit >/dev/null 2>&1; then
  run_check "Dependency security audit (Hex)" \
    "mix hex.audit" \
    "Update vulnerable dependencies" \
    "$SEVERITY_HIGH"
else
  run_optional_check "Dependency security audit" \
    "false" \
    "Install: mix archive.install hex mix_audit" \
    "$SEVERITY_MEDIUM"
fi

# 3. Outdated Dependencies (LOW)
run_outdated_dependencies_check

# 4. Unused Dependencies (LOW)
run_check "Unused dependencies" \
  "mix deps.unlock --check-unused" \
  "Run: mix deps.clean --unused" \
  "$SEVERITY_LOW"

# 5. Code Formatting (HIGH)
run_check "Code formatting" \
  "mix format --check-formatted" \
  "Run: mix format" \
  "$SEVERITY_HIGH"

# 6. Static Analysis (HIGH)
run_check "Static analysis (Credo)" \
  "mix credo --strict" \
  "Run: mix credo --strict and fix issues" \
  "$SEVERITY_HIGH"

# 7. Compilation Warnings (CRITICAL)
run_check "Compilation warnings" \
  "mix compile --warnings-as-errors" \
  "Fix all compilation warnings before deployment" \
  "$SEVERITY_CRITICAL"

# 8. Test Suite (CRITICAL)
run_check "Test suite" \
  "mix test" \
  "Fix failing tests before deployment" \
  "$SEVERITY_CRITICAL"

# 9. Test Coverage (MEDIUM)
if grep -q "excoveralls" mix.exs 2>/dev/null; then
  run_check "Test coverage (>80%)" \
    "mix coveralls.json && jq -e '.coverage > 80' cover/excoveralls.json" \
    "Improve test coverage to at least 80%" \
    "$SEVERITY_MEDIUM"
fi

# 10. Dialyzer (MEDIUM)
if grep -q "dialyxir" mix.exs 2>/dev/null; then
  run_optional_check "Type checking (Dialyzer)" \
    "mix dialyzer --format short" \
    "Fix Dialyzer warnings" \
    "$SEVERITY_MEDIUM"
fi

# 11. Production Compilation (CRITICAL)
run_check "Production compilation" \
  "MIX_ENV=prod mix compile" \
  "Fix production compilation errors" \
  "$SEVERITY_CRITICAL"

# 12. Security Analysis (HIGH)
if mix help sobelow >/dev/null 2>&1; then
  run_optional_check "Security analysis (Sobelow)" \
    "mix sobelow --exit" \
    "Review and address security issues" \
    "$SEVERITY_HIGH"
else
  run_optional_check "Security analysis (Sobelow)" \
    "false" \
    "Install: mix archive.install hex sobelow" \
    "$SEVERITY_MEDIUM"
fi

# 13. Documentation Generation (LOW)
if mix help docs >/dev/null 2>&1; then
  run_check "Documentation generation" \
    "mix docs" \
    "Fix documentation errors" \
    "$SEVERITY_LOW"
else
  run_optional_check "Documentation generation" \
    "false" \
    "Install: mix local.hex && mix archive.install hex ex_doc" \
    "$SEVERITY_LOW"
fi

# 14. Module Documentation (LOW)
run_check "Module documentation" \
  "! grep -r '@moduledoc false' lib/ 2>/dev/null | grep -v test | grep -v _build | grep -q ." \
  "Add @moduledoc to all public modules" \
  "$SEVERITY_LOW"

# 15. Deprecated Functions (MEDIUM)
run_check "Deprecated functions" \
  "! mix xref deprecated 2>&1 | grep -q 'Deprecated'" \
  "Replace deprecated function calls" \
  "$SEVERITY_MEDIUM"

# Print summary
# After all checks
print_summary

echo -e "\n${BLUE}📋 Report saved to $REPORT${NC}"

# Run automatic setup AFTER all checks if requested
if [ "$RUN_SETUP" = true ]; then
  echo ""
  echo -e "${BLUE}🚀 Starting automatic setup (ignoring critical failures)...${NC}"
  auto_setup
fi


# === Exit Handling ===
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

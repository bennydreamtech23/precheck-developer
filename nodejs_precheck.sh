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

REPORT="nodejs_report.txt"
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

# Check for required tools BEFORE any setup
check_required_tools() {
  local missing_tools=()
  
  if ! command -v node >/dev/null 2>&1; then
    missing_tools+=("node")
  fi
  
  if ! command -v npm >/dev/null 2>&1; then
    missing_tools+=("npm")
  fi
  
  if [ ${#missing_tools[@]} -gt 0 ]; then
    echo -e "\n${RED}❌ Missing required tools: ${missing_tools[*]}${NC}"
    echo ""
    echo "Install Node.js:"
    echo "  macOS:  brew install node"
    echo "  Ubuntu: sudo apt-get install nodejs npm"
    echo "  Docs:   https://nodejs.org/"
    echo ""
    exit 1
  fi
}

# Detect package manager
detect_package_manager() {
  if [ -f "bun.lockb" ]; then
    echo "bun"
  elif [ -f "pnpm-lock.yaml" ]; then
    echo "pnpm"
  elif [ -f "yarn.lock" ]; then
    echo "yarn"
  else
    echo "npm"
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
  
  # Check for required environment variables
  if [ -f "package.json" ] && command -v jq >/dev/null 2>&1; then
    if jq -e '.scripts.start' package.json >/dev/null 2>&1 || jq -e '.scripts.dev' package.json >/dev/null 2>&1; then
      if [ -f ".env.example" ] && [ -f ".env" ]; then
        # Compare .env.example and .env for missing vars
        local missing_vars=()
        while IFS= read -r line; do
          if [[ "$line" =~ ^[A-Z_]+= ]]; then
            local var_name="${line%%=*}"
            if ! grep -q "^${var_name}=" .env 2>/dev/null; then
              missing_vars+=("$var_name")
            fi
          fi
        done < .env.example
        
        if [ ${#missing_vars[@]} -gt 0 ]; then
          echo -e "${YELLOW}⚠️  Missing environment variables in .env:${NC}"
          for var in "${missing_vars[@]}"; do
            echo -e "     ❌ $var"
          done
          echo ""
        fi
      fi
    fi
  fi
}

# Run security scan for secrets and hardcoded credentials
run_security_scan() {
  echo -e "\n${CYAN}╔════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║     SECURITY SCAN                      ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════╝${NC}\n"
  
  local secrets_found=0
  
  # Check for hardcoded credentials
  echo -e "${BLUE}Scanning for hardcoded credentials...${NC}"
  
  if grep -rn --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" -E '(password|secret|apiKey|api_key|token)\s*[:=]\s*["\x27][^"\x27]+["\x27]' src/ 2>/dev/null | grep -v "test\|spec\|mock"; then
    echo -e "${RED}⚠️  Found hardcoded credentials in source files${NC}"
    secrets_found=$((secrets_found + 1))
  else
    echo -e "${GREEN}✅ No hardcoded credentials found${NC}"
  fi
  
  # Check for API keys and tokens
  echo -e "\n${BLUE}Scanning for API keys and tokens...${NC}"
  
  if grep -rn --include="*.js" --include="*.ts" --include="*.jsx" --include="*.tsx" -E '(AKIA|ghp_|sk-|xox[baprs]-|AIza)[A-Za-z0-9_-]+' src/ 2>/dev/null; then
    echo -e "${RED}⚠️  Found potential API keys/tokens in source files${NC}"
    secrets_found=$((secrets_found + 1))
  else
    echo -e "${GREEN}✅ No API keys/tokens found${NC}"
  fi
  
  # Check for database connection strings
  echo -e "\n${BLUE}Scanning for database connection strings...${NC}"
  
  if grep -rn --include="*.js" --include="*.ts" -E '(mongodb|postgres|mysql)://[^:]+:[^@]+@' src/ 2>/dev/null; then
    echo -e "${RED}⚠️  Found database connection strings with credentials${NC}"
    secrets_found=$((secrets_found + 1))
  else
    echo -e "${GREEN}✅ No database connection strings with credentials${NC}"
  fi
  
  # Check .gitignore
  echo -e "\n${BLUE}Checking .gitignore configuration...${NC}"
  
  if [ ! -f ".gitignore" ]; then
    echo -e "${RED}⚠️  No .gitignore file found${NC}"
    secrets_found=$((secrets_found + 1))
  else
    local sensitive_patterns=(".env" ".env.local" "*.pem" "*.key" "config/secrets.yml")
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
  
  # Check for committed .env files
  echo -e "\n${BLUE}Checking for committed sensitive files...${NC}"
  
 if git ls-files 2>/dev/null | grep -E '\.env$|\.env\.local|\.pem$|\.key$' >/dev/null 2>&1; then

    echo -e "${RED}⚠️  Found sensitive files in git repository${NC}"
   git ls-files 2>/dev/null | grep -E '\.env$|\.env\.local|\.pem$|\.key$' | while read -r file; do
      echo -e "     ${RED}✗${NC} $file"
    done
    secrets_found=$((secrets_found + 1))
  else
    echo -e "${GREEN}✅ No sensitive files committed${NC}"
  fi
  
  # Summary
  echo ""
  if [ $secrets_found -gt 0 ]; then
    echo -e "${RED}⚠️  Security scan found $secrets_found issue(s)${NC}"
    echo -e "${YELLOW}Recommendations:${NC}"
    echo "  1. Remove hardcoded secrets from source code"
    echo "  2. Use process.env for sensitive values"
    echo "  3. Add sensitive files to .gitignore"
    echo "  4. Use environment variables or secret management tools"
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
  
  local pkg_manager=$(detect_package_manager)
  echo -e "Package Manager: ${CYAN}$pkg_manager${NC}\n"
  
  # Check environment first
  check_environment
  
  # Install dependencies
  section "Installing dependencies"
  case "$pkg_manager" in
    yarn)
      if yarn install; then
        echo -e "${GREEN}✅ Dependencies installed with Yarn${NC}"
      else
        echo -e "${RED}❌ Failed to install dependencies${NC}"
        return 1
      fi
      ;;
    pnpm)
      if pnpm install; then
        echo -e "${GREEN}✅ Dependencies installed with pnpm${NC}"
      else
        echo -e "${RED}❌ Failed to install dependencies${NC}"
        return 1
      fi
      ;;
    bun)
      if bun install; then
        echo -e "${GREEN}✅ Dependencies installed with Bun${NC}"
      else
        echo -e "${RED}❌ Failed to install dependencies${NC}"
        return 1
      fi
      ;;
    *)
      if npm install; then
        echo -e "${GREEN}✅ Dependencies installed with npm${NC}"
      else
        echo -e "${RED}❌ Failed to install dependencies${NC}"
        return 1
      fi
      ;;
  esac
  
  # Run build if build script exists
  if grep -q '"build"' package.json 2>/dev/null; then
    section "Building project"
    if npm run build; then
      echo -e "${GREEN}✅ Build completed${NC}"
    else
      echo -e "${YELLOW}⚠️  Build failed${NC}"
    fi
  fi
  
  echo -e "\n${GREEN}✅ Setup complete!${NC}\n"
  
  # Ask to start the development server
  if grep -q '"dev"\|"start"' package.json 2>/dev/null; then
    read -p "Start development server now? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${GREEN}Starting development server...${NC}"
      echo -e "${YELLOW}Press Ctrl+C to stop${NC}"
      echo ""
      
      # Try dev script first, then start
      if grep -q '"dev"' package.json 2>/dev/null; then
        npm run dev
      elif grep -q '"start"' package.json 2>/dev/null; then
        npm start
      fi
    fi
  fi
}

# ============================================
# MAIN SCRIPT
# ============================================

echo -e "${BLUE}🔍 Node.js Pre-deployment Check${NC}" | tee -a "$REPORT"
echo "Project: $(basename "$(pwd)")" | tee -a "$REPORT"
echo "Date: $(date)" | tee -a "$REPORT"

# Check for required tools FIRST
check_required_tools

# Detect package manager
PKG_MANAGER=$(detect_package_manager)
echo "Package Manager: $PKG_MANAGER" | tee -a "$REPORT"

# Parse arguments
# Parse arguments
RUN_SETUP=false
if [[ "${1:-}" == "--setup" ]] || [[ "${1:-}" == "-s" ]]; then
  RUN_SETUP=true
  echo -e "${YELLOW}⚙️  Setup mode enabled - running full checks before automatic setup...${NC}"
  echo ""
fi


# Quick dependency check if not running setup
if [ "$RUN_SETUP" = false ]; then
  if [ ! -d "node_modules" ]; then
    echo -e "\n${YELLOW}⚠️  Dependencies not installed${NC}"
    echo -e "Run: ${CYAN}precheck --setup${NC} or ${CYAN}$PKG_MANAGER install${NC}"
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

# 1. Node.js version check (CRITICAL)
run_check "Node.js version compatibility" \
  "node --version >/dev/null 2>&1" \
  "Install Node.js from https://nodejs.org/" \
  "$SEVERITY_CRITICAL"

# 2. Package manager availability (CRITICAL)
run_check "Package manager availability" \
  "$PKG_MANAGER --version >/dev/null 2>&1" \
  "Install $PKG_MANAGER package manager" \
  "$SEVERITY_CRITICAL"

# 3. Dependencies installed (HIGH)
run_check "Dependencies installed" \
  "[ -d node_modules ]" \
  "Run: $PKG_MANAGER install" \
  "$SEVERITY_HIGH"

# 4. Outdated dependencies (MEDIUM)
run_check "Outdated dependencies check" \
  "npm outdated --json | jq -e 'length == 0' 2>/dev/null || ! npm outdated 2>&1 | grep -q ." \
  "Run: npm update (review changes carefully)" \
  "$SEVERITY_MEDIUM"

# 5. Security audit (HIGH)
run_check "Security vulnerabilities" \
  "npm audit --audit-level=moderate" \
  "Run: npm audit fix (review changes carefully)" \
  "$SEVERITY_HIGH"

# 6. ESLint (HIGH)
if [ -f "node_modules/.bin/eslint" ] || [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || grep -q '"eslint"' package.json 2>/dev/null; then
  run_check "ESLint code quality" \
    "npx eslint . --max-warnings 0" \
    "Run: npx eslint . --fix" \
    "$SEVERITY_HIGH"
else
  run_optional_check "ESLint code quality" \
    "false" \
    "Install: npm install --save-dev eslint && npx eslint --init" \
    "$SEVERITY_LOW"
fi

# 7. Prettier formatting (MEDIUM)
if [ -f "node_modules/.bin/prettier" ] || [ -f ".prettierrc" ] || grep -q '"prettier"' package.json 2>/dev/null; then
  run_check "Code formatting (Prettier)" \
    "npx prettier --check ." \
    "Run: npx prettier --write ." \
    "$SEVERITY_MEDIUM"
else
  run_optional_check "Code formatting (Prettier)" \
    "false" \
    "Install: npm install --save-dev prettier" \
    "$SEVERITY_LOW"
fi

# 8. TypeScript type checking (CRITICAL if TS project)
if [ -f "tsconfig.json" ]; then
  run_check "TypeScript type checking" \
    "npx tsc --noEmit" \
    "Fix TypeScript errors before deployment" \
    "$SEVERITY_CRITICAL"
fi

# 9. Test suite (CRITICAL)
if grep -q '"test"' package.json 2>/dev/null; then
  run_check "Test suite execution" \
    "npm test -- --passWithNoTests 2>&1 | grep -qE 'Tests:|PASS|✓' || npm test -- --passWithNoTests" \
    "Fix failing tests before deployment" \
    "$SEVERITY_CRITICAL"
else
  run_optional_check "Test suite execution" \
    "false" \
    "Add test script to package.json and write tests" \
    "$SEVERITY_MEDIUM"
fi

# 10. Build process (CRITICAL if build script exists)
if grep -q '"build"' package.json 2>/dev/null; then
  run_check "Production build" \
    "npm run build" \
    "Fix build errors before deployment" \
    "$SEVERITY_CRITICAL"
fi

# 11. Environment variables (MEDIUM)
if [ -f ".env.example" ] && [ ! -f ".env" ]; then
  run_check "Environment configuration" \
    "false" \
    "Copy .env.example to .env and configure variables" \
    "$SEVERITY_MEDIUM"
fi

# 12. Package.json validation (CRITICAL)
run_check "Package.json syntax" \
  "jq empty package.json 2>/dev/null || node -e 'require(\"./package.json\")'" \
  "Fix JSON syntax errors in package.json" \
  "$SEVERITY_CRITICAL"

# 13. Node version specification (MEDIUM)
run_check "Node.js version specified" \
  "grep -q '\"engines\"' package.json && grep -q '\"node\"' package.json" \
  "Add engines.node field to package.json" \
  "$SEVERITY_MEDIUM"

# 14. Lockfile consistency (HIGH)
if [ -f "package-lock.json" ]; then
  run_check "Lockfile consistency" \
    "npm ci --dry-run >/dev/null 2>&1" \
    "Run: npm install to update package-lock.json" \
    "$SEVERITY_HIGH"
fi

# 15. License check (LOW)
run_check "Package license defined" \
  "grep -q '\"license\"' package.json" \
  "Add license field to package.json" \
  "$SEVERITY_LOW"

# Print summary
print_summary

echo -e "\n${BLUE}📋 Report saved to $REPORT${NC}"

# Exit with appropriate code
# Run automatic setup AFTER all checks if requested
# Run automatic setup AFTER all checks if requested
if [ "$RUN_SETUP" = true ]; then
  echo ""
  echo -e "${BLUE}🚀 Starting automatic setup...${NC}"
  auto_setup
fi


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
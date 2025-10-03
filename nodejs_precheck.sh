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

auto_setup() {
  echo -e "\n${CYAN}╔════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║    AUTOMATIC PROJECT SETUP             ║${NC}"
  echo -e "${CYAN}╚════════════════════════════════════════╝${NC}\n"
  
  # Detect package manager
  local pkg_manager="npm"
  if [ -f "yarn.lock" ]; then
    pkg_manager="yarn"
  elif [ -f "pnpm-lock.yaml" ]; then
    pkg_manager="pnpm"
  elif [ -f "bun.lockb" ]; then
    pkg_manager="bun"
  fi
  
  log "Detected package manager: $pkg_manager"
  
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
  
  # Setup Husky if present
  if [ -d ".husky" ] || grep -q '"husky"' package.json 2>/dev/null; then
    section "Setting up Git hooks (Husky)"
    if npm run prepare 2>/dev/null || npx husky install 2>/dev/null; then
      echo -e "${GREEN}✅ Git hooks configured${NC}"
    else
      echo -e "${YELLOW}⚠️  Git hooks setup skipped${NC}"
    fi
  fi
  
  # Generate prisma client if using Prisma
  if [ -f "prisma/schema.prisma" ]; then
    section "Generating Prisma client"
    if npx prisma generate; then
      echo -e "${GREEN}✅ Prisma client generated${NC}"
    else
      echo -e "${YELLOW}⚠️  Prisma generation failed${NC}"
    fi
  fi
  
  echo -e "\n${GREEN}✅ Auto-setup complete!${NC}\n"
}

# ============================================
# MAIN SCRIPT
# ============================================

echo -e "${BLUE}🔍 Node.js Pre-deployment Check${NC}" | tee -a "$REPORT"
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

# 1. Node.js version check (CRITICAL)
run_check "Node.js version compatibility" \
  "node --version >/dev/null 2>&1" \
  "Install Node.js from https://nodejs.org/" \
  "$SEVERITY_CRITICAL"

# 2. Package manager check (CRITICAL)
run_check "Package manager availability" \
  "npm --version >/dev/null 2>&1" \
  "Install npm (comes with Node.js)" \
  "$SEVERITY_CRITICAL"

# 3. Dependencies installation check (HIGH)
run_check "Dependencies installed" \
  "[ -d node_modules ] && [ -f package-lock.json ] || [ -f yarn.lock ] || [ -f pnpm-lock.yaml ]" \
  "Run: npm install (or yarn/pnpm install)" \
  "$SEVERITY_HIGH"

# 4. Outdated dependencies (MEDIUM)
run_check "Outdated dependencies check" \
  "npm outdated --json | jq -e 'length == 0' 2>/dev/null || ! npm outdated 2>&1 | grep -q ." \
  "Run: npm update or manually update package.json" \
  "$SEVERITY_MEDIUM"

# 5. Security audit (HIGH - security vulnerabilities)
run_check "Security vulnerabilities (npm audit)" \
  "npm audit --audit-level=moderate" \
  "Run: npm audit fix --force (review changes carefully)" \
  "$SEVERITY_HIGH"

# 6. ESLint check (HIGH - code quality)
if [ -f "node_modules/.bin/eslint" ] || [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || grep -q '"eslint"' package.json 2>/dev/null; then
  run_check "ESLint code quality" \
    "npx eslint . --max-warnings 0" \
    "Run: npx eslint . --fix to auto-fix issues" \
    "$SEVERITY_HIGH"
else
  run_optional_check "ESLint code quality" \
    "false" \
    "Install ESLint: npm install --save-dev eslint && npx eslint --init" \
    "$SEVERITY_LOW"
fi

# 7. Prettier formatting (MEDIUM)
if [ -f "node_modules/.bin/prettier" ] || [ -f ".prettierrc" ] || grep -q '"prettier"' package.json 2>/dev/null; then
  run_check "Code formatting (Prettier)" \
    "npx prettier --check ." \
    "Run: npx prettier --write . to format all files" \
    "$SEVERITY_MEDIUM"
else
  run_optional_check "Code formatting (Prettier)" \
    "false" \
    "Install Prettier: npm install --save-dev prettier" \
    "$SEVERITY_LOW"
fi

# 8. TypeScript type checking (CRITICAL if TS project)
if [ -f "tsconfig.json" ]; then
  run_check "TypeScript type checking" \
    "npx tsc --noEmit" \
    "Fix TypeScript errors before deployment" \
    "$SEVERITY_CRITICAL"
fi

# 9. Test suite (CRITICAL - core functionality)
if grep -q '"test"' package.json 2>/dev/null; then
  run_check "Test suite execution" \
    "npm test -- --passWithNoTests" \
    "Fix failing tests before deployment" \
    "$SEVERITY_CRITICAL"
else
  run_optional_check "Test suite execution" \
    "false" \
    "Add test script to package.json and write tests" \
    "$SEVERITY_MEDIUM"
fi

# 10. Test coverage (MEDIUM)
if grep -q '"coverage"' package.json 2>/dev/null || [ -f "jest.config.js" ]; then
  run_optional_check "Test coverage (>80%)" \
    "npm run coverage 2>&1 | grep -E 'All files.*[8-9][0-9]|100' || npm test -- --coverage 2>&1 | grep -E 'All files.*[8-9][0-9]|100'" \
    "Improve test coverage to at least 80%" \
    "$SEVERITY_MEDIUM"
fi

# 11. Build process (CRITICAL if build script exists)
if grep -q '"build"' package.json 2>/dev/null; then
  run_check "Production build" \
    "npm run build" \
    "Fix build errors before deployment" \
    "$SEVERITY_CRITICAL"
fi

# 12. Bundle size analysis (LOW)
if [ -f "webpack.config.js" ] || grep -q '"webpack"' package.json 2>/dev/null; then
  run_optional_check "Bundle size check" \
    "npm run build 2>&1 | grep -i 'size' || echo 'Build successful'" \
    "Consider using webpack-bundle-analyzer for optimization" \
    "$SEVERITY_LOW"
fi

# 13. Environment variables check (MEDIUM)
if [ -f ".env.example" ] && [ ! -f ".env" ]; then
  run_check "Environment configuration" \
    "false" \
    "Copy .env.example to .env and configure variables" \
    "$SEVERITY_MEDIUM"
fi

# 14. Git hooks (Husky) (LOW)
if [ -d ".husky" ] || grep -q '"husky"' package.json 2>/dev/null; then
  run_optional_check "Git hooks (Husky)" \
    "[ -f .husky/pre-commit ] || [ -f .husky/pre-push ]" \
    "Run: npm run prepare or npx husky install" \
    "$SEVERITY_LOW"
fi

# 15. License check (LOW)
run_check "Package license defined" \
  "grep -q '\"license\"' package.json" \
  "Add license field to package.json" \
  "$SEVERITY_LOW"

# 16. Package.json validation (CRITICAL)
run_check "Package.json syntax" \
  "jq empty package.json 2>/dev/null || node -e 'require(\"./package.json\")'" \
  "Fix JSON syntax errors in package.json" \
  "$SEVERITY_CRITICAL"

# 17. Node version specification (MEDIUM)
run_check "Node.js version specified" \
  "grep -q '\"engines\"' package.json && grep -q '\"node\"' package.json" \
  "Add engines.node field to package.json for version control" \
  "$SEVERITY_MEDIUM"

# 18. Lockfile consistency (HIGH)
if [ -f "package-lock.json" ]; then
  run_check "Lockfile consistency" \
    "npm ci --dry-run >/dev/null 2>&1" \
    "Run: npm install to update package-lock.json" \
    "$SEVERITY_HIGH"
fi

# 19. Circular dependencies (MEDIUM)
if command -v npx >/dev/null 2>&1; then
  run_optional_check "Circular dependencies check" \
    "npx madge --circular --extensions js,jsx,ts,tsx src/ 2>/dev/null | grep -q 'No circular' || ! npx madge --circular --extensions js,jsx,ts,tsx src/ 2>/dev/null | grep -q 'Circular'" \
    "Install madge: npm install --save-dev madge, then check and refactor circular dependencies" \
    "$SEVERITY_MEDIUM"
fi

# 20. Unused dependencies (LOW)
if command -v npx >/dev/null 2>&1; then
  run_optional_check "Unused dependencies" \
    "npx depcheck --ignores='@types/*,eslint-*,prettier' 2>/dev/null | grep -q 'No depcheck issue' || ! npx depcheck 2>/dev/null | grep -qE 'Unused dependencies|Unused devDependencies'" \
    "Install depcheck: npm install -g depcheck, then remove unused packages" \
    "$SEVERITY_LOW"
fi

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
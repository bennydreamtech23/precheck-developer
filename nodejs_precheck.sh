#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

REPORT_FILE="node_report.txt"
FAILURES=0
FAILURE_STEPS=()

echo -e "${CYAN}🔍 Node.js Pre-deployment Checks${NC}"
echo -e "${CYAN}================================${NC}"
echo "" > "$REPORT_FILE"

log_section() {
  echo -e "\n${BLUE}--- $1 ---${NC}" | tee -a "$REPORT_FILE"
}

check_command() {
  local description="$1"
  local cmd="$2"

  log_section "$description"
  if eval "$cmd" >>"$REPORT_FILE" 2>&1; then
    echo -e "${GREEN}✅ $description passed${NC}" | tee -a "$REPORT_FILE"
  else
    echo -e "${RED}❌ $description failed${NC}" | tee -a "$REPORT_FILE"
    FAILURES=$((FAILURES+1))
    FAILURE_STEPS+=("$description")
  fi
}

# 1. Dependency analysis
log_section "Dependency Analysis (npm outdated)"
if npm outdated >>"$REPORT_FILE" 2>&1; then
  echo -e "${GREEN}✅ No outdated dependencies${NC}" | tee -a "$REPORT_FILE"
else
  echo -e "${RED}❌ Outdated dependencies found${NC}" | tee -a "$REPORT_FILE"
  echo "👉 Recommendation: Run 'npm update' or update manually." | tee -a "$REPORT_FILE"
  FAILURES=$((FAILURES+1))
  FAILURE_STEPS+=("Dependency Analysis")
fi

# 2. Security Audit
log_section "Security Audit"
if ! command -v npm &>/dev/null; then
  echo -e "${RED}❌ npm not installed${NC}" | tee -a "$REPORT_FILE"
  echo "👉 Recommendation: Install Node.js + npm from https://nodejs.org/" | tee -a "$REPORT_FILE"
  FAILURES=$((FAILURES+1))
  FAILURE_STEPS+=("Security Audit (npm missing)")
else
  if npm audit --audit-level=moderate >>"$REPORT_FILE" 2>&1; then
    echo -e "${GREEN}✅ No known vulnerabilities${NC}" | tee -a "$REPORT_FILE"
  else
    echo -e "${RED}❌ Vulnerabilities found${NC}" | tee -a "$REPORT_FILE"
    echo "👉 Recommendation: Run 'npm audit fix' and review issues." | tee -a "$REPORT_FILE"
    FAILURES=$((FAILURES+1))
    FAILURE_STEPS+=("Security Audit")
  fi
fi

# 3. Linting (ESLint + Prettier if available)
if [ -f "node_modules/.bin/eslint" ]; then
  check_command "ESLint Check" "npx eslint ."
else
  echo -e "${YELLOW}⚠️ ESLint not found, skipping lint check${NC}" | tee -a "$REPORT_FILE"
  echo "👉 Recommendation: Install with 'npm install --save-dev eslint'" | tee -a "$REPORT_FILE"
fi

if [ -f "node_modules/.bin/prettier" ]; then
  check_command "Prettier Formatting Check" "npx prettier --check ."
else
  echo -e "${YELLOW}⚠️ Prettier not found, skipping format check${NC}" | tee -a "$REPORT_FILE"
  echo "👉 Recommendation: Install with 'npm install --save-dev prettier'" | tee -a "$REPORT_FILE"
fi

# 4. TypeScript type checking (if applicable)
if [ -f "tsconfig.json" ]; then
  check_command "TypeScript Type Checking" "npx tsc --noEmit"
fi

# 5. Run tests
check_command "Test Suite Execution" "npm test -- --passWithNoTests"

# 6. Build validation
if [ -f "package.json" ] && grep -q '"build"' package.json; then
  check_command "Build Process Validation" "npm run build"
fi

# ✅ Final Summary
echo -e "\n${CYAN}Summary Report${NC}" | tee -a "$REPORT_FILE"
if [ $FAILURES -eq 0 ]; then
  echo -e "${GREEN}🎉 All checks passed successfully!${NC}" | tee -a "$REPORT_FILE"
else
  echo -e "${RED}⚠️ Some checks failed:${NC}" | tee -a "$REPORT_FILE"
  for step in "${FAILURE_STEPS[@]}"; do
    echo -e "   - ${RED}$step${NC}" | tee -a "$REPORT_FILE"
  done
  echo -e "\nSee full details in ${YELLOW}$REPORT_FILE${NC}"
  exit 1
fi

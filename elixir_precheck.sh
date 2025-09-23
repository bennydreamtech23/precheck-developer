#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPORT="elixir_report.txt"
: > "$REPORT"

log() {
  echo -e "$1" | tee -a "$REPORT"
}

section() {
  echo -e "\n${BLUE}=== $1 ===${NC}" | tee -a "$REPORT"
}

run_check() {
  local description="$1"
  local command="$2"
  section "$description"
  echo -e "${YELLOW}Running: $command${NC}" | tee -a "$REPORT"

  if eval "$command" >>"$REPORT" 2>&1; then
    echo -e "${GREEN}✅ $description passed${NC}" | tee -a "$REPORT"
  else
    echo -e "${RED}❌ $description failed${NC}" | tee -a "$REPORT"

    # Recommendations
    case "$description" in
      "Dependency analysis")
        log "👉 Run: mix deps.get && mix deps.update --all"
        ;;
      "Code formatting")
        log "👉 Run: mix format"
        ;;
      "Static analysis (Credo)")
        log "👉 Run: mix credo --strict"
        ;;
      "Test suite")
        log "👉 Fix failing tests before deployment"
        ;;
      "Production compilation")
        log "👉 Run: MIX_ENV=prod mix compile"
        ;;
      "Security analysis (Sobelow)")
        log "👉 Install Sobelow: mix archive.install hex sobelow"
        ;;
      "Documentation generation")
        log "👉 Run: mix docs"
        ;;
    esac
  fi
}

echo -e "${BLUE}🔍 Elixir Pre-deployment Check${NC}" | tee -a "$REPORT"
echo "Project: $(basename "$(pwd)")" | tee -a "$REPORT"
echo "Date: $(date)" | tee -a "$REPORT"

# === Checks ===
run_check "Dependency analysis" "mix deps.get && mix deps.audit"
run_check "Code formatting" "mix format --check-formatted"
run_check "Static analysis (Credo)" "mix credo --strict"
run_check "Test suite" "mix test --cover"
run_check "Production compilation" "MIX_ENV=prod mix compile --force"

# Sobelow with fallback
section "Security analysis (Sobelow)"
if mix help sobelow >/dev/null 2>&1; then
  if mix sobelow --verbose --exit >>"$REPORT" 2>&1; then
    echo -e "${GREEN}✅ Security analysis (Sobelow) passed${NC}" | tee -a "$REPORT"
  else
    echo -e "${RED}❌ Security analysis (Sobelow) failed${NC}" | tee -a "$REPORT"
    log "👉 Review Sobelow findings above"
  fi
else
  echo -e "${RED}❌ Sobelow not installed${NC}" | tee -a "$REPORT"
  log "👉 Install Sobelow: mix archive.install hex sobelow"
fi

run_check "Documentation generation" "mix docs"

echo -e "\n${BLUE}📋 Report saved to $REPORT${NC}"

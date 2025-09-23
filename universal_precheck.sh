#!/usr/bin/env bash

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}🔍 Universal Pre-deployment Check Script${NC}"
echo -e "${CYAN}=======================================${NC}"
echo ""

detect_and_run() {
  local project_type=""
  local script_name=""
  
  # Check for Elixir project
  if [ -f "mix.exs" ]; then
    project_type="Elixir"
    script_name="elixir_precheck.sh"
  # Check for Node.js project
  elif [ -f "package.json" ]; then
    project_type="Node.js"
    script_name="nodejs_precheck.sh"
  else
    echo -e "${RED}❌ No mix.exs or package.json found.${NC}"
    echo -e "${RED}   This directory doesn't appear to contain a recognized Elixir or Node.js project.${NC}"
    echo ""
    echo -e "${YELLOW}Supported project types:${NC}"
    echo -e "  • Elixir projects (requires mix.exs)"
    echo -e "  • Node.js projects (requires package.json)"
    exit 1
  fi
  
  echo -e "${GREEN}✅ Detected: $project_type project${NC}"
  echo ""
  
  # Check if the specific script exists
  local script_path="$SCRIPT_DIR/$script_name"
  if [ ! -f "$script_path" ]; then
    echo -e "${RED}❌ Script not found: $script_path${NC}"
    echo -e "${RED}   Please ensure the $script_name file exists in the same directory.${NC}"
    exit 1
  fi
  
  # Make the script executable if it isn't already
  if [ ! -x "$script_path" ]; then
    echo -e "${YELLOW}⚠️  Making $script_name executable...${NC}"
    chmod +x "$script_path"
  fi
  
  echo -e "${BLUE}🚀 Running $project_type pre-deployment checks...${NC}"
  echo ""
  
  # Execute the appropriate script
  exec "$script_path" "$@"
}

# Show help if requested
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  cat << EOF
${CYAN}Universal Pre-deployment Check Script${NC}

This script automatically detects your project type and runs the appropriate 
pre-deployment checks.

${YELLOW}Usage:${NC}
  $0 [options]

${YELLOW}Supported Projects:${NC}
  • Elixir projects (detected by mix.exs)
  • Node.js projects (detected by package.json)

${YELLOW}Options:${NC}
  -h, --help    Show this help message

${YELLOW}Environment Variables:${NC}
  OPENAI_API_KEY    Optional: Enable AI-powered code review

${YELLOW}Examples:${NC}
  # Basic usage
  $0

  # With AI feedback
  export OPENAI_API_KEY="your-api-key"
  $0

${YELLOW}What gets checked:${NC}
  
  ${BLUE}Elixir Projects:${NC}
  • Dependency analysis (outdated packages, vulnerabilities)
  • Code formatting (mix format)
  • Static analysis (Credo)
  • Test suite execution with coverage
  • Production compilation with performance timing
  • Security analysis (Sobelow)
  • Release build testing
  • Documentation generation
  
  ${BLUE}Node.js Projects:${NC}
  • Dependency analysis (npm outdated, npm audit)
  • Code quality (ESLint, Prettier)
  • Test suite execution
  • Build process validation
  • TypeScript type checking (if applicable)
  • Security pattern analysis
  • Performance analysis
  • Environment validation

${YELLOW}Output Files:${NC}
  • elixir_report.txt / node_report.txt - Detailed check results
  • elixir_ai_feedback.txt / node_ai_feedback.txt - AI recommendations (if enabled)

EOF
  exit 0
fi

# Main execution
detect_and_run "$@"
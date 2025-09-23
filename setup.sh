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

echo -e "${CYAN}🔧 Pre-deployment Scripts Setup${NC}"
echo -e "${CYAN}===============================${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to make script executable
make_executable() {
    local script_path="$1"
    local script_name="$2"
    
    if [ -f "$script_path" ]; then
        if [ -x "$script_path" ]; then
            echo -e "${GREEN}✅ $script_name is already executable${NC}"
        else
            chmod +x "$script_path"
            echo -e "${GREEN}✅ Made $script_name executable${NC}"
        fi
    else
        echo -e "${RED}❌ $script_name not found at $script_path${NC}"
        return 1
    fi
}

# Main setup function
main() {
    echo -e "${BLUE}Setting up pre-deployment check scripts...${NC}"
    echo ""
    
    # Make all scripts executable
    echo -e "${YELLOW}📝 Making scripts executable...${NC}"
    make_executable "$SCRIPT_DIR/universal_precheck.sh" "universal_precheck.sh"
    make_executable "$SCRIPT_DIR/elixir_precheck.sh" "elixir_precheck.sh"  
    make_executable "$SCRIPT_DIR/nodejs_precheck.sh" "nodejs_precheck.sh"
    echo ""
    
    # Check system dependencies
    echo -e "${YELLOW}🔍 Checking system dependencies...${NC}"
    
    # Essential tools
    if command_exists curl; then
        echo -e "${GREEN}✅ curl is available${NC}"
    else
        echo -e "${RED}❌ curl is not installed (required for AI feedback)${NC}"
        echo -e "${YELLOW}   Install: sudo apt-get install curl (Ubuntu/Debian)${NC}"
        echo -e "${YELLOW}   Install: brew install curl (macOS)${NC}"
    fi
    
    if command_exists jq; then
        echo -e "${GREEN}✅ jq is available${NC}"
    else
        echo -e "${RED}❌ jq is not installed (required for JSON processing)${NC}"
        echo -e "${YELLOW}   Install: sudo apt-get install jq (Ubuntu/Debian)${NC}"
        echo -e "${YELLOW}   Install: brew install jq (macOS)${NC}"
    fi
    
    # Check for development environments
    echo ""
    echo -e "${YELLOW}🔍 Checking development environments...${NC}"
    
    # Node.js environment
    if command_exists node; then
        NODE_VERSION=$(node --version)
        echo -e "${GREEN}✅ Node.js $NODE_VERSION is available${NC}"
        
        if command_exists npm; then
            NPM_VERSION=$(npm --version)
            echo -e "${GREEN}✅ npm $NPM_VERSION is available${NC}"
        else
            echo -e "${RED}❌ npm is not available${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Node.js is not installed${NC}"
        echo -e "${YELLOW}   Required for Node.js project checks${NC}"
    fi
    
    # Elixir environment
    if command_exists elixir; then
     ELIXIR_VERSION=$(elixir --version | grep -m1 "Elixir")
echo -e "${GREEN}✅ $ELIXIR_VERSION is available${NC}"

        
        if command_exists mix; then
            echo -e "${GREEN}✅ Mix build tool is available${NC}"
        else
            echo -e "${RED}❌ Mix is not available${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  Elixir is not installed${NC}"
        echo -e "${YELLOW}   Required for Elixir project checks${NC}"
    fi
    
    # Check for optional tools
    echo ""
    echo -e "${YELLOW}🔍 Checking optional tools...${NC}"
    
    if command_exists git; then
        echo -e "${GREEN}✅ Git is available${NC}"
    else
        echo -e "${YELLOW}⚠️  Git is not installed (recommended for version info)${NC}"
    fi
    
    # Environment variables
    echo ""
    echo -e "${YELLOW}🔍 Checking environment configuration...${NC}"
    
    if [ -n "${OPENAI_API_KEY:-}" ]; then
        echo -e "${GREEN}✅ OPENAI_API_KEY is set (AI feedback enabled)${NC}"
    else
        echo -e "${YELLOW}⚠️  OPENAI_API_KEY not set (AI feedback disabled)${NC}"
        echo -e "${YELLOW}   Set with: export OPENAI_API_KEY='your-api-key'${NC}"
    fi
    
    # Check current directory for project type
    echo ""
    echo -e "${YELLOW}🔍 Detecting current project type...${NC}"
    
    if [ -f "mix.exs" ]; then
        echo -e "${GREEN}✅ Elixir project detected (mix.exs found)${NC}"
        PROJECT_NAME=$(grep -E "app:\s*:" mix.exs | sed 's/.*app: *:\([^,]*\).*/\1/' | tr -d ' ' || echo "unknown")
        echo -e "${BLUE}   Project: $PROJECT_NAME${NC}"
    elif [ -f "package.json" ]; then
        echo -e "${GREEN}✅ Node.js project detected (package.json found)${NC}"
        if command_exists jq && [ -f "package.json" ]; then
            PROJECT_NAME=$(jq -r '.name // "unknown"' package.json 2>/dev/null)
            PROJECT_VERSION=$(jq -r '.version // "unknown"' package.json 2>/dev/null)
            echo -e "${BLUE}   Project: $PROJECT_NAME v$PROJECT_VERSION${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No project files detected in current directory${NC}"
        echo -e "${YELLOW}   Run this setup from your project root directory${NC}"
    fi
    
    # Test script execution
    echo ""
    echo -e "${YELLOW}🧪 Testing script execution...${NC}"
    
    if [ -f "$SCRIPT_DIR/universal_precheck.sh" ] && [ -x "$SCRIPT_DIR/universal_precheck.sh" ]; then
        if "$SCRIPT_DIR/universal_precheck.sh" --help >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Universal precheck script is working${NC}"
        else
            echo -e "${RED}❌ Universal precheck script has issues${NC}"
        fi
    fi
    
    # Installation recommendations
    echo ""
    echo -e "${CYAN}📋 Setup Summary${NC}"
    echo -e "${CYAN}===============${NC}"
    
    echo -e "${GREEN}✅ All scripts are now executable${NC}"
    echo ""
    echo -e "${YELLOW}🚀 Quick start:${NC}"
    echo -e "   ./universal_precheck.sh"
    echo ""
    echo -e "${YELLOW}📖 For detailed usage:${NC}"
    echo -e "   ./universal_precheck.sh --help"
    echo ""
    
    if [ ! -f "mix.exs" ] && [ ! -f "package.json" ]; then
        echo -e "${YELLOW}💡 Tip:${NC}"
        echo -e "   Navigate to your project directory before running the scripts"
        echo ""
    fi
    
    # Create a simple alias suggestion
    echo -e "${YELLOW}💡 Optional: Create an alias for easy access${NC}"
    echo -e "   Add to your ~/.bashrc or ~/.zshrc:"
    echo -e "   alias precheck='$SCRIPT_DIR/universal_precheck.sh'"
    echo ""
    
    echo -e "${GREEN}✨ Setup completed successfully!${NC}"
}

# Help message
if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    cat << EOF
${CYAN}Pre-deployment Scripts Setup${NC}

This setup script prepares all pre-deployment check scripts and validates your environment.

${YELLOW}Usage:${NC}
  $0 [options]

${YELLOW}Options:${NC}
  -h, --help    Show this help message

${YELLOW}What this script does:${NC}
  • Makes all check scripts executable
  • Validates system dependencies (curl, jq)
  • Checks development environments (Node.js, Elixir)
  • Detects current project type
  • Tests script functionality
  • Provides setup recommendations

${YELLOW}After setup, you can run:${NC}
  ./universal_precheck.sh        # Auto-detect and run appropriate checks
  ./elixir_precheck.sh          # Run Elixir-specific checks
  ./nodejs_precheck.sh          # Run Node.js-specific checks

EOF
    exit 0
fi

# Run main setup
main "$@"
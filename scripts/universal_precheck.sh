#!/usr/bin/env bash

set -euo pipefail

# Version and metadata
VERSION="1.0.0-beta"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.precheck_config"
INSTALL_DIR="$HOME/.precheck"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Debug mode
DEBUG_MODE="${PRECHECK_DEBUG:-false}"

log_debug() {
    if [ "$DEBUG_MODE" = "true" ]; then
        echo -e "${CYAN}[DEBUG] $1${NC}" >&2
    fi
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

show_banner() {
    echo -e "${CYAN}╔════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║   Developer Precheck v$VERSION         ║${NC}"
    echo -e "${CYAN}║   Pre-deployment Validation Toolkit    ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════╝${NC}"
    echo ""
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Load configuration
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        log_debug "Loading configuration from $CONFIG_FILE"
        # shellcheck source=/dev/null
        source "$CONFIG_FILE"
        # Use PRECHECK_INSTALL_DIR from config if available
        if [ -n "${PRECHECK_INSTALL_DIR:-}" ]; then
            INSTALL_DIR="$PRECHECK_INSTALL_DIR"
        fi
    fi
    log_debug "Using install directory: $INSTALL_DIR"
}

# Enhanced project detection
detect_project_type() {
    local elixir_confidence=0
    local node_confidence=0
    
    log_info "Detecting project type..."
    
    # Elixir detection
    if [ -f "mix.exs" ]; then
        elixir_confidence=50
        [ -d "lib/" ] && elixir_confidence=$((elixir_confidence + 20))
        [ -f "config/config.exs" ] && elixir_confidence=$((elixir_confidence + 15))
        [ -d "test/" ] && elixir_confidence=$((elixir_confidence + 15))
    fi
    
    # Node.js detection
    if [ -f "package.json" ]; then
        node_confidence=50
        [ -f "package-lock.json" ] || [ -f "yarn.lock" ] || [ -f "pnpm-lock.yaml" ] && \
            node_confidence=$((node_confidence + 20))
        [ -d "node_modules/" ] && node_confidence=$((node_confidence + 15))
        [ -f "tsconfig.json" ] && node_confidence=$((node_confidence + 15))
    fi
    
    if [ $elixir_confidence -gt $node_confidence ] && [ $elixir_confidence -gt 0 ]; then
        export DETECTED_PROJECT_TYPE="Elixir"
        export DETECTED_SCRIPT_NAME="elixir_precheck.sh"
        export DETECTION_CONFIDENCE=$elixir_confidence
    elif [ $node_confidence -gt 0 ]; then
        export DETECTED_PROJECT_TYPE="Node.js"
        export DETECTED_SCRIPT_NAME="nodejs_precheck.sh"
        export DETECTION_CONFIDENCE=$node_confidence
    else
        log_error "No supported project type detected"
        echo ""
        echo "Supported project types:"
        echo "  • Elixir projects (requires mix.exs)"
        echo "  • Node.js projects (requires package.json)"
        echo ""
        return 1
    fi
    
    log_success "Detected: $DETECTED_PROJECT_TYPE project (confidence: $DETECTION_CONFIDENCE%)"
    [ $DETECTION_CONFIDENCE -lt 70 ] && log_warn "Low confidence detection. Results may vary."
    
    return 0
}

# Detect package manager for Node.js projects
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

# Run the appropriate precheck script
run_precheck() {
    # First try to find script in INSTALL_DIR, then fallback to SCRIPT_DIR
    local script_path="$INSTALL_DIR/$DETECTED_SCRIPT_NAME"
    
    if [ ! -f "$script_path" ]; then
        # Fallback to SCRIPT_DIR (for local development/testing)
        script_path="$SCRIPT_DIR/$DETECTED_SCRIPT_NAME"
    fi
    
    if [ ! -f "$script_path" ]; then
        log_error "Script not found: $INSTALL_DIR/$DETECTED_SCRIPT_NAME"
        log_info "Run the install script to set up precheck properly"
        log_debug "Checked locations:"
        log_debug "  1. $INSTALL_DIR/$DETECTED_SCRIPT_NAME"
        log_debug "  2. $SCRIPT_DIR/$DETECTED_SCRIPT_NAME"
        return 1
    fi
    
    if [ ! -x "$script_path" ]; then
        log_info "Making $DETECTED_SCRIPT_NAME executable..."
        chmod +x "$script_path"
    fi
    
    log_info "Running $DETECTED_PROJECT_TYPE pre-deployment checks..."
    log_debug "Using script: $script_path"
    echo ""
    
    # Execute the language-specific script with all passed arguments
    exec "$script_path" "$@"
}


# Show help
show_help() {
    cat << EOF
${CYAN}Developer Precheck v$VERSION${NC}

Automatically detects your project type and runs appropriate pre-deployment checks.

${YELLOW}Usage:${NC}
  precheck [options]

${YELLOW}Options:${NC}
  -h, --help      Show this help message
  -v, --version   Show version information
  --debug         Enable debug mode with verbose logging
  --setup, -s     Run automatic project setup before checks

${YELLOW}Supported Projects:${NC}
  • Elixir projects (detected by mix.exs)
  • Node.js projects (detected by package.json)

${YELLOW}Examples:${NC}
  # Basic usage
  precheck

  # With automatic setup
  precheck --setup

  # Debug mode
  precheck --debug

${YELLOW}Configuration:${NC}
  Location: $CONFIG_FILE
  To enable debug mode permanently: export PRECHECK_DEBUG=true

${YELLOW}Exit Codes:${NC}
  0 - All checks passed or only minor issues
  1 - High priority issues detected
  2 - Critical failures detected (blocks deployment)

EOF
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "Developer Precheck v$VERSION"
                exit 0
                ;;
            --debug)
                export DEBUG_MODE="true"
                export PRECHECK_DEBUG="true"
                shift
                ;;
            --setup|-s)
                export RUN_SETUP="true"
                shift
                ;;
            *)
                shift
                ;;
        esac
    done
}

# Main execution
main() {
    parse_args "$@"
    
    load_config
    show_banner
    
    if ! detect_project_type; then
        exit 1
    fi
    
    # Pass setup flag to language-specific script
    if [ "${RUN_SETUP:-false}" = "true" ]; then
        run_precheck --setup
    else
        run_precheck
    fi
}

main "$@"

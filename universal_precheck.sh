#!/usr/bin/env bash

set -euo pipefail

# Version and metadata
VERSION="1.0.0-beta"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.precheck_config"

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
    fi
}

# Enhanced project detection with confidence scoring
detect_project_type() {
    local confidence=0
    local project_type=""
    local script_name=""
    local features=()
    
    log_info "Detecting project type..."
    
    # Elixir project detection
    if [ -f "mix.exs" ]; then
        confidence=$((confidence + 50))
        project_type="Elixir"
        script_name="elixir_precheck.sh"
        features+=("mix.exs")
        
        [ -d "lib/" ] && confidence=$((confidence + 20)) && features+=("lib/")
        [ -f "config/config.exs" ] && confidence=$((confidence + 15)) && features+=("config/")
        [ -d "test/" ] && confidence=$((confidence + 15)) && features+=("test/")
    fi
    
    # Node.js project detection
    if [ -f "package.json" ]; then
        local node_confidence=50
        local node_features=("package.json")
        
        [ -f "package-lock.json" ] || [ -f "yarn.lock" ] || [ -f "pnpm-lock.yaml" ] && \
            node_confidence=$((node_confidence + 20)) && node_features+=("lockfile")
        [ -d "node_modules/" ] && node_confidence=$((node_confidence + 15)) && node_features+=("node_modules/")
        [ -f "tsconfig.json" ] && node_confidence=$((node_confidence + 15)) && node_features+=("TypeScript")
        
        # Use Node.js if confidence is higher or if Elixir wasn't detected
        if [ $node_confidence -gt $confidence ]; then
            confidence=$node_confidence
            project_type="Node.js"
            script_name="nodejs_precheck.sh"
            features=("${node_features[@]}")
        fi
    fi
    
    # Report detection results
    if [ $confidence -eq 0 ]; then
        log_error "No supported project type detected"
        echo ""
        echo "Supported project types:"
        echo "  • Elixir projects (requires mix.exs)"
        echo "  • Node.js projects (requires package.json)"
        echo ""
        return 1
    fi
    
    log_success "Detected: $project_type project (confidence: $confidence%)"
    
    if [ "$DEBUG_MODE" = "true" ]; then
        log_debug "Detection features: ${features[*]}"
    fi
    
    if [ $confidence -lt 70 ]; then
        log_warn "Low confidence detection. Results may vary."
    fi
    
    # Export for use in execution
    export DETECTED_PROJECT_TYPE="$project_type"
    export DETECTED_SCRIPT_NAME="$script_name"
    export DETECTION_CONFIDENCE="$confidence"
    
    return 0
}

# Run the appropriate precheck script
run_precheck() {
    local script_path="$SCRIPT_DIR/$DETECTED_SCRIPT_NAME"
    
    if [ ! -f "$script_path" ]; then
        log_error "Script not found: $script_path"
        log_info "Run the install script to set up precheck properly"
        return 1
    fi
    
    if [ ! -x "$script_path" ]; then
        log_info "Making $DETECTED_SCRIPT_NAME executable..."
        chmod +x "$script_path"
    fi
    
    log_info "Running $DETECTED_PROJECT_TYPE pre-deployment checks..."
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
            *)
                # Pass unknown arguments to the language-specific script
                break
                ;;
        esac
    done
}

# Main execution
main() {
    # Parse arguments first (this may exit early for --help or --version)
    parse_args "$@"
    
    # Load configuration
    load_config
    
    # Show banner
    show_banner
    
    # Detect project type
    if ! detect_project_type; then
        exit 1
    fi
    
    # Run the appropriate precheck script
    run_precheck "$@"
}

# Execute main function with all arguments
main "$@"SCRIPT_NAME
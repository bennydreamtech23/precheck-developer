#!/usr/bin/env bash

set -euo pipefail

# Version and metadata
VERSION="1.0.0-beta"
SCRIPT_NAME="Universal Precheck"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.precheck_config"
BETA_MODE="${PRECHECK_BETA:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m' 

# Beta features flag
ENABLE_EXPERIMENTAL="${PRECHECK_EXPERIMENTAL:-false}"
DEBUG_MODE="${PRECHECK_DEBUG:-false}"

# Smart installation URLs
GITHUB_REPO="https://api.github.com/repos/bennydreamtech23/precheck-developer"
INSTALL_URL="https://raw.githubusercontent.com/bennydreamtech23/precheck-developer/main/install.sh"

log_debug() {
    if [ "$DEBUG_MODE" = "true" ]; then
        echo -e "${PURPLE}[DEBUG] $1${NC}" >&2
    fi
}

log_info() {
    echo -e "${CYAN}[INFO] $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

show_banner() {
    local mode_text=""
    if [ "$BETA_MODE" = "true" ]; then
        mode_text="${PURPLE} [BETA MODE] ${NC}"
    fi
    
    echo -e "${CYAN}🚀 $SCRIPT_NAME v$VERSION$mode_text${NC}"
    echo -e "${CYAN}===========================================${NC}"
    if [ "$BETA_MODE" = "true" ]; then
        echo -e "${PURPLE}⚡ Beta features enabled - Experimental functionality active${NC}"
    fi
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
    else
        log_debug "No configuration file found, using defaults"
    fi
}

# Save configuration
save_config() {
    log_debug "Saving configuration to $CONFIG_FILE"
    cat > "$CONFIG_FILE" << EOF
# Precheck Configuration
PRECHECK_BETA=${BETA_MODE}
PRECHECK_EXPERIMENTAL=${ENABLE_EXPERIMENTAL}
PRECHECK_DEBUG=${DEBUG_MODE}
PRECHECK_AUTO_UPDATE=${AUTO_UPDATE:-true}
PRECHECK_AI_ENABLED=${AI_ENABLED:-false}
LAST_UPDATE_CHECK=$(date +%s)
EOF
}

# Check for updates
check_for_updates() {
    local auto_update="${AUTO_UPDATE:-true}"
    local last_check="${LAST_UPDATE_CHECK:-0}"
    local current_time=$(date +%s)
    local check_interval=$((24 * 3600)) # 24 hours
    
    if [ "$auto_update" != "true" ]; then
        log_debug "Auto-update disabled, skipping update check"
        return 0
    fi
    
    if [ $((current_time - last_check)) -lt $check_interval ]; then
        log_debug "Update check skipped (checked recently)"
        return 0
    fi
    
    log_info "Checking for updates..."
    
    if ! command_exists curl; then
        log_warn "curl not available, skipping update check"
        return 0
    fi
    
    local latest_version
    if latest_version=$(curl -s "$GITHUB_REPO/releases/latest" | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4 2>/dev/null); then
        if [ "$latest_version" != "$VERSION" ]; then
            log_warn "New version available: $latest_version (current: $VERSION)"
            echo -e "${YELLOW}Run './universal_precheck.sh --update' to update${NC}"
        else
            log_debug "Already using latest version: $VERSION"
        fi
    else
        log_debug "Could not check for updates"
    fi
    
    # Update last check time
    export LAST_UPDATE_CHECK="$current_time"
    save_config
}

# Smart dependency installer
smart_install_dependencies() {
    log_info "🔧 Smart dependency installation starting..."
    local missing_deps=()
    local os_type=""
    local install_cmd=""
    
    # Detect OS
    case "$(uname -s)" in
        Linux*)
            if command_exists apt-get; then
                os_type="debian"
                install_cmd="sudo apt-get install -y"
            elif command_exists yum; then
                os_type="rhel"
                install_cmd="sudo yum install -y"
            elif command_exists pacman; then
                os_type="arch"
                install_cmd="sudo pacman -S --noconfirm"
            else
                log_warn "Unsupported Linux distribution"
                return 1
            fi
            ;;
        Darwin*)
            os_type="macos"
            if command_exists brew; then
                install_cmd="brew install"
            else
                log_warn "Homebrew not installed. Please install from https://brew.sh/"
                return 1
            fi
            ;;
        MINGW*|MSYS*|CYGWIN*)
            os_type="windows"
            log_warn "Windows detected. Please install dependencies manually."
            return 1
            ;;
        *)
            log_warn "Unsupported operating system"
            return 1
            ;;
    esac
    
    log_debug "Detected OS: $os_type"
    
    # Check essential dependencies
    local essential_deps=("curl" "jq" "git")
    for dep in "${essential_deps[@]}"; do
        if ! command_exists "$dep"; then
            missing_deps+=("$dep")
        fi
    done
    
    # Install missing dependencies
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_info "Installing missing dependencies: ${missing_deps[*]}"
        
        case "$os_type" in
            debian)
                sudo apt-get update
                ;;
        esac
        
        for dep in "${missing_deps[@]}"; do
            log_info "Installing $dep..."
            if $install_cmd "$dep"; then
                log_success "✅ $dep installed successfully"
            else
                log_error "❌ Failed to install $dep"
                return 1
            fi
        done
    else
        log_success "✅ All essential dependencies are already installed"
    fi
    
    # Install project-specific dependencies
    install_project_dependencies
}

# Install project-specific dependencies based on detected project type
install_project_dependencies() {
    log_info "🔍 Installing project-specific dependencies..."
    
    # Node.js dependencies
    if [ -f "package.json" ]; then
        log_info "Node.js project detected"
        
        if ! command_exists node; then
            log_info "Installing Node.js..."
            case "$os_type" in
                debian)
                    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
                    sudo apt-get install -y nodejs
                    ;;
                macos)
                    brew install node
                    ;;
                *)
                    log_warn "Please install Node.js manually from https://nodejs.org/"
                    ;;
            esac
        fi
        
        # Install optional Node.js tools
        local node_tools=("eslint" "prettier" "@typescript-eslint/parser")
        for tool in "${node_tools[@]}"; do
            if [ ! -d "node_modules/$tool" ] && [ "$BETA_MODE" = "true" ]; then
                log_info "Installing $tool (beta feature)..."
                npm install --save-dev "$tool" 2>/dev/null || log_debug "Failed to install $tool"
            fi
        done
    fi
    
    # Elixir dependencies
    if [ -f "mix.exs" ]; then
        log_info "Elixir project detected"
        
        if ! command_exists elixir; then
            log_info "Installing Elixir..."
            case "$os_type" in
                debian)
                    wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
                    sudo dpkg -i erlang-solutions_2.0_all.deb
                    sudo apt-get update
                    sudo apt-get install -y esl-erlang elixir
                    rm erlang-solutions_2.0_all.deb
                    ;;
                macos)
                    brew install elixir
                    ;;
                *)
                    log_warn "Please install Elixir manually from https://elixir-lang.org/"
                    ;;
            esac
        fi
        
        # Install optional Elixir tools
        if [ "$BETA_MODE" = "true" ]; then
            log_info "Installing Elixir development tools (beta feature)..."
            mix archive.install hex sobelow --force 2>/dev/null || log_debug "Failed to install sobelow"
            mix archive.install hex credo --force 2>/dev/null || log_debug "Failed to install credo"
        fi
    fi
}

# Beta mode performance profiler
performance_profiler() {
    if [ "$BETA_MODE" != "true" ]; then
        return 0
    fi
    
    log_info "🎯 Running performance profiler (beta feature)..."
    
    local start_time=$(date +%s%N)
    local memory_before=$(free -m | awk 'NR==2{print $3}' 2>/dev/null || echo "0")
    
    # Store performance data
    export PERF_START_TIME="$start_time"
    export PERF_MEMORY_BEFORE="$memory_before"
    
    # Set up performance monitoring trap
    trap 'performance_report' EXIT
}

performance_report() {
    if [ "$BETA_MODE" != "true" ] || [ -z "${PERF_START_TIME:-}" ]; then
        return 0
    fi
    
    local end_time=$(date +%s%N)
    local memory_after=$(free -m | awk 'NR==2{print $3}' 2>/dev/null || echo "0")
    local duration=$(( (end_time - PERF_START_TIME) / 1000000 )) # Convert to milliseconds
    local memory_diff=$((memory_after - PERF_MEMORY_BEFORE))
    
    echo ""
    log_info "📊 Performance Report (Beta)"
    echo -e "${CYAN}   Duration: ${duration}ms${NC}"
    echo -e "${CYAN}   Memory Delta: ${memory_diff}MB${NC}"
    
    if [ "$duration" -gt 60000 ]; then
        log_warn "   Execution took longer than 1 minute"
    fi
    
    if [ "$memory_diff" -gt 100 ]; then
        log_warn "   High memory usage detected"
    fi
}

# Enhanced project detection with confidence scoring
enhanced_project_detection() {
    local confidence=0
    local project_type=""
    local script_name=""
    local features=()
    
    log_info "🔍 Enhanced project detection..."
    
    # Elixir project detection
    if [ -f "mix.exs" ]; then
        confidence=$((confidence + 50))
        project_type="Elixir"
        script_name="elixir_precheck.sh"
        features+=("mix.exs found")
        
        if [ -d "lib/" ]; then
            confidence=$((confidence + 20))
            features+=("lib/ directory")
        fi
        
        if [ -f "config/config.exs" ]; then
            confidence=$((confidence + 15))
            features+=("config structure")
        fi
        
        if [ -d "test/" ]; then
            confidence=$((confidence + 15))
            features+=("test directory")
        fi
    fi
    
    # Node.js project detection
    if [ -f "package.json" ]; then
        local node_confidence=50
        project_type="Node.js"
        script_name="nodejs_precheck.sh"
        local node_features=("package.json found")
        
        if [ -f "package-lock.json" ] || [ -f "yarn.lock" ]; then
            node_confidence=$((node_confidence + 20))
            node_features+=("lockfile found")
        fi
        
        if [ -d "node_modules/" ]; then
            node_confidence=$((node_confidence + 15))
            node_features+=("node_modules directory")
        fi
        
        if [ -f "tsconfig.json" ]; then
            node_confidence=$((node_confidence + 15))
            node_features+=("TypeScript configuration")
        fi
        
        # If both projects detected, use higher confidence
        if [ $node_confidence -gt $confidence ]; then
            confidence=$node_confidence
            project_type="Node.js"
            script_name="nodejs_precheck.sh"
            features=("${node_features[@]}")
        fi
    fi
    
    # Report detection results
    if [ $confidence -eq 0 ]; then
        log_error "❌ No supported project type detected"
        echo ""
        echo -e "${YELLOW}Supported project types:${NC}"
        echo -e "  • Elixir projects (requires mix.exs)"
        echo -e "  • Node.js projects (requires package.json)"
        return 1
    fi
    
    log_success "✅ Detected: $project_type project (confidence: $confidence%)"
    
    if [ "$DEBUG_MODE" = "true" ]; then
        log_debug "Detection features: ${features[*]}"
    fi
    
    if [ $confidence -lt 70 ]; then
        log_warn "⚠️  Low confidence detection. Results may vary."
    fi
    
    # Export for use in other functions
    export DETECTED_PROJECT_TYPE="$project_type"
    export DETECTED_SCRIPT_NAME="$script_name"
    export DETECTION_CONFIDENCE="$confidence"
    
    return 0
}

# AI-enhanced project analysis (beta feature)
ai_project_analysis() {
    if [ "$BETA_MODE" != "true" ] || [ -z "${OPENAI_API_KEY:-}" ]; then
        return 0
    fi
    
    log_info "🤖 AI Project Analysis (beta feature)..."
    
    local project_context=""
    if [ -f "README.md" ]; then
        project_context=$(head -20 "README.md" 2>/dev/null || echo "")
    fi
    
    if [ -f "package.json" ]; then
        project_context="$project_context\n$(cat package.json 2>/dev/null || echo "")"
    elif [ -f "mix.exs" ]; then
        project_context="$project_context\n$(head -30 mix.exs 2>/dev/null || echo "")"
    fi
    
    local ai_prompt="Analyze this project and provide deployment readiness recommendations in 3 bullet points:\n$project_context"
    
    local ai_response
    if ai_response=$(curl -s -X POST "https://api.openai.com/v1/chat/completions" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{
            \"model\": \"gpt-3.5-turbo\",
            \"messages\": [{\"role\": \"user\", \"content\": \"$ai_prompt\"}],
            \"max_tokens\": 200
        }" | jq -r '.choices[0].message.content' 2>/dev/null); then
        
        echo ""
        echo -e "${PURPLE}🤖 AI Recommendations:${NC}"
        echo -e "${CYAN}$ai_response${NC}"
        echo ""
    else
        log_debug "AI analysis failed or API key invalid"
    fi
}

# Update mechanism
update_script() {
    log_info "🔄 Updating precheck scripts..."
    
    if ! command_exists curl; then
        log_error "curl is required for updates"
        return 1
    fi
    
    local temp_dir
    temp_dir=$(mktemp -d)
    
    log_info "Downloading latest version..."
    if curl -fsSL "$INSTALL_URL" -o "$temp_dir/install.sh"; then
        chmod +x "$temp_dir/install.sh"
        log_info "Running installer..."
        bash "$temp_dir/install.sh"
        log_success "✅ Update completed!"
    else
        log_error "❌ Failed to download update"
        rm -rf "$temp_dir"
        return 1
    fi
    
    rm -rf "$temp_dir"
}

# Main execution function
run_precheck() {
    # Performance profiling
    performance_profiler
    
    # Enhanced detection
    if ! enhanced_project_detection; then
        return 1
    fi
    
    # AI analysis
    ai_project_analysis
    
    # Check if specific script exists
    local script_path="$SCRIPT_DIR/$DETECTED_SCRIPT_NAME"
    if [ ! -f "$script_path" ]; then
        log_error "❌ Script not found: $script_path"
        log_info "💡 Try running with --install to set up missing components"
        return 1
    fi
    
    # Make executable if needed
    if [ ! -x "$script_path" ]; then
        log_info "Making $DETECTED_SCRIPT_NAME executable..."
        chmod +x "$script_path"
    fi
    
    log_info "🚀 Running $DETECTED_PROJECT_TYPE pre-deployment checks..."
    echo ""
    
    # Execute the appropriate script with all arguments
    if [ "$BETA_MODE" = "true" ]; then
        export PRECHECK_BETA="true"
        export PRECHECK_EXPERIMENTAL="$ENABLE_EXPERIMENTAL"
    fi
    
    exec "$script_path" "$@"
}

# Show help
show_help() {
    cat << EOF
${CYAN}$SCRIPT_NAME v$VERSION${NC}

Automatically detects your project type and runs appropriate pre-deployment checks.

${YELLOW}Usage:${NC}
  $0 [options]

${YELLOW}Options:${NC}
  -h, --help           Show this help message
  -v, --version        Show version information
  --beta               Enable beta mode with experimental features
  --debug              Enable debug mode with verbose logging
  --install            Smart install missing dependencies
  --update             Update to latest version
  --config             Show current configuration
  --reset-config       Reset configuration to defaults

${YELLOW}Environment Variables:${NC}
  PRECHECK_BETA        Enable beta mode (true/false)
  PRECHECK_EXPERIMENTAL Enable experimental features (true/false)
  PRECHECK_DEBUG       Enable debug logging (true/false)
  OPENAI_API_KEY      Enable AI-powered analysis

${YELLOW}Beta Features:${NC}
  🤖 AI-powered project analysis
  📊 Performance profiling
  🎯 Enhanced project detection
  ⚡ Smart dependency installation
  🔄 Automatic updates

${YELLOW}Supported Projects:${NC}
  • Elixir projects (detected by mix.exs)
  • Node.js projects (detected by package.json)

${YELLOW}Examples:${NC}
  # Basic usage
  $0

  # Enable beta features
  $0 --beta

  # Install dependencies automatically
  $0 --install

  # With AI feedback
  export OPENAI_API_KEY="your-api-key"
  $0 --beta

${YELLOW}Configuration File:${NC}
  Location: $CONFIG_FILE

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
                echo -e "${CYAN}$SCRIPT_NAME v$VERSION${NC}"
                exit 0
                ;;
            --beta)
                export BETA_MODE="true"
                export PRECHECK_BETA="true"
                shift
                ;;
            --debug)
                export DEBUG_MODE="true"
                export PRECHECK_DEBUG="true"
                shift
                ;;
            --experimental)
                export ENABLE_EXPERIMENTAL="true"
                export PRECHECK_EXPERIMENTAL="true"
                shift
                ;;
            --install)
                smart_install_dependencies
                exit $?
                ;;
            --update)
                update_script
                exit $?
                ;;
            --config)
                echo -e "${CYAN}Current Configuration:${NC}"
                cat "$CONFIG_FILE" 2>/dev/null || echo "No configuration file found"
                exit 0
                ;;
            --reset-config)
                rm -f "$CONFIG_FILE"
                log_success "✅ Configuration reset"
                exit 0
                ;;
            *)
                # Pass unknown arguments to the specific script
                break
                ;;
        esac
    done
}

# Main execution
main() {
    # Parse arguments first
    parse_args "$@"
    
    # Load configuration
    load_config
    
    # Show banner
    show_banner
    
    # Check for updates (if enabled)
    check_for_updates
    
    # Save current configuration
    save_config
    
    # Run the main precheck process
    run_precheck "$@"
}

# Execute main function
main "$@"
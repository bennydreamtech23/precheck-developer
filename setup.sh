#!/usr/bin/env bash

set -euo pipefail

# Version and metadata
SETUP_VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="$HOME/.precheck_config"
BETA_MODE="${PRECHECK_BETA:-false}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

# Progress tracking
TOTAL_STEPS=12
CURRENT_STEP=0

# System information
SYSTEM_INFO=""
MISSING_DEPS=()
INSTALLED_TOOLS=()

log_step() {
    CURRENT_STEP=$((CURRENT_STEP + 1))
    echo -e "${CYAN}[$CURRENT_STEP/$TOTAL_STEPS] $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_debug() {
    if [ "${PRECHECK_DEBUG:-false}" = "true" ]; then
        echo -e "${PURPLE}[DEBUG] $1${NC}" >&2
    fi
}

show_banner() {
    if [ "$BETA_MODE" = "true" ]; then
        cat << 'EOF'
   ____                  __               __      ____       __        
  / __ \_________  _____/ /_  ___  _____/ /__   / __ )___  / /_____ _ 
 / /_/ / ___/ _ \/ ___/ __ \/ _ \/ ___/ //_/   / __  / _ \/ __/ __ `/ 
/ ____/ /  /  __/ /__/ / / /  __/ /__/ ,<     / /_/ /  __/ /_/ /_/ /  
/_/   /_/   \___/\___/_/ /_/\___/\___/_/|_|   /_____/\___/\__/\__,_/   
EOF
    else
        cat << 'EOF'
   ____                  __               __  
  / __ \_________  _____/ /_  ___  _____/ /__
 / /_/ / ___/ _ \/ ___/ __ \/ _ \/ ___/ //_/
/ ____/ /  /  __/ /__/ / / /  __/ /__/ ,<   
/_/   /_/   \___/\___/_/ /_/\___/\___/_/|_|  
EOF
    fi
    
    echo ""
    local mode_text=""
    if [ "$BETA_MODE" = "true" ]; then
        mode_text="${PURPLE} [BETA SETUP] ${NC}"
    fi
    echo -e "${CYAN}🔧 Enhanced Setup v$SETUP_VERSION$mode_text${NC}"
    echo -e "${CYAN}=====================================${NC}"
    echo ""
}

# Enhanced system detection
detect_system() {
    log_step "Detecting system environment..."
    
    local os arch distro
    
    case "$(uname -s)" in
        Linux*)
            os="Linux"
            if grep -qi microsoft /proc/version 2>/dev/null; then
                SYSTEM_INFO="WSL"
            elif [ -f /etc/alpine-release ]; then
                SYSTEM_INFO="Alpine Linux"
            elif [ -f /etc/debian_version ]; then
                SYSTEM_INFO="Debian/Ubuntu"
                distro=$(lsb_release -si 2>/dev/null || echo "Debian")
            elif [ -f /etc/redhat-release ]; then
                SYSTEM_INFO="RHEL/CentOS/Fedora"
                distro=$(cat /etc/redhat-release | cut -d' ' -f1)
            elif [ -f /etc/arch-release ]; then
                SYSTEM_INFO="Arch Linux"
                distro="Arch"
            else
                SYSTEM_INFO="Linux (Unknown)"
            fi
            ;;
        Darwin*)
            os="macOS"
            SYSTEM_INFO="macOS $(sw_vers -productVersion 2>/dev/null || echo 'Unknown')"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            os="Windows"
            SYSTEM_INFO="Windows (Git Bash/MSYS2)"
            ;;
        *)
            os="Unknown"
            SYSTEM_INFO="Unknown OS: $(uname -s)"
            ;;
    esac
    
    case "$(uname -m)" in
        x86_64|amd64) arch="x64" ;;
        arm64|aarch64) arch="arm64" ;;
        armv7*) arch="armv7" ;;
        i386|i686) arch="x86" ;;
        *) arch="unknown" ;;
    esac
    
    export DETECTED_OS="$os"
    export DETECTED_ARCH="$arch"
    export SYSTEM_DISTRO="${distro:-unknown}"
    
    log_info "System: $SYSTEM_INFO ($arch)"
    log_debug "OS: $os, Arch: $arch, Distro: ${distro:-unknown}"
}

# Enhanced command checking with version detection
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

get_command_version() {
    local cmd="$1"
    case "$cmd" in
        node)
            node --version 2>/dev/null | sed 's/v//'
            ;;
        npm)
            npm --version 2>/dev/null
            ;;
        elixir)
            elixir --version 2>/dev/null | head -1 | grep -o 'Elixir [0-9][^ ]*' | cut -d' ' -f2
            ;;
        mix)
            mix --version 2>/dev/null | head -1 | grep -o 'Mix [0-9][^ ]*' | cut -d' ' -f2
            ;;
        git)
            git --version 2>/dev/null | cut -d' ' -f3
            ;;
        curl)
            curl --version 2>/dev/null | head -1 | cut -d' ' -f2
            ;;
        jq)
            jq --version 2>/dev/null | sed 's/jq-//'
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Comprehensive prerequisite checking
check_prerequisites() {
    log_step "Checking system prerequisites..."
    
    local essential_commands=("curl" "chmod" "mkdir" "ln")
    local recommended_commands=("git" "jq" "wget")
    local dev_commands=("node" "npm" "elixir" "mix")
    
    # Check essential commands
    log_info "Checking essential tools..."
    for cmd in "${essential_commands[@]}"; do
        if command_exists "$cmd"; then
            local version=$(get_command_version "$cmd")
            log_success "$cmd ($version)"
            INSTALLED_TOOLS+=("$cmd:$version")
        else
            log_error "$cmd is missing (required)"
            MISSING_DEPS+=("$cmd")
        fi
    done
    
    # Check recommended commands
    log_info "Checking recommended tools..."
    for cmd in "${recommended_commands[@]}"; do
        if command_exists "$cmd"; then
            local version=$(get_command_version "$cmd")
            log_success "$cmd ($version)"
            INSTALLED_TOOLS+=("$cmd:$version")
        else
            log_warn "$cmd is missing (recommended)"
            if [ "$BETA_MODE" = "true" ]; then
                MISSING_DEPS+=("$cmd")
            fi
        fi
    done
    
    # Check development tools
    log_info "Checking development environments..."
    for cmd in "${dev_commands[@]}"; do
        if command_exists "$cmd"; then
            local version=$(get_command_version "$cmd")
            log_success "$cmd ($version)"
            INSTALLED_TOOLS+=("$cmd:$version")
        else
            log_info "$cmd not found (will install if needed)"
        fi
    done
    
    # System-specific checks
    case "$DETECTED_OS" in
        Linux)
            if [ ! -w "/usr/local/bin" ]; then
                log_info "Will require sudo for global installation"
                export NEEDS_SUDO="true"
            fi
            ;;
        Darwin)
            if ! command_exists brew; then
                log_warn "Homebrew not found - some auto-installation features disabled"
            fi
            ;;
    esac
}

# Enhanced script setup with validation
setup_scripts() {
    log_step "Setting up executable scripts..."
    
    local scripts=(
        "universal_precheck.sh:Universal precheck script"
        "elixir_precheck.sh:Elixir project validation"
        "nodejs_precheck.sh:Node.js project validation"
        "setup.sh:Setup script"
    )
    
    for script_info in "${scripts[@]}"; do
        local script_name="${script_info%%:*}"
        local description="${script_info##*:}"
        local script_path="$SCRIPT_DIR/$script_name"
        
        if [ -f "$script_path" ]; then
            if [ -x "$script_path" ]; then
                log_success "$script_name ($description) - already executable"
            else
                chmod +x "$script_path"
                if [ -x "$script_path" ]; then
                    log_success "$script_name ($description) - made executable"
                else
                    log_error "Failed to make $script_name executable"
                fi
            fi
            
            # Validate script syntax (beta feature)
            if [ "$BETA_MODE" = "true" ]; then
                if bash -n "$script_path" 2>/dev/null; then
                    log_debug "$script_name - syntax validation passed"
                else
                    log_warn "$script_name - syntax validation failed"
                fi
            fi
        else
            log_error "$script_name not found at $script_path"
        fi
    done
}

# Smart dependency installation
install_missing_dependencies() {
    log_step "Installing missing dependencies..."
    
    if [ ${#MISSING_DEPS[@]} -eq 0 ]; then
        log_success "No missing dependencies to install"
        return 0
    fi
    
    log_info "Installing missing dependencies: ${MISSING_DEPS[*]}"
    
    case "$DETECTED_OS" in
        Linux)
            if command_exists apt-get; then
                log_info "Using apt-get package manager..."
                sudo apt-get update -qq || log_warn "Failed to update package list"
                for dep in "${MISSING_DEPS[@]}"; do
                    # Map command names to package names
                    local package_name="$dep"
                    case "$dep" in
                        jq) package_name="jq" ;;
                        curl) package_name="curl" ;;
                        git) package_name="git" ;;
                        wget) package_name="wget" ;;
                    esac
                    
                    if sudo apt-get install -y "$package_name"; then
                        log_success "Installed $dep"
                    else
                        log_warn "Failed to install $dep"
                    fi
                done
            elif command_exists yum; then
                log_info "Using yum package manager..."
                for dep in "${MISSING_DEPS[@]}"; do
                    sudo yum install -y "$dep" && log_success "Installed $dep" || log_warn "Failed to install $dep"
                done
            elif command_exists pacman; then
                log_info "Using pacman package manager..."
                for dep in "${MISSING_DEPS[@]}"; do
                    sudo pacman -S --noconfirm "$dep" && log_success "Installed $dep" || log_warn "Failed to install $dep"
                done
            else
                log_warn "No supported package manager found"
                log_info "Please install manually: ${MISSING_DEPS[*]}"
            fi
            ;;
        Darwin)
            if command_exists brew; then
                log_info "Using Homebrew package manager..."
                for dep in "${MISSING_DEPS[@]}"; do
                    brew install "$dep" && log_success "Installed $dep" || log_warn "Failed to install $dep"
                done
            else
                log_warn "Homebrew not available"
                log_info "Install Homebrew: https://brew.sh/"
                log_info "Then install: ${MISSING_DEPS[*]}"
            fi
            ;;
        *)
            log_warn "Automatic installation not supported on $DETECTED_OS"
            log_info "Please install manually: ${MISSING_DEPS[*]}"
            ;;
    esac
}

# Project type detection and setup
setup_project_environments() {
    log_step "Setting up project environments..."
    
    local current_dir="$(pwd)"
    local project_types=()
    
    # Enhanced project detection
    if [ -f "mix.exs" ]; then
        project_types+=("Elixir")
        setup_elixir_environment
    fi
    
    if [ -f "package.json" ]; then
        project_types+=("Node.js")
        setup_nodejs_environment
    fi
    
    if [ ${#project_types[@]} -eq 0 ]; then
        log_info "No project files detected in current directory"
        log_info "Project-specific setup will run when you use precheck in a project directory"
    else
        log_success "Detected project types: ${project_types[*]}"
    fi
}

setup_elixir_environment() {
    log_info "Setting up Elixir environment..."
    
    if ! command_exists elixir; then
        log_info "Elixir not found - installation will be offered when needed"
        return 0
    fi
    
    local elixir_version=$(get_command_version elixir)
    log_info "Found Elixir $elixir_version"
    
    # Install Hex if not present
    if ! mix local.hex --if-missing >/dev/null 2>&1; then
        log_info "Installing Hex package manager..."
        mix local.hex --force
    fi
    
    # Install useful archives in beta mode
    if [ "$BETA_MODE" = "true" ]; then
        log_info "Installing Elixir development tools..."
        
        # Install Sobelow for security analysis
        if ! mix help sobelow >/dev/null 2>&1; then
            mix archive.install hex sobelow --force 2>/dev/null || log_debug "Failed to install sobelow"
        fi
        
        # Install Credo for code analysis
        if ! mix help credo >/dev/null 2>&1; then
            mix archive.install hex credo --force 2>/dev/null || log_debug "Failed to install credo"
        fi
    fi
    
    log_success "Elixir environment configured"
}

setup_nodejs_environment() {
    log_info "Setting up Node.js environment..."
    
    if ! command_exists node; then
        log_info "Node.js not found - installation will be offered when needed"
        return 0
    fi
    
    local node_version=$(get_command_version node)
    local npm_version=$(get_command_version npm)
    log_info "Found Node.js $node_version, npm $npm_version"
    
    # Check for package.json and install dependencies
    if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
        log_info "Installing Node.js dependencies..."
        npm install
    fi
    
    # Install global tools in beta mode
    if [ "$BETA_MODE" = "true" ]; then
        log_info "Installing Node.js development tools..."
        
        # Check and install useful global packages
        local global_tools=("eslint" "prettier" "@typescript-eslint/parser")
        for tool in "${global_tools[@]}"; do
            if ! npm list -g "$tool" >/dev/null 2>&1; then
                npm install -g "$tool" 2>/dev/null || log_debug "Failed to install $tool globally"
            fi
        done
    fi
    
    log_success "Node.js environment configured"
}

# Enhanced configuration creation
create_configuration() {
    log_step "Creating configuration files..."
    
    # Create main configuration
    cat > "$CONFIG_FILE" << EOF
# Precheck Configuration v$SETUP_VERSION
# Generated on $(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Version Information
PRECHECK_VERSION="2.0.0"
SETUP_VERSION="$SETUP_VERSION"

# System Information
DETECTED_OS="$DETECTED_OS"
DETECTED_ARCH="$DETECTED_ARCH"
SYSTEM_DISTRO="$SYSTEM_DISTRO"
SYSTEM_INFO="$SYSTEM_INFO"

# Feature Flags
PRECHECK_BETA=${BETA_MODE}
PRECHECK_EXPERIMENTAL=false
PRECHECK_DEBUG=false
PRECHECK_AUTO_UPDATE=true
PRECHECK_AI_ENABLED=false

# Performance Settings
PRECHECK_PARALLEL=true
PRECHECK_MAX_JOBS=4
PRECHECK_TIMEOUT=300
PRECHECK_MAX_MEMORY=2048M

# Paths
PRECHECK_INSTALL_DIR="$SCRIPT_DIR"
PRECHECK_CONFIG_FILE="$CONFIG_FILE"

# Statistics
INSTALL_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
LAST_UPDATE_CHECK=0
USAGE_COUNT=0

# Installed Tools
EOF
    
    # Add installed tools to config
    for tool_info in "${INSTALLED_TOOLS[@]}"; do
        local tool_name="${tool_info%%:*}"
        local tool_version="${tool_info##*:}"
        echo "INSTALLED_${tool_name^^}_VERSION=\"$tool_version\"" >> "$CONFIG_FILE"
    done
    
    log_success "Configuration created at $CONFIG_FILE"
    
    # Create project-specific config template
    if [ "$BETA_MODE" = "true" ]; then
        create_project_config_template
    fi
}

create_project_config_template() {
    local template_file="$SCRIPT_DIR/.precheck.yml.template"
    
    cat > "$template_file" << 'EOF'
# Precheck Project Configuration Template
# Copy this file to your project root as .precheck.yml

version: "2.0"

# Enable/disable specific checks
checks:
  dependencies: true
  security: true
  formatting: true
  testing: true
  performance: true
  documentation: true

# Performance thresholds
thresholds:
  test_coverage: 80
  build_time_ms: 30000
  security_severity: medium
  max_dependencies: 100

# Files and directories to ignore
ignore:
  - "deps/phoenix_live_reload"
  - "node_modules/@types"
  - "*.min.js"
  - "build/"
  - "dist/"

# AI configuration (requires API key)
ai:
  enabled: false
  model: "gpt-3.5-turbo"
  analysis_depth: "standard"  # basic, standard, comprehensive
  
# Notification settings
notifications:
  slack_webhook: ""
  email: ""
  teams_webhook: ""

# Custom commands
custom_commands:
  pre_check: ""
  post_check: ""
  on_failure: ""
  on_success: ""
EOF
    
    log_info "Created project config template at $template_file"
}

# Performance testing and validation
run_performance_tests() {
    log_step "Running performance validation..."
    
    if [ "$BETA_MODE" != "true" ]; then
        log_info "Performance testing skipped (not in beta mode)"
        return 0
    fi
    
    local test_start=$(date +%s%N)
    
    # Test script execution speed
    log_info "Testing script execution performance..."
    
    if [ -x "$SCRIPT_DIR/universal_precheck.sh" ]; then
        local script_start=$(date +%s%N)
        "$SCRIPT_DIR/universal_precheck.sh" --version >/dev/null 2>&1
        local script_end=$(date +%s%N)
        local script_duration=$(( (script_end - script_start) / 1000000 ))
        log_info "Script startup time: ${script_duration}ms"
        
        if [ $script_duration -gt 5000 ]; then
            log_warn "Script startup is slow (>5s)"
        else
            log_success "Script startup performance is good"
        fi
    fi
    
    # Test system performance
    local available_memory=$(free -m 2>/dev/null | awk 'NR==2{print $7}' || echo "unknown")
    local cpu_cores=$(nproc 2>/dev/null || echo "unknown")
    
    log_info "System resources: ${available_memory}MB available memory, $cpu_cores CPU cores"
    
    local test_end=$(date +%s%N)
    local total_duration=$(( (test_end - test_start) / 1000000 ))
    log_success "Performance validation completed in ${total_duration}ms"
}

# Global access setup with multiple methods
setup_global_access() {
    log_step "Setting up global access..."
    
    local precheck_script="$SCRIPT_DIR/universal_precheck.sh"
    local methods_tried=()
    
    # Method 1: Symlink to /usr/local/bin
    if [ -w "/usr/local/bin" ]; then
        if ln -sf "$precheck_script" "/usr/local/bin/precheck" 2>/dev/null; then
            log_success "Created global symlink: /usr/local/bin/precheck"
            methods_tried+=("symlink")
            return 0
        fi
    fi
    
    # Method 2: Symlink with sudo
    if [ "${NEEDS_SUDO:-false}" = "true" ]; then
        if sudo ln -sf "$precheck_script" "/usr/local/bin/precheck" 2>/dev/null; then
            log_success "Created global symlink with sudo: /usr/local/bin/precheck"
            methods_tried+=("sudo_symlink")
            return 0
        fi
    fi
    
    # Method 3: User bin directory
    local user_bin="$HOME/.local/bin"
    mkdir -p "$user_bin"
    if ln -sf "$precheck_script" "$user_bin/precheck" 2>/dev/null; then
        log_success "Created user symlink: $user_bin/precheck"
        log_info "Make sure $user_bin is in your PATH"
        methods_tried+=("user_symlink")
        return 0
    fi
    
    # Method 4: Shell alias
    log_info "Setting up shell alias..."
    setup_shell_alias
    methods_tried+=("alias")
}

setup_shell_alias() {
    local alias_cmd="alias precheck='$SCRIPT_DIR/universal_precheck.sh'"
    local shell_configs=()
    
    # Detect shell configuration files
    if [ -n "${ZSH_VERSION:-}" ] || [ "$SHELL" = "/bin/zsh" ]; then
        shell_configs+=("$HOME/.zshrc")
    fi
    
    if [ -n "${BASH_VERSION:-}" ] || [ "$SHELL" = "/bin/bash" ]; then
        [ -f "$HOME/.bashrc" ] && shell_configs+=("$HOME/.bashrc")
        [ -f "$HOME/.bash_profile" ] && shell_configs+=("$HOME/.bash_profile")
    fi
    
    # Add generic profile as fallback
    [ -f "$HOME/.profile" ] && shell_configs+=("$HOME/.profile")
    
    # Remove duplicates and non-existent files
    local unique_configs=()
    for config in "${shell_configs[@]}"; do
        if [ -f "$config" ] && ! printf '%s\n' "${unique_configs[@]}" | grep -qx "$config"; then
            unique_configs+=("$config")
        fi
    done
    
    if [ ${#unique_configs[@]} -eq 0 ]; then
        # Create .profile if no config files exist
        echo "$alias_cmd" > "$HOME/.profile"
        log_success "Created alias in new $HOME/.profile"
        log_warn "Please restart your shell or run: source $HOME/.profile"
        return 0
    fi
    
    # Add alias to the most appropriate config file
    local target_config="${unique_configs[0]}"
    
    if ! grep -q "alias precheck=" "$target_config" 2>/dev/null; then
        echo "" >> "$target_config"
        echo "# Precheck tool alias - added by setup script" >> "$target_config"
        echo "$alias_cmd" >> "$target_config"
        log_success "Added alias to $target_config"
        log_warn "Please restart your shell or run: source $target_config"
    else
        log_info "Alias already exists in $target_config"
    fi
}

# Network connectivity and update checking
check_connectivity() {
    log_step "Checking network connectivity..."
    
    local test_urls=(
        "https://raw.githubusercontent.com"
        "https://api.github.com"
        "https://registry.npmjs.org"
        "https://hex.pm"
    )
    
    local connectivity_score=0
    for url in "${test_urls[@]}"; do
        if curl -s --connect-timeout 5 "$url" >/dev/null 2>&1; then
            connectivity_score=$((connectivity_score + 1))
            log_debug "✓ $url accessible"
        else
            log_debug "✗ $url not accessible"
        fi
    done
    
    if [ $connectivity_score -eq 0 ]; then
        log_warn "No internet connectivity detected"
        log_info "Some features may not work without internet access"
        export OFFLINE_MODE="true"
    elif [ $connectivity_score -lt 3 ]; then
        log_warn "Limited internet connectivity ($connectivity_score/4 services accessible)"
        export LIMITED_CONNECTIVITY="true"
    else
        log_success "Internet connectivity confirmed"
        export OFFLINE_MODE="false"
        
        # Check for updates if in beta mode
        if [ "$BETA_MODE" = "true" ]; then
            check_for_updates
        fi
    fi
}

check_for_updates() {
    log_info "Checking for updates..."
    
    local api_url="https://api.github.com/repos/bennydreamtech23/precheck-developer/releases/latest"
    local latest_version
    
    if latest_version=$(curl -s "$api_url" | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4 2>/dev/null); then
        if [ "$latest_version" != "v$SETUP_VERSION" ] && [ -n "$latest_version" ]; then
            log_warn "New version available: $latest_version (current: v$SETUP_VERSION)"
            log_info "Run 'precheck --update' to update to the latest version"
        else
            log_success "Using latest version"
        fi
    else
        log_debug "Could not check for updates"
    fi
}

# Security validation
run_security_checks() {
    log_step "Running security validation..."
    
    # Check script permissions
    local scripts=("$SCRIPT_DIR"/*.sh)
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            local perms=$(stat -c "%a" "$script" 2>/dev/null || stat -f "%A" "$script" 2>/dev/null || echo "unknown")
            if [ "$perms" = "755" ] || [ "$perms" = "744" ]; then
                log_debug "$(basename "$script"): permissions OK ($perms)"
            else
                log_warn "$(basename "$script"): unusual permissions ($perms)"
            fi
        fi
    done
    
    # Check for secure directories
    local secure_dirs=("$HOME/.precheck" "$HOME/.ssh" "$HOME/.gnupg")
    for dir in "${secure_dirs[@]}"; do
        if [ -d "$dir" ]; then
            local perms=$(stat -c "%a" "$dir" 2>/dev/null || stat -f "%A" "$dir" 2>/dev/null || echo "unknown")
            if [ "$perms" = "700" ] || [ "$perms" = "755" ]; then
                log_debug "$dir: permissions OK ($perms)"
            else
                log_warn "$dir: permissions should be more restrictive ($perms)"
            fi
        fi
    done
    
    # Check environment variables for sensitive data
    if [ -n "${OPENAI_API_KEY:-}" ]; then
        if [[ "$OPENAI_API_KEY" =~ ^sk-[a-zA-Z0-9]{48}$ ]]; then
            log_success "OpenAI API key format appears valid"
        else
            log_warn "OpenAI API key format appears invalid"
        fi
    fi
    
    log_success "Security validation completed"
}

# Comprehensive validation and testing
run_validation_tests() {
    log_step "Running comprehensive validation..."
    
    local test_results=()
    local failed_tests=()
    
    # Test 1: Script syntax validation
    log_info "Validating script syntax..."
    local scripts=("$SCRIPT_DIR"/*.sh)
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if bash -n "$script" 2>/dev/null; then
                test_results+=("$(basename "$script"): syntax OK")
            else
                failed_tests+=("$(basename "$script"): syntax error")
                log_error "Syntax error in $(basename "$script")"
            fi
        fi
    done
    
    # Test 2: Script execution test
    log_info "Testing script execution..."
    if [ -x "$SCRIPT_DIR/universal_precheck.sh" ]; then
        if "$SCRIPT_DIR/universal_precheck.sh" --version >/dev/null 2>&1; then
            test_results+=("universal_precheck.sh: execution OK")
        else
            failed_tests+=("universal_precheck.sh: execution failed")
            log_error "Failed to execute universal_precheck.sh"
        fi
    fi
    
    # Test 3: Configuration file validation
    log_info "Validating configuration..."
    if [ -f "$CONFIG_FILE" ]; then
        if bash -n "$CONFIG_FILE" 2>/dev/null; then
            test_results+=("configuration: syntax OK")
        else
            failed_tests+=("configuration: syntax error")
            log_error "Configuration file has syntax errors"
        fi
    fi
    
    # Test 4: Dependency availability
    log_info "Testing dependency availability..."
    local critical_deps=("curl" "chmod")
    for dep in "${critical_deps[@]}"; do
        if command_exists "$dep"; then
            test_results+=("$dep: available")
        else
            failed_tests+=("$dep: missing")
            log_error "Critical dependency missing: $dep"
        fi
    done
    
    # Report results
    if [ ${#failed_tests[@]} -eq 0 ]; then
        log_success "All validation tests passed (${#test_results[@]} tests)"
    else
        log_error "Some validation tests failed:"
        for failure in "${failed_tests[@]}"; do
            echo "  ❌ $failure"
        done
        log_info "Successful tests: ${#test_results[@]}"
    fi
    
    # Beta feature: Generate validation report
    if [ "$BETA_MODE" = "true" ]; then
        generate_validation_report "${test_results[@]}" "${failed_tests[@]}"
    fi
}

generate_validation_report() {
    local report_file="$SCRIPT_DIR/setup_validation_report.txt"
    
    cat > "$report_file" << EOF
# Precheck Setup Validation Report
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Setup Version: $SETUP_VERSION
# System: $SYSTEM_INFO

## System Information
- OS: $DETECTED_OS
- Architecture: $DETECTED_ARCH
- Distribution: $SYSTEM_DISTRO
- Beta Mode: $BETA_MODE

## Installed Tools
EOF
    
    for tool_info in "${INSTALLED_TOOLS[@]}"; do
        echo "- ${tool_info//:/ version }" >> "$report_file"
    done
    
    echo "" >> "$report_file"
    echo "## Validation Results" >> "$report_file"
    
    while [ $# -gt 0 ]; do
        if [[ "$1" =~ "OK" ]]; then
            echo "✅ $1" >> "$report_file"
        else
            echo "❌ $1" >> "$report_file"
        fi
        shift
    done
    
    echo "" >> "$report_file"
    echo "## Configuration Location" >> "$report_file"
    echo "$CONFIG_FILE" >> "$report_file"
    
    log_info "Validation report saved to $report_file"
}

# Final setup summary and next steps
show_setup_summary() {
    echo ""
    echo -e "${CYAN}🎉 Setup Complete!${NC}"
    echo -e "${CYAN}==================${NC}"
    echo ""
    
    # System summary
    echo -e "${BLUE}📋 System Summary${NC}"
    echo -e "   OS: $SYSTEM_INFO"
    echo -e "   Architecture: $DETECTED_ARCH"
    echo -e "   Beta Mode: ${BETA_MODE}"
    echo -e "   Scripts Location: $SCRIPT_DIR"
    echo -e "   Configuration: $CONFIG_FILE"
    echo ""
    
    # Installed tools summary
    if [ ${#INSTALLED_TOOLS[@]} -gt 0 ]; then
        echo -e "${GREEN}✅ Installed Tools${NC}"
        for tool_info in "${INSTALLED_TOOLS[@]}"; do
            local tool_name="${tool_info%%:*}"
            local tool_version="${tool_info##*:}"
            echo -e "   $tool_name ($tool_version)"
        done
        echo ""
    fi
    
    # Usage instructions
    echo -e "${YELLOW}🚀 Quick Start${NC}"
    echo -e "   1. Navigate to your project directory"
    echo -e "   2. Run: ${CYAN}precheck${NC}"
    echo -e "   3. Review the generated report"
    echo ""
    
    # Advanced features
    if [ "$BETA_MODE" = "true" ]; then
        echo -e "${PURPLE}🧪 Beta Features Available${NC}"
        echo -e "   ${CYAN}precheck --beta${NC}           Enable all beta features"
        echo -e "   ${CYAN}precheck --install${NC}        Auto-install dependencies"
        echo -e "   ${CYAN}precheck --update${NC}         Update to latest version"
        echo ""
    fi
    
    # AI features
    if [ -n "${OPENAI_API_KEY:-}" ]; then
        echo -e "${GREEN}🤖 AI Features Ready${NC}"
        echo -e "   OpenAI API key detected - AI analysis available"
    else
        echo -e "${YELLOW}💡 Enable AI Features${NC}"
        echo -e "   export OPENAI_API_KEY='your-api-key'"
        echo -e "   precheck --beta"
    fi
    echo ""
    
    # Troubleshooting
    echo -e "${BLUE}🔧 Troubleshooting${NC}"
    echo -e "   Help: ${CYAN}precheck --help${NC}"
    echo -e "   Debug: ${CYAN}PRECHECK_DEBUG=true precheck${NC}"
    echo -e "   Config: ${CYAN}precheck --config${NC}"
    echo ""
    
    # Next steps
    echo -e "${CYAN}📚 Resources${NC}"
    echo -e "   Documentation: https://github.com/bennydreamtech23/precheck-developer#readme"
    echo -e "   Issues: https://github.com/bennydreamtech23/precheck-developer/issues"
    echo -e "   Configuration: $CONFIG_FILE"
    echo ""
    
    log_success "Setup completed successfully! 🎉"
}

# Cleanup function
cleanup_on_exit() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo ""
        log_error "Setup failed with exit code $exit_code"
        log_info "Check the error messages above for details"
        
        # Offer to create a debug report
        if [ "$BETA_MODE" = "true" ]; then
            echo ""
            echo -e "${YELLOW}Create debug report? (y/n): ${NC}"
            read -r create_debug
            if [ "$create_debug" = "y" ] || [ "$create_debug" = "Y" ]; then
                create_debug_report
            fi
        fi
    fi
}

create_debug_report() {
    local debug_file="$SCRIPT_DIR/setup_debug_report.txt"
    
    cat > "$debug_file" << EOF
# Precheck Setup Debug Report
# Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")
# Exit Code: $?

## System Information
$(uname -a)

## Environment Variables
$(env | grep -E '^(PRECHECK_|PATH|SHELL|HOME)' | sort)

## Installed Tools
EOF
    
    local tools=("curl" "git" "jq" "node" "npm" "elixir" "mix")
    for tool in "${tools[@]}"; do
        if command_exists "$tool"; then
            echo "$tool: $(get_command_version "$tool")" >> "$debug_file"
        else
            echo "$tool: not found" >> "$debug_file"
        fi
    done
    
    echo "" >> "$debug_file"
    echo "## Script Directory Contents" >> "$debug_file"
    ls -la "$SCRIPT_DIR" >> "$debug_file" 2>&1
    
    echo "" >> "$debug_file"
    echo "## Recent Setup Log" >> "$debug_file"
    echo "Check the terminal output above for detailed error messages." >> "$debug_file"
    
    log_info "Debug report created: $debug_file"
    log_info "Please include this file when reporting issues"
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --beta)
                export BETA_MODE="true"
                export PRECHECK_BETA="true"
                shift
                ;;
            --debug)
                export PRECHECK_DEBUG="true"
                shift
                ;;
            --force)
                export FORCE_SETUP="true"
                shift
                ;;
            --offline)
                export OFFLINE_MODE="true"
                shift
                ;;
            --skip-deps)
                export SKIP_DEPENDENCIES="true"
                shift
                ;;
            *)
                log_warn "Unknown option: $1"
                shift
                ;;
        esac
    done
}

show_help() {
    cat << EOF
${CYAN}Enhanced Setup Script v$SETUP_VERSION${NC}

Prepares the precheck development environment with comprehensive validation
and optional beta features.

${YELLOW}Usage:${NC}
  $0 [options]

${YELLOW}Options:${NC}
  -h, --help       Show this help message
  --beta           Enable beta features and experimental functionality
  --debug          Enable debug logging and verbose output
  --force          Force setup even if already configured
  --offline        Skip network-dependent features
  --skip-deps      Skip automatic dependency installation

${YELLOW}Beta Features:${NC}
  🤖 AI-powered project analysis
  📊 Performance profiling and monitoring
  🔧 Smart dependency management
  🔄 Automatic update checking
  📋 Comprehensive validation reporting

${YELLOW}What This Script Does:${NC}
  1. Detects your system environment and capabilities
  2. Validates and installs required dependencies
  3. Configures all precheck scripts with proper permissions
  4. Sets up global access (symlinks or shell aliases)
  5. Creates configuration files and templates
  6. Runs comprehensive validation tests
  7. Configures development environment integrations

${YELLOW}After Setup:${NC}
  • Run 'precheck' from any project directory
  • Use 'precheck --help' for all available options
  • Check '$CONFIG_FILE' for configuration
  • Enable AI features with OPENAI_API_KEY environment variable

${YELLOW}Examples:${NC}
  $0                    # Standard setup
  $0 --beta             # Setup with beta features
  $0 --debug --force    # Debug mode with forced reinstall

EOF
}

# Main execution function
main() {
    # Set up cleanup trap
    trap cleanup_on_exit EXIT
    
    # Parse command line arguments
    parse_arguments "$@"
    
    # Show banner
    show_banner
    
    # Run all setup steps
    detect_system
    check_prerequisites
    
    if [ "${SKIP_DEPENDENCIES:-false}" != "true" ]; then
        install_missing_dependencies
    fi
    
    setup_scripts
    setup_project_environments
    create_configuration
    
    if [ "${OFFLINE_MODE:-false}" != "true" ]; then
        check_connectivity
    fi
    
    run_performance_tests
    setup_global_access
    run_security_checks
    run_validation_tests
    
    # Show completion summary
    show_setup_summary
    
    # Update last setup time in config
    if [ -f "$CONFIG_FILE" ]; then
        echo "LAST_SETUP_DATE=\"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\"" >> "$CONFIG_FILE"
    fi
}

# Execute main function with all arguments
main "$@"
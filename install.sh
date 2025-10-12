#!/usr/bin/env bash
set -euo pipefail

# Precheck Installer v1.0.0-beta
VERSION="1.0.0-beta"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Installation paths
INSTALL_DIR="$HOME/.precheck"
CONFIG_FILE="$HOME/.precheck_config"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Banner
show_banner() {
    cat << 'EOF'
    ____                  __               __  
   / __ \_________  _____/ /_  ___  _____/ /__
  / /_/ / ___/ _ \/ ___/ __ \/ _ \/ ___/ //_/
 / ____/ /  /  __/ /__/ / / /  __/ /__/ ,<   
/_/   /_/   \___/\___/_/ /_/\___/\___/_/|_|  
                                              
EOF
    echo -e "${CYAN}Developer Precheck Installer v$VERSION${NC}"
    echo ""
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect operating system
detect_system() {
    log_info "Detecting system..."
    
    case "$(uname -s)" in
        Linux*)
            OS="Linux"
            if grep -qi microsoft /proc/version 2>/dev/null; then
                OS="WSL"
            fi
            ;;
        Darwin*)
            OS="macOS"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            OS="Windows"
            ;;
        *)
            OS="Unknown"
            ;;
    esac
    
    log_success "Detected OS: $OS"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing_deps=()
    
    # Essential commands
    for cmd in curl chmod mkdir; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    # Recommended commands
    if ! command_exists git; then
        log_warn "git not found (recommended)"
    fi
    
    if ! command_exists jq; then
        log_warn "jq not found (recommended)"
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        echo ""
        echo "Install missing dependencies:"
        case "$OS" in
            Linux|WSL)
                echo "  sudo apt-get install -y ${missing_deps[*]}"
                ;;
            macOS)
                echo "  brew install ${missing_deps[*]}"
                ;;
            *)
                echo "  Please install: ${missing_deps[*]}"
                ;;
        esac
        exit 1
    fi
    
    log_success "All prerequisites met"
}

# Check if running from local repo or remote install
detect_install_source() {
    if [ -f "universal_precheck.sh" ] && [ -f "elixir_precheck.sh" ] && [ -f "nodejs_precheck.sh" ]; then
        INSTALL_SOURCE="local"
        log_info "Installing from local repository"
    else
        INSTALL_SOURCE="remote"
        log_info "Installing from remote repository"
    fi
}

# Download scripts from GitHub
download_scripts() {
    log_info "Downloading precheck scripts..."
    
    mkdir -p "$INSTALL_DIR"
    
    local base_url="https://raw.githubusercontent.com/bennydreamtech23/precheck-developer/main"
    local scripts=(
        "universal_precheck.sh"
        "elixir_precheck.sh"
        "nodejs_precheck.sh"
        "check_secrets.sh"
    )
    
    for script in "${scripts[@]}"; do
        log_info "Downloading $script..."
        if curl -fsSL "$base_url/$script" -o "$INSTALL_DIR/$script" 2>/dev/null; then
            chmod +x "$INSTALL_DIR/$script"
            log_success "$script installed"
        else
            log_error "Failed to download $script"
            log_info "Please check your internet connection or try manual installation"
            exit 1
        fi
    done
}

# Copy scripts from local repository
copy_local_scripts() {
    log_info "Installing from local repository..."
    
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    mkdir -p "$INSTALL_DIR"
    
    local scripts=(
        "universal_precheck.sh"
        "elixir_precheck.sh"
        "nodejs_precheck.sh"
        "check_secrets.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$script_dir/$script" ]; then
            log_info "Installing $script..."
            cp "$script_dir/$script" "$INSTALL_DIR/$script"
            chmod +x "$INSTALL_DIR/$script"
            log_success "$script installed"
        else
            log_warn "$script not found, skipping"
        fi
    done
}

# Create configuration file
create_config() {
    log_info "Creating configuration..."
    
    cat > "$CONFIG_FILE" << EOF
# Precheck Configuration v$VERSION
# Generated on $(date -u +"%Y-%m-%dT%H:%M:%SZ")

PRECHECK_VERSION="$VERSION"
PRECHECK_INSTALL_DIR="$INSTALL_DIR"
PRECHECK_DEBUG=false
INSTALL_DATE="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
INSTALL_SOURCE="$INSTALL_SOURCE"
OS="$OS"
EOF
    
    log_success "Configuration created at $CONFIG_FILE"
}

# Setup global command access
setup_global_command() {
    log_info "Setting up global command..."
    
    local precheck_script="$INSTALL_DIR/universal_precheck.sh"
    
    # Try /usr/local/bin (preferred)
    if [ -w "/usr/local/bin" ] 2>/dev/null; then
        if ln -sf "$precheck_script" "/usr/local/bin/precheck" 2>/dev/null; then
            log_success "Global command created: /usr/local/bin/precheck"
            return 0
        fi
    fi
    
    # Try with sudo
    if command_exists sudo && [ "$OS" != "Windows" ]; then
        log_info "Attempting to create global command with sudo..."
        if sudo ln -sf "$precheck_script" "/usr/local/bin/precheck" 2>/dev/null; then
            log_success "Global command created: /usr/local/bin/precheck"
            return 0
        fi
    fi
    
    # Fallback to user bin directory
    local user_bin="$HOME/.local/bin"
    mkdir -p "$user_bin"
    
    if ln -sf "$precheck_script" "$user_bin/precheck" 2>/dev/null; then
        log_success "User command created: $user_bin/precheck"
        
        # Check if in PATH
        if [[ ":$PATH:" != *":$user_bin:"* ]]; then
            log_warn "$user_bin is not in your PATH"
            echo ""
            echo "Add to your shell configuration (~/.bashrc or ~/.zshrc):"
            echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
            echo ""
        fi
        return 0
    fi
    
    # Final fallback: shell alias
    log_warn "Could not create global command"
    setup_shell_alias
}

# Setup shell alias as fallback
setup_shell_alias() {
    log_info "Setting up shell alias..."
    
    local alias_line="alias precheck='$INSTALL_DIR/universal_precheck.sh'"
    local shell_rc=""
    
    # Detect shell configuration file
    if [ -n "${ZSH_VERSION:-}" ] || [ "$SHELL" = "/bin/zsh" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "${BASH_VERSION:-}" ] || [ "$SHELL" = "/bin/bash" ]; then
        if [ -f "$HOME/.bashrc" ]; then
            shell_rc="$HOME/.bashrc"
        else
            shell_rc="$HOME/.bash_profile"
        fi
    else
        shell_rc="$HOME/.profile"
    fi
    
    # Add alias if not already present
    if [ -f "$shell_rc" ]; then
        if ! grep -q "alias precheck=" "$shell_rc" 2>/dev/null; then
            echo "" >> "$shell_rc"
            echo "# Precheck alias - added by installer" >> "$shell_rc"
            echo "$alias_line" >> "$shell_rc"
            log_success "Alias added to $shell_rc"
            echo ""
            log_warn "Run: source $shell_rc (or restart your shell)"
        else
            log_info "Alias already exists in $shell_rc"
        fi
    else
        # Create new shell rc file
        echo "$alias_line" > "$shell_rc"
        log_success "Created $shell_rc with precheck alias"
        log_warn "Run: source $shell_rc"
    fi
}

# Show completion message
show_completion() {
    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                ║${NC}"
    echo -e "${GREEN}║     Installation Complete! 🎉                 ║${NC}"
    echo -e "${GREEN}║                                                ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${CYAN}Quick Start:${NC}"
    echo "  1. Navigate to your project directory"
    echo "  2. Run: ${GREEN}precheck${NC}"
    echo "  3. Review the generated report"
    echo ""
    
    echo -e "${CYAN}Available Commands:${NC}"
    echo "  ${GREEN}precheck${NC}          Run automatic project checks"
    echo "  ${GREEN}precheck-elixir --setup{NC}  Run checks with automatic project setup for elixir"
    echo "  ${GREEN}precheck-node --setup{NC}  Run checks with automatic project setup for Nodejs"
    echo "  ${GREEN}precheck --help${NC}   Show help and options"
    echo "  ${GREEN}precheck --debug${NC}  Enable debug mode"
    echo ""
    
    echo -e "${CYAN}Supported Project Types:${NC}"
    echo "  - Elixir (detected by mix.exs)"
    echo "  - Node.js (detected by package.json)"
    echo ""
    
    echo -e "${CYAN}Installation Paths:${NC}"
    echo "  Scripts:  $INSTALL_DIR"
    echo "  Config:   $CONFIG_FILE"
    echo ""
    
    echo -e "${CYAN}Optional Enhancements:${NC}"
    echo "  For additional shell aliases and helpers, run:"
    echo "  ${GREEN}bash $INSTALL_DIR/../shell_integration.sh${NC}"
    echo ""
    
    echo -e "${CYAN}Need Help?${NC}"
    echo "  Docs:   https://github.com/bennydreamtech23/precheck-developer"
    echo "  Issues: https://github.com/bennydreamtech23/precheck-developer/issues"
    echo ""
}

# Main installation flow
main() {
    show_banner
    detect_system
    check_prerequisites
    detect_install_source
    
    # Install scripts based on source
    if [ "$INSTALL_SOURCE" = "local" ]; then
        copy_local_scripts
    else
        download_scripts
    fi
    
    create_config
    setup_global_command
    show_completion
    
    log_success "Installation completed successfully!"
}

# Run installer
main "$@"
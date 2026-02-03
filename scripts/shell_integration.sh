#!/usr/bin/env bash
set -euo pipefail

# Shell Integration Script v1.0.0-beta
VERSION="1.0.0-beta"
INSTALL_DIR="$HOME/.precheck"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

show_banner() {
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Precheck Shell Integration v$VERSION     ║${NC}"
    echo -e "${CYAN}║  Optional Enhancements & Aliases          ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo ""
    log_info "This script adds convenience aliases and helpers to your shell"
    echo ""
}

# Detect available shells
detect_shells() {
    log_info "Detecting shell configurations..."
    
    local configs=()
    
    # Bash
    [ -f "$HOME/.bashrc" ] && configs+=("$HOME/.bashrc:bash")
    [ -f "$HOME/.bash_profile" ] && configs+=("$HOME/.bash_profile:bash")
    
    # Zsh
    [ -f "$HOME/.zshrc" ] && configs+=("$HOME/.zshrc:zsh")
    
    # Fish
    [ -f "$HOME/.config/fish/config.fish" ] && configs+=("$HOME/.config/fish/config.fish:fish")
    
    # Generic
    [ -f "$HOME/.profile" ] && configs+=("$HOME/.profile:generic")
    
    if [ ${#configs[@]} -eq 0 ]; then
        log_warn "No shell configuration files found"
        return 1
    fi
    
    log_success "Found ${#configs[@]} shell configuration(s)"
    echo "${configs[@]}"
}

# Add integration to bash/zsh
add_bash_zsh_integration() {
    local config_file="$1"
    local shell_type="$2"
    
    log_info "Adding integration to $config_file ($shell_type)"
    
    # Check if already integrated
    if grep -q "Precheck shell integration" "$config_file" 2>/dev/null; then
        log_warn "Integration already exists in $config_file"
        return 0
    fi
    
    # Backup
    cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Add integration
    cat >> "$config_file" << EOF

# ============================================
# Precheck shell integration
# Added: $(date)
# ============================================

# Basic aliases
alias precheck='$INSTALL_DIR/universal_precheck.sh'
alias precheck-elixir='$INSTALL_DIR/elixir_precheck.sh'
alias precheck-node='$INSTALL_DIR/nodejs_precheck.sh'
alias precheck-secrets='$INSTALL_DIR/check_secrets.sh'

# Debug mode
alias precheck-debug='PRECHECK_DEBUG=true $INSTALL_DIR/universal_precheck.sh'

# Helper function to show available commands
precheck-help() {
    cat << 'HELP_EOF'
Precheck Commands:
  precheck            - Auto-detect project type and run checks
  precheck-elixir     - Run Elixir-specific checks
  precheck-node       - Run Node.js-specific checks  
  precheck-secrets    - Scan for secrets and sensitive data
  precheck-debug      - Run with debug output enabled
  precheck-report     - View last report
  precheck-clean      - Clean up old reports
HELP_EOF
}

# View last generated report
precheck-report() {
    local reports=(*_report.txt 2>/dev/null)
    if [ \${#reports[@]} -gt 0 ]; then
        local latest=\$(ls -t *_report.txt 2>/dev/null | head -1)
        if [ -n "\$latest" ]; then
            echo "📋 Viewing: \$latest"
            echo "===================="
            cat "\$latest"
        fi
    else
        echo "No reports found. Run 'precheck' first."
    fi
}

# Clean up old reports
precheck-clean() {
    local count=\$(find . -maxdepth 1 -name "*_report.txt" -type f 2>/dev/null | wc -l)
    if [ "\$count" -gt 0 ]; then
        find . -maxdepth 1 -name "*_report.txt" -type f -delete
        echo "✅ Cleaned \$count report file(s)"
    else
        echo "No report files to clean"
    fi
}

EOF

    log_success "Integration added to $config_file"
}

# Add integration to Fish shell
add_fish_integration() {
    local config_file="$1"
    
    log_info "Adding integration to $config_file (fish)"
    
    # Check if already integrated
    if grep -q "Precheck shell integration" "$config_file" 2>/dev/null; then
        log_warn "Integration already exists in $config_file"
        return 0
    fi
    
    # Backup
    cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Add Fish-specific syntax
    cat >> "$config_file" << EOF

# ============================================
# Precheck shell integration
# Added: $(date)
# ============================================

# Basic aliases
alias precheck '$INSTALL_DIR/universal_precheck.sh'
alias precheck-elixir '$INSTALL_DIR/elixir_precheck.sh'
alias precheck-node '$INSTALL_DIR/nodejs_precheck.sh'
alias precheck-secrets '$INSTALL_DIR/check_secrets.sh'
alias precheck-debug 'env PRECHECK_DEBUG=true $INSTALL_DIR/universal_precheck.sh'

# Helper functions
function precheck-help
    echo "Precheck Commands:"
    echo "  precheck            - Auto-detect project type and run checks"
    echo "  precheck-elixir     - Run Elixir-specific checks"
    echo "  precheck-node       - Run Node.js-specific checks"
    echo "  precheck-secrets    - Scan for secrets and sensitive data"
    echo "  precheck-debug      - Run with debug output enabled"
    echo "  precheck-report     - View last report"
    echo "  precheck-clean      - Clean up old reports"
end

function precheck-report
    set reports *_report.txt 2>/dev/null
    if test (count \$reports) -gt 0
        set latest (ls -t *_report.txt 2>/dev/null | head -1)
        if test -n "\$latest"
            echo "📋 Viewing: \$latest"
            echo "===================="
            cat "\$latest"
        end
    else
        echo "No reports found. Run 'precheck' first."
    end
end

function precheck-clean
    set count (find . -maxdepth 1 -name "*_report.txt" -type f 2>/dev/null | wc -l)
    if test \$count -gt 0
        find . -maxdepth 1 -name "*_report.txt" -type f -delete
        echo "✅ Cleaned \$count report file(s)"
    else
        echo "No report files to clean"
    end
end

EOF

    log_success "Integration added to $config_file"
}

# Add development-specific aliases
add_dev_aliases() {
    echo ""
    read -p "Add development workflow aliases? (git shortcuts, mix/npm helpers) [y/N]: " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping development aliases"
        return 0
    fi
    
    log_info "Adding development workflow aliases..."
    
    local shell_configs
    shell_configs=$(detect_shells)
    
    for config_info in $shell_configs; do
        local config_file="${config_info%%:*}"
        local shell_type="${config_info##*:}"
        
        if [ "$shell_type" = "fish" ]; then
            add_fish_dev_aliases "$config_file"
        else
            add_bash_zsh_dev_aliases "$config_file"
        fi
        
        break # Only add to primary shell
    done
    
    log_success "Development aliases added"
}

# Add development aliases for bash/zsh
add_bash_zsh_dev_aliases() {
    local config_file="$1"
    
    cat >> "$config_file" << 'EOF'

# Development workflow aliases
if command -v git >/dev/null 2>&1; then
    alias gs='git status'
    alias ga='git add'
    alias gc='git commit'
    alias gp='git push'
    alias gl='git pull'
    alias gd='git diff'
    alias glog='git log --oneline -10'
fi

if command -v npm >/dev/null 2>&1; then
    alias ni='npm install'
    alias nid='npm install --save-dev'
    alias nr='npm run'
    alias nt='npm test'
    alias nb='npm run build'
fi

if command -v mix >/dev/null 2>&1; then
    alias mt='mix test'
    alias mf='mix format'
    alias mc='mix compile'
    alias md='mix deps.get'
    alias ms='mix phx.server'
fi

EOF
}

# Add development aliases for fish
add_fish_dev_aliases() {
    local config_file="$1"
    
    cat >> "$config_file" << 'EOF'

# Development workflow aliases
if command -v git >/dev/null 2>&1
    alias gs 'git status'
    alias ga 'git add'
    alias gc 'git commit'
    alias gp 'git push'
    alias gl 'git pull'
    alias gd 'git diff'
    alias glog 'git log --oneline -10'
end

if command -v npm >/dev/null 2>&1
    alias ni 'npm install'
    alias nid 'npm install --save-dev'
    alias nr 'npm run'
    alias nt 'npm test'
    alias nb 'npm run build'
end

if command -v mix >/dev/null 2>&1
    alias mt 'mix test'
    alias mf 'mix format'
    alias mc 'mix compile'
    alias md 'mix deps.get'
    alias ms 'mix phx.server'
end

EOF
}

# Setup git pre-commit hook
setup_git_hook() {
    echo ""
    read -p "Install git pre-commit hook to run precheck automatically? [y/N]: " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping git hook installation"
        return 0
    fi
    
    if [ ! -d ".git" ]; then
        log_warn "Not in a git repository. Run this command from your project root."
        return 1
    fi
    
    log_info "Installing git pre-commit hook..."
    
    local hook_file=".git/hooks/pre-commit"
    
    cat > "$hook_file" << 'EOF'
#!/bin/bash
# Precheck pre-commit hook

echo "🔍 Running precheck before commit..."

if command -v precheck >/dev/null 2>&1; then
    if precheck; then
        echo "✅ Precheck passed - proceeding with commit"
        exit 0
    else
        echo ""
        echo "❌ Precheck found issues"
        echo "Fix the issues or use 'git commit --no-verify' to bypass"
        exit 1
    fi
else
    echo "⚠️  Precheck not found in PATH"
    echo "Installing globally or use: ~/.precheck/universal_precheck.sh"
    exit 0
fi
EOF
    
    chmod +x "$hook_file"
    log_success "Git pre-commit hook installed"
}

# Create enhanced IEx config for Elixir developers
setup_iex_config() {
    if ! command -v elixir >/dev/null 2>&1; then
        return 0
    fi
    
    echo ""
    read -p "Create enhanced IEx configuration for Elixir development? [y/N]: " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping IEx configuration"
        return 0
    fi
    
    if [ -f "$HOME/.iex.exs" ]; then
        log_warn "IEx config already exists at ~/.iex.exs"
        read -p "Overwrite? [y/N]: " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return 0
        fi
        cp "$HOME/.iex.exs" "$HOME/.iex.exs.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    log_info "Creating enhanced IEx configuration..."
    
    cat > "$HOME/.iex.exs" << 'EOF'
# Enhanced IEx Configuration
# Created by Precheck shell integration

# Helper functions
defmodule IExHelpers do
  def clear, do: IO.write("\e[H\e[2J")
  def pwd, do: File.cwd!() |> IO.puts()
  def ls(path \\ "."), do: File.ls!(path) |> Enum.each(&IO.puts/1)
  
  def recompile do
    IEx.Helpers.recompile()
    IO.puts("✅ Recompiled")
  end
end

import IExHelpers

# Enable ANSI colors
Application.put_env(:elixir, :ansi_enabled, true)

# History configuration
Application.put_env(:elixir, :iex_history, [
  enabled: true,
  path: Path.expand("~/.iex_history")
])

# Custom prompt with colors
IEx.configure(
  colors: [
    eval_result: [:cyan, :bright],
    eval_error: [:red, :bright],
    eval_info: [:yellow, :bright]
  ],
  default_prompt: "#{IO.ANSI.cyan()}iex#{IO.ANSI.reset()}(%counter)> ",
  alive_prompt: "#{IO.ANSI.cyan()}iex#{IO.ANSI.reset()}(#{IO.ANSI.yellow()}%node#{IO.ANSI.reset()})> "
)

IO.puts("""
#{IO.ANSI.cyan()}
✨ Enhanced IEx loaded!
Helpers: clear/0, pwd/0, ls/1, recompile/0
#{IO.ANSI.reset()}
""")
EOF
    
    log_success "Enhanced IEx config created at ~/.iex.exs"
}

# Show summary
show_summary() {
    echo ""
    echo -e "${CYAN}╔════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║  Shell Integration Complete! 🎉           ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════╝${NC}"
    echo ""
    
    log_info "Added aliases and functions to your shell configuration"
    echo ""
    
    echo -e "${YELLOW}Next Steps:${NC}"
    echo "1. Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
    echo "2. Type 'precheck-help' to see all available commands"
    echo "3. Navigate to a project and run 'precheck'"
    echo ""
    
    echo -e "${YELLOW}New Commands:${NC}"
    echo "  precheck              - Run automatic checks"
    echo "  precheck-elixir       - Run Elixir checks"
    echo "  precheck-node         - Run Node.js checks"
    echo "  precheck-secrets      - Scan for secrets"
    echo "  precheck-debug        - Run with debug output"
    echo "  precheck-report       - View last report"
    echo "  precheck-clean        - Clean up reports"
    echo "  precheck-help         - Show all commands"
    echo ""
    
    if command -v git >/dev/null 2>&1 && [ -f ".git/hooks/pre-commit" ]; then
        echo -e "${GREEN}✅ Git pre-commit hook installed${NC}"
        echo ""
    fi
    
    if [ -f "$HOME/.iex.exs" ]; then
        echo -e "${GREEN}✅ Enhanced IEx configuration created${NC}"
        echo ""
    fi
}

# Main execution
main() {
    show_banner
    
    # Check if precheck is installed
    if [ ! -d "$INSTALL_DIR" ] || [ ! -f "$INSTALL_DIR/universal_precheck.sh" ]; then
        log_error "Precheck not installed"
        echo ""
        echo "Please run the installer first:"
        echo "  curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash"
        exit 1
    fi
    
    # Detect and integrate shells
    local shell_configs
    shell_configs=$(detect_shells)
    
    if [ -z "$shell_configs" ]; then
        log_error "No shell configuration files found"
        exit 1
    fi
    
    for config_info in $shell_configs; do
        local config_file="${config_info%%:*}"
        local shell_type="${config_info##*:}"
        
        case "$shell_type" in
            bash|zsh|generic)
                add_bash_zsh_integration "$config_file" "$shell_type"
                ;;
            fish)
                add_fish_integration "$config_file"
                ;;
        esac
        
        break # Only integrate with primary shell
    done
    
    # Optional enhancements
    add_dev_aliases
    setup_git_hook
    setup_iex_config
    
    show_summary
    
    log_success "Shell integration completed!"
}

# Handle command line arguments
case "${1:-}" in
    -h|--help)
        cat << EOF
Precheck Shell Integration v$VERSION

Adds convenient aliases and helper functions to your shell configuration.

Usage: $0 [options]

Options:
  -h, --help     Show this help message
  --version      Show version information

Features:
  - Convenient precheck aliases (precheck-node, precheck-elixir, etc.)
  - Report viewing and cleanup commands
  - Optional development workflow aliases
  - Optional git pre-commit hook
  - Optional enhanced IEx configuration (Elixir)

Interactive Setup:
  The script will prompt you to choose which features to install.

Note: Precheck must be installed first. Run:
  curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash

EOF
        exit 0
        ;;
    --version)
        echo "$VERSION"
        exit 0
        ;;
esac

# Run main function
main "$@"
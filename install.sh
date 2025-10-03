#!/usr/bin/env bash

set -euo pipefail

# Enhanced Shell Integration Script
SCRIPT_VERSION="1.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

detect_shells_and_configs() {
    echo -e "${CYAN}🐚 Shell Integration Setup${NC}"
    echo -e "${CYAN}=========================${NC}"
    echo ""
    
    local detected_shells=()
    local shell_configs=()
    local current_shell="$(basename "${SHELL:-}" 2>/dev/null || echo "unknown")"
    
    log_info "Current shell: $current_shell"
    
    # Check for multiple shell configurations
    log_info "Scanning for shell configuration files..."
    
    # Bash configurations
    if [ -f "$HOME/.bashrc" ]; then
        shell_configs+=("$HOME/.bashrc:bash")
        detected_shells+=("bash")
        log_success "Found Bash configuration: ~/.bashrc"
    fi
    
    if [ -f "$HOME/.bash_profile" ]; then
        shell_configs+=("$HOME/.bash_profile:bash")
        if [[ ! " ${detected_shells[@]} " =~ " bash " ]]; then
            detected_shells+=("bash")
        fi
        log_success "Found Bash configuration: ~/.bash_profile"
    fi
    
    # Zsh configurations
    if [ -f "$HOME/.zshrc" ]; then
        shell_configs+=("$HOME/.zshrc:zsh")
        detected_shells+=("zsh")
        log_success "Found Zsh configuration: ~/.zshrc"
    fi
    
    if [ -f "$HOME/.zprofile" ]; then
        shell_configs+=("$HOME/.zprofile:zsh")
        if [[ ! " ${detected_shells[@]} " =~ " zsh " ]]; then
            detected_shells+=("zsh")
        fi
        log_success "Found Zsh configuration: ~/.zprofile"
    fi
    
    # Fish shell
    if [ -f "$HOME/.config/fish/config.fish" ]; then
        shell_configs+=("$HOME/.config/fish/config.fish:fish")
        detected_shells+=("fish")
        log_success "Found Fish configuration: ~/.config/fish/config.fish"
    fi
    
    # Generic profile
    if [ -f "$HOME/.profile" ]; then
        shell_configs+=("$HOME/.profile:generic")
        log_success "Found generic profile: ~/.profile"
    fi
    
    echo ""
    
    # Summary
    if [ ${#detected_shells[@]} -gt 0 ]; then
        log_info "Detected shells: ${detected_shells[*]}"
    else
        log_warn "No shell configurations detected"
    fi
    
    # Handle multiple shells
    if [[ " ${detected_shells[@]} " =~ " bash " ]] && [[ " ${detected_shells[@]} " =~ " zsh " ]]; then
        log_info "🔄 Both Bash and Zsh detected - will configure both"
        setup_multi_shell_integration "${shell_configs[@]}"
    elif [ ${#shell_configs[@]} -gt 0 ]; then
        setup_single_shell_integration "${shell_configs[@]}"
    else
        setup_fallback_integration
    fi
}

setup_multi_shell_integration() {
    local configs=("$@")
    
    echo ""
    log_info "Setting up multi-shell integration..."
    
    # Create a shared configuration file
    local shared_config="$HOME/.precheck_shell_integration"
    create_shared_config "$shared_config"
    
    # Add sourcing to each shell config
    for config_info in "${configs[@]}"; do
        local config_file="${config_info%%:*}"
        local shell_type="${config_info##*:}"
        
        case "$shell_type" in
            bash|zsh)
                add_integration_to_file "$config_file" "$shared_config" "$shell_type"
                ;;
            fish)
                add_fish_integration "$config_file"
                ;;
            generic)
                add_integration_to_file "$config_file" "$shared_config" "posix"
                ;;
        esac
    done
    
    log_success "Multi-shell integration configured"
    log_info "Shared config: $shared_config"
}

setup_single_shell_integration() {
    local configs=("$@")
    
    echo ""
    log_info "Setting up single shell integration..."
    
    for config_info in "${configs[@]}"; do
        local config_file="${config_info%%:*}"
        local shell_type="${config_info##*:}"
        
        case "$shell_type" in
            bash|zsh)
                add_direct_integration "$config_file" "$shell_type"
                ;;
            fish)
                add_fish_integration "$config_file"
                ;;
            generic)
                add_direct_integration "$config_file" "posix"
                ;;
        esac
        
        break # Use the first one found
    done
}

create_shared_config() {
    local shared_config="$1"
    
    cat > "$shared_config" << 'EOF'
# Precheck Shell Integration
# Generated automatically - do not edit manually

# Precheck aliases and functions
alias precheck='SCRIPT_DIR/universal_precheck.sh'
alias precheck-node='SCRIPT_DIR/nodejs_precheck.sh'
alias precheck-elixir='SCRIPT_DIR/elixir_precheck.sh'
alias precheck-beta='PRECHECK_BETA=true SCRIPT_DIR/universal_precheck.sh'
alias precheck-debug='PRECHECK_DEBUG=true SCRIPT_DIR/universal_precheck.sh'

# Precheck functions
precheck-help() {
    echo "Precheck Commands:"
    echo "  precheck           - Auto-detect and run appropriate checks"
    echo "  precheck-node      - Run Node.js specific checks"
    echo "  precheck-elixir    - Run Elixir specific checks"
    echo "  precheck-beta      - Run with beta features enabled"
    echo "  precheck-debug     - Run with debug output"
    echo "  precheck-update    - Update to latest version"
    echo "  precheck-config    - Show current configuration"
}

precheck-update() {
    SCRIPT_DIR/universal_precheck.sh --update
}

precheck-config() {
    SCRIPT_DIR/universal_precheck.sh --config
}

precheck-install-deps() {
    SCRIPT_DIR/universal_precheck.sh --install
}

# Environment optimizations
export PRECHECK_SHELL_INTEGRATION=true

# Development environment optimizations
if command -v node >/dev/null 2>&1; then
    # Node.js optimizations
    export NODE_OPTIONS="--max-old-space-size=4096"
    
    # npm completion (if available)
    if command -v npm >/dev/null 2>&1 && [ -n "$BASH_VERSION$ZSH_VERSION" ]; then
        if [ -n "$ZSH_VERSION" ]; then
            # Zsh npm completion
            if [[ ! -f "$HOME/.zsh/completions/_npm" ]]; then
                mkdir -p "$HOME/.zsh/completions" 2>/dev/null || true
                npm completion > "$HOME/.zsh/completions/_npm" 2>/dev/null || true
            fi
        elif [ -n "$BASH_VERSION" ]; then
            # Bash npm completion
            if command -v npm >/dev/null 2>&1; then
                eval "$(npm completion 2>/dev/null || true)"
            fi
        fi
    fi
fi

if command -v elixir >/dev/null 2>&1; then
    # Elixir/Erlang optimizations
    export ERL_AFLAGS="-kernel shell_history enabled"
    export ELIXIR_EDITOR="code --wait"
    
    # IEx aliases
    alias iex-test='MIX_ENV=test iex -S mix'
    alias iex-prod='MIX_ENV=prod iex -S mix'
    
    # Mix aliases
    alias mt='mix test'
    alias mtw='mix test.watch'
    alias mf='mix format'
    alias mc='mix compile'
    alias md='mix deps.get'
    alias mdu='mix deps.update --all'
    alias mdc='mix deps.clean --all'
    alias mr='mix run'
    alias ms='mix phx.server'
    alias mig='mix ecto.migrate'
    alias rollback='mix ecto.rollback'
    alias reset='mix ecto.reset'
fi

# Git aliases for development workflow
if command -v git >/dev/null 2>&1; then
    alias gst='git status'
    alias gco='git checkout'
    alias gcb='git checkout -b'
    alias gaa='git add .'
    alias gcm='git commit -m'
    alias gps='git push'
    alias gpl='git pull'
    alias glog='git log --oneline -10'
    alias gdiff='git diff'
    
    # Pre-commit hook for running precheck
    precheck-git-hook() {
        local hook_file=".git/hooks/pre-commit"
        if [ -d ".git" ]; then
            cat > "$hook_file" << 'HOOK_EOF'
#!/bin/bash
echo "Running precheck before commit..."
if SCRIPT_DIR/universal_precheck.sh; then
    echo "✅ Precheck passed - proceeding with commit"
    exit 0
else
    echo "❌ Precheck failed - commit blocked"
    echo "Fix issues and try again, or use 'git commit --no-verify' to bypass"
    exit 1
fi
HOOK_EOF
            chmod +x "$hook_file"
            echo "✅ Git pre-commit hook installed"
        else
            echo "❌ Not in a git repository"
        fi
    }
fi

# Performance monitoring functions
if [ "$PRECHECK_BETA" = "true" ]; then
    # Development server with performance monitoring
    dev-server() {
        echo "🚀 Starting development server with monitoring..."
        if [ -f "package.json" ]; then
            if command -v npm >/dev/null 2>&1; then
                echo "📊 Starting Node.js development server..."
                npm run dev 2>&1 | while IFS= read -r line; do
                    echo "[$(date +'%H:%M:%S')] $line"
                done
            fi
        elif [ -f "mix.exs" ]; then
            if command -v mix >/dev/null 2>&1; then
                echo "📊 Starting Phoenix development server..."
                mix phx.server 2>&1 | while IFS= read -r line; do
                    echo "[$(date +'%H:%M:%S')] $line"
                done
            fi
        else
            echo "❌ No development server configuration found"
        fi
    }
    
    # Project health dashboard
    project-health() {
        echo "📊 Project Health Dashboard"
        echo "========================="
        
        if [ -f "package.json" ]; then
            echo ""
            echo "📦 Node.js Project"
            if command -v jq >/dev/null 2>&1; then
                local name=$(jq -r '.name' package.json)
                local version=$(jq -r '.version' package.json)
                local deps=$(jq -r '.dependencies | length' package.json 2>/dev/null || echo "0")
                echo "Name: $name"
                echo "Version: $version"
                echo "Dependencies: $deps"
            fi
        fi
        
        if [ -f "mix.exs" ]; then
            echo ""
            echo "💎 Elixir Project"
            local app_name=$(grep -E "app:\s*:" mix.exs | sed 's/.*app: *:\([^,]*\).*/\1/' | tr -d ' ' || echo "unknown")
            local version=$(grep -E "version:\s*\"" mix.exs | sed 's/.*version: *"\([^"]*\)".*/\1/' || echo "unknown")
            echo "App: $app_name"
            echo "Version: $version"
        fi
        
        echo ""
        echo "🔍 Quick Checks"
        
        # Git status
        if command -v git >/dev/null 2>&1 && [ -d ".git" ]; then
            local git_status=$(git status --porcelain | wc -l)
            if [ "$git_status" -eq 0 ]; then
                echo "✅ Git: Clean working directory"
            else
                echo "⚠️  Git: $git_status uncommitted changes"
            fi
        fi
        
        # Last precheck run
        local report_files=("*_report.txt")
        for report in "${report_files[@]}"; do
            if [ -f "$report" ]; then
                local age_seconds=$(( $(date +%s) - $(stat -c %Y "$report" 2>/dev/null || stat -f %m "$report" 2>/dev/null || echo 0) ))
                local age_hours=$(( age_seconds / 3600 ))
                
                if [ $age_hours -lt 24 ]; then
                    echo "✅ Last precheck: ${age_hours}h ago"
                else
                    echo "⚠️  Last precheck: ${age_hours}h ago (consider running again)"
                fi
                break
            fi
        done
    }
fi

EOF

    # Replace SCRIPT_DIR placeholder with actual path
    sed -i "s|SCRIPT_DIR|$SCRIPT_DIR|g" "$shared_config" 2>/dev/null || \
    sed -i '' "s|SCRIPT_DIR|$SCRIPT_DIR|g" "$shared_config" 2>/dev/null
    
    log_success "Created shared configuration: $shared_config"
}

add_integration_to_file() {
    local config_file="$1"
    local shared_config="$2"
    local shell_type="$3"
    
    log_info "Adding integration to $config_file ($shell_type)"
    
    # Check if already integrated
    if grep -q "precheck shell integration" "$config_file" 2>/dev/null; then
        log_info "Integration already exists in $config_file"
        return 0
    fi
    
    # Backup original file
    cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    # Add integration
    cat >> "$config_file" << EOF

# Precheck shell integration - added $(date)
if [ -f "$shared_config" ]; then
    source "$shared_config"
fi
EOF
    
    log_success "Integration added to $config_file"
    log_info "Backup created: ${config_file}.backup.*"
}

add_direct_integration() {
    local config_file="$1"
    local shell_type="$2"
    
    log_info "Adding direct integration to $config_file ($shell_type)"
    
    # Check if already integrated
    if grep -q "precheck.*universal_precheck" "$config_file" 2>/dev/null; then
        log_info "Precheck integration already exists in $config_file"
        return 0
    fi
    
    # Backup original file
    cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    # Add direct aliases and functions
    cat >> "$config_file" << EOF

# Precheck integration - added $(date)
alias precheck='$SCRIPT_DIR/universal_precheck.sh'
alias precheck-node='$SCRIPT_DIR/nodejs_precheck.sh'
alias precheck-elixir='$SCRIPT_DIR/elixir_precheck.sh'
alias precheck-beta='PRECHECK_BETA=true $SCRIPT_DIR/universal_precheck.sh'
alias precheck-debug='PRECHECK_DEBUG=true $SCRIPT_DIR/universal_precheck.sh'

# Precheck helper functions
precheck-help() {
    echo "Precheck Commands:"
    echo "  precheck           - Auto-detect and run appropriate checks"
    echo "  precheck-node      - Run Node.js specific checks"
    echo "  precheck-elixir    - Run Elixir specific checks"
    echo "  precheck-beta      - Run with beta features enabled"
    echo "  precheck-debug     - Run with debug output"
}

precheck-update() {
    $SCRIPT_DIR/universal_precheck.sh --update
}

precheck-config() {
    $SCRIPT_DIR/universal_precheck.sh --config
}
EOF
    
    log_success "Direct integration added to $config_file"
    log_info "Backup created: ${config_file}.backup.*"
}

add_fish_integration() {
    local config_file="$1"
    
    log_info "Adding Fish shell integration to $config_file"
    
    # Check if already integrated
    if grep -q "precheck.*universal_precheck" "$config_file" 2>/dev/null; then
        log_info "Precheck integration already exists in $config_file"
        return 0
    fi
    
    # Backup original file
    cp "$config_file" "${config_file}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
    
    # Add Fish-specific syntax
    cat >> "$config_file" << EOF

# Precheck integration - added $(date)
alias precheck '$SCRIPT_DIR/universal_precheck.sh'
alias precheck-node '$SCRIPT_DIR/nodejs_precheck.sh'
alias precheck-elixir '$SCRIPT_DIR/elixir_precheck.sh'
alias precheck-beta 'env PRECHECK_BETA=true $SCRIPT_DIR/universal_precheck.sh'
alias precheck-debug 'env PRECHECK_DEBUG=true $SCRIPT_DIR/universal_precheck.sh'

function precheck-help
    echo "Precheck Commands:"
    echo "  precheck           - Auto-detect and run appropriate checks"
    echo "  precheck-node      - Run Node.js specific checks"
    echo "  precheck-elixir    - Run Elixir specific checks"
    echo "  precheck-beta      - Run with beta features enabled"
    echo "  precheck-debug     - Run with debug output"
end

function precheck-update
    $SCRIPT_DIR/universal_precheck.sh --update
end

function precheck-config
    $SCRIPT_DIR/universal_precheck.sh --config
end
EOF
    
    log_success "Fish integration added to $config_file"
    log_info "Backup created: ${config_file}.backup.*"
}

setup_fallback_integration() {
    log_warn "No shell configuration files found"
    log_info "Creating fallback integration..."
    
    # Create .profile if it doesn't exist
    if [ ! -f "$HOME/.profile" ]; then
        touch "$HOME/.profile"
        log_success "Created $HOME/.profile"
    fi
    
    add_direct_integration "$HOME/.profile" "posix"
    
    log_info "Fallback integration added to ~/.profile"
    log_warn "You may need to restart your shell or run: source ~/.profile"
}

setup_development_environment_integration() {
    echo ""
    log_info "Setting up development environment integration..."
    
    # Node.js specific integration
    if command -v node >/dev/null 2>&1; then
        log_info "Configuring Node.js development environment..."
        
        # Check for .nvmrc
        if [ -f ".nvmrc" ]; then
            log_success "Found .nvmrc - Node.js version pinned"
        else
            log_info "Consider creating .nvmrc to pin Node.js version"
            local node_version=$(node --version)
            echo "💡 Current Node.js version: $node_version"
        fi
        
        # Package manager optimization
        if [ -f "package-lock.json" ]; then
            log_info "Using npm - consider 'npm ci' for faster installs"
        elif [ -f "yarn.lock" ]; then
            log_info "Using Yarn - optimized for performance"
        elif [ -f "pnpm-lock.yaml" ]; then
            log_info "Using pnpm - excellent choice for performance"
        fi
    fi
    
    # Elixir specific integration
    if command -v elixir >/dev/null 2>&1; then
        log_info "Configuring Elixir development environment..."
        
        # Check for .tool-versions (asdf)
        if [ -f ".tool-versions" ]; then
            log_success "Found .tool-versions - versions managed by asdf"
            local elixir_version=$(grep elixir .tool-versions | cut -d' ' -f2 2>/dev/null || echo "not specified")
            local erlang_version=$(grep erlang .tool-versions | cut -d' ' -f2 2>/dev/null || echo "not specified")
            log_info "Elixir: $elixir_version, Erlang: $erlang_version"
        fi
        
        # IEx configuration
        if [ ! -f "$HOME/.iex.exs" ]; then
            log_info "Creating enhanced IEx configuration..."
            create_iex_config
        else
            log_success "IEx configuration already exists"
        fi
        
        # Mix configuration
        setup_mix_configuration
    fi
}

create_iex_config() {
    cat > "$HOME/.iex.exs" << 'EOF'
# Enhanced IEx Configuration
# Auto-generated by precheck shell integration

# Import common modules
import Ecto.Query, warn: false

# Helper functions
defmodule IExHelpers do
  def clear do
    IO.write("\e[H\e[2J")
  end
  
  def pwd do
    File.cwd!()
  end
  
  def ls(path \\ ".") do
    File.ls!(path)
    |> Enum.each(&IO.puts/1)
  end
  
  def cat(file) do
    File.read!(file)
    |> IO.puts()
  end
  
  def memory do
    :erlang.memory()
    |> Enum.map(fn {key, val} -> {key, div(val, 1024 * 1024)} end)
    |> IO.inspect(label: "Memory (MB)")
  end
  
  def processes do
    :erlang.system_info(:process_count)
    |> IO.inspect(label: "Process count")
  end
end

import IExHelpers

# Custom prompt
Application.put_env(:elixir, :ansi_enabled, true)

# History configuration
Application.put_env(:elixir, :iex_history, [
  enabled: true,
  path: Path.expand("~/.iex_history")
])

# Auto-complete configuration
IEx.configure(
  colors: [
    eval_result: [:cyan, :bright],
    eval_error: [[:red, :bright, "** "]],
    eval_info: [:yellow, :bright],
    stack_info: [:red],
    blame_diff: [:red]
  ],
  default_prompt:
    "#{IO.ANSI.cyan()}iex#{IO.ANSI.reset()}(#{IO.ANSI.yellow()}%counter#{IO.ANSI.reset()})> ",
  alive_prompt:
    "#{IO.ANSI.cyan()}iex#{IO.ANSI.reset()}(#{IO.ANSI.yellow()}%node#{IO.ANSI.reset()})#{IO.ANSI.cyan()}(%counter)#{IO.ANSI.reset()}> "
)

# Welcome message
IO.puts """
#{IO.ANSI.cyan()}
🧪 Enhanced IEx Environment Ready!
Helper functions available: clear/0, pwd/0, ls/1, cat/1, memory/0, processes/0
#{IO.ANSI.reset()}
"""
EOF
    
    log_success "Enhanced IEx configuration created at ~/.iex.exs"
}

setup_mix_configuration() {
    log_info "Setting up Mix configuration..."
    
    # Check for .formatter.exs
    if [ ! -f ".formatter.exs" ] && [ -f "mix.exs" ]; then
        log_info "Creating .formatter.exs..."
        cat > ".formatter.exs" << 'EOF'
# .formatter.exs
[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"]
]
EOF
        log_success "Created .formatter.exs"
    fi
}

show_integration_summary() {
    echo ""
    echo -e "${CYAN}📋 Integration Summary${NC}"
    echo -e "${CYAN}======================${NC}"
    echo ""
    
    log_success "Shell integration completed!"
    echo ""
    
    log_info "Available Commands:"
    echo "  precheck           - Auto-detect and run appropriate checks"
    echo "  precheck-node      - Run Node.js specific checks"
    echo "  precheck-elixir    - Run Elixir specific checks"
    echo "  precheck-beta      - Run with beta features enabled"
    echo "  precheck-debug     - Run with debug output"
    echo "  precheck-help      - Show all available commands"
    echo "  precheck-update    - Update to latest version"
    echo "  precheck-config    - Show current configuration"
    echo ""
    
    if [ "$PRECHECK_BETA" = "true" ]; then
        log_info "Beta Commands (when PRECHECK_BETA=true):"
        echo "  dev-server         - Start development server with monitoring"
        echo "  project-health     - Show project health dashboard"
        echo "  precheck-git-hook  - Install git pre-commit hook"
        echo ""
    fi
    
    log_info "Next Steps:"
    echo "1. Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
    echo "2. Navigate to your project directory"
    echo "3. Run 'precheck' to validate your project"
    echo "4. Use 'precheck-help' to see all available commands"
    echo ""
    
    log_info "Configuration Files:"
    if [ -f "$HOME/.precheck_shell_integration" ]; then
        echo "  Shared config: ~/.precheck_shell_integration"
    fi
    
    for config in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.config/fish/config.fish" "$HOME/.profile"; do
        if [ -f "$config" ] && grep -q "precheck" "$config" 2>/dev/null; then
            echo "  Modified: $config"
        fi
    done
    
    if [ -f "$HOME/.iex.exs" ]; then
        echo "  Enhanced IEx: ~/.iex.exs"
    fi
    
    echo ""
    echo -e "${GREEN}✨ Shell integration setup complete!${NC}"
}

# Parse arguments
case "${1:-}" in
    -h|--help)
        echo "Enhanced Shell Integration v$SCRIPT_VERSION"
        echo ""
        echo "Automatically detects and configures shell integrations for:"
        echo "  • Bash (.bashrc, .bash_profile)"
        echo "  • Zsh (.zshrc, .zprofile)"  
        echo "  • Fish (.config/fish/config.fish)"
        echo "  • Generic POSIX (.profile)"
        echo ""
        echo "Usage: $0 [options]"
        echo ""
        echo "Options:"
        echo "  -h, --help     Show this help"
        echo "  --version      Show version"
        echo ""
        exit 0
        ;;
    --version)
        echo "$SCRIPT_VERSION"
        exit 0
        ;;
esac

# Main execution
main() {
    detect_shells_and_configs
    setup_development_environment_integration
    show_integration_summary
}

main "$@"
# Precheck Developer

> ⚠️ **Private Repository** - This is the development repository for Precheck.

For user installation, visit: https://github.com/bennydreamtech23/precheck

## Development Setup

```bash
# Clone
git clone git@github.com:bennydreamtech23/precheck-developer.git
cd precheck-developer

# Install Elixir dependencies
mix deps.get

# Build Rust native module
cd native/precheck_native      # Correct path for Rust NIF module
cargo build --release
cd ../..

# Run tests
mix test
cargo test --manifest-path native/precheck_native/Cargo.toml

# Test scripts
./scripts/universal_precheck.sh --help
```

## Project Structure

- `lib/` - Elixir source code
- `native/` - Rust NIF modules
- `scripts/` - Internal development/validation scripts (not shipped in hardened public artifacts)
- `test/` - Test files

## Release Process

```bash
# 1. Update version in mix.exs
# 2. Update CHANGELOG.md
# 3. Tag and push
git tag v1.0.0
git push origin --tags
```

GitHub Actions will automatically build and publish to the public repo.

---

# Developer Precheck v1.0.0-beta

A comprehensive pre-deployment validation toolkit for modern development teams. Automatically detects your project type and runs intelligent checks to ensure deployment readiness.

[![Version](https://img.shields.io/badge/version-1.0.0--beta-blue.svg)](https://github.com/bennydreamtech23/precheck-developer)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Supported Languages](https://img.shields.io/badge/supports-Elixir%20%7C%20Node.js-orange.svg)](#supported-languages)

> **Beta Release**: This is a beta version for testing and feedback. Report issues on [GitHub](https://github.com/bennydreamtech23/precheck-developer/issues).

---

## Quick Start

### One-Line Installation

```bash
curl -fsSL https://raw.githubusercontent.com/bennydreamtech23/precheck-developer/master/install.sh | bash
```

### Manual Installation

```bash
git clone https://github.com/bennydreamtech23/precheck-developer.git
cd precheck-developer
chmod +x install.sh
./install.sh
```

---

## Usage

Navigate to your project directory and run:

```bash
precheck
```

The tool automatically detects your project type (Elixir or Node.js) and runs appropriate checks.

### With Automatic Setup

```bash
precheck --setup
```

This will:
1. Check for required tools (elixir/mix or node/npm)
2. Validate environment configuration (.env files)
3. Install dependencies
4. Compile/build the project
5. Setup database (Elixir/Phoenix projects)
6. Prompt to start the development server
7. Run security scan for secrets
8. Run all validation checks

### Other Options

```bash
precheck --help    # Show all options
precheck --debug   # Enable debug mode
```

---

## What Gets Checked

### Security Checks (Runs First)

Before any validation, Precheck automatically scans for security issues:

#### Hardcoded Credentials Detection
- Passwords, API keys, and tokens in source code
- Database connection strings with credentials
- Secret keys and authentication tokens

**Example patterns detected:**
```javascript
// FLAGGED as insecure
const apiKey = "sk-1234567890abcdef"
const password = "MyPassword123"

// SAFE - uses environment variables
const apiKey = process.env.API_KEY
const password = process.env.PASSWORD
```

#### Secrets Scanning
- AWS Access Keys (AKIA...)
- GitHub Tokens (ghp_...)
- OpenAI Keys (sk-...)
- Slack Tokens (xox...)
- Private keys and certificates

#### Configuration Security
- Missing .env files
- .gitignore validation
- Committed sensitive files detection

**Security scan output:**
```
╔════════════════════════════════════════╗
║     SECURITY SCAN                      ║
╚════════════════════════════════════════╝

Scanning for hardcoded credentials...
⚠️  Found hardcoded credentials in source files
   src/config.js:12: const API_KEY = "sk-1234..."

Checking .gitignore configuration...
⚠️  .gitignore missing sensitive patterns:
     .env
     *.pem

⚠️  Security scan found 2 issue(s)
Recommendations:
  1. Remove hardcoded secrets from source code
  2. Use environment variables for sensitive values
  3. Add sensitive files to .gitignore
  4. Rotate any exposed credentials
```

---

### Elixir Projects

**Core Checks:**
- **Dependencies**: Security audit via `mix hex.audit` or `mix deps.audit`
- **Naming Conventions**: Code style validation
- **Code Quality**: Format checking with `mix format --check-formatted`
- **Static Analysis**: Credo code analysis
- **Type Safety**: Dialyzer analysis (if configured)
- **Unused Dependencies**: Detection via `mix deps.unlock --check-unused`
- **Testing**: Unit tests with coverage reporting
- **Compilation**: Production build validation
- **Security**: Sobelow security analysis (if installed)
- **Documentation**: ExDoc generation and completeness

**Environment Checks:**
- Validates .env file exists
- Checks for required environment variables
- Prompts to configure missing values

**Auto-Setup (--setup flag):**
1. Install dependencies with `mix deps.get`
2. Compile project with `mix compile`
3. Create database (Phoenix/Ecto projects)
4. Run migrations
5. Setup frontend assets (Phoenix projects)
6. Prompt to start server with `mix phx.server`

---

### Node.js Projects

**Core Checks:**
- **Dependencies**: Security audit via `npm audit`
- **Outdated Packages**: Detection of outdated dependencies
- **Code Quality**: ESLint validation (if configured)
- **Code Formatting**: Prettier checks (if configured)
- **TypeScript**: Type checking (for TypeScript projects)
- **Testing**: Test suite execution and coverage
- **Build Process**: Production build validation
- **Package.json**: Syntax validation and required fields
- **Lockfile**: Consistency checking

**Environment Checks:**
- Validates .env file exists
- Compares .env.example vs .env
- Lists missing environment variables

**Auto-Setup (--setup flag):**
1. Detect package manager (npm/yarn/pnpm/bun)
2. Install dependencies
3. Run build script (if exists)
4. Prompt to start server with `npm run dev` or `npm start`

---

## Severity Levels

Each check is assigned a severity level for prioritization:

| Level | Symbol | Meaning | Action |
|-------|--------|---------|--------|
| **CRITICAL** | 🚨 | Must fix before PR/deployment | Blocks PR, exit code 2 |
| **HIGH** | ⚠️ | Should fix before PR | Strongly recommended, exit code 1 |
| **MEDIUM** | ⚠️ | Recommended to fix | Optional but advised |
| **LOW** | ℹ️ | Optional improvements | Nice to have |

**Example output:**
```
╔════════════════════════════════════════╗
║         TEST SUMMARY                   ║
╚════════════════════════════════════════╝

Total Tests: 15
Passed: 13
Failed: 2
Pass Rate: 86%

🚨 CRITICAL Failures: 1 (MUST FIX BEFORE PR)
⚠️  HIGH Priority: 1 (Should fix before PR)

🚨 CRITICAL Issues (Block PR):
  • Compilation warnings

⚠️  HIGH Priority Issues:
  • Security vulnerabilities

❌ NOT READY FOR PR - Critical issues must be fixed
```

---

## Reports

Each run generates detailed reports:

```
project-name/
├── elixir_report.txt    # Detailed Elixir check results
└── node_report.txt      # Detailed Node.js check results
```

View reports:
```bash
cat elixir_report.txt    # Manual view
precheck-report          # If shell integration installed
```

---

## Prerequisites

### System Requirements
- **Bash** 4.0 or higher
- **curl** for downloads
- **git** (recommended)
- **jq** (recommended for JSON processing)

### Language-Specific

**For Elixir projects:**
- Elixir 1.12+ 
- Erlang/OTP 24+
- Mix build tool

**For Node.js projects:**
- Node.js 14+
- npm/yarn/pnpm/bun

**Installation will check for these and provide install instructions if missing.**

---

## Optional: Enhanced Shell Integration

For power users who want convenient aliases and helpers:

```bash
bash ~/.precheck/shell_integration.sh
```

This adds:
- **Aliases**: `precheck-node`, `precheck-elixir`, `precheck-secrets`
- **Helpers**: `precheck-report`, `precheck-clean`
- **Git hooks**: Optional pre-commit hook
- **Dev shortcuts**: Optional git/npm/mix aliases

See [Shell Integration Guide](docs/shell_integration.md) for details.

---

## Environment Configuration

### Automatic .env Validation

Precheck automatically checks for missing environment files:

```bash
⚠️  Environment file missing!
   Found .env.example but no .env file
   Action required: cp .env.example .env

Create .env from .env.example now? (y/n): y
✅ Created .env file
⚠️  Please configure required values in .env before starting

Required variables:
  ✅ DATABASE_URL (configured)
  ❌ SECRET_KEY_BASE (MISSING)
  ❌ API_KEY (MISSING)
```

This prevents runtime crashes from missing configuration.

---

## Exit Codes

| Code | Meaning | Description |
|------|---------|-------------|
| 0 | Success | All checks passed or only minor issues |
| 1 | Warning | HIGH priority issues detected |
| 2 | Critical | CRITICAL failures - blocks deployment |

**Usage in CI/CD:**
```bash
#!/bin/bash
precheck
EXIT_CODE=$?

if [ $EXIT_CODE -eq 2 ]; then
  echo "Critical failures - blocking deployment"
  exit 1
elif [ $EXIT_CODE -eq 1 ]; then
  echo "High priority issues - review required"
  # Could still deploy with approval
fi
```

---

## Security Features

### Built-in Secrets Detection

Every run automatically scans for:

1. **Hardcoded Credentials**
   - Passwords, API keys, tokens
   - Database connection strings
   - Authentication secrets

2. **API Keys and Tokens**
   - AWS (AKIA...)
   - GitHub (ghp_...)
   - OpenAI (sk-...)
   - Slack (xox...)
   - Stripe (sk_live_...)

3. **Configuration Security**
   - Missing .env files
   - .gitignore validation
   - Committed sensitive files

4. **Best Practices**
   - Environment variable usage
   - Secret management recommendations
   - Security compliance tips

### Standalone Deep Scan

For thorough security audits:
```bash
~/.precheck/check_secrets.sh
```

---

## Troubleshooting

### "Missing required tools"

```bash
❌ Missing required tools: elixir, mix

Install Elixir:
  macOS:  brew install elixir
  Ubuntu: sudo apt-get install elixir
  Docs:   https://elixir-lang.org/install.html
```

**Solution**: Install the missing tools, then run precheck again.

### "Environment file missing"

```bash
⚠️  Environment file missing!
Found .env.example but no .env file
```

**Solution**: 
```bash
cp .env.example .env
# Then configure required values
```

Or run `precheck --setup` which prompts to create it.

### "Dependencies not installed"

```bash
⚠️  Dependencies not installed
Run: precheck --setup or mix deps.get
```

**Solution**: Run `precheck --setup` for automatic installation.

### Installation Issues

```bash
# Fix permission issues
sudo chown -R $USER:$USER ~/.precheck
chmod +x ~/.precheck/*.sh

# Reinstall with clean slate
rm -rf ~/.precheck ~/.precheck_config
curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
```

---

## Configuration

### Default Configuration
Precheck works out of the box with sensible defaults.

**Config location**: `~/.precheck_config`

### Environment Variables

```bash
export PRECHECK_DEBUG=true    # Enable debug logging
```

---

## CI/CD Integration

### GitHub Actions

```yaml
name: Precheck Validation

on: [push, pull_request]

jobs:
  precheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Precheck
        run: |
          curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
      
      - name: Run Precheck
        run: precheck
```

### GitLab CI

```yaml
precheck:
  script:
    - curl -fsSL https://raw.githubusercontent.com/.../install.sh | bash
    - precheck
  allow_failure: false
```

---

## Supported Languages

### Currently Supported (v1.0.0-beta)

- **Elixir**: Full support including Phoenix, LiveView, and OTP applications
- **Node.js**: Complete support including TypeScript, React, Vue, and Express

### Coming Soon

- **Python**: Django, Flask, FastAPI support
- **Go**: Standard library and popular frameworks
- **Rust**: Cargo-based projects
- **Ruby**: Rails and other frameworks

---

## Contributing

We welcome contributions! This is a beta release, and your feedback is valuable.

### Ways to Contribute

- **Bug Reports**: Report issues with detailed reproduction steps
- **Feature Requests**: Suggest new features or improvements
- **Testing**: Test beta features and provide feedback
- **Documentation**: Improve docs, fix typos, add examples
- **Code**: Submit pull requests for new features or fixes

### Development Setup

```bash
git clone https://github.com/bennydreamtech23/precheck-developer.git
cd precheck-developer
chmod +x *.sh

# Test locally
./universal_precheck.sh --debug
```

### Adding Language Support

1. Create `your_language_precheck.sh` based on template
2. Add detection logic to `universal_precheck.sh`
3. Add security patterns for your language
4. Update documentation
5. Submit pull request

---

## Beta Testing Feedback

Please report any issues or suggestions:

**GitHub Issues**: https://github.com/bennydreamtech23/precheck-developer/issues

**Include:**
- Operating system and version
- Project type (Elixir/Node.js)
- Error messages or unexpected behavior
- Steps to reproduce

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

Special thanks to:
- **Contributors**: Everyone who has tested and provided feedback
- **Open Source Community**: The amazing tools that make this possible
- **Users**: Your support drives continuous improvement

---

## Roadmap

### v1.0.0 (Current Beta)
- ✅ Elixir project support
- ✅ Node.js project support
- ✅ Auto-detection
- ✅ Severity-based reporting
- ✅ Auto-setup with server start
- ✅ Integrated secrets detection
- ✅ Hardcoded credentials scanning
- ✅ Environment validation

### v1.1.0 (Planned)
- 🔄 Python project support
- 🔄 Custom configuration files (.precheck.yml)
- 🔄 CI/CD templates (GitHub Actions, GitLab CI)
- 🔄 Performance optimization
- 🔄 Parallel check execution

### v2.0.0 (Future)
- 🔮 AI-powered code analysis
- 🔮 Multi-language monorepo support
- 🔮 Advanced caching system
- 🔮 Custom rule engine
- 🔮 Team collaboration features

---

**Made with ❤️ by developers, for developers**

*Start using Precheck today and ship with confidence!*

---

**Version**: 1.0.0-beta  
**Last Updated**: 2024  
**Status**: Beta Testing  
**Support**: https://github.com/bennydreamtech23/precheck-developer

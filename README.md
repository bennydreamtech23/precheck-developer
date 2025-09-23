# Pre-deployment Test Scripts

A collection of comprehensive pre-deployment validation scripts for Elixir and Node.js projects.

## 📁 Directory Structure

```
pre_test_script/
├── README.md                    # This file
├── universal_precheck.sh        # Auto-detect and run appropriate script
├── elixir_precheck.sh          # Elixir-specific checks
├── nodejs_precheck.sh          # Node.js-specific checks
└── setup.sh                    # Setup script to make all scripts executable
```

## 🚀 Quick Start

### Option 1: Universal Script (Recommended)
The universal script automatically detects your project type and runs the appropriate checks.

```bash
# Make executable and run
chmod +x universal_precheck.sh
./universal_precheck.sh
```

### Option 2: Direct Script Usage
Run the specific script for your project type directly.

```bash
# For Elixir projects
chmod +x elixir_precheck.sh
./elixir_precheck.sh

# For Node.js projects  
chmod +x nodejs_precheck.sh
./nodejs_precheck.sh
```

### Option 3: Setup All Scripts
Make all scripts executable at once.

```bash
chmod +x setup.sh
./setup.sh
```

## 🎯 What Gets Checked

### Elixir Projects (`elixir_precheck.sh`)

- **Dependencies**: Outdated packages, security vulnerabilities
- **Code Quality**: Format checking, Credo static analysis
- **Type Safety**: Dialyzer (if configured)
- **Testing**: Unit tests with coverage analysis
- **Compilation**: Production build with performance timing
- **Security**: Sobelow security analysis
- **Release**: Release build validation
- **Documentation**: ExDoc generation
- **Configuration**: Production config validation

### Node.js Projects (`nodejs_precheck.sh`)

- **Dependencies**: Outdated packages, npm audit vulnerabilities
- **Code Quality**: ESLint linting, Prettier formatting
- **Testing**: Test suite execution
- **Build Process**: Production build validation
- **Type Safety**: TypeScript checking (if applicable)
- **Security**: Pattern analysis for common security issues
- **Performance**: Bundle size analysis, build timing
- **Environment**: Configuration validation

## 🤖 AI-Powered Code Review

Both scripts support optional AI-powered code review using OpenAI's API.

```bash
export OPENAI_API_KEY="your-openai-api-key"
./universal_precheck.sh
```

The AI will analyze your pre-deployment report and provide specific recommendations for:
- Code quality improvements
- Security considerations  
- Performance optimizations
- Deployment readiness assessment
- Risk identification

## 📊 Output Files

Each script generates detailed reports:

- `elixir_report.txt` / `node_report.txt` - Complete check results
- `elixir_ai_feedback.txt` / `node_ai_feedback.txt` - AI recommendations (if enabled)

## 🔧 Prerequisites

### For Elixir Projects
- Elixir and Mix installed
- Hex package manager
- Dependencies: credo, sobelow (optional), excoveralls (optional)

### For Node.js Projects  
- Node.js and npm installed
- jq (for JSON processing)
- Project dependencies installed

### For AI Features
- OpenAI API key
- curl and jq installed

## 📝 Usage Examples

### Basic Usage
```bash
# Auto-detect project type and run checks
./universal_precheck.sh
```

### With AI Feedback
```bash
export OPENAI_API_KEY="sk-..."
./universal_precheck.sh
```

### Help and Documentation
```bash
./universal_precheck.sh --help
```

### Integration with CI/CD

#### GitHub Actions
```yaml
name: Pre-deployment Checks
on: [push, pull_request]
jobs:
  precheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run pre-deployment checks
        run: |
          chmod +x pre_test_script/universal_precheck.sh
          cd pre_test_script && ./universal_precheck.sh
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
```

#### GitLab CI
```yaml
precheck:
  stage: test
  script:
    - chmod +x pre_test_script/universal_precheck.sh
    - cd pre_test_script && ./universal_precheck.sh
  variables:
    OPENAI_API_KEY: $OPENAI_API_KEY
```

## 🛠️ Customization

### Adding Custom Checks

You can extend the scripts by adding custom validation steps:

```bash
# Add to elixir_precheck.sh or nodejs_precheck.sh
log "${YELLOW}[Custom] Running custom checks${NC}"
check_step "Custom validation" \
  "your_custom_command" \
  "Custom check passed" \
  "Custom check failed"
```

### Environment-Specific Configuration

Create environment-specific validation by checking for config files:

```bash
# Example: Staging-specific checks
if [ -f "config/staging.exs" ]; then
  check_step "Staging config validation" \
    "MIX_ENV=staging mix app.config" \
    "Staging configuration valid" \
    "Staging configuration issues"
fi
```

### Performance Thresholds

Adjust performance warning thresholds:

```bash
# Elixir compilation time threshold
COMPILE_THRESHOLD=30000  # 30 seconds

# Node.js build time threshold  
BUILD_THRESHOLD=60000    # 60 seconds
```

## 🚨 Exit Codes

- `0` - All checks passed, ready for deployment
- `1` - One or more checks failed, deployment blocked

## 🔍 Troubleshooting

### Common Issues

**Script not found**
```bash
# Make sure you're in the correct directory
ls -la pre_test_script/
chmod +x pre_test_script/*.sh
```

**Permission denied**
```bash
chmod +x pre_test_script/universal_precheck.sh
```

**Missing dependencies**
```bash
# For Elixir
mix local.hex --force
mix deps.get

# For Node.js  
npm install
# or
npm ci
```

**jq not found**
```bash
# Ubuntu/Debian
sudo apt-get install jq

# macOS
brew install jq

# Windows (using Chocolatey)
choco install jq
```

### Debug Mode

Enable verbose output for troubleshooting:

```bash
# Add to the top of any script after set -euo pipefail
set -x  # Enable debug mode
```

## 🔒 Security Considerations

### Protecting API Keys

Never commit API keys to version control:

```bash
# Use environment variables
export OPENAI_API_KEY="your-key"

# Or use .env file (add to .gitignore)
echo "OPENAI_API_KEY=your-key" >> .env
source .env
```

### Script Security

- Scripts use `set -euo pipefail` for strict error handling
- Input validation for all user-provided data
- Temporary files are cleaned up automatically
- No execution of user-provided code without validation

## 📈 Performance Optimization

### Parallel Execution

For faster execution, some checks can be run in parallel:

```bash
# Example: Run linting and tests in parallel
{
  npm run lint > lint.log 2>&1 &
  npm test > test.log 2>&1 &
  wait
}
```

### Caching

Speed up repeated runs by caching dependencies:

```bash
# Node.js - use npm ci instead of npm install
npm ci  # Uses package-lock.json for faster, reliable installs

# Elixir - cache compiled dependencies
export MIX_ENV=test
mix deps.compile
```

## 🤝 Contributing

### Adding New Checks

1. Follow the existing `check_step` function pattern
2. Add appropriate error handling
3. Include helpful success/failure messages
4. Update this README

### Supporting New Project Types

1. Create a new `{language}_precheck.sh` script
2. Add detection logic to `universal_precheck.sh`
3. Update the README documentation
4. Test thoroughly

### Example Contribution

```bash
# Add Python support
touch python_precheck.sh
chmod +x python_precheck.sh

# Add to universal_precheck.sh detect_and_run():
elif [ -f "requirements.txt" ] || [ -f "pyproject.toml" ]; then
  project_type="Python"
  script_name="python_precheck.sh"
```

## 📚 Additional Resources

- [Elixir Testing Best Practices](https://hexdocs.pm/ex_unit/ExUnit.html)
- [Node.js Security Best Practices](https://nodejs.org/en/docs/guides/security/)
- [DevOps Pre-deployment Checklists](https://www.atlassian.com/devops/frameworks/deployment-checklist)
- [OpenAI API Documentation](https://platform.openai.com/docs/api-reference)

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏷️ Version History

- **v1.0.0** - Initial release with Elixir and Node.js support
- **v1.1.0** - Added AI-powered code review
- **v1.2.0** - Enhanced security checks and performance monitoring
- **v1.3.0** - Universal auto-detection script
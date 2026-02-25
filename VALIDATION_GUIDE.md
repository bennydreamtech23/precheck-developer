# Validation and Testing Guide

## Overview
Use this guide to validate repository health after changes.

## Quick Validation

```bash
./scripts/validate_fixes.sh
```

## Manual Validation

### 1. Shell Scripts

```bash
for script in scripts/*.sh; do
  echo "Checking $script..."
  shellcheck "$script"
done

./scripts/universal_precheck.sh --help
./scripts/elixir_precheck.sh --help
./scripts/nodejs_precheck.sh --help
```

### 2. Elixir Project

```bash
mix format --check-formatted
mix compile
mix test
```

### 3. CI Workflow Coverage

Current CI jobs in `.github/workflows/ci.yml`:

- `test-elixir`
- `test-scripts`

## Troubleshooting

### If validation fails

1. Read the first failing command and error output.
2. Run the failing command manually.
3. Apply a focused fix.
4. Re-run validation.

### Common issues

- `mix` errors: verify Elixir/OTP versions match workflow setup.
- shellcheck errors: apply quoted variables and safer shell patterns.
- script execution errors: confirm executable permissions with `chmod +x scripts/*.sh`.

## Maintenance Rule

Before opening a PR, ensure:

- `mix test` passes
- shell script help/smoke checks pass
- docs match current CI and release behavior

# Precheck

Precheck is an open-source pre-deployment validation toolkit for Elixir and Node.js projects.

This repository is now the single source of truth for development, installation, and releases.

## Install

### One-line install

```bash
curl -fsSL https://raw.githubusercontent.com/bennydreamtech23/precheck-developer/master/scripts/install.sh | bash
```

### Local install from source

```bash
git clone https://github.com/bennydreamtech23/precheck-developer.git
cd precheck-developer
./scripts/install.sh
```

## Usage

Run inside your project directory:

```bash
precheck
```

Common options:

```bash
precheck --help
precheck --setup
precheck --debug
```

## What It Checks

- Project type detection (Elixir or Node.js)
- Dependency/security checks
- Build and test readiness checks
- Basic secrets and hardcoded credential detection
- Environment and configuration hygiene checks

## Repository Structure

- `scripts/` shell-based runtime checks and installer
- `lib/` Elixir CLI and scanning logic
- `.github/workflows/` CI and release automation
- `test/` Elixir test suite

## Development

```bash
mix deps.get
mix test
./scripts/universal_precheck.sh --help
```

Optional local validation:

```bash
./scripts/validate_fixes.sh
```


## Release

Tag-based release builds happen in this repository:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Release workflow builds the escript, packages scripts + docs, and publishes GitHub release assets with checksums.

## Security Notes

- The project uses script-first and Elixir-based scanning for portability.
- Legacy Rust artifacts were removed and are not part of runtime, CI, or release packaging.

## Contributing

External contributors must fork this repository before contributing.

See the full guide in [CONTRIBUTING.md](./CONTRIBUTING.md).

## License

MIT - see `LICENSE`.

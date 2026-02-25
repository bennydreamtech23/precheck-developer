# Precheck - AI Coding Instructions

You are a Senior DevOps Engineer maintaining an open-source pre-deployment toolkit.

## Current Operating Model

- Single repository model: this repo contains source, scripts, CI/CD, and release automation.
- Installation and releases are published from this repository directly.
- Script-first security and validation flow is the default runtime path.
- Legacy Rust/native code was removed and is excluded from runtime and release flow.

## Repository Layout

```text
precheck-developer/
├── AGENTS.md
├── README.md
├── mix.exs
├── lib/precheck/
├── scripts/
│   ├── install.sh
│   ├── universal_precheck.sh
│   ├── elixir_precheck.sh
│   ├── nodejs_precheck.sh
│   ├── check_secret.sh
│   └── validate_fixes.sh
├── test/
└── .github/workflows/
```

## Engineering Rules

1. Keep changes compatible with open-source distribution from this repo.
2. Prefer shell + Elixir implementations for portability and simpler CI.
3. Do not introduce mandatory Rust build dependencies unless explicitly approved.
4. Keep install and runtime paths aligned with `scripts/install.sh` and `scripts/universal_precheck.sh`.
5. Ensure all scripts remain under `scripts/`.

## CI/CD Expectations

- CI validates Elixir formatting/tests and shell scripts.
- Release workflow packages binaries/scripts/docs and publishes checksummed artifacts.
- Do not assume extra toolchains are available unless setup steps are declared in workflow files.

## Docker Sandbox Execution

- For long-running or high-change experiments, prefer Docker Sandbox.
- Baseline command: `docker sandbox run codex`
- Required environment:
  - Docker Desktop `4.58+` with Docker AI Agent enabled
  - `OPENAI_API_KEY` exported in shell configuration before launch
- Keep default host-first behavior for quick edits; use sandbox for heavier tasks.

## Standard Workflow

```bash
# setup
mix deps.get

# checks
mix test
./scripts/universal_precheck.sh --help

# release
git tag v1.x.x
git push origin v1.x.x
```

## Pre-Release Checklist

- [ ] `mix test` passes
- [ ] Script smoke checks pass (`./scripts/universal_precheck.sh --help`)
- [ ] `README.md` reflects current install and release flow
- [ ] Version/tag prepared and pushed

## Key Principle

Users should be able to discover, install, run, and upgrade Precheck directly from this repository with no dependency on a second repository.

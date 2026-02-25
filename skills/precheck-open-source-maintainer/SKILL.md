---
name: precheck-open-source-maintainer
description: Maintain Precheck as a single-repository open-source project. Use this when updating install flow, CI/CD, docs, script checks, Elixir scanner logic, or release packaging for this repo.
---

# Precheck Open-Source Maintainer

## Use This Skill When

- A request changes installation or release behavior.
- Docs must be aligned with actual scripts/workflows.
- CI/CD or validation scripts need updates.
- Security scanning behavior in `lib/` or `scripts/` is modified.

## Source of Truth

- `README.md` for user-facing install/use docs
- `AGENTS.md` for agent operating rules
- `scripts/install.sh` for installation behavior
- `scripts/universal_precheck.sh` for runtime entrypoint
- `.github/workflows/ci.yml` and `.github/workflows/release.yml` for automation

## Required Workflow

1. Inspect impacted files with `rg` before editing.
2. Keep installation tied to this repository only.
3. Prefer script + Elixir solutions; avoid introducing mandatory Rust dependencies.
4. Ensure `README.md`, `AGENTS.md`, and workflow files stay consistent.
5. Run focused validation after edits.

For long-running tasks, use Docker Sandbox when available:

```bash
docker sandbox run codex
```

## Validation Commands

```bash
mix format
mix test
./scripts/universal_precheck.sh --help
```

Optional:

```bash
./scripts/validate_fixes.sh
```

## Guardrails

- Keep all shell scripts under `scripts/`.
- Do not reintroduce dual-repo/private-public release assumptions.
- Do not add hidden install steps that differ from documented commands.

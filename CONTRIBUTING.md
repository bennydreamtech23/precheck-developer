# Contributing to Precheck

Thanks for your interest in contributing.

## Fork-First Policy (Required)

This project accepts external contributions from forks only.

If you are not a core maintainer, you must:

1. Fork this repository to your own GitHub account.
2. Create your feature/fix branch in your fork.
3. Open a pull request from your fork branch to this repository.

Direct branch pushes to this repository are reserved for maintainers.

## Contribution Workflow

1. Fork the repository.
2. Clone your fork:

```bash
git clone https://github.com/<your-username>/precheck-developer.git
cd precheck-developer
```

3. Add upstream remote:

```bash
git remote add upstream https://github.com/bennydreamtech23/precheck-developer.git
git fetch upstream
```

4. Create a branch from latest upstream `master`:

```bash
git checkout -b feat/<short-description> upstream/master
```

5. Make your changes and run checks:

```bash
mix test
./scripts/universal_precheck.sh --help
```

6. Commit and push to your fork:

```bash
git add .
git commit -m "feat: short description"
git push origin feat/<short-description>
```

7. Open a Pull Request from your fork to `bennydreamtech23/precheck-developer:master`.

## Pull Request Requirements

- PR must come from a fork (required for non-maintainers).
- Keep changes focused and explain why they are needed.
- Update docs when behavior changes.
- Ensure checks pass before requesting review.

## Syncing Your Fork

```bash
git fetch upstream
git checkout master
git merge upstream/master
git push origin master
```

## Code Standards

- Keep shell scripts in `scripts/`.
- Prefer portable shell + Elixir implementations.
- Avoid adding mandatory Rust dependencies.


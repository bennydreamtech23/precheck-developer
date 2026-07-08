## v1.0.0 — 2026-07-02

First stable release of Precheck — a pre-deployment validation toolkit for Elixir and Node.js projects.

### Highlights

- Auto-detects Elixir (`mix.exs`) or Node.js (`package.json`) projects and runs the right checks
- Severity-tiered checks (CRITICAL/HIGH/MEDIUM/LOW) with a clear PR-readiness verdict
- Built-in secrets & hardcoded-credential scanner
- One-line installer with global `precheck` command
- Optional shell integration: aliases, git pre-commit hook, enhanced IEx config
- Reusable GitHub Actions workflows (`elixir-ci.yml`, `elixir-deploy.yml`) so any app repo can call shared CI/CD with one `ci-required` check

### Install

````bash
curl -fsSL https://raw.githubusercontent.com/bennydreamtech23/precheck-developer/master/scripts/install.sh | bash


## v1.0.2 — 2026-07-08

Added -- github to enable precheck run on github wihout breaking

### Highlights

- Added --github tag for when we run on CI

### Install

```bash
curl -fsSL https://raw.githubusercontent.com/bennydreamtech23/precheck-developer/master/scripts/install.sh | bash
````

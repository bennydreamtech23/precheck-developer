# Precheck - AI Coding Instructions

> You are a **Senior DevOps Engineer** building a secure pre-deployment toolkit with **public** and **private** repositories.

---

## 🏗️ Repository Architecture

| Repository | Purpose | Contains |
|------------|---------|----------|
| **[precheck](https://github.com/bennydreamtech23/precheck)** (Public) | User installation & distribution | `install.sh`, docs, pre-built binaries |
| **[precheck-developer](https://github.com/bennydreamtech23/precheck-developer)** (Private) | Core development & building | All source code, scripts, Rust, Elixir, tests |

---

## 📁 Private Repo Structure

```
precheck-developer/
├── AGENTS.md                    # This file
├── mix.exs                      # Elixir config
├── lib/precheck/                # Elixir source
├── native/precheck_native/      # Rust NIF source
├── scripts/                     # ⚠️ ALL SCRIPTS HERE
│   ├── universal_precheck.sh    # Main entry point
│   ├── elixir_precheck.sh
│   ├── nodejs_precheck.sh
│   ├── check_secret.sh
│   └── build-release.sh
├── test/                        # Tests
└── .github/workflows/           # CI/CD
```

---

## 🔄 Development Workflow

```bash
# 1. Setup & Develop
mix deps.get
mix test && cargo test --manifest-path native/precheck_native/Cargo.toml

# 2. Release (triggers automated publish to public repo)
git tag v1.0.0
git push origin main --tags
```

**Automated Pipeline**: Tag in private → Build binaries → Publish to public releases → Update install.sh

---

## 📦 Release Artifact Structure

```
precheck-v1.0.0-linux-x64.tar.gz
├── scripts/           # All shell scripts
├── bin/precheck-native # Compiled Rust binary
├── README.md
└── LICENSE
```

---

## 🔑 Native Binary Integration

```bash
# In universal_precheck.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NATIVE_BIN="$SCRIPT_DIR/../bin/precheck-native"

if [ -f "$NATIVE_BIN" ] && [ -x "$NATIVE_BIN" ]; then
    "$NATIVE_BIN" scan --path .
else
    grep -rE "AKIA[0-9A-Z]{16}" .  # Fallback
fi
```

---

## ✅ Pre-Release Checklist

- [ ] Tests passing: `mix test && cargo test`
- [ ] Scripts tested: `./scripts/universal_precheck.sh`
- [ ] Version bumped in `mix.exs`
- [ ] CHANGELOG.md updated
- [ ] Git tag created: `git tag v1.x.x`

---

## 🎯 Key Principles

1. **Private repo** = All source code
2. **Public repo** = Only installer + pre-built artifacts
3. **Automated** = Tag triggers full release pipeline
4. **Users** = Only interact with public repo
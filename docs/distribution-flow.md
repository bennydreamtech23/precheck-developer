# Distribution Flow (KISS)

## Goal

Users install one command (`precheck`) and run checks.  
Internal shell scripts stay private/internal and are never shipped in public release assets.

## Public Artifact Contract

Each release tarball includes only:

- `bin/precheck` (compiled CLI)
- `bin/precheck-core` (compiled CLI alias)
- `priv/native/precheck_native.so` (or platform equivalent)
- `README.md`
- `LICENSE`

Must not include:

- `scripts/`
- any `*.sh` runtime logic

## How It Works

1. Private CI builds Elixir+Rust compiled artifacts.
2. Private CI enforces compiled-only artifact policy.
3. Private CI publishes tarballs + sha256 checksums.
4. Public repo publish workflow mirrors those assets.
5. Public `install.sh` verifies checksum, installs compiled assets only.
6. User runs `precheck` and gets checks.

## Internal Scripts

- Keep script development under `scripts/` in this private repo.
- Keep script tests in private CI (`test-scripts` job).
- Do not package scripts in public release.

## Release Checklist

1. `mix test`
2. `cargo test --manifest-path native/precheck_native/Cargo.toml`
3. `./scripts/universal_precheck.sh --help` (internal only)
4. Tag and push: `git tag vX.Y.Z && git push origin --tags`
5. Verify public release assets do not include shell scripts.

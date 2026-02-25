# Distribution Flow

## Goal

Users install and run `precheck` directly from this repository.

## Release Artifact Contract

Each release tarball includes:

- `bin/precheck`
- `scripts/*.sh`
- `README.md`
- `LICENSE`

## CI/CD Flow

1. CI runs Elixir and script checks.
2. Tag push (`v*`) triggers release build.
3. Release job builds escript and packages scripts/docs.
4. GitHub Release publishes tarballs + sha256 checksums.

## Checklist

1. `mix test`
2. `./scripts/universal_precheck.sh --help`
3. `git tag vX.Y.Z && git push origin vX.Y.Z`

---
name: dependency-upgrade
description: Upgrade dependencies safely - audit first, read changelogs, bump in small staged steps, run tests after each, record breaking changes. Use when asked to update, bump or upgrade packages, fix a vulnerability advisory, or when npm audit / pip-audit / cargo audit / govulncheck reports findings.
license: MIT
metadata:
  version: "1.0"
---

# Dependency upgrade

Small, ordered, tested steps. One ecosystem at a time, one major bump per commit.

## 1. Inventory

- Find the manifest and lockfile (`package.json` + lockfile, `pyproject.toml` + `uv.lock`,
  `go.mod`, `Cargo.toml`); note the install and test commands from `AGENTS.md`.
- Run the audit tool: `npm audit` / `pnpm audit`, `pip-audit`, `cargo audit`,
  `govulncheck ./...`, or `osv-scanner --recursive .`.
- List candidates: security fixes first, then direct dependencies pinned more than one
  major behind, then the rest. Skip transitive-only bumps unless an advisory names them.

## 2. Plan the order

- Group: (a) advisories, (b) patch/minor bumps that need no code change, (c) majors.
- For each major: read the changelog or migration guide *before* bumping. Write one line
  per breaking change that touches this codebase (`rg` for the API).
- Check the license of anything new against the allowlist (`scripts/license-audit.sh`).

## 3. Execute, one group at a time

1. Bump. 2. Install. 3. Run the fast tests, then lint and type-check. 4. Fix the code the
changelog said would break, nothing else. 5. Run the full suite. 6. Commit
(`build(deps): bump <pkg> to <version>`; body lists the breaking changes handled).

If a bump breaks something the changelog did not mention, stop and report it rather than
patching around it; that is either a real upstream bug or a hidden coupling worth knowing.

## 4. Report

```
Advisories fixed: <ids or none>
Bumped: <pkg old→new>, ...
Breaking changes handled: <one line each>
Deferred: <pkg: why (needs X first / no migration path / license)>
Tests: <commands and results>
```

## Do not

- Do not update everything at once; a 40-package bump that breaks cannot be bisected.
- Do not remove a pin to "get latest"; pin the new version.
- Do not disable or skip tests to make the upgrade pass.
- Do not add a dependency to replace a deprecated one without checking its license and
  maintenance first.

---
description: Upgrade dependencies safely — audit, staged bumps, tests after each. Usage — /upgrade [package or "security"]
agent: build
---
Load the dependency-upgrade skill and follow it. Scope (may be empty, meaning: audit and
propose): $ARGUMENTS

Manifests present:
!`ls package.json pnpm-lock.yaml package-lock.json pyproject.toml uv.lock requirements.txt go.mod Cargo.toml 2>/dev/null`

Run the audit tool for the ecosystem, propose the ordered plan (advisories → minors →
majors), and wait for confirmation before bumping anything. Bump one group at a time with
tests after each; commit each group separately.

---
name: repo-onboarding
description: Map an unfamiliar repository quickly and produce or improve its AGENTS.md. Use when a repo has no AGENTS.md, when asked to "explain this codebase", "how is this organised", or before the first substantial change in a new project.
license: MIT
metadata:
  version: "1.0"
---

# Repo onboarding

Goal: in ≤ 30 tool calls, know enough to work safely, and leave an `AGENTS.md` draft behind.
Prefer the local model (`coder-local`) for the reading phase.

## 1. Inventory (no reading yet)

```
git ls-files | head -200          # shape
git ls-files | wc -l              # size
git log --oneline -n 20           # activity, commit style
ls                                # top level
```

Identify: language(s), package manager, build tool, test framework, CI config, container
files, docs directory, existing instruction files (`AGENTS.md`, `CLAUDE.md`, `.cursor/rules`,
`CONTRIBUTING.md`).

## 2. Entry points and commands

- Read the manifest (`package.json` scripts, `pyproject.toml`, `Makefile`, `justfile`,
  `Cargo.toml`, `go.mod`) and CI workflow: these are the *real* build/test/lint commands.
- Find `main`/entry modules and the routing/wiring layer (`rg -n "def main|func main|app\.(get|post|use)|router|Router"`).
- Find configuration loading (env vars, config files).

## 3. Architecture map

For each top-level directory: one line on what lives there. Note the boundaries
(api / domain / persistence / infra), shared utilities, and where a new feature of each kind
would go. Note anything odd: generated code, vendored deps, multiple apps.

## 4. Conventions the code reveals

- naming, error handling style, logging library, test naming and layout, fixtures
- formatter/linter config present (`.prettierrc`, `ruff.toml`, `.golangci.yml`)
- commit message style from `git log`

## 5. Produce `AGENTS.md`

Use `templates/project/AGENTS.md` if available; otherwise this outline, ≤ 150 lines:

```
# <project> — instructions for agents
<one paragraph: what it is, current goal>
## Commands
build / test (fast) / test (full) / lint / format / run — exact, verified
## Map
<dir> — <what>; where to add: routes → …, models → …, tests → …
## Conventions
<what you found in 4>
## Do not
<files never to touch; commands never to run; patterns banned>
## Definition of done
tests pass, lint clean, docs updated where user-visible
```

Run each command you write down; mark any you could not verify with `(unverified)`.

## 6. Report

Summarise in ≤ 20 lines: what it is, how to build/test, three things that would surprise a
newcomer, and open questions for the owners. Offer the `AGENTS.md` as a draft PR, not a
silent commit.

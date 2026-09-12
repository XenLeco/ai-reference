# AGENTS.md — instructions for agents working in this repository

This repository is a **reference and template collection** for AI-assisted engineering.
It contains no application code. Its artifacts are documentation, configuration files
(YAML / JSON / TOML), skills (`SKILL.md` folders) and small shell / PowerShell scripts.

## What matters here

- Accuracy over volume. Every model ID, config key and URL must match current vendor docs.
  If you are not sure a key exists, say so in a comment rather than inventing it.
- Keep the two profiles in sync: any control added to `gateway/config/litellm.enterprise.yaml`
  or `templates/enterprise/` must be explained in `docs/08-enterprise-profile.md`.
- Keep the client-neutral core neutral. OpenCode is the primary client, but nothing in
  `skills/`, `templates/project/AGENTS.md` or `mcp/` may assume OpenCode.
- **Permissive licenses only, safe by default.** Every third-party tool, plugin, MCP server,
  model or container image this repo recommends must be under MIT, MIT-0, Apache-2.0, BSD,
  ISC or similar (allowlist in `skills/community.json`) and must pass the safety gate in
  `docs/11-community-skills.md` (no bundled outbound network, no unpinned code execution,
  telemetry off, reviewable writes). Anything else goes under `excluded` with a reason.
  `scripts/validate.sh` enforces the license field in both catalogs.

## Commands

```bash
./scripts/validate.sh            # lint JSON/YAML/TOML, check skill frontmatter, license gate (bash)
pwsh ./scripts/validate.ps1      # same on Windows
./scripts/evals.sh [--agents]    # promptfoo regression evals through the gateway (needs LITELLM_API_KEY)
cd gateway && docker compose config   # validate compose files
```

## Layout

See the map in `README.md`. Docs are numbered and cross-linked; ADRs live in `docs/adr/`.

## Conventions

- Markdown: one H1 per file, sentence-case headings, tables for matrices, fenced blocks with a language tag.
- Config files carry comments explaining *why*, not *what*, when the format allows comments
  (YAML, TOML, JSONC). Plain JSON gets its explanation in the sibling `README.md`.
- Skills follow the Agent Skills spec: `name` equals the folder name, lowercase-hyphen,
  `description` says what *and when*; keep `SKILL.md` under 200 lines, move detail to `references/`.
- Scripts come in pairs: `foo.sh` (bash, `set -euo pipefail`) and `foo.ps1` (PowerShell 7).
- Dates in docs are absolute (`2026-09-11`), never relative.

## Do not

- Do not put real API keys, tokens or hostnames of private infrastructure anywhere in the repo.
- Do not add a dependency on a paid or closed service for the *personal* profile.
- Do not delete the `Verified:` lines in docs; update the date when you re-check facts.

# 06 — Making a repository AI-ready

*Verified: 2026-09-11.*

An agent works well in a repo that a new senior engineer would work well in on day one,
plus a few things machines need that humans forgive.

## The drop-in set (`templates/project/`)

| File | Purpose |
|---|---|
| `AGENTS.md` | the instructions file; edit every section |
| `CLAUDE.md` | `@AGENTS.md` import for Claude Code |
| `GEMINI.md` | same for Gemini CLI |
| `.cursor/rules/agents.mdc` | same for Cursor (Cursor also reads `AGENTS.md` directly; the rule pins `alwaysApply`) |
| `opencode.json` | project-level OpenCode config: model per agent, instructions, permissions |
| `.mcp.json` | MCP servers for Claude Code / Cursor (OpenCode reads its own `mcp` block) |
| `.editorconfig` | consistent whitespace so agent edits do not produce noise diffs |
| `llms.txt` | reading order for agents and fetch tools; edit the doc list |
| `.agents/skills/` | project-specific skills (empty by default) |

Copy, then edit `AGENTS.md`. Nothing else needs changes to start.

## Structure that helps agents

- **One command per intent**, documented in `AGENTS.md`: `make test`, `npm run lint`,
  `just build`. Agents run what you write there; if the real command is `pnpm -F api
  vitest run --reporter=dot`, write exactly that.
- **A fast test path** (< 30 s) separate from the full suite. Agents iterate; a 10-minute
  suite means they stop running tests.
- **Deterministic setup**: a devcontainer, `mise`/`asdf` `.tool-versions`, or a lockfile
  plus a one-line install. "Works on my machine" is fatal for an agent. The template ships
  `.devcontainer/` (spec and images are MIT): Node, Python, `gh`, OpenCode, `uv`,
  pre-commit and the sandbox runtime preinstalled; the gateway reached at
  `host.docker.internal:4000`; your OpenCode config and skills mounted read-only; keys
  passed from the host environment, never baked into the image.
- **Small modules, explicit boundaries.** Agents read files whole; a 3,000-line file is
  read badly or not at all.
- **Types and tests as specification.** Typed signatures and existing tests are the most
  reliable instructions an agent gets; they are checked, prose is not.
- **Errors that say what to do.** A test failure or lint error that names the fix gets fixed;
  one that says `exit 1` gets guessed at.
- **Docs next to code** (`docs/` at root, `README.md` per package). Agents find them; wikis
  and Notion pages they do not.
- **No secrets on disk in plaintext.** `.env` files are read by agents like any other file.
  Use a secrets manager or at least keep `.env` in `.gitignore` and deny it in agent
  permissions (`templates/enterprise/opencode.json` does).

## Git and review hygiene

- Conventional commits (skill provided). Agents produce better history when the format is
  mechanical.
- Small PRs. Agents can produce a 2,000-line diff in minutes; reviewers cannot review it.
  Cap at what a human reads in 20 minutes, split otherwise.
- **Worktrees for parallel agents.** `git worktree add ../repo-feat feat` lets two sessions
  work without stepping on each other. OpenCode and Claude Code both support this natively.
- **AI disclosure**: a checkbox in the PR template ("AI assisted: yes/no, tool") plus the
  commit trailer `Assisted-by: LLM` (the Linux kernel's format, machine-readable) and, where
  traceability is required, `AI-Tool: <client> <alias>`. The `conventional-commits` skill
  and the `/commit` command add them. Humans alone add `Signed-off-by`.
- Secret scanning in pre-commit (`gitleaks`) and CI. Agents paste things.
- Branch protection: tests + review required, no exceptions for agent branches.

## CI

Run exactly the commands in `AGENTS.md`. If CI and `AGENTS.md` disagree, agents will
"fix" the wrong one. The template ships three workflows: `security-scan.yml` (gitleaks,
OSV-Scanner, Trivy, the license audit), `ai-review.yml` (OpenCode's read-only `/review-pr`
through the gateway on a `ci` key, skipped for fork PRs) and `ai-assist.yml` (`/oc` mentions
by repository members). A Claude Code variant is next to them as `.example`. The gateway
must be reachable from the runner, which for a personal localhost gateway means a
self-hosted runner. Never let CI agents push; the enterprise variant also requires a label.

## Monorepos

Root `AGENTS.md` for shared rules and the map; a nested `AGENTS.md` per package for its
commands and quirks. OpenCode and Codex read nested files automatically; Claude Code does
through imports (`@packages/api/AGENTS.md`) or its own nested `CLAUDE.md`. The `instructions`
key in `opencode.json` can glob them: `"instructions": ["packages/*/AGENTS.md"]`.

## Checklist before turning agents loose on a repo

- [ ] `AGENTS.md` exists, commands in it run as written, under 300 lines
- [ ] fast test command exists and passes on a clean clone
- [ ] `.gitignore` covers env files, build output, agent session dirs
- [ ] secret scanning on commit and in CI
- [ ] permissions: destructive git and network commands set to `ask` (OpenCode/Claude Code) or sandboxed (Codex)
- [ ] a virtual key per tool, with a budget, in the developer's shell profile — not in the repo
- [ ] PR template has an AI-assistance line
- [ ] (enterprise) data classification of the repo recorded in `AGENTS.md` policy block (08)

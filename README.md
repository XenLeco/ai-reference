# AI Reference — an AI-ready engineering setup

A reference repository for adopting AI coding agents well. It documents and ships a
working configuration for a **gateway-first** setup:

```
 editors / CLIs / SDKs  ──►  LiteLLM gateway  ──►  Anthropic · OpenAI · local (Ollama / vLLM) · hosted open models
 (OpenCode is primary)       one URL, one key,     Claude Fable 5.1 / Opus 5 / Sonnet 5 / Haiku 4.5
                             role aliases,         GPT-6 Astra / GPT-5.6 Sol · Terra · Luna
                             fallbacks, budgets    Gemma 4 (E2B · E4B · 12B · 26B-A4B · 31B) · Qwen3-Coder (30B-A3B · 480B-A35B · Next)
```

**OpenCode + LiteLLM is the main path**, but nothing here depends on OpenCode. Instructions
live in `AGENTS.md`, skills follow the open Agent Skills spec, MCP servers are declared once,
and every client (Claude Code, Codex CLI, Cursor, Gemini CLI, SDKs) points at the same gateway.
Swap the client, keep the rest.

Two profiles ship side by side:

| Profile | For | What changes |
|---|---|---|
| **personal** | your own machines and repos | convenience defaults, local models for free/offline work, one virtual key per client for spend tracking |
| **enterprise** | working inside a company with policies | explicit allowlists, per-developer keys and budgets, PII masking, content logging off, data-classification routing, managed client settings, a written policy |

## Quick start (personal)

1. **Gateway.** Copy `gateway/.env.example` to `gateway/.env`, add your vendor keys, then:
   ```bash
   cd gateway && docker compose up -d && ./scripts/smoke-test.sh
   ```
2. **Client.** On the machine where you run OpenCode, install the config, agents, commands and skills:
   ```bash
   ./scripts/install-personal.sh      # scripts/install-personal.ps1 on Windows
   ```
3. **Project.** Copy `templates/project/*` into any repository and edit its `AGENTS.md`.

Then run `opencode` in that repo, type `/models`, pick `coder-fast`. Everything else is documented below.

## Map

| Path | What it is |
|---|---|
| [docs/00-overview.md](docs/00-overview.md) | Architecture, design principles, how the pieces fit |
| [docs/01-models.md](docs/01-models.md) | Model catalog (Anthropic, OpenAI, Gemma 4, Qwen3-Coder), tiers, selection matrix |
| [docs/02-gateway-litellm.md](docs/02-gateway-litellm.md) | Gateway design: aliases, routing, fallbacks, keys, budgets, observability |
| [docs/03-opencode.md](docs/03-opencode.md) | Primary client: config, agents, commands, skills, MCP, permissions |
| [docs/04-other-clients.md](docs/04-other-clients.md) | Claude Code, Codex CLI, Cursor, Gemini CLI, Copilot, SDKs — all through the gateway |
| [docs/05-agents-skills-commands.md](docs/05-agents-skills-commands.md) | Designing agents, skills and commands that port across tools |
| [docs/06-repo-conventions.md](docs/06-repo-conventions.md) | Making any repository AI-ready (AGENTS.md, structure, tests, CI) |
| [docs/07-security-privacy.md](docs/07-security-privacy.md) | Secrets, prompt injection, data handling, MCP hygiene |
| [docs/08-enterprise-profile.md](docs/08-enterprise-profile.md) | Company mode: policy, controls, compliance mapping, rollout |
| [docs/09-workflows.md](docs/09-workflows.md) | Day-to-day playbooks: feature, bug, refactor, review, docs |
| [docs/10-troubleshooting.md](docs/10-troubleshooting.md) | Known failure modes and fixes |
| [docs/11-community-skills.md](docs/11-community-skills.md) | Third-party tools that cut consumption (Serena, code graphs, beads) or sharpen decisions (superpowers, spec-kit, compound-engineering, AI-DLC); vetting checklist, recommended stacks |
| [docs/12-roadmap.md](docs/12-roadmap.md) | Researched backlog: what to add next, prioritised, each item checked against the license and safety gates |
| [docs/13-local-inference.md](docs/13-local-inference.md) | Local models: hardware sizing, quantisation, context window, speculative decoding, engine choice |
| [docs/adr/](docs/adr/) | Decision records for the non-obvious choices |
| [gateway/](gateway/) | LiteLLM: compose files, `litellm.personal.yaml`, `litellm.enterprise.yaml`, scripts |
| [clients/opencode/](clients/opencode/) | Global `opencode.json`, agents, commands (installed to `~/.config/opencode/`) |
| [clients/claude-code/](clients/claude-code/) · [codex/](clients/codex/) · [cursor/](clients/cursor/) · [gemini-cli/](clients/gemini-cli/) · [sdk/](clients/sdk/) | Per-client gateway wiring |
| [llms.txt](llms.txt) | Reading order for agents and fetch tools (the project template ships one too) |
| [skills/](skills/) | Portable skills (Agent Skills spec), installed to `~/.agents/skills`; `community.json` catalogs vetted third-party ones |
| [evals/promptfoo/](evals/promptfoo/) | Regression evals for the skills and agents, run through the gateway with promptfoo (`scripts/evals.sh`) |
| [evals/bakeoff/](evals/bakeoff/) | Model bake-off: same tasks across aliases, pass rate / latency / tokens, standard library only |
| [clients/agent-sdk/](clients/agent-sdk/) | Claude Agent SDK (MIT) example for scheduled read-only automations through the gateway |
| [mcp/](mcp/) | MCP server catalog and per-client declaration formats |
| [templates/project/](templates/project/) | Drop-in files for any repo (`AGENTS.md`, `opencode.json`, `.mcp.json`, …) |
| [templates/enterprise/](templates/enterprise/) | Policy file, managed settings, stricter project config |
| [scripts/](scripts/) | Install and validate helpers (bash + PowerShell); `install-community-skills` is the opt-in installer for third-party skills; `license-audit` checks a project's dependency tree against the permissive allowlist |

## Principles (short version)

1. **One gateway, one credential per client.** Vendor keys never touch a laptop or a repo.
2. **Clients ask for a role, not a vendor.** `coder-fast`, `reasoning-max`, `coder-local` are stable names; what they resolve to is a gateway decision.
3. **`AGENTS.md` is the single source of instructions.** `CLAUDE.md`, `GEMINI.md` and Cursor rules only import it.
4. **Skills over prompts.** Reusable know-how lives in `SKILL.md` folders that every major agent can load.
5. **Local models are first-class.** Gemma 4 and Qwen3-Coder cover exploration, private data and offline work at zero API cost.
6. **Everything is config-as-code and reviewable.** Gateway config, agent definitions and policies live in git.
7. **Enterprise is a profile, not a fork.** Same layout, stricter values.
8. **Permissive licenses only, safe by default.** Every recommended tool, plugin, MCP server, model and image is MIT/Apache/BSD-class and passes a safety gate (no bundled outbound network, pinned code, telemetry off). The validator enforces it; the repo itself is MIT.

## Status and maintenance

Model IDs, prices and tool config schemas move fast. Each doc carries a `Verified:` line with
the date its facts were last checked against vendor documentation. Re-run `scripts/validate.sh`
after edits; it lints JSON/YAML/TOML and checks skill frontmatter.

This directory is not yet a git repository with history. Run `git init` and commit when the
first pass looks right (see [docs/06-repo-conventions.md](docs/06-repo-conventions.md)).

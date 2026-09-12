# 03 — OpenCode, the primary client

*Verified: 2026-09-11 against opencode.ai/docs (config, providers, agents, commands, skills,
mcp-servers, rules) and docs.litellm.ai/docs/tutorials/opencode_integration.*

OpenCode is an open-source terminal coding agent with a TUI, primary agents and subagents,
custom commands, skills, MCP, LSP integration and a permission system. It is the primary
client here because it is provider-agnostic by design and its configuration is plain JSON
that lives in git.

## Install

```bash
curl -fsSL https://opencode.ai/install | bash     # or: npm i -g opencode-ai, brew install sst/tap/opencode
opencode --version
```

## Configuration files and precedence

Files merge; later wins:

1. remote config (`.well-known/opencode`, org use)
2. **global** `~/.config/opencode/opencode.json` (Windows: `%USERPROFILE%\.config\opencode\`)
3. `$OPENCODE_CONFIG` path
4. **project** `opencode.json` in the repo root
5. `.opencode/` directories: `agents/`, `commands/`, `skills/`, `plugins/`, `tools/`, `themes/`
6. `$OPENCODE_CONFIG_CONTENT` inline
7. managed/admin config (`/etc/opencode/`, macOS managed preferences)

This repo installs the **global** file from `clients/opencode/opencode.json` and ships a
**project** template in `templates/project/opencode.json`. Global holds the provider and
personal defaults; project holds repo-specific model choices, instructions and permissions.

Values support `{env:NAME}` and `{file:path}` substitution.

## The provider block (LiteLLM)

```json
"provider": {
  "litellm": {
    "npm": "@ai-sdk/openai-compatible",
    "name": "LiteLLM Gateway",
    "options": {
      "baseURL": "http://localhost:4000/v1",
      "apiKey": "{env:LITELLM_API_KEY}"
    },
    "models": {
      "coder-fast": {
        "name": "coder-fast (Sonnet 5 via gateway)",
        "limit": { "context": 1000000, "output": 128000 },
        "modalities": { "input": ["text", "image"], "output": ["text"] },
        "tool_call": true,
        "reasoning": true
      }
    }
  }
}
```

Rules that matter:

- `npm` is `@ai-sdk/openai-compatible` (Chat Completions). Use `@ai-sdk/openai` only if you
  want the Responses API; the gateway serves both.
- Model keys **must equal** the gateway `model_name`s. Anything missing here is invisible to
  `/models`.
- Declare `modalities` with `image` for vision-capable models; custom providers default to
  text-only.
- `limit.context` / `limit.output` drive compaction; set them to the real values of the model
  behind the alias (they are conservative for aliases whose fallback is smaller).
- `reasoning: true` lets OpenCode send reasoning options; the gateway drops
  `reasoningSummary` for providers that reject it.
- `cost` (per 1M tokens) is optional and only feeds the TUI's cost display.

`model` is `"litellm/coder-fast"` and `small_model` (titles, summaries) is
`"litellm/local-small"` in the personal profile — free and private.

## Agents

Built-in **primary** agents: `build` (all tools) and `plan` (edits and bash default to
`ask`). Built-in **subagents**: `general`, `explore` (read-only), `scout` (read-only,
dependencies and external docs). Switch primaries with Tab; invoke subagents with
`@name` or let the primary delegate through the Task tool.

Custom agents are markdown files with frontmatter in `.opencode/agents/` (project) or
`~/.config/opencode/agents/` (global). Older releases used the singular `agent/`; both are
still read.

```markdown
---
description: Reviews a diff for correctness, security and maintainability. Read-only. Use before committing.
mode: subagent
model: litellm/coder-fast
temperature: 0.1
permission:
  edit: deny
  bash:
    "*": deny
    "git diff*": allow
    "git log*": allow
    "git status": allow
---
System prompt body…
```

Fields: `description` (required; the primary agent uses it to decide when to delegate),
`mode` (`primary` | `subagent` | `all`), `model`, `temperature`, `steps` (max iterations),
`permission`, `hidden`, `color`, `prompt` (`{file:…}` to load from a file).

This repo ships in `clients/opencode/agents/`:

| Agent | Mode | Model | Tools | Purpose |
|---|---|---|---|---|
| `architect` | subagent | `reasoning-max` | read-only | design options, trade-offs, migration plans |
| `reviewer` | subagent | `coder-fast` | read-only + `git diff/log/status` | pre-commit and PR review |
| `test-writer` | subagent | `coder-fast` | edit + test runners | write/extend tests from a spec or a diff |
| `docs-writer` | subagent | `coder-cheap` | edit docs only | READMEs, ADRs, changelogs |
| `security-auditor` | subagent | `coder-frontier` | read-only | OWASP/secrets/dependency review of a change |
| `local-scout` | subagent | `coder-local` | read-only | cheap, private codebase exploration; summarises for the primary |

And it overrides the built-ins' models in `opencode.json`: `build` → `coder-fast`,
`plan` → `reasoning-max`, `general` → `coder-fast`, `explore` → `coder-local`.

`opencode agent create` scaffolds a new one interactively.

## Commands

Markdown files in `.opencode/commands/` or `~/.config/opencode/commands/`; the filename is
the slash command. Frontmatter: `description`, `agent`, `model`, `subtask` (run as a
subagent). Body is the prompt template; `$ARGUMENTS` / `$1…$n` are substituted,
`` !`cmd` `` injects shell output, `@path` injects a file.

```markdown
---
description: Review staged changes (or the ref range in $ARGUMENTS)
agent: reviewer
subtask: true
---
Review these changes. Findings first, ordered by severity, with file:line.
!`git diff --staged $ARGUMENTS`
```

Shipped commands: `/review`, `/test`, `/commit`, `/pr`, `/explain`, `/fix`, `/docs`,
`/plan`, `/security`. See `clients/opencode/commands/`.

## Skills

OpenCode loads Agent Skills from `.opencode/skills/<name>/SKILL.md`,
`.claude/skills/<name>/SKILL.md` and `.agents/skills/<name>/SKILL.md` (project, walking up
to the git root), and from the same three paths under `~`. This repo installs to
`~/.agents/skills/` so Claude Code and Codex see the same skills.

Agents discover skills through the native `skill` tool (name + description are always
visible; the body loads on demand). Permission per skill pattern:

```json
"permission": { "skill": { "*": "allow", "enterprise-*": "ask" } }
```

## MCP servers

```json
"mcp": {
  "context7": { "type": "remote", "url": "https://mcp.context7.com/mcp", "enabled": true },
  "filesystem": {
    "type": "local",
    "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "."],
    "enabled": false
  }
}
```

`type: local` runs a process (`command`, `environment`, `cwd`); `type: remote` connects to a
URL (`headers`, optional `oauth`). Default timeout 5 s (`timeout` in ms). Disable a server's
tools globally with `"tools": { "context7*": false }` and re-enable per agent. The catalog
and the reasoning about which servers are worth it are in `mcp/`.

## Permissions

`allow` / `ask` / `deny` per tool, with glob patterns for `bash` and `skill`. Personal
defaults in this repo:

```json
"permission": {
  "edit": "allow",
  "bash": {
    "*": "allow",
    "git push*": "ask",
    "git reset --hard*": "ask",
    "rm -rf*": "ask",
    "docker*": "ask",
    "curl*": "ask"
  },
  "webfetch": "allow",
  "skill": { "*": "allow" }
}
```

Read-only subagents get `edit: deny` and a bash allowlist in their own frontmatter, which
overrides the global setting. The enterprise profile flips `edit` and `bash` to `ask` by
default and denies network tools (08).

## Instructions

`AGENTS.md` in the repo root (and parents, up to the git root) is loaded automatically;
`~/.config/opencode/AGENTS.md` holds personal preferences. `CLAUDE.md` is read as a fallback
when no `AGENTS.md` exists (`OPENCODE_DISABLE_CLAUDE_CODE=1` turns that off). The
`instructions` key adds more files, globs or URLs:

```json
"instructions": ["docs/CONTRIBUTING.md", "packages/*/AGENTS.md"]
```

## Other settings worth setting

| Key | Personal value | Why |
|---|---|---|
| `share` | `"manual"` | never auto-publish sessions; enterprise uses `"disabled"` |
| `autoupdate` | `"notify"` | know when a new version lands, decide when to take it |
| `compaction.auto` | `true` | long sessions survive |
| `compaction.prune` | `true` | drop stale tool output before summarising |
| `snapshot` | `true` | file snapshots enable undo |
| `default_agent` | `"build"` | |
| `enabled_providers` | `["litellm"]` | hides direct-vendor providers so nothing bypasses the gateway |
| `subagent_depth` | `1` | subagents cannot spawn subagents; keeps cost bounded |
| `lsp` | `true` | diagnostics reach the model |
| `formatter` | leave default | OpenCode runs the repo's formatter after edits |

## Install from this repo

`scripts/install-personal.sh` copies `clients/opencode/{opencode.json,AGENTS.md,agents,commands}`
into `~/.config/opencode/` and `skills/*` into `~/.agents/skills/`. It never overwrites an
existing `opencode.json` without `--force`; it writes `opencode.json.new` next to it instead.

Set `LITELLM_API_KEY` in your shell profile to the virtual key you created for OpenCode.
Verify with `opencode` → `/models`; the list should show only the gateway's aliases.

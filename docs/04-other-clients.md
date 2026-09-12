# 04 — Other clients through the same gateway

*Verified: 2026-09-11 against code.claude.com/docs (llm-gateway, llm-gateway-connect),
learn.chatgpt.com/docs/config-file/config-reference (Codex), docs.litellm.ai
(anthropic_unified, responses API), vendor IDE docs.*

The gateway exposes three wire formats. Every client below only needs a base URL and a
virtual key. Create one key per client (`gateway/scripts/create-key.sh <alias>`), so spend
is attributable and revocation is surgical.

## Portability matrix

What each tool reads, so you know which parts of this repo carry over:

| Capability | OpenCode | Claude Code | Codex CLI | Cursor | Gemini CLI |
|---|---|---|---|---|---|
| Instructions file | `AGENTS.md` (native), `CLAUDE.md` fallback | `CLAUDE.md` (import `@AGENTS.md`) | `AGENTS.md` (native) | `AGENTS.md` (native) + `.cursor/rules/*.mdc` | `GEMINI.md` (import `@AGENTS.md`) |
| Skills (`SKILL.md`) | `.agents/skills`, `.claude/skills`, `.opencode/skills` | `.claude/skills`, `~/.claude/skills`, `.agents/skills` | `.agents/skills`, `~/.agents/skills` | partial (rules only) | partial |
| MCP | `opencode.json` → `mcp` | `.mcp.json`, `~/.claude.json` | `config.toml` → `[mcp_servers.*]` | `.cursor/mcp.json` | `settings.json` → `mcpServers` |
| Slash commands | `.opencode/commands/*.md` | `.claude/commands/*.md` (same frontmatter idea) | prompts in `~/.codex/prompts/` | none | custom commands TOML |
| Subagents | `.opencode/agents/*.md` | `.claude/agents/*.md` | none (single agent) | none | none |
| Gateway wire format | Chat Completions (or Responses) | Anthropic Messages | Responses | Chat Completions | Gemini native only |
| Non-vendor models via gateway | any | **Claude models only** (Anthropic does not support routing Claude Code to other models) | any model the gateway serves on `/v1/responses` | any (chat only) | no |

`.agents/skills/` is the cross-tool location; this repo installs skills there and symlinks
`.claude/skills` to it where a tool insists on its own path.

## Claude Code

Claude Code speaks the Anthropic Messages format, which LiteLLM serves on `/v1/messages`.
The base URL is the **gateway root** (no `/v1`).

`~/.claude/settings.json` (from `clients/claude-code/settings.json`):

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://localhost:4000",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-5",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-5",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "claude-haiku-4-5",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "apiKeyHelper": "~/.claude/get-gateway-key.sh"
}
```

- Credential: `ANTHROPIC_AUTH_TOKEN` (sent as `Authorization: Bearer`, which LiteLLM reads)
  or an `apiKeyHelper` script that prints the key (rotation-friendly; sends both headers).
  `ANTHROPIC_API_KEY` also works (`x-api-key`) but prompts once for approval.
- While a gateway credential is set, the claude.ai subscription is **not** used; usage is
  billed to whoever owns the upstream key. Remote Control and voice features are unavailable.
- The three `ANTHROPIC_DEFAULT_*_MODEL` pins must be names the gateway serves. Keep the
  vendor-native names in the gateway for this reason. Haiku pin also moves background tasks
  (titles) to that model.
- `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1` makes `/model` list what the gateway
  returns from `/v1/models`.
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` stops telemetry to Anthropic hosts; the
  enterprise profile requires it.
- Verify: `curl -X POST $ANTHROPIC_BASE_URL/v1/messages -H "Authorization: Bearer $KEY"
  -H "anthropic-version: 2023-06-01" -H "content-type: application/json" -d '{"model":"claude-haiku-4-5","max_tokens":16,"messages":[{"role":"user","content":"ping"}]}'`.
- Enterprise: distribute `clients/claude-code/managed-settings.enterprise.json` through
  managed settings (macOS `/Library/Application Support/ClaudeCode/managed-settings.json`,
  Linux `/etc/claude-code/managed-settings.json`, Windows `C:\Program Files\ClaudeCode\managed-settings.json`)
  so developers configure nothing and cannot override permissions.

## Codex CLI

Codex speaks the Responses API only (`wire_api = "responses"`); LiteLLM serves it on
`/v1/responses` and bridges to Chat Completions for providers that lack it, so Claude and
local models work too.

`~/.codex/config.toml` (from `clients/codex/config.toml`):

```toml
model_provider = "litellm"
model = "gpt-6-astra"            # or an alias such as "coder-frontier"
model_reasoning_effort = "high"
approval_policy = "on-request"
sandbox_mode = "workspace-write"

[model_providers.litellm]
name = "LiteLLM Gateway"
base_url = "http://localhost:4000/v1"
env_key = "LITELLM_API_KEY"
wire_api = "responses"

[mcp_servers.context7]
command = "npx"
args = ["-y", "@upstash/context7-mcp"]
```

Codex reads `AGENTS.md` natively (root and nested) and skills from `.agents/skills/`.
Sandbox modes: `read-only`, `workspace-write`, `danger-full-access`; approval policies:
`untrusted`, `on-request`, `on-failure`, `never`. Enterprise: `workspace-write` +
`on-request`, project trust explicit in `[projects."<path>"]`.

## Cursor

Cursor supports an OpenAI-compatible override: *Settings → Models → OpenAI API Key*, enable
*Override OpenAI Base URL* → `http://localhost:4000/v1`, then add custom model names that
match gateway aliases. Limits: only chat/agent completions route through the override; Tab
completion and some Composer features run on Cursor's own backend and cannot be redirected.
Enable *Privacy Mode* in enterprise use.

Rules: Cursor reads `AGENTS.md` at the repo root. For folder-scoped rules add
`.cursor/rules/*.mdc`; the template in `templates/project/.cursor/rules/agents.mdc` just
points at `AGENTS.md` so there is one source. MCP: `.cursor/mcp.json` (same JSON shape as
Claude Code's `.mcp.json`).

## Gemini CLI

Gemini CLI talks the Gemini API natively and does not accept an OpenAI-compatible base URL.
Use it directly against Gemini models with `GEMINI_API_KEY`, and keep `GEMINI.md` as a
one-line import of `AGENTS.md` (`templates/project/GEMINI.md`). Routing it through the
gateway is possible via LiteLLM's Gemini pass-through and `GOOGLE_GEMINI_BASE_URL`, but that
path changes between releases; verify against the current Gemini CLI docs before relying on
it. MCP servers go in `~/.gemini/settings.json` under `mcpServers`.

## GitHub Copilot (VS Code)

Copilot's *Manage Models → Bring your own key* supports Anthropic, OpenAI, Azure, Ollama
and OpenAI-compatible endpoints on individual plans. Point the OpenAI-compatible entry at
the gateway with a virtual key. Enterprise Copilot plans often disable BYOK; check with the
admin before assuming it works.

## Continue, Cline, Aider, Zed and others

Anything with an "OpenAI-compatible" provider works: base URL `http://localhost:4000/v1`,
API key = virtual key, model = an alias. Aider: `OPENAI_API_BASE` + `--model openai/coder-fast`.

## SDKs, scripts and CI

- OpenAI SDK: `OpenAI(base_url="http://gateway:4000/v1", api_key=KEY)`; `model="coder-fast"`.
- Anthropic SDK: `Anthropic(base_url="http://gateway:4000", api_key=KEY)`; `model="claude-sonnet-5"`.
- Any request may add `x-litellm-tags: ci,repo=foo` for tag routing and spend breakdown.
- CI gets its own key with a small budget and a `ci` tag; store it as a CI secret, never in
  the workflow file. Examples in `clients/sdk/`.

## When a client cannot use the gateway

Some tools only accept a vendor key (mobile apps, some hosted IDEs). Prefer not to use them
for repo work in the enterprise profile; in the personal profile, give them a dedicated
vendor key with a spend cap set in the vendor console so the blast radius stays small.

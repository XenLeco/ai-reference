# mcp/ — MCP server catalog

MCP gives agents tools for **external systems**: documentation indexes, trackers, browsers,
databases. Do not use it for what a shell already does (git, gh, docker); every enabled server
adds its tool descriptions to every request. Enable per agent, not globally.

`catalog.json` lists servers this setup has vetted, with transport, package/URL, purpose, risk
notes and which profile allows them. Per-client declaration formats:

| Client | File | Shape |
|---|---|---|
| OpenCode | `opencode.json` → `mcp` | `{ "name": { "type": "local", "command": [...] } }` or `{ "type": "remote", "url": "..." }` |
| Claude Code | `.mcp.json` (project) / `~/.claude.json` | `{ "mcpServers": { "name": { "command": "...", "args": [...] } } }` or `{ "type": "http", "url": "..." }` |
| Codex | `~/.codex/config.toml` → `[mcp_servers.name]` | `command = "..."`, `args = [...]` |
| Cursor | `.cursor/mcp.json` | same as Claude Code |
| Gemini CLI | `~/.gemini/settings.json` → `mcpServers` | `{ "command": ... }` or `{ "httpUrl": "..." }` |

## Rules

- Pin versions in `npx -y pkg@x.y.z`; `@latest` is a supply-chain hole.
- Remote servers over HTTPS only; tokens from env (`{env:...}` in OpenCode, `env` block elsewhere).
- Read the tool list of a server before enabling it; a filesystem server rooted at `/` is a shell.
- Enterprise: only servers in `catalog.json` with `"enterprise": true`; add through PR + security review.

## Catalog summary

| Server | Transport | Purpose | Personal | Enterprise |
|---|---|---|---|---|
| serena | local (uv) | LSP symbol navigation and editing; the biggest retrieval saving | yes, scoped per agent | yes, vendored |
| code-review-graph | local (uv) | self-updating code graph, blast radius, no LLM calls | yes (pick this or graphify), scoped per agent | yes, pinned |
| context7 | remote HTTP / npx | current library docs by version | yes | yes (remote, no data leaves except queries) |
| github | remote HTTP (PAT) / binary | issues, PRs, code search on GitHub | yes | with org PAT, read scopes |
| playwright | npx | browser automation for E2E and scraping | yes | ask: outbound network |
| postgres (read-only) | npx | schema and read queries on a dev DB | yes | only against non-production, tagged restricted |
| sentry | remote HTTP (OAuth) | error context for debugging | yes | yes |
| atlassian (Jira/Confluence) | remote HTTP (OAuth) | ticket context | optional | yes, typical |
| filesystem | npx | file access outside the repo | rarely needed | no |

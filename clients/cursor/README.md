# clients/cursor/ — Cursor through the gateway

Cursor can route its chat and agent completions through an OpenAI-compatible endpoint.
Details and limits: [docs/04-other-clients.md](../../docs/04-other-clients.md).

## Setup

1. `gateway/scripts/create-key.sh cursor 50 30d`.
2. Cursor → *Settings → Models*:
   - OpenAI API Key: paste the virtual key.
   - Enable *Override OpenAI Base URL* → `http://localhost:4000/v1` (or your gateway host).
   - *Add model* for each gateway name you want in the picker: `coder-fast`, `coder-frontier`,
     `reasoning-max`, `coder-local`.
3. Pick the model in the chat/agent panel.

## Limits

- Only chat/agent completions use the override. Tab completion and some Composer features
  run on Cursor's own backend and cannot be redirected.
- Cursor may verify the key with a request against its own model list; if verification fails,
  the override still works for the custom model names you added.
- Enterprise: enable *Privacy Mode*; if the plan forbids custom endpoints, treat Cursor as a
  vendor-direct tool restricted to Public/Internal repos (docs/08 §5).

## Rules and MCP

- Cursor reads `AGENTS.md` at the repo root. `templates/project/.cursor/rules/agents.mdc`
  additionally pins it with `alwaysApply: true`.
- MCP: `.cursor/mcp.json`, same shape as Claude Code's `.mcp.json` (`templates/project/.mcp.json`).

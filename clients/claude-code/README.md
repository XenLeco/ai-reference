# clients/claude-code/ — Claude Code through the gateway

Claude Code speaks the Anthropic Messages format; the gateway serves it at `/v1/messages`.
Base URL is the gateway **root** (no `/v1`). Details: [docs/04-other-clients.md](../../docs/04-other-clients.md).

| File | Installed as | Purpose |
|---|---|---|
| `settings.json` | merge into `~/.claude/settings.json` | gateway URL, model pins, telemetry off, key helper, safe permissions |
| `get-gateway-key.sh` / `.ps1` | `~/.claude/` | `apiKeyHelper`: prints the virtual key from an env var or a key file |
| `managed-settings.enterprise.json` | managed settings path (admin-distributed) | locked-down enterprise configuration users cannot override |

## Personal setup

1. Create a key: `gateway/scripts/create-key.sh claude-code 50 30d`.
2. Store it: `export LITELLM_CLAUDE_CODE_KEY=sk-...` in your shell profile, **or** write it to
   `~/.config/ai-gateway/claude-code.key` (mode 600). The helper checks both.
3. Copy `get-gateway-key.sh` to `~/.claude/` and `chmod +x` it (Windows: the `.ps1`, and set
   `apiKeyHelper` to `powershell -NoProfile -File C:\Users\<you>\.claude\get-gateway-key.ps1`).
4. Merge `settings.json` into `~/.claude/settings.json` (`scripts/install-personal.sh` writes
   `~/.claude/settings.gateway.json` for you to merge by hand; it never overwrites).
5. Run `claude`; the Status tab should show the gateway base URL and `apiKeyHelper` as the
   credential source. Verify with the curl in docs/04.

Alternative to the helper: put `ANTHROPIC_AUTH_TOKEN` in the `env` block. Simpler, but the
key then sits in a JSON file.

## Notes

- While the gateway credential is active, your claude.ai subscription is not used and
  Remote Control / voice are unavailable. Unset `ANTHROPIC_BASE_URL` and the helper to go back.
- Anthropic does not support routing Claude Code to non-Claude models through a gateway;
  keep the three model pins on Claude names the gateway serves.
- `CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1` makes `/model` list the gateway's models.
- Managed settings locations: macOS `/Library/Application Support/ClaudeCode/managed-settings.json`,
  Linux `/etc/claude-code/managed-settings.json`, Windows `C:\Program Files\ClaudeCode\managed-settings.json`.

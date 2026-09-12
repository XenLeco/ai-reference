#!/usr/bin/env bash
# apiKeyHelper for Claude Code: print the gateway virtual key and nothing else.
# Source order: LITELLM_CLAUDE_CODE_KEY env var, then ~/.config/ai-gateway/claude-code.key.
# Enterprise: replace the body with a call to the org's secrets tool (vault, 1password, aws secretsmanager).
set -euo pipefail
if [[ -n "${LITELLM_CLAUDE_CODE_KEY:-}" ]]; then
  printf '%s' "$LITELLM_CLAUDE_CODE_KEY"
  exit 0
fi
f="${XDG_CONFIG_HOME:-$HOME/.config}/ai-gateway/claude-code.key"
if [[ -r "$f" ]]; then
  tr -d '[:space:]' < "$f"
  exit 0
fi
echo "no gateway key: set LITELLM_CLAUDE_CODE_KEY or create $f" >&2
exit 1

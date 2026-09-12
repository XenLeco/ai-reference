#!/usr/bin/env bash
# Exercise the gateway on every wire format clients use.
# Usage: LITELLM_API_KEY=sk-... ./smoke-test.sh [chat_model=coder-cheap] [anthropic_model=claude-haiku-4-5]
set -euo pipefail

BASE="${LITELLM_BASE_URL:-http://localhost:4000}"
KEY="${LITELLM_API_KEY:-${LITELLM_MASTER_KEY:-}}"
MODEL="${1:-coder-cheap}"
ANTHROPIC_MODEL="${2:-claude-haiku-4-5}"

if [[ -z "$KEY" ]]; then
  echo "error: set LITELLM_API_KEY (a virtual key) or LITELLM_MASTER_KEY" >&2
  exit 1
fi

pretty() {
  if command -v python3 >/dev/null 2>&1; then python3 -m json.tool; elif command -v jq >/dev/null 2>&1; then jq .; else cat; fi
}

step() { printf '\n== %s ==\n' "$1"; }

step "liveliness"
curl -fsS "$BASE/health/liveliness"; echo

step "models visible to this key"
curl -fsS -H "Authorization: Bearer $KEY" "$BASE/v1/models" \
  | { python3 -c 'import sys,json; [print(" -", m["id"]) for m in sorted(json.load(sys.stdin)["data"], key=lambda m: m["id"])]' 2>/dev/null || cat; }

step "chat completions ($MODEL)"
curl -fsS "$BASE/v1/chat/completions" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"Reply with the single word OK.\"}],\"max_tokens\":16}" \
  | pretty

step "responses API ($MODEL)"
curl -fsS "$BASE/v1/responses" \
  -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" \
  -d "{\"model\":\"$MODEL\",\"input\":\"Reply with the single word OK.\",\"max_output_tokens\":16}" \
  | pretty

step "anthropic messages ($ANTHROPIC_MODEL)"
curl -fsS "$BASE/v1/messages" \
  -H "Authorization: Bearer $KEY" -H "anthropic-version: 2023-06-01" -H "Content-Type: application/json" \
  -d "{\"model\":\"$ANTHROPIC_MODEL\",\"max_tokens\":16,\"messages\":[{\"role\":\"user\",\"content\":\"Reply with the single word OK.\"}]}" \
  | pretty

step "key info"
curl -fsS -H "Authorization: Bearer $KEY" "$BASE/key/info" | pretty || echo "(key/info needs a virtual key; skipped)"

printf '\nall checks passed\n'

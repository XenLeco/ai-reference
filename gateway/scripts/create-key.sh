#!/usr/bin/env bash
# Issue a virtual key. Requires the master key in LITELLM_MASTER_KEY.
#
# Usage:
#   create-key.sh <alias> [max_budget_usd] [budget_duration] [models] [tags] [team_id]
#     alias            e.g. opencode-laptop, claude-code, codex, ci, alice-opencode
#     max_budget_usd   default 25
#     budget_duration  default 30d   (e.g. 1d, 7d, 30d)
#     models           comma list of model names or access groups; empty = all models
#                      enterprise: "external,local" (groups) or "local" for a restricted key
#     tags             comma list; enterprise: "confidential" or "restricted" selects the lane
#     team_id          enterprise: the team the key belongs to
#     mcp              comma list of MCP servers or access groups the key may use through
#                      the gateway's /mcp endpoint (e.g. "context7,mcp-dev"); empty = none
#
# Examples:
#   create-key.sh opencode 50 30d
#   create-key.sh alice-opencode 100 30d "external,local" "confidential" team-payments "context7,mcp-dev"
#   create-key.sh alice-restricted 20 30d "local" "restricted" team-payments
set -euo pipefail

BASE="${LITELLM_BASE_URL:-http://localhost:4000}"
MASTER="${LITELLM_MASTER_KEY:?set LITELLM_MASTER_KEY}"

ALIAS="${1:?alias required}"
BUDGET="${2:-25}"
DURATION="${3:-30d}"
MODELS="${4:-}"
TAGS="${5:-}"
TEAM="${6:-}"
MCP="${7:-}"

to_json_list() {  # "a,b" -> ["a","b"]
  local IFS=','; local out="" x
  for x in $1; do out="${out:+$out,}\"$x\""; done
  printf '[%s]' "$out"
}

payload="{\"key_alias\":\"$ALIAS\",\"max_budget\":$BUDGET,\"budget_duration\":\"$DURATION\",\"metadata\":{\"created_by\":\"create-key.sh\"}"
[[ -n "$MODELS" ]] && payload="$payload,\"models\":$(to_json_list "$MODELS")"
[[ -n "$TAGS" ]]   && payload="$payload,\"tags\":$(to_json_list "$TAGS")"
[[ -n "$TEAM" ]]   && payload="$payload,\"team_id\":\"$TEAM\""
if [[ -n "$MCP" ]]; then
  # names that match a server go to mcp_servers, the rest are treated as access groups
  servers=""; groups=""
  IFS=',' read -r -a items <<< "$MCP"
  for it in "${items[@]}"; do
    if [[ "$it" == mcp-* ]]; then groups="${groups:+$groups,}$it"; else servers="${servers:+$servers,}$it"; fi
  done
  perm=""
  [[ -n "$servers" ]] && perm="\"mcp_servers\":$(to_json_list "$servers")"
  [[ -n "$groups" ]]  && perm="${perm:+$perm,}\"mcp_access_groups\":$(to_json_list "$groups")"
  payload="$payload,\"object_permission\":{$perm}"
fi
payload="$payload}"

resp="$(curl -fsS "$BASE/key/generate" \
  -H "Authorization: Bearer $MASTER" -H "Content-Type: application/json" \
  -d "$payload")"

key="$(printf '%s' "$resp" | python3 -c 'import sys,json; print(json.load(sys.stdin)["key"])' 2>/dev/null || true)"
if [[ -n "$key" ]]; then
  printf 'alias: %s\nkey:   %s\n\nexport LITELLM_API_KEY=%s\n' "$ALIAS" "$key" "$key"
else
  printf '%s\n' "$resp"
fi

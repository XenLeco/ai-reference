#!/usr/bin/env bash
# Run the promptfoo regression evals against the gateway.
# Usage: evals.sh [--agents] [extra promptfoo args]
#   default: skills suite (gateway only)   --agents: also the OpenCode agent suite
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../evals/promptfoo"
: "${LITELLM_API_KEY:?set LITELLM_API_KEY to a virtual key}"
PF="npx -y promptfoo@latest"   # pin a version once the suite is stable
agents=0; extra=()
for a in "$@"; do [[ "$a" == "--agents" ]] && agents=1 || extra+=("$a"); done
echo "== skills suite =="
$PF eval -c promptfooconfig.yaml --no-cache "${extra[@]}"
if [[ $agents -eq 1 ]]; then
  echo "== agents suite (opencode run) =="
  $PF eval -c promptfooconfig.agents.yaml --no-cache "${extra[@]}"
fi
echo "browse: npx -y promptfoo@latest view"

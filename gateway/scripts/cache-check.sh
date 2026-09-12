#!/usr/bin/env bash
# Prompt-cache hit rate per model over the last N days: cache_read_input_tokens / prompt_tokens.
# A low ratio on a model you use for long agent sessions means a silent cache invalidator
# (changing system prompt, unstable tool list, timestamps) — see docs/01 and docs/02.
# Usage: LITELLM_MASTER_KEY=... cache-check.sh [days=7]
set -euo pipefail
BASE="${LITELLM_BASE_URL:-http://localhost:4000}"
KEY="${LITELLM_MASTER_KEY:?set LITELLM_MASTER_KEY (admin)}"
DAYS="${1:-7}"
if date -v-1d >/dev/null 2>&1; then START="$(date -v-"${DAYS}"d +%F)"; else START="$(date -d "-${DAYS} days" +%F)"; fi
END="$(date +%F)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

curl -fsS -H "Authorization: Bearer $KEY" \
  "$BASE/user/daily/activity?start_date=$START&end_date=$END" -o "$tmp/daily.json"

python3 - "$tmp/daily.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
days = data.get("results", data if isinstance(data, list) else [])
agg = {}
for d in days:
    for name, m in ((d.get("breakdown", {}) or {}).get("models", {}) or {}).items():
        met = m.get("metrics", m)
        a = agg.setdefault(name, [0, 0, 0])
        a[0] += int(met.get("prompt_tokens", 0) or 0)
        a[1] += int(met.get("cache_read_input_tokens", 0) or 0)
        a[2] += int(met.get("cache_creation_input_tokens", 0) or 0)
if not agg:
    print("no usage in range, or this LiteLLM version does not expose cache fields in daily activity")
    sys.exit(0)
hdr = ("model", "input tok", "cache read", "cache write", "hit rate")
print(f"{hdr[0]:30} {hdr[1]:>12} {hdr[2]:>12} {hdr[3]:>12} {hdr[4]:>9}")
for name, (inp, rd, wr) in sorted(agg.items(), key=lambda kv: -kv[1][0]):
    rate = (rd / inp * 100) if inp else 0.0
    flag = "  <- low for an agent model" if inp > 200000 and rate < 20 else ""
    print(f"{name[:30]:30} {inp:12d} {rd:12d} {wr:12d} {rate:8.1f}%{flag}")
PY

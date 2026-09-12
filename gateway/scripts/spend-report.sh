#!/usr/bin/env bash
# Spend report from the gateway: per key/team/model for the last N days.
# Usage: LITELLM_MASTER_KEY=... spend-report.sh [days=30] [group_by=api_key|team|customer]
# Uses /global/spend/report (grouped totals) and /user/daily/activity (per-day, per-model).
set -euo pipefail
BASE="${LITELLM_BASE_URL:-http://localhost:4000}"
KEY="${LITELLM_MASTER_KEY:?set LITELLM_MASTER_KEY (admin)}"
DAYS="${1:-30}"
GROUP="${2:-api_key}"
if date -v-1d >/dev/null 2>&1; then START="$(date -v-"${DAYS}"d +%F)"; else START="$(date -d "-${DAYS} days" +%F)"; fi
END="$(date +%F)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

echo "== spend by $GROUP, $START .. $END =="
if curl -fsS -H "Authorization: Bearer $KEY" \
    "$BASE/global/spend/report?start_date=$START&end_date=$END&group_by=$GROUP" -o "$tmp/report.json"; then
  python3 - "$tmp/report.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
rows = data if isinstance(data, list) else data.get("data", data)
if not isinstance(rows, list):
    print(json.dumps(data, indent=2)); sys.exit()
total = 0.0
for r in rows:
    if not isinstance(r, dict):
        continue
    ident = (r.get("group_by_day") or r.get("api_key") or r.get("key_alias") or r.get("team_alias")
             or r.get("team_id") or r.get("customer") or "")
    spend = float(r.get("total_spend", r.get("spend", 0)) or 0)
    total += spend
    print(f"  {str(ident)[:40]:40} ${spend:10.4f}")
    for m in r.get("models", []) or []:
        if isinstance(m, dict):
            name = str(m.get("model", "?"))[:34]
            mspend = float(m.get("total_spend", m.get("spend", 0)) or 0)
            print(f"      {name:34} ${mspend:10.4f}")
print(f"  {'TOTAL':40} ${total:10.4f}")
PY
else
  echo "  (report endpoint unavailable)"
fi

echo
echo "== per-day, per-model (daily activity) =="
if curl -fsS -H "Authorization: Bearer $KEY" \
    "$BASE/user/daily/activity?start_date=$START&end_date=$END" -o "$tmp/daily.json"; then
  python3 - "$tmp/daily.json" <<'PY'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
days = data.get("results", data if isinstance(data, list) else [])
agg = {}
for d in days:
    models = (d.get("breakdown", {}) or {}).get("models", {}) or {}
    for name, m in models.items():
        a = agg.setdefault(name, {"spend": 0.0, "req": 0, "in": 0, "out": 0, "cache": 0})
        met = m.get("metrics", m)
        a["spend"] += float(met.get("spend", 0) or 0)
        a["req"] += int(met.get("api_requests", 0) or 0)
        a["in"] += int(met.get("prompt_tokens", 0) or 0)
        a["out"] += int(met.get("completion_tokens", 0) or 0)
        a["cache"] += int(met.get("cache_read_input_tokens", 0) or 0)
hdr = ("model", "requests", "input tok", "cache read", "output tok", "spend")
print(f"  {hdr[0]:30} {hdr[1]:>9} {hdr[2]:>12} {hdr[3]:>12} {hdr[4]:>12} {hdr[5]:>10}")
for name, a in sorted(agg.items(), key=lambda kv: -kv[1]["spend"]):
    print(f"  {name[:30]:30} {a['req']:9d} {a['in']:12d} {a['cache']:12d} {a['out']:12d} ${a['spend']:9.4f}")
if not agg:
    print("  (no usage in range)")
PY
else
  echo "  (daily activity unavailable)"
fi

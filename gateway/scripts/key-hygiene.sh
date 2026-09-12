#!/usr/bin/env bash
# Key hygiene: list virtual keys, flag expired ones and ones with no spend in the last N days,
# optionally delete the flagged ones. Run quarterly (docs/08 §4).
# Usage: LITELLM_MASTER_KEY=... key-hygiene.sh [idle_days=90] [--delete]
# Endpoints: GET /key/list?page=&size=&return_full_object=true ; GET /global/spend/report?group_by=api_key ; POST /key/delete
set -euo pipefail
BASE="${LITELLM_BASE_URL:-http://localhost:4000}"
KEY="${LITELLM_MASTER_KEY:?set LITELLM_MASTER_KEY (admin)}"
DAYS="${1:-90}"
DELETE=0; for a in "$@"; do [[ "$a" == "--delete" ]] && DELETE=1; done
if date -v-1d >/dev/null 2>&1; then START="$(date -v-"${DAYS}"d +%F)"; else START="$(date -d "-${DAYS} days" +%F)"; fi
END="$(date +%F)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

curl -fsS -H "Authorization: Bearer $KEY" "$BASE/key/list?page=1&size=200&return_full_object=true" -o "$tmp/keys.json"
curl -fsS -H "Authorization: Bearer $KEY" "$BASE/global/spend/report?start_date=$START&end_date=$END&group_by=api_key" -o "$tmp/spend.json" || echo "[]" > "$tmp/spend.json"

python3 - "$tmp/keys.json" "$tmp/spend.json" "$DAYS" > "$tmp/flagged.txt" <<'PY'
import json, sys
from datetime import datetime, timezone
keys = json.load(open(sys.argv[1], encoding="utf-8"))
spend = json.load(open(sys.argv[2], encoding="utf-8"))
days = sys.argv[3]
rows = keys.get("keys", keys) if isinstance(keys, dict) else keys
if not isinstance(rows, list):
    print(json.dumps(keys, indent=2)[:2000], file=sys.stderr); sys.exit(1)
# hashed tokens with spend in the window
active = set()
def walk(o):
    if isinstance(o, dict):
        for k in ("api_key", "token", "key"):
            if isinstance(o.get(k), str) and float(o.get("total_spend", o.get("spend", 0)) or 0) > 0:
                active.add(o[k])
        for v in o.values(): walk(v)
    elif isinstance(o, list):
        for v in o: walk(v)
walk(spend)
now = datetime.now(timezone.utc)
print(f"{'alias':28} {'token':14} {'spend':>9} {'expires':>11} {'flag'}", file=sys.stderr)
for r in rows:
    if isinstance(r, str):
        r = {"token": r}
    tok = r.get("token") or r.get("key") or ""
    alias = r.get("key_alias") or "-"
    exp = r.get("expires")
    expired = False
    if exp:
        try:
            expired = datetime.fromisoformat(str(exp).replace("Z", "+00:00")) < now
        except ValueError:
            pass
    idle = tok not in active
    flag = "EXPIRED" if expired else ("idle>%sd" % days if idle else "")
    print(f"{alias[:28]:28} {tok[:14]:14} {float(r.get('spend', 0) or 0):9.2f} {str(exp)[:11] if exp else '-':>11} {flag}", file=sys.stderr)
    if flag:
        print(tok)
PY

n="$(grep -c . "$tmp/flagged.txt" || true)"
echo
echo "flagged: $n key(s) (expired or no spend since $START)"
if [[ "$n" -gt 0 && $DELETE -eq 1 ]]; then
  read -r -p "delete these $n keys? [y/N] " ans
  if [[ "$ans" == "y" || "$ans" == "Y" ]]; then
    payload="$(python3 -c 'import json,sys; print(json.dumps({"keys": [l.strip() for l in open(sys.argv[1]) if l.strip()]}))' "$tmp/flagged.txt")"
    curl -fsS -X POST -H "Authorization: Bearer $KEY" -H "Content-Type: application/json" "$BASE/key/delete" -d "$payload" && echo "deleted"
  else
    echo "aborted"
  fi
elif [[ "$n" -gt 0 ]]; then
  echo "re-run with --delete to remove them (note: key/list is paged; raise size= if you have more than 200 keys)"
fi

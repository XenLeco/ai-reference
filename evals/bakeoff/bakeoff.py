#!/usr/bin/env python3
"""Model bake-off through the gateway: same tasks, several aliases, pass rate / latency / tokens.

  export LITELLM_API_KEY=sk-...
  python bakeoff.py --models coder-local,coder-cheap,coder-fast --runs 3
  python bakeoff.py --tasks tasks.json --models gemma4-26b --runs 5 --judge-model coder-cheap --json

Standard library only. Deterministic checks (expect_regex / expect_contains /
expect_not_contains / max_lines) decide pass/fail; the optional `judge` rubric is graded by
a cheap model through the gateway and reported separately.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import statistics
import sys
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

HERE = Path(__file__).resolve().parent


def chat(base: str, key: str, model: str, system: str, user: str, temperature: float = 0.1,
         max_tokens: int = 2000, timeout: int = 600) -> tuple[str, dict, float]:
    body = json.dumps({
        "model": model,
        "messages": [{"role": "system", "content": system}, {"role": "user", "content": user}],
        "temperature": temperature,
        "max_tokens": max_tokens,
    }).encode()
    req = urllib.request.Request(f"{base}/v1/chat/completions", data=body, method="POST", headers={
        "Authorization": f"Bearer {key}", "Content-Type": "application/json", "x-litellm-tags": "bakeoff",
    })
    t0 = time.perf_counter()
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        data = json.loads(resp.read().decode())
    latency = time.perf_counter() - t0
    text = data["choices"][0]["message"].get("content") or ""
    usage = data.get("usage", {}) or {}
    return text, usage, latency


def strip_fences(text: str) -> str:
    return text


def check(task: dict, output: str) -> tuple[bool, list[str]]:
    reasons: list[str] = []
    for pat in task.get("expect_regex", []):
        if not re.search(pat, output):
            reasons.append(f"missing /{pat}/")
    for s in task.get("expect_contains", []):
        if s not in output:
            reasons.append(f"missing '{s}'")
    for s in task.get("expect_not_contains", []):
        if s in output:
            reasons.append(f"contains '{s}'")
    if "max_lines" in task and output.count("\n") + 1 > task["max_lines"]:
        reasons.append(f"too long ({output.count(chr(10)) + 1} > {task['max_lines']} lines)")
    return (not reasons), reasons


JUDGE_SYSTEM = "You grade an answer against a rubric. Reply with exactly PASS or FAIL on the first line, then one sentence."


def judge(base: str, key: str, model: str, rubric: str, prompt: str, output: str) -> bool | None:
    try:
        text, _, _ = chat(base, key, model, JUDGE_SYSTEM,
                          f"Rubric: {rubric}\n\nTask:\n{prompt}\n\nAnswer:\n{output}", temperature=0, max_tokens=100)
    except Exception:
        return None
    return text.strip().upper().startswith("PASS")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--tasks", default=str(HERE / "tasks.json"))
    ap.add_argument("--models", required=True, help="comma-separated gateway model names / aliases")
    ap.add_argument("--runs", type=int, default=3)
    ap.add_argument("--judge-model", default="coder-cheap", help="'' to disable rubric grading")
    ap.add_argument("--base", default=os.environ.get("LITELLM_BASE_URL", "http://localhost:4000"))
    ap.add_argument("--json", action="store_true", help="print the results JSON path only")
    ap.add_argument("--only", default="", help="comma-separated task ids")
    args = ap.parse_args()

    key = os.environ.get("LITELLM_API_KEY") or os.environ.get("LITELLM_MASTER_KEY")
    if not key:
        print("set LITELLM_API_KEY", file=sys.stderr)
        return 2
    spec = json.loads(Path(args.tasks).read_text(encoding="utf-8"))
    system = spec.get("system", "")
    tasks = spec["tasks"]
    if args.only:
        wanted = set(args.only.split(","))
        tasks = [t for t in tasks if t["id"] in wanted]
    models = [m.strip() for m in args.models.split(",") if m.strip()]

    results: dict[str, list[dict]] = {m: [] for m in models}
    for model in models:
        for task in tasks:
            for run in range(args.runs):
                rec = {"task": task["id"], "run": run}
                try:
                    out, usage, lat = chat(args.base, key, model, system, task["prompt"])
                except urllib.error.HTTPError as e:
                    rec.update({"error": f"HTTP {e.code}: {e.read().decode()[:200]}", "pass": False})
                    results[model].append(rec)
                    print(f"  {model:18} {task['id']:20} run {run}: ERROR {rec['error'][:60]}", file=sys.stderr)
                    continue
                except Exception as e:  # network, timeout
                    rec.update({"error": str(e)[:200], "pass": False})
                    results[model].append(rec)
                    print(f"  {model:18} {task['id']:20} run {run}: ERROR {rec['error'][:60]}", file=sys.stderr)
                    continue
                ok, reasons = check(task, out)
                rec.update({"pass": ok, "reasons": reasons, "latency_s": round(lat, 2),
                            "prompt_tokens": usage.get("prompt_tokens"), "completion_tokens": usage.get("completion_tokens"),
                            "output": out})
                if args.judge_model and task.get("judge"):
                    rec["judge"] = judge(args.base, key, args.judge_model, task["judge"], task["prompt"], out)
                results[model].append(rec)
                mark = "ok  " if ok else "FAIL"
                if not args.json:
                    print(f"  {model:18} {task['id']:20} run {run}: {mark} {lat:6.1f}s  "
                          f"in={usage.get('prompt_tokens', '?')} out={usage.get('completion_tokens', '?')}"
                          + (f"  judge={'PASS' if rec.get('judge') else 'FAIL' if rec.get('judge') is False else '-'}" if 'judge' in rec else "")
                          + (f"  [{'; '.join(reasons)[:60]}]" if reasons else ""))

    # summary
    out_dir = HERE / "results"
    out_dir.mkdir(exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d-%H%M%S")
    path = out_dir / f"bakeoff-{stamp}.json"
    path.write_text(json.dumps({"base": args.base, "runs": args.runs, "tasks": [t["id"] for t in tasks],
                                "results": results}, indent=2), encoding="utf-8")

    print()
    print(f"{'model':18} {'pass %':>7} {'judge %':>8} {'p50 s':>7} {'in tok':>8} {'out tok':>8} {'errors':>7}")
    for model, recs in results.items():
        n = len(recs)
        passed = sum(1 for r in recs if r.get("pass"))
        judged = [r["judge"] for r in recs if r.get("judge") is not None]
        lats = [r["latency_s"] for r in recs if "latency_s" in r]
        ins = [r["prompt_tokens"] for r in recs if r.get("prompt_tokens")]
        outs = [r["completion_tokens"] for r in recs if r.get("completion_tokens")]
        errs = sum(1 for r in recs if "error" in r)
        print(f"{model:18} {100 * passed / n if n else 0:6.0f}% "
              f"{(100 * sum(judged) / len(judged)) if judged else float('nan'):7.0f}% "
              f"{statistics.median(lats) if lats else float('nan'):7.1f} "
              f"{statistics.mean(ins) if ins else float('nan'):8.0f} "
              f"{statistics.mean(outs) if outs else float('nan'):8.0f} {errs:7d}")
    print(f"\nresults: {path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

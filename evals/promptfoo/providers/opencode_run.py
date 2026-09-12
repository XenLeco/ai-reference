#!/usr/bin/env python3
"""promptfoo exec provider: run an OpenCode agent non-interactively in the fixture repo.

promptfoo calls: python3 opencode_run.py "<prompt>" "<provider config json>" "<context json>"
The context JSON carries the test vars; `vars.agent` selects the agent (default: build),
`vars.model` overrides the model (default: litellm/coder-fast), `vars.dir` the working
directory (default: fixtures/mini-repo relative to this file). Prints the agent's final
answer on stdout; anything else goes to stderr.
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def main() -> int:
    prompt = sys.argv[1] if len(sys.argv) > 1 else ""
    ctx = {}
    if len(sys.argv) > 3:
        try:
            ctx = json.loads(sys.argv[3])
        except json.JSONDecodeError:
            ctx = {}
    vars_ = ctx.get("vars", ctx) if isinstance(ctx, dict) else {}
    agent = vars_.get("agent", "build")
    model = vars_.get("model", "litellm/coder-fast")
    workdir = Path(vars_.get("dir", HERE.parent / "fixtures" / "mini-repo")).resolve()

    exe = shutil.which("opencode")
    if not exe:
        print("opencode not found on PATH; install it and run scripts/install-personal.sh", file=sys.stderr)
        return 2
    if not workdir.exists():
        print(f"fixture directory missing: {workdir}", file=sys.stderr)
        return 2

    cmd = [exe, "run", "--dir", str(workdir), "--agent", agent, "--model", model, prompt]
    env = dict(os.environ, OPENCODE_DISABLE_AUTOUPDATE="1")
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, env=env, timeout=600)
    except subprocess.TimeoutExpired:
        print("opencode run timed out after 600s", file=sys.stderr)
        return 3
    if p.returncode != 0:
        print(p.stderr, file=sys.stderr)
        return p.returncode
    sys.stdout.write(p.stdout.strip() + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())

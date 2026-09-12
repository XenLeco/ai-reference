"""Nightly read-only repository triage with the Claude Agent SDK, through the gateway.

    pip install claude-agent-sdk
    export ANTHROPIC_BASE_URL=http://localhost:4000 ANTHROPIC_AUTH_TOKEN=sk-...
    python nightly_triage.py /path/to/repo > triage-$(date +%F).md

Read-only: the tool allowlist has no Edit/Write/Bash. Bounded: max_turns caps the loop.
"""

from __future__ import annotations

import sys
from pathlib import Path

import anyio
from claude_agent_sdk import AssistantMessage, ClaudeAgentOptions, ResultMessage, TextBlock, query

PROMPT = """Triage this repository for tomorrow's standup. Read only; do not modify anything.

1. List TODO / FIXME / XXX markers with file:line and a one-line paraphrase, grouped by area.
2. Find tests that are skipped, xfail'd or commented out, with file:line.
3. Find files changed in the last 7 days (`git log --since=7.days --name-only` is not available to you;
   infer from recent commits shown in AGENTS.md or skip this step if not possible).
4. Report in Markdown: a 3-line summary, then the lists. Under 80 lines."""


async def main(repo: str) -> int:
    options = ClaudeAgentOptions(
        cwd=repo,
        system_prompt="You are a careful engineer producing a factual triage report. Cite file:line for every claim.",
        allowed_tools=["Read", "Glob", "Grep"],   # read-only surface
        max_turns=25,
        model="claude-sonnet-5",                   # a name the gateway serves (doc 04)
    )
    cost = None
    async for message in query(prompt=PROMPT, options=options):
        if isinstance(message, AssistantMessage):
            for block in message.content:
                if isinstance(block, TextBlock):
                    print(block.text)
        elif isinstance(message, ResultMessage):
            cost = getattr(message, "total_cost_usd", None)
    if cost is not None:
        print(f"\n<!-- cost: ${cost:.4f} -->", file=sys.stderr)
    return 0


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else "."
    if not Path(target).is_dir():
        print(f"not a directory: {target}", file=sys.stderr)
        sys.exit(2)
    sys.exit(anyio.run(main, str(Path(target).resolve())))

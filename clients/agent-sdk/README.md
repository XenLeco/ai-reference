# clients/agent-sdk/ — scheduled automations with the Claude Agent SDK

The Claude Agent SDK (`claude-agent-sdk`, MIT; verified from its LICENSE file) is Claude
Code packaged as a library: the same tools (Read, Grep, Bash, Edit), permissions and
`AGENTS.md`/`CLAUDE.md` loading, driven from your own script. Use it for automations that
are more than one prompt: nightly issue triage, docs-drift detection, changelog assembly,
dependency audits.

It reads `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN` like Claude Code, so it runs
through the gateway with its own virtual key (Claude models only, as with Claude Code).

```bash
pip install claude-agent-sdk           # needs the Claude Code CLI on PATH as well
export ANTHROPIC_BASE_URL=http://localhost:4000
export ANTHROPIC_AUTH_TOKEN=sk-...     # create-key.sh automations 10 30d "" "automation"
python nightly_triage.py /path/to/repo
```

`nightly_triage.py` reads a repository read-only, lists open TODO/FIXME markers and failing
or skipped tests, and writes a short Markdown report to stdout. It never edits files
(`allowed_tools` is read-only, `permission_mode` default) and stops after a bounded number
of turns. Schedule it with cron or a CI job on a self-hosted runner.

Adapt: change the prompt, widen `allowed_tools` to `Edit`/`Write` with
`permission_mode="acceptEdits"` only for automations whose output goes through a PR and a
human review. Never give an unattended automation `git push`.

API shape used (check the SDK README for your version): `query(prompt, options)` yields
`AssistantMessage` (with `TextBlock` content) and a final `ResultMessage` carrying
`total_cost_usd` and `usage`.

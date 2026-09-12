---
name: model-selection
description: Choose which gateway model alias to use for a task and when to escalate or downgrade. Use when asked which model to use, whether a task needs a frontier model, how to reduce cost, or when planning subagent work. Encodes the local-to-frontier ladder and the data-classification rule.
license: MIT
metadata:
  version: "1.0"
---

# Model selection

Models are reached through gateway aliases. Never name a vendor model in agent config when an
alias fits; the gateway owns the mapping.

## The ladder

| Alias | Backed by (default) | Use for |
|---|---|---|
| `local-small` | Gemma 4 12B, local | titles, summaries, commit messages, rewording, private data |
| `coder-local` | Qwen3-Coder 30B-A3B, local | exploration, boilerplate, tests from a spec, offline, restricted data |
| `coder-cheap` | Claude Haiku 4.5 | subagents, bulk mechanical edits, explain-a-file |
| `coder-fast` | Claude Sonnet 5 | default for features, fixes, refactors, reviews |
| `coder-frontier` | Claude Opus 5 | multi-file changes with judgement, migrations, bugs that resisted `coder-fast` |
| `reasoning-max` | Claude Fable 5.1 (personal) / Opus 5 (enterprise) | architecture, plans, hard concurrency/perf bugs, long autonomous runs |

## Decide in this order

1. **Data class.** Restricted (PII, secrets, regulated, customer data) → local aliases only.
   In the enterprise profile the gateway enforces this through the key; still choose
   `coder-local` explicitly so the intent is visible.
2. **Context size.** Estimate tokens (≈ 4 chars/token). > 60K → not local; > 190K → not
   `coder-cheap`.
3. **Task kind.**
   - typing (rename, boilerplate, tests from a clear spec, mechanical refactor) → rung 1–2
   - judgement (ambiguous requirement, design, debugging an unknown) → rung 3+
   - reading a lot to answer a little → `coder-local` subagent, then a higher rung on the summary
4. **History.** Failed twice on the current rung with a clear prompt → go up one rung.
   Succeeding easily → next similar task goes down one rung.
5. **Latency.** Interactive pairing → `coder-fast` or below. Batch/background → any.

## Cost hygiene

- Subagents that read code run on `coder-cheap` or `coder-local`; the expensive model reads
  their summary.
- Keep the system prompt and `AGENTS.md` stable across turns so prompt caching hits.
- Prefer one model per session; switching mid-session loses cache and consistency.
- Set a per-session key budget for long autonomous runs.
- Rough per-feature cost: `coder-fast` $1–5, `coder-frontier` 2.5×, `reasoning-max` 5×.

## Say it out loud

When you pick a rung other than `coder-fast`, state the reason in one line
("using coder-local: restricted data" / "escalating to coder-frontier: two failed attempts").

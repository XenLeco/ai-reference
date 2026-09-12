---
name: pr-writeup
description: Write a pull request title and description that a reviewer can act on - what, why, how it was tested, risks, rollout. Use when opening a PR, drafting a merge request, or asked to "describe these changes".
license: MIT
metadata:
  version: "1.0"
---

# PR write-up

A PR description is for the reviewer now and the archaeologist in two years. Both need the
*why* more than the *what*; the diff already shows the what.

## Inputs to gather

- `git log --oneline base..HEAD` (commits), `git diff base...HEAD --stat` (scope).
- The issue or plan the work came from, if any.
- The exact test commands run (from `AGENTS.md`), and their result.

## Title

Same rules as a commit subject: `type(scope): imperative summary`, ≤ 72 chars.

## Body template

```
## Why
One to three sentences: the problem or goal, and why now. Link the issue.

## What
Bullets, grouped by area. Say what changed for users/callers, not which files.
Call out anything surprising or non-obvious in the approach.

## How it was tested
- `exact command` → result
- manual steps, if any, with what was observed
- what was NOT tested and why

## Risks and rollback
- risk → mitigation
- how to revert (plain revert / feature flag / migration down)

## Notes for the reviewer
Where to start reading; decisions you want challenged; follow-ups deliberately left out.

AI assistance: yes/no — tool(s) used, human-reviewed: yes
```

## Rules

- Keep it under ~40 lines for a normal PR. A PR that needs more is probably two PRs.
- Never claim tests you did not run. Paste the command, not "tests pass".
- Breaking changes go first, in bold, with the migration.
- Screenshots or logs only when they prove something words cannot.
- If the repository has a PR template, fill it instead of this one, keeping the same content.

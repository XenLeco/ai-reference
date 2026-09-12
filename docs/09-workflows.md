# 09 — Day-to-day workflows

*Verified: 2026-09-11.*

Playbooks that use the agents, commands and aliases shipped here. Commands are OpenCode
names; the equivalents in other tools are noted in doc 04.

## Start of any session

1. `cd repo && opencode` — `AGENTS.md` loads automatically.
2. Check the model: `/models` → `coder-fast` unless you have a reason.
3. State the goal in one paragraph plus the definition of done. Vague asks produce vague
   diffs.

## New feature

```
/plan <what and why>                → architect (reasoning-max, read-only) returns options + a plan
(pick an option, refine)
Tab → build                          → implement the plan step by step; run the fast tests after each step
/test                                → test-writer adds/extends tests for the diff
/review                              → reviewer returns findings by severity; fix; re-run once
/commit                              → conventional commit from the staged diff
/pr                                  → PR description with what/why/how-tested
```

Cost profile: plan ≈ 1 frontier call; build ≈ dozens of `coder-fast` calls; review/test
≈ a few. If build stalls twice on the same step, switch that step to `coder-frontier`.

## Bug fix

```
/fix <issue text or link>            → debug-reproduce-first skill: reproduce, isolate, fix, regression test
/review
/commit
```

Refuse to accept a fix without a failing test that now passes. If reproduction fails, ask
the agent for the three most likely causes and how to disambiguate them, then decide.

## Refactor

1. `/plan refactor <scope>` with an explicit invariant ("behaviour identical; public API
   unchanged"). 2. Ensure test coverage first (`/test` on the scope). 3. Build in small
   commits. 4. `/review` with the invariant in `$ARGUMENTS`.

Large mechanical refactors (rename across 200 files): `coder-cheap` or `coder-local` with a
precise instruction beats `coder-frontier` with a vague one.

## Understanding an unfamiliar codebase

```
@local-scout summarise the architecture of this repo and where <feature> lives
/explain path/to/file
```

`local-scout` runs on Qwen3-Coder locally; it costs nothing and its summary goes into the
primary agent's context instead of the raw tree. For a repo without `AGENTS.md`, the
`repo-onboarding` skill produces a draft.

## Reviewing someone else's PR

```
/review origin/main...feature-branch
/security                            → security-auditor on the same range (coder-frontier)
```

Paste the findings into the PR as your review after you agree with them. Do not post
unread agent output.

## Documentation

`/docs <target>` runs `docs-writer` (`coder-cheap`, edits only under `docs/` and README
files). Give it the audience and the length.

## Long autonomous runs

For multi-hour tasks (migrations, large upgrades):

- write the plan to a file first and reference it (`@PLAN.md`), so compaction cannot lose it;
- use a worktree; commit at every green test run;
- `reasoning-max` for the plan, `coder-fast` for execution, `coder-frontier` when stuck;
- set a budget on the key for that session (`create-key.sh migration-run 30 1d`);
- check in every hour; re-read the plan, prune the session.

## Working with local models only

Offline, restricted repos, or cost pressure: set `model` to `litellm/coder-local` in the
project `opencode.json`. Expect: slower, weaker on multi-file reasoning, fine for tests,
boilerplate, exploration and small fixes. Keep prompts specific and files small. Gemma 4
26B-A4B is the better generalist, Qwen3-Coder 30B-A3B the better coder.

## Team conventions worth agreeing on

- which alias is the default (`coder-fast`) and who may use `reasoning-max` freely;
- that `/review` runs before every PR;
- that agent-generated PRs are labelled;
- that `AGENTS.md` changes go through review like code;
- a monthly look at the gateway spend page per key.

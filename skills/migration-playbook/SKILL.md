---
name: migration-playbook
description: Plan and execute migrations that must be reversible - database schema changes, data backfills, API version changes, framework or runtime upgrades, moving between services. Use when asked to migrate, backfill, rename a column, change a contract, or upgrade a major framework version.
license: MIT
metadata:
  version: "1.0"
---

# Migration playbook

Every migration is a sequence of steps that each leave the system working, and each has a
way back. If a step cannot be reversed, it needs a backup and an explicit go/no-go.

## 1. Frame it

- Current state → target state, in two sentences.
- Invariant during the migration ("reads keep working", "no double writes", "old clients
  keep working until date X").
- Blast radius: which tables, services, clients, jobs touch the thing.
- Size: rows, traffic, number of callers. Big numbers change the plan (batching, off-peak).

## 2. Choose the shape

| Change | Shape |
|---|---|
| add column / field | additive first; write both; read new; drop old later (expand → migrate → contract) |
| rename | add new, dual-write, backfill, switch reads, stop old writes, drop old |
| type change | new column, backfill with validation, switch, drop |
| API contract | version it; serve both; deprecate with a date; remove after telemetry shows zero use |
| framework/runtime major | branch, upgrade in isolation, run full suite, canary, then cut over |
| data move between stores | dual-write, backfill, verify counts and checksums, switch reads, decommission |

Never combine a schema change with a behaviour change in one step.

## 3. Write the plan

For each step: what changes; how it is verified (query, test, metric); rollback (`down`
migration, feature flag off, revert); whether it can ship alone. Steps that touch data at
scale get a batch size and a rate limit.

## 4. Execute

- Backfills: idempotent, resumable, batched, logged with counts; run on a copy first when
  possible.
- Verify before switching reads: row counts, checksums or sampled comparisons, not "it
  looks fine".
- Keep the old path until the new one has carried real traffic for an agreed period.
- The "contract" step (dropping the old column/endpoint) is a separate PR, after the
  verification window.

## 5. Report

```
Shape: <expand-migrate-contract | versioned API | ...>
Steps shipped: <n of m>, current state: <...>
Verification: <what was compared, result>
Rollback tested: <yes/no, how>
Remaining: <steps, dates, owners>
```

## Do not

- Do not write a destructive migration (drop, truncate, type-narrowing) without a verified
  backup and a named approver.
- Do not run a backfill without a way to stop and resume it.
- Do not touch `migrations/` that already shipped; add a new one.

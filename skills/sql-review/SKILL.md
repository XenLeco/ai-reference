---
name: sql-review
description: Review SQL queries, schema changes and ORM code for correctness, performance and safety - injection, missing indexes, N+1, lock contention, unsafe migrations. Use when a change touches queries, migrations, models or database access code, or when a query is slow.
license: MIT
metadata:
  version: "1.0"
---

# SQL review

## Correctness

- Joins: every join has its key; an unintended cross join shows up as row multiplication.
  Outer joins with a filter on the outer table in `WHERE` silently become inner joins;
  move the condition to `ON`.
- NULL: `NOT IN (subquery)` with any NULL returns nothing; `= NULL` is never true; use
  `IS [NOT] NULL`, `NOT EXISTS`.
- Aggregates: every non-aggregated column is in `GROUP BY`; `COUNT(col)` ignores NULLs.
- Time: store UTC; compare timestamps with explicit zones; beware `DATE(col)` killing
  index use.
- Pagination: keyset (`WHERE id > ?`) over `OFFSET` for anything that grows.
- Transactions: reads and writes that must agree are in one transaction with the right
  isolation; retries on serialisation failures are idempotent.

## Safety

- Parameterised queries only. String formatting into SQL is a blocker, including for
  identifiers (allowlist them).
- Least privilege: the app role cannot `DROP`, `TRUNCATE` or read tables it does not need.
- No secrets or PII in query logs; mask in the logger, not in the query.

## Performance

- Run `EXPLAIN (ANALYZE, BUFFERS)` on anything non-trivial; look for sequential scans on
  large tables, nested loops with high row estimates, sorts spilling to disk, hash joins on
  unfiltered inputs.
- Index for the predicate and sort: leading columns match `WHERE` equality first, then
  range, then `ORDER BY`. Composite over several single-column indexes for one query.
  Partial indexes for common filters (`WHERE deleted_at IS NULL`).
- `SELECT *` in application code is a maintenance and bandwidth cost; list columns.
- N+1 in ORM code: a query inside a loop, lazy relationships in a list view. Fix with
  joins, `IN` batches, or eager loading.
- Functions on indexed columns in `WHERE` (`LOWER(email)`, `DATE(created_at)`) disable the
  index; use expression indexes or rewrite the predicate.
- Big deletes/updates: batch with a limit and a loop; one statement locks and bloats.

## Migrations

- Adding a `NOT NULL` column without a default, adding an index without `CONCURRENTLY`
  (Postgres), changing a column type, renaming: each locks or rewrites the table. Use
  expand → migrate → contract (see `migration-playbook`).
- Every `up` has a `down`, or the PR says why not and names the backup.
- Backfills are separate from schema changes and are batched.

## Output shape

```
[blocker|should-fix|nit] file:line — issue → fix
EXPLAIN evidence: <one line, if run>
```

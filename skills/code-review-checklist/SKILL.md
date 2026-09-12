---
name: code-review-checklist
description: Structured checklist and severity ladder for reviewing a diff or pull request. Use when asked to review code, check a PR, look over changes before commit, or when acting as the reviewer agent. Produces findings ordered by severity with file:line and a concrete fix.
license: MIT
metadata:
  version: "1.0"
---

# Code review checklist

Read the whole diff once before writing anything. Then go through the ladder top to bottom.
Report only what you found evidence for; mark suspicions "verify:".

## Severity ladder

**Blocker** (must fix before merge)
- Wrong behaviour on a reachable path; off-by-one; wrong boolean; unhandled null/None.
- Data loss or corruption: destructive migration, missing transaction, partial writes.
- Security: injection (SQL, shell, template, path), auth bypass, secrets in code or logs,
  unsafe deserialisation, disabled TLS verification, over-broad permissions.
- Broken contract: public API/type change without callers updated; serialized format change
  without versioning.
- Concurrency: shared mutable state without synchronisation, await inside a lock, races on
  check-then-act.
- Resource leaks: unclosed files/connections, unbounded growth, missing timeouts on I/O.

**Should fix** (merge only with a follow-up ticket)
- Error handling that swallows or misreports failures; bare `except`/`catch` without rethrow.
- Missing tests for changed behaviour, or tests that do not assert the thing that changed.
- Misleading names, comments that contradict the code, dead code left behind.
- Performance: N+1 queries, O(n²) on unbounded input, blocking calls on hot paths.
- Logging: secrets or PII in logs; missing context on errors.

**Nit** (optional, max five)
- Style beyond what the formatter enforces, wording, ordering.

## Questions to ask of every change

1. What is the intended behaviour, and does the diff do exactly that and nothing more?
2. What input reaches this code, and what happens with empty, huge, malformed, or hostile input?
3. What happens when the dependency it calls fails or is slow?
4. Who else calls the things that changed? (`rg` the symbol; check callers.)
5. Is the change observable (logs/metrics) and reversible (feature flag, migration down)?
6. Do the tests fail without the change? (For fixes: is there a regression test?)

## Output shape

```
## Blockers
- path:line — problem. Fix: …
## Should fix
- …
## Nits
- …
## Good
- (only if notable)
## Verdict
approve | approve with fixes | request changes — one sentence
```

## Do not

- Do not comment on formatting a tool enforces.
- Do not request refactors outside the diff's purpose; note them as follow-ups at most.
- Do not pad: an empty section is a real finding ("no blockers").
- Do not accept "tests pass" as evidence for behaviour the tests do not cover.

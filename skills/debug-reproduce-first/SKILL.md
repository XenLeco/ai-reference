---
name: debug-reproduce-first
description: Disciplined bug-fixing procedure - reproduce, isolate, fix, add a regression test, verify. Use for any bug report, error message, stack trace, flaky test, or "this used to work" complaint. Prevents guess-and-patch fixes.
license: MIT
metadata:
  version: "1.0"
---

# Debug: reproduce first

No fix before a reproduction. A fix without a failing-then-passing test is a hypothesis.

## 1. Reproduce

- Turn the report into a command or a test that fails now. Prefer a unit test; fall back to
  a script or a curl.
- If the report lacks inputs, derive the smallest plausible input from the code path and say
  that you did.
- Record: exact command, expected result, actual result, environment (versions, OS, flags).
- Cannot reproduce after three honest attempts → stop. Report what you tried, the three most
  likely causes, and what information would disambiguate them. Do not "fix" blind.

## 2. Isolate

- Read the stack trace bottom-up to the first frame in this repository.
- Bisect: `git log -S` / `git bisect` if it used to work; comment out / stub halves if not.
- Add temporary prints or assertions rather than reasoning about state you have not seen.
  Remove them before committing.
- Distinguish the *trigger* (what input) from the *cause* (what invariant is violated) from
  the *site* (where it surfaces). Fix the cause.

## 3. Fix

- Smallest change that restores the invariant. If the right fix is large, ship a guard now
  and a ticket for the real fix, and say so.
- Check the same pattern elsewhere (`rg` for the idiom); fix siblings or list them.
- Do not change behaviour beyond the bug. Do not refactor in the same change.

## 4. Regression test

- The reproduction from step 1 becomes a permanent test. It must fail on the pre-fix code
  (verify by stashing the fix if cheap) and pass after.
- Name it after the behaviour, not the ticket: `test_retry_does_not_duplicate_writes`, not
  `test_issue_412`. Reference the ticket in a comment.

## 5. Verify and report

- Run the fast tests, then the full suite if the area is shared.
- Report in this shape:

```
Root cause: <one sentence: which invariant broke and why>
Trigger: <input/condition>
Fix: <files, one line each>
Evidence: <failing test before → passing after; commands run>
Follow-ups: <siblings, tickets, or "none">
```

## Flaky tests

Treat as a bug in the test or the code, never as noise. Run it 20× in a loop to get a
rate; look for time, order, shared state, network. Do not add retries or sleeps to make it
green.

---
description: Fix a bug the disciplined way — reproduce, isolate, fix, regression test. Usage — /fix <issue text, error, or link>
agent: build
---
Load the debug-reproduce-first skill and follow it exactly.

Bug report: $ARGUMENTS

Current state:
!`git status --short`

Do not propose a fix before you have a failing reproduction (a test or a command). When the
fix is in, run the fast tests, then the regression test, then summarise: root cause, change,
evidence.

---
description: Write or extend tests for the current change (or a target given as argument), then run them. Usage — /test [path|behaviour]
agent: test-writer
subtask: true
---
Target: $ARGUMENTS (empty means: the current uncommitted change)

Current change:
!`git diff --stat`
!`git diff`

Follow the test command and conventions in AGENTS.md. Cover every changed branch and any
bug being fixed. Run the tests and report results; do not modify production code.

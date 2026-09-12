---
description: Security review of staged changes, a ref range, or a component. Usage — /security [ref-range|path]
agent: security-auditor
subtask: true
---
Security review target: $ARGUMENTS (empty means the staged diff)

!`git diff --staged --stat $ARGUMENTS`
!`git diff --staged $ARGUMENTS`

Apply the secure-coding-baseline skill. Findings first, with severity, path:line, exploit
path and fix. End with the verdict line.

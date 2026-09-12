---
description: Write or update documentation for a target. Usage — /docs <path, feature, or "changelog">
agent: docs-writer
subtask: true
---
Document: $ARGUMENTS

Recent changes that may need documenting:
!`git diff --staged --stat`
!`git log --oneline -n 10`

Follow the repository's documentation structure. State the audience in one line at the top
of your report, then make the edits and list the files changed.

---
description: Review staged changes, or a ref range / paths given as arguments. Usage — /review [ref-range|paths]
agent: reviewer
subtask: true
---
Review these changes. Arguments (may be empty, meaning the staged diff): $ARGUMENTS

Diff:
!`git diff --staged --stat $ARGUMENTS`
!`git diff --staged $ARGUMENTS`

If the diff above is empty, review the unstaged working-tree diff instead:
!`git diff --stat $ARGUMENTS`
!`git diff $ARGUMENTS`

Apply the code-review-checklist skill and report in your standard shape.

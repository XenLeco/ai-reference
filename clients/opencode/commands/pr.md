---
description: Draft a pull request description for the current branch against the base branch. Usage — /pr [base=main]
agent: build
model: litellm/coder-fast
---
Load the pr-writeup skill. Base branch: $1 (default main).

Branch and commits:
!`git branch --show-current`
!`git log --oneline $1..HEAD 2>/dev/null || git log --oneline main..HEAD`

Full diff against base:
!`git diff $1...HEAD --stat 2>/dev/null || git diff main...HEAD --stat`

Write the PR title and description in the skill's template. Include how it was tested,
using the actual commands from AGENTS.md. Print it; do not create the PR unless asked.

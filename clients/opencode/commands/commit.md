---
description: Stage-aware conventional commit for the current changes. Usage — /commit [extra context]
agent: build
model: litellm/coder-cheap
---
Load the conventional-commits skill.

Context from the user (may be empty): $ARGUMENTS

Staged changes:
!`git diff --staged --stat`
!`git diff --staged`

If nothing is staged, show `git status --short` and ask which files to stage; do not stage
everything blindly. Otherwise write the commit message (subject ≤ 72 chars, body explains
why, footer for breaking changes or issue refs) and end it with the trailers
`Assisted-by: LLM` and `AI-Tool: OpenCode <current model alias>`; keep any
`Co-Authored-By:` trailer the tool adds and never add `Signed-off-by:`. Run `git commit`
with it. Never amend, never push.

---
description: Prepare a release — changelog, version bump, tag commands (never pushes). Usage — /release [major|minor|patch]
agent: release-manager
subtask: true
---
Prepare the next release. Requested bump (may be empty, meaning: decide from the commits): $ARGUMENTS

Last tag and commits since:
!`git describe --tags --abbrev=0 2>/dev/null || echo "(no tags yet)"`
!`git log --oneline "$(git describe --tags --abbrev=0 2>/dev/null || git rev-list --max-parents=0 HEAD)"..HEAD`

Write the changelog entry, bump the version, commit, and print the tag and push commands
for me to run.

---
name: conventional-commits
description: Write commit messages in the Conventional Commits format from a staged diff. Use when committing, writing or rewording a commit message, squashing, or generating changelog entries. Covers type, scope, subject, body, breaking-change and issue footers.
license: MIT
metadata:
  version: "1.0"
---

# Conventional commits

## Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

- **type**: `feat` (user-visible behaviour), `fix` (bug), `refactor` (no behaviour change),
  `perf`, `test`, `docs`, `build` (deps, tooling), `ci`, `chore` (nothing else fits), `revert`.
- **scope**: optional; the package, module or area (`api`, `auth`, `gateway`). Use what the
  repo already uses (`git log --oneline -n 30` shows the convention).
- **subject**: imperative, lowercase start, no period, ≤ 72 characters including type and
  scope. Says *what changes*, not *what was done* ("add retry to fetch", not "added retries").
- **body**: optional; wrap at 72. Explains *why* and anything non-obvious about *how*.
  Skip restating the diff.
- **footer**: `BREAKING CHANGE: <what breaks and the migration>` and/or issue refs
  (`Closes #123`, `Refs PROJ-42`). A `!` after the type/scope (`feat(api)!:`) also marks a
  breaking change.

## Procedure

1. Read the staged diff (`git diff --staged`). If it mixes unrelated changes, say so and
   propose a split before writing a message.
2. Pick the type by the *effect on users of the code*, not by which files changed
   (a bug fix in a test file that exposes a real bug is still `fix` if production code changed;
   test-only changes are `test`).
3. Write the subject first; if it needs "and", split the commit.
4. Add a body only when a future reader would ask "why?". Mention trade-offs and rejected
   alternatives in one or two lines.
5. Add footers for breaking changes and issue references.
6. Commit with `git commit -F -` or `-m` for subject-only. Never amend or push unless asked.

## Examples

```
fix(gateway): fall back to gpt-5.6-terra when sonnet returns 529

Anthropic overload errors were surfacing to clients because the router
only retried on 429. Add 529 to the retriable set and route through the
existing fallback chain.

Refs #88
```

```
feat(auth)!: require PKCE for all OAuth clients

BREAKING CHANGE: clients that omit code_challenge are rejected with 400.
Migration: see docs/auth.md#pkce.
```

## Do not

- Do not write `update`, `fix stuff`, `wip`, or messages that name files instead of changes.
- Do not include AI-tool banners or emojis unless the repo's history does.
- Do not exceed 72 characters in the subject; shorten the scope or split the change.

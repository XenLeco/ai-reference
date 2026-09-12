---
name: release-notes
description: Write release notes and changelog entries from commits and PRs, grouped by user impact, with breaking changes and upgrade steps first. Use when cutting a release, tagging a version, updating CHANGELOG.md, or asked "what changed since X".
license: MIT
metadata:
  version: "1.0"
---

# Release notes

Readers are users and operators, not the authors. Say what changed *for them*.

## 1. Collect

```
git log --oneline <last-tag>..HEAD
git log --format='%s%n%b' <last-tag>..HEAD | grep -iE 'BREAKING|Closes|Refs'
```

Conventional Commits make this mechanical: `feat` → Added, `fix` → Fixed, `perf` →
Performance, `!`/`BREAKING CHANGE` → Breaking, `docs`/`chore`/`ci`/`test` → usually
omitted unless user-visible. Merge PR titles when they are clearer than commit subjects.

## 2. Write

```
## <version> — <YYYY-MM-DD>

### Breaking changes
- <what breaks> → <what to do>. (#PR)

### Added
- <capability, from the user's point of view>. (#PR)

### Changed
### Fixed
### Performance
### Security
### Deprecated
```

Rules:

- One line per change, present tense, user-facing wording ("Exports now include the
  `region` column", not "add region to export serializer").
- Breaking changes first, each with the migration step; link the doc if longer.
- Security fixes name the advisory id if public; never describe an exploit.
- Group by impact, not by author or module. Omit internal refactors unless they change
  behaviour or performance.
- Keep `CHANGELOG.md` in Keep-a-Changelog order (newest first); add an `Unreleased`
  section for work in progress.

## 3. Verify

- Every breaking change in the diff appears in the notes (grep `BREAKING`, `!:`,
  removed public symbols).
- Every note maps to a commit or PR; no aspirational items.
- Version and date match the tag.

## Do not

- Do not paste commit messages verbatim.
- Do not list dependency bumps individually unless one is security-relevant or breaking;
  say "dependencies updated" and link the diff.
- Do not invent user impact for internal changes; leave them out.

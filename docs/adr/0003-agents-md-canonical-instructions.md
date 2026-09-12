# ADR-0003: `AGENTS.md` is the canonical instructions file

Date: 2026-09-11 · Status: accepted

## Context

Each agent tool has its own instructions file name: `AGENTS.md` (OpenCode, Codex, Cursor,
many others), `CLAUDE.md` (Claude Code), `GEMINI.md` (Gemini CLI), `.cursor/rules`.
Maintaining several copies guarantees drift.

## Decision

`AGENTS.md` at the repository root (and nested per package when needed) is the only file
with content. `CLAUDE.md` and `GEMINI.md` contain a single import line (`@AGENTS.md`);
`.cursor/rules/agents.mdc` points to it. OpenCode reads `AGENTS.md` natively and falls
back to `CLAUDE.md` only when it is absent.

Personal preferences that should not be committed go in the tool's global file
(`~/.config/opencode/AGENTS.md`, `~/.claude/CLAUDE.md`).

## Consequences

- One file to review, own (CODEOWNERS) and keep under the length budget.
- Tools that do not support imports would need a copy; none of the tools in scope do.
- Nested files require care: OpenCode/Codex read them automatically, Claude Code needs an
  import or a nested `CLAUDE.md` stub.

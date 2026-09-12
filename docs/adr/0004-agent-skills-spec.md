# ADR-0004: Reusable know-how is packaged as Agent Skills

Date: 2026-09-11 · Status: accepted

## Context

Procedures such as "how we write commits", "how we review", "how we debug" were being
pasted into prompts, commands and instruction files, in slightly different words each time.
They needed a portable, versioned, discoverable form.

## Decision

Follow the Agent Skills specification (agentskills.io): a folder per skill with `SKILL.md`
(frontmatter `name`, `description`; optional `license`, `compatibility`, `metadata`,
`allowed-tools`) and optional `scripts/`, `references/`, `assets/`. Skills are installed to
`~/.agents/skills/` (global) and `.agents/skills/` (project), the locations OpenCode, Claude
Code and Codex all scan. `SKILL.md` stays under 200 lines; detail goes to `references/`.

## Alternatives considered

- **Long `AGENTS.md`**: always in context, so every procedure costs tokens on every turn and
  dilutes attention. Rejected.
- **Commands only**: user-triggered, not model-triggered; the model cannot decide to apply
  the review checklist by itself. Commands remain for invocation; skills hold the how.
- **Tool-specific plugin formats**: not portable.

## Consequences

- Skills are code: reviewed, versioned, validated (`scripts/validate.sh`).
- Descriptions must be written as triggers; a poor description means a skill never loads.
- Tools with partial skill support (Cursor, Gemini CLI) get the same content through rules
  or manual reference.

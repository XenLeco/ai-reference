# ADR-0002: Clients reference role aliases, not vendor model IDs

Date: 2026-09-11 · Status: accepted

## Context

Model generations turn over every few months. Agent definitions, commands and docs that
name `claude-sonnet-5` or `gpt-5.6-terra` go stale together and must be edited in many
places. Different tasks need different tiers, and that mapping is a judgement that should
be made once.

## Decision

The gateway exposes stable **role aliases**: `local-small`, `coder-local`, `coder-cheap`,
`coder-fast`, `coder-frontier`, `reasoning-max`. Each alias is one primary deployment with
an explicit cross-vendor fallback chain. Agents, commands, templates and docs use aliases.

Vendor-native names are **also** exposed, unchanged, for tools that must pin a real ID
(Claude Code's model pins, Codex's `model`) and for deliberate one-off choices.

## Alternatives considered

- **Vendor names everywhere**: no indirection, but every model upgrade is a multi-file edit
  and per-task tiering is left to habit.
- **Load-balancing two vendors under one alias**: LiteLLM supports it; rejected as the
  default because mixing models within one agent session produces inconsistent behaviour
  and defeats prompt caching. Fallback-on-error keeps a session on one model until it fails.

## Consequences

- Re-pointing an alias is a one-line gateway change and a table update in doc 01.
- Context limits declared in client configs are conservative when a fallback is smaller.
- Renaming an alias is a breaking change; add new ones instead.

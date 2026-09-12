# ADR-0005: Personal and enterprise are profiles of one layout

Date: 2026-09-11 · Status: accepted

## Context

The same person uses agents on personal projects and inside a company with policies
(data classification, approved vendors, audit, budgets). A separate "enterprise repo" would
duplicate everything and the two would diverge.

## Decision

One layout, two value sets. Every enterprise artifact sits next to its personal counterpart
with an `.enterprise` suffix or under `templates/enterprise/`, and doc 08 explains each
difference. Structure, naming, aliases, skills and agents are shared; permissions,
allowlists, logging, guardrails and key policy differ.

## Consequences

- A personal setup can be hardened incrementally rather than rebuilt.
- Every new control must be added in both places or explicitly marked enterprise-only
  (the repo `AGENTS.md` says so).
- Some enterprise needs (SSO, Prometheus) rely on LiteLLM's paid tier or a reverse proxy;
  documented, not bundled.

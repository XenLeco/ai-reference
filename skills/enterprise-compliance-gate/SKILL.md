---
name: enterprise-compliance-gate
description: Pre-flight check before sending code or data to a non-local model in a company repository - classification, secrets, PII, third-party code, approvals. Use in enterprise/work contexts whenever the repository AGENTS.md has a policy block, when handling customer data, or when unsure whether content may leave the network.
license: MIT
compatibility: Intended for the enterprise profile described in docs/08-enterprise-profile.md; the gateway enforces routing, this skill makes the agent check intent first.
metadata:
  version: "1.0"
---

# Enterprise compliance gate

The gateway enforces where requests may go. This skill makes sure the *agent* does not try
to send the wrong thing in the first place, and that a human can see the decision.

## When to run the gate

Before the first request in a session that will include repository content, and again
whenever the content you are about to send changes class (you open a data file, a config
with credentials, a customer export).

## The gate

1. **Read the policy block** in the repository `AGENTS.md` (`## Policy` section: class,
   allowed aliases, prohibited actions, contact). If there is none in a company repo, treat
   the repo as **Confidential** and say so.
2. **Classify what you are about to send.** Answer yes/no:
   - contains secrets, tokens, private keys, connection strings?
   - contains personal data (names + identifiers, emails, phone numbers, addresses, health,
     payment, government IDs)?
   - contains customer or partner data (exports, logs with user records, tickets with PII)?
   - contains third-party proprietary code under NDA?
   - is the repository itself marked Restricted?
   Any yes on the first two → **remove or redact before sending, regardless of model**.
   Any yes on the rest, or repo Restricted → **local aliases only** (`coder-local`,
   `local-small`).
3. **Choose the alias** accordingly (see `model-selection`). State it in one line with the
   reason: "using coder-local: repository class Restricted".
4. **Prohibited actions** from the policy block apply to you: no external network, no
   pushing, no touching listed paths. If a task requires one, stop and ask the named contact.
5. **Disclosure**: any commit or PR you help produce carries the AI-assistance line required
   by the policy.

## Redaction rules

- Replace secrets with `<REDACTED:kind>`; never paraphrase them.
- Replace personal data with role placeholders (`<customer-1>`, `<email>`); keep structure.
- If redaction makes the task impossible, say what is missing and stop; do not "just send it".

## Escalation

If the policy is unclear, the classification is ambiguous, or you are asked to bypass the
gate: do not proceed. Summarise the situation in three lines and name the contact from the
policy block (or "security owner" if none). A human decides.

## Record

Add one line to your final report for the session:
`Compliance: class=<class>, alias=<alias>, redactions=<n>, escalations=<n|none>`.

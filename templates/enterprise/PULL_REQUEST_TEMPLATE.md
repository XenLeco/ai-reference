## Why

<!-- problem or goal, link the ticket -->

## What

<!-- what changed for users/callers; anything surprising -->

## How it was tested

- [ ] `<fast test command>`
- [ ] `<full test command>`
- manual:

## Risks and rollback

## AI assistance (required)

- [ ] No AI tools used
- [ ] AI-assisted — tool(s): `<...>`; model alias: `<coder-fast / coder-local / ...>`
- [ ] Every AI-assisted commit carries `Assisted-by: LLM` and `AI-Tool: <client> <alias>` trailers
- [ ] All AI-generated changes were read and understood by me
- [ ] No customer data, personal data or secrets were included in prompts
- [ ] Repository data class respected (see AGENTS.md → Policy)

## Reviewer checklist

- [ ] Tests cover the changed behaviour; a bug fix has a regression test
- [ ] No secrets, credentials or PII in code, config, tests or logs
- [ ] Dependencies added are pinned and justified
- [ ] Changes under `infra/`, `deploy/`, `migrations/` had explicit approval

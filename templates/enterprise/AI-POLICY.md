# AI-assisted engineering policy

<!-- Template. Replace <placeholders>, remove what does not apply, get sign-off from
     security, legal/privacy and engineering leadership. Version and date it. -->

**Owner:** <platform / engineering leadership> · **Security contact:** <team, channel> ·
**Privacy contact:** <team> · **Version:** 1.0 · **Effective:** <date> · **Review:** quarterly

## 1. Purpose and scope

This policy governs the use of AI coding assistants and agents (OpenCode, Claude Code,
Codex CLI, Cursor, IDE plugins, scripts calling model APIs) by <organisation> staff and
contractors on <organisation> code, data and systems. It applies to all repositories,
environments and devices used for that work.

## 2. Principles

1. **Human accountability.** The engineer who commits or merges is responsible for the
   change, whoever or whatever produced it.
2. **Data stays classified.** The classification of data does not change because a model
   processes it. Restricted data never leaves <organisation>-controlled infrastructure.
3. **One approved path.** Model access goes through the <organisation> AI gateway with a
   personal credential. Direct vendor keys for company work are prohibited unless listed in §5.
4. **Least privilege for agents.** Agents get the minimum tool access their task needs and
   require approval for irreversible or outbound actions.
5. **Transparency.** AI assistance is disclosed in pull requests.

## 3. Data classification and allowed processing

| Class | Definition | Allowed models |
|---|---|---|
| Public | released source, public docs | any approved (§5) |
| Internal | proprietary code and docs without customer/personal data | any approved (§5) |
| Confidential | code or data touching customer data, unreleased products, security tooling, partner NDA material | approved vendors with zero-data-retention or ≤ 30-day retention **and** region pinning where required; local models |
| Restricted | personal data, health, payment, government identifiers, secrets, regulated datasets, legal privilege | **local models only** (gateway `restricted` lane) |

Each repository declares its class in its `AGENTS.md` policy block. Unknown → Confidential.

Before any prompt: remove secrets and personal data. The gateway masks common PII patterns;
masking is a safety net, not permission.

## 4. Approved tools and configuration

- Tools: <OpenCode, Claude Code, Codex CLI, Cursor (Privacy Mode), …>. Versions are pinned
  and distributed by <team>; auto-update is disabled.
- Configuration is managed (`managed-settings`, distributed `opencode.json`, `config.toml`).
  Users may not weaken permission settings, disable the gateway, or enable sharing features.
- MCP servers, plugins and skills: only from the approved catalog (`mcp/catalog.json`,
  `skills/`). Additions require a PR reviewed by <security>.
- Network access from agent sandboxes is disabled by default.

## 5. Approved models and vendors

| Alias | Backing model | Vendor terms | Classes |
|---|---|---|---|
| `coder-fast`, `coder-cheap`, `coder-frontier`, `reasoning-max` | <Anthropic Claude Sonnet 5 / Haiku 4.5 / Opus 5>, <OpenAI GPT-5.6 / GPT-6> as fallback | DPA <ref>, ZDR <yes/no>, region <eu/us> | Public, Internal, Confidential (if ZDR/region satisfied) |
| `coder-local`, `local-small` | <Qwen3-Coder 30B-A3B, Gemma 4 12B/26B on org GPUs> | self-hosted | all, including Restricted |

Adding a vendor or model requires the checklist in docs/08 §7 and sign-off from
<security> and <privacy>. Claude Fable 5.1 is <not approved / approved> because it requires
30-day retention.

## 6. Obligations of engineers

- Use your own gateway credential; never share it; report loss immediately.
- Review every AI-generated change as you would a colleague's; run the tests.
- Disclose AI assistance in the PR template; keep the `Co-Authored-By` trailer if the tool
  adds one.
- Do not paste production data, customer records or secrets into any assistant.
- Do not let an agent push, deploy, or modify infrastructure without explicit approval.
- Follow the repository `AGENTS.md` policy block; when in doubt, ask <security contact>.

## 7. Logging and privacy of usage data

The gateway records who used which model, when, and token counts, for cost and audit.
Prompt and completion content is **not** stored by the gateway. Logs are retained <n> months
and accessible to <roles>. Vendors' own retention is governed by their terms (§5).

## 8. Intellectual property and licensing

- AI-generated code is treated as authored by the committing engineer; the same license and
  contribution rules apply.
- Do not ask assistants to reproduce third-party code verbatim; CI license scanning flags
  unusual headers and copyleft snippets.
- Open-weights models are used under their licenses (Gemma 4, Qwen3-Coder: Apache-2.0 at
  the time of writing); <legal> reviews changes.
- Community tools (skills, plugins, MCP servers, gateway components) are adopted only under
  permissive OSI licenses (MIT, MIT-0, Apache-2.0, BSD-2/3, ISC, 0BSD, Zlib, PostgreSQL).
  Copyleft (GPL/LGPL/AGPL), source-available (SSPL, RSAL, BSL, SUL, Elastic) and unlicensed
  code are not installed on company machines or into company repositories. Each adopted tool
  is recorded in the approved catalog with its license and safety properties (network,
  hooks, telemetry, what it writes) and pinned to a reviewed version.

## 9. Incidents

Report within <n> hours to <security contact>: credential leaks, suspected data sent to a
non-approved destination, prompt-injection incidents that caused an action, agent-caused
production changes. The platform team revokes credentials, preserves gateway logs, and files
vendor deletion requests where a DPA provides for it. Post-incident, the failing control is
changed.

## 10. Exceptions

Written, time-boxed, approved by <security> and <engineering leadership>, recorded in
<register>. Blanket exceptions are not granted.

## 11. Review

This policy, the model allowlist, the MCP/skills catalog and issued credentials are reviewed
quarterly by <owner>.

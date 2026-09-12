# 08 — Enterprise profile: working inside a company with policies

*Verified: 2026-09-11. Legal and compliance statements are templates to adapt with your
security, legal and privacy teams; nothing here is legal advice.*

Everything in the personal profile still applies. This document lists what changes when the
code, the data and the risk belong to an organisation, and maps each change to a file in
this repo. The enterprise artifacts are:

| Artifact | Path |
|---|---|
| gateway config | `gateway/config/litellm.enterprise.yaml` |
| compose overlay (Presidio, no public port) | `gateway/docker-compose.enterprise.yml` |
| OpenCode global config | `clients/opencode/opencode.enterprise.json` |
| OpenCode project config | `templates/enterprise/opencode.json` |
| Claude Code managed settings | `clients/claude-code/managed-settings.enterprise.json` |
| Codex config | `templates/enterprise/codex-config.toml` |
| policy document | `templates/enterprise/AI-POLICY.md` |
| `AGENTS.md` with policy block | `templates/enterprise/AGENTS.md` |
| compliance gate skill | `skills/enterprise-compliance-gate/` |

## 1. Principles that change

| Personal | Enterprise |
|---|---|
| convenience defaults, `allow` most things | least privilege, `ask` by default, deny lists for secrets and network |
| any vendor you have a key for | an **approved model allowlist** with a documented owner |
| one key per tool | one key per **person per tool**, under a **team** with a budget |
| local models for cost/offline | local models as a **mandatory lane** for restricted data |
| logs for your own curiosity | audit trail with retention, content logging **off** |
| you decide | a written policy, an approver, a review cadence |

## 2. Roles

- **Platform owner** (infra/DevEx): runs the gateway, owns `litellm.enterprise.yaml`,
  issues keys, reviews changes via PR.
- **Security owner**: approves the model allowlist, MCP server allowlist, guardrail config,
  reviews incidents.
- **Data/privacy owner**: signs off vendor DPAs, retention, region choices; owns the
  classification scheme.
- **Developers**: hold personal keys, follow the policy, disclose AI assistance in PRs.

## 3. Data classification drives routing

Define four classes (rename to your scheme) and record a repo's class in its `AGENTS.md`
policy block:

| Class | Examples | Allowed models | Gateway enforcement |
|---|---|---|---|
| **Public** | OSS code, public docs | any approved external or local | key models allowlist |
| **Internal** | proprietary code without customer data | approved external vendors with DPA + retention terms; local | key models allowlist |
| **Confidential** | code touching customer data, unreleased products, security tooling | approved vendors **with ZDR or ≤ 30-day retention and region pinning**; local preferred | key tag `confidential` → deployments tagged `confidential-ok` |
| **Restricted** | PII, PHI, payment data, secrets, regulated datasets, legal | **local only** | key tag `restricted` → local deployments only (`enable_tag_filtering`) |

In `litellm.enterprise.yaml` every deployment carries `tags`; a key created with
`tags: ["restricted"]` can only reach deployments that also carry `restricted`. A developer
working on a restricted repo gets a restricted key. The `enterprise-compliance-gate` skill
makes the agent itself ask the classification question before sending anything to a
non-local model.

Note the Anthropic nuance: **Claude Fable 5.1 requires 30-day retention**; organisations
on zero-data-retention terms should alias `reasoning-max` to `claude-opus-5` (or
`gpt-6-astra` under an OpenAI ZDR agreement). The enterprise config does this.

## 4. Gateway controls (`litellm.enterprise.yaml`)

| Control | Setting | Why |
|---|---|---|
| explicit allowlist, no wildcards | every `model_list` entry named; no `openai/*` | a new vendor model must be reviewed before anyone can use it |
| access groups | `model_info.access_groups: [external, local]`; keys get groups not model lists | a group change updates every key |
| tag routing | `router_settings.enable_tag_filtering: true`; deployments tagged | restricted data cannot reach external vendors even by mistake |
| content logging off | `litellm_settings.turn_off_message_logging: true` | spend and metadata are logged; prompts and completions are not stored in the gateway DB |
| PII masking | `guardrails` → Presidio `pre_call`, `default_on: true` | emails, card numbers, national IDs masked before leaving the network; tune entities |
| audit trail | `litellm_settings.callbacks: ["otel"]` to the org collector | who, when, which model, how many tokens; retained per policy |
| budgets and limits | team `max_budget`, key `max_budget`, `rpm_limit`, `tpm_limit` | cost containment, abuse detection |
| alerting | `general_settings.alerting: ["slack"]` | budget crossing, outages, slow responses |
| no UI edits | `store_model_in_db: false` | config only via PR |
| region | Anthropic `inference_geo`, OpenAI EU project, EU-hosted vLLM | residency requirements |
| TLS + auth in front | reverse proxy with org cert; UI behind SSO (LiteLLM SSO is a paid feature; a proxy with OIDC works) | never expose port 4000 raw |
| DB | managed Postgres, backups, encryption at rest | keys and spend are sensitive |
| replicas | Redis for shared rate limits and cooldowns when > 1 replica | consistency |
| secrets | `os.environ/` from the vault injector; no `.env` on the host | |
| pinned image | `ghcr.io/berriai/litellm:main-v1.x.y`, upgraded via PR after changelog review | |

Key issuance is scripted: `gateway/scripts/create-key.sh` accepts a team, a class tag and a
budget. Offboarding = `/key/delete`. Quarterly: list keys, delete unused.

## 5. Client controls

OpenCode (`opencode.enterprise.json`, `templates/enterprise/opencode.json`):
`share: "disabled"`, `autoupdate: false` (versions pinned and distributed), `enabled_providers:
["litellm"]`, `permission.edit: "ask"`, `permission.bash` allowlist of build/test/git-read
commands with everything else `ask`, `webfetch: "deny"`, MCP servers only from the approved
catalog, `read` denied for `.env*`, `**/*.pem`, `**/secrets/**`.

Claude Code (`managed-settings.enterprise.json`): distributed through managed settings so
users cannot override; gateway URL pinned; `permissions.deny` for secret paths and
`curl|wget|nc|ssh|scp`; `disableBypassPermissionsMode: "disable"`;
`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1`; models pinned to the approved Claude names.

Codex (`codex-config.toml`): `sandbox_mode = "workspace-write"`, `approval_policy =
"on-request"`, explicit `[projects]` trust, MCP allowlist.

Cursor / Copilot: enterprise plans with Privacy Mode / no-training settings; BYOK to the
gateway only if the plan allows; otherwise treat them as vendor-direct tools limited to
Public/Internal repos.

## 6. Repository controls

- `templates/enterprise/AGENTS.md` adds a **policy block**: repo classification, allowed
  aliases, prohibited actions (no external network, no writing to `infra/`, no secrets),
  disclosure requirement, escalation contact.
- CODEOWNERS on `AGENTS.md`, `opencode.json`, `.mcp.json`, `.agents/skills/` — changes to
  what agents are told are reviewed like code.
- Third-party skills and workflows only from an internal `approved-skills` repository,
  vendored at a reviewed commit; plugins and always-on rulesets (ponytail, AI-DLC runtime)
  reviewed like build tools and pinned; no `curl | sh` installers on managed machines.
  Vetting checklist and per-skill verdicts: doc 11.
- PR template with mandatory AI-assistance disclosure and the reviewer checklist from the
  `code-review-checklist` skill.
- Pre-commit: `gitleaks`; CI: dependency and license scanning (AI-generated code can
  introduce copyleft snippets; flag unusual license headers).
- Branch protection: no direct pushes, tests required, one human approval minimum regardless
  of AI review.

## 7. Vendor and legal checklist

Before a vendor enters the allowlist:

- [ ] DPA signed; sub-processor list reviewed
- [ ] training on API data excluded in writing
- [ ] retention terms known (default / ZDR); recorded per model (Fable 5.1 caveat)
- [ ] data residency option confirmed if required
- [ ] SOC 2 Type II / ISO 27001 evidence on file
- [ ] rate limits and SLAs adequate; status page monitored
- [ ] cost model understood; budget alerts configured
- [ ] open-weights models: license reviewed (Gemma 4 and Qwen3-Coder are Apache-2.0 at
      verification time; re-check when versions change), model card reviewed for
      restrictions
- [ ] community tools, plugins, MCP servers and infrastructure images: license in the
      permissive allowlist (MIT, MIT-0, Apache-2.0, BSD, ISC …) and the safety gate of
      doc 11 passed; `scripts/validate.sh` enforces the license field in both catalogs

## 8. Compliance mapping (starting point)

| Framework area | Where this profile addresses it |
|---|---|
| Access control (ISO 27001 A.5.15–A.5.18, SOC 2 CC6) | per-person keys, access groups, offboarding = key deletion, UI behind SSO |
| Logging and monitoring (A.8.15, CC7) | OTel audit trail, spend logs, alerts; content logging off by design |
| Data classification and handling (A.5.12–A.5.13) | four-class scheme, tag routing, local lane |
| Cryptography and transport (A.8.24) | TLS termination, encrypted DB, salted key storage |
| Supplier relationships (A.5.19–A.5.23) | vendor checklist, allowlist owner |
| Secure development (A.8.25–A.8.29) | review requirement, disclosure, secret scanning, sandboxed agents |
| GDPR Art. 28 / 32 | DPAs, PII masking, region pinning, retention records |
| EU AI Act (deployer duties, transparency) | policy document, disclosure in PRs, human review of agent output; coding assistants are generally limited-risk, confirm with counsel |

## 9. Rollout

1. **Pilot** (2–4 weeks): platform owner runs the gateway with the enterprise config, five
   volunteers on Public/Internal repos, personal-profile permissions minus network. Measure
   spend, collect friction.
2. **Policy**: adapt `AI-POLICY.md`, get sign-off, publish.
3. **Distribution**: managed settings for Claude Code, pinned OpenCode version + config via
   the org's device management, key issuance self-service via a ticket or script.
4. **Training**: one hour: the ladder, the classification question, prompt injection, how
   to disclose. The `enterprise-compliance-gate` skill reinforces it in-session.
5. **Expand** by repo class: Internal first, Confidential once ZDR/region terms are in
   place, Restricted only with the local lane proven.
6. **Review quarterly**: allowlist, keys, spend per team, incidents, policy changes.

## 10. Incident handling additions

Everything in 07 plus: an incident log with owner and timestamps; vendor deletion requests
for confirmed data leakage; notification duties per your DPA and, where applicable, GDPR
Art. 33 timelines; post-incident change to the guardrail or permission that failed.

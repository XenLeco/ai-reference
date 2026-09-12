# templates/enterprise/ — stricter project files for company repositories

Apply `templates/project/` first, then overlay these. Rationale for every control is in
[docs/08-enterprise-profile.md](../../docs/08-enterprise-profile.md).

| File | Replaces / adds | Purpose |
|---|---|---|
| `AI-POLICY.md` | new, org-level (one per organisation, linked from repos) | the written policy: scope, classification, allowed tools/models, obligations, incidents |
| `AGENTS.md` | appends a `## Policy` block to the project `AGENTS.md` | repo class, allowed aliases, prohibited actions, disclosure, contact |
| `opencode.json` | replaces `templates/project/opencode.json` | `ask` by default, allowlisted commands, secrets unreadable, catalog-only MCP |
| `codex-config.toml` | `~/.codex/config.toml` on company machines | sandboxed, approval on request, gateway-only |
| `CODEOWNERS` | `.github/CODEOWNERS` fragment | review required for anything that instructs agents |
| `PULL_REQUEST_TEMPLATE.md` | `.github/PULL_REQUEST_TEMPLATE.md` | mandatory disclosure and reviewer checklist |
| `workflows/ai-review.yml` | `.github/workflows/ai-review.yml` | label-gated, self-hosted, read-only, pinned AI review through the internal gateway |

Client-level enterprise files live next to their personal counterparts:
`clients/opencode/opencode.enterprise.json`, `clients/claude-code/managed-settings.enterprise.json`,
`gateway/config/litellm.enterprise.yaml`, `gateway/docker-compose.enterprise.yml`.

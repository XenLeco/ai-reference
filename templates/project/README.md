# templates/project/ — drop-in files for any repository

Copy everything in this directory (including dotfiles) into the root of a repository, then
edit `AGENTS.md`. Nothing else needs changing to start.

```bash
cp -r templates/project/. /path/to/repo/     # bash; copies dotfiles too
Copy-Item templates/project/* /path/to/repo -Recurse -Force   # PowerShell
```

| File | Read by | Edit? |
|---|---|---|
| `AGENTS.md` | OpenCode, Codex, Cursor (native); Claude Code and Gemini via import | **yes** — every section |
| `CLAUDE.md` | Claude Code | no (imports `AGENTS.md`) |
| `GEMINI.md` | Gemini CLI | no |
| `.cursor/rules/agents.mdc` | Cursor | no |
| `opencode.json` | OpenCode (project-level, merges over global) | optionally: model per agent, instructions, permissions |
| `.mcp.json` | Claude Code, Cursor | optionally: enable servers from `mcp/catalog.json` |
| `.agents/skills/` | OpenCode, Claude Code, Codex | add project-specific skills |
| `.editorconfig` | editors and agents | rarely |
| `.github/PULL_REQUEST_TEMPLATE.md` | GitHub | adapt to the repo |
| `.pre-commit-config.yaml` | pre-commit | run `pre-commit autoupdate` to pin revisions, then `pre-commit install` |
| `.devcontainer/` | VS Code / devcontainer CLI | agent tooling preinstalled, gateway wired via `host.docker.internal`, keys from host env |
| `.github/workflows/security-scan.yml` | GitHub Actions | gitleaks, OSV-Scanner, Trivy, license audit; pin action SHAs |
| `.github/workflows/ai-review.yml` | GitHub Actions | OpenCode read-only PR review via the gateway; set `LITELLM_BASE_URL` var and `LITELLM_CI_KEY` secret |
| `.github/workflows/ai-assist.yml` | GitHub Actions | `/oc` mentions by repo members |
| `.github/workflows/ai-review-claude.yml.example` | GitHub Actions | Claude Code alternative; rename to enable |

Enterprise repositories use `templates/enterprise/` on top of this.

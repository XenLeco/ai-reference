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

Enterprise repositories use `templates/enterprise/` on top of this.

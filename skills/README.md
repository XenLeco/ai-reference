# skills/ — portable Agent Skills

Each folder is one skill in the [Agent Skills](https://agentskills.io/specification) format:
`SKILL.md` with `name` (= folder name) and `description` frontmatter, optional
`scripts/`, `references/`, `assets/`. OpenCode, Claude Code and Codex discover them from
`~/.agents/skills/` (installed by `scripts/install-personal.sh`) and `.agents/skills/` in a
project. Design rules: [docs/05-agents-skills-commands.md](../docs/05-agents-skills-commands.md).

| Skill | Triggers on | Profile |
|---|---|---|
| `conventional-commits` | commit, commit message, changelog | both |
| `code-review-checklist` | review, PR review, "look over this diff" | both |
| `debug-reproduce-first` | bug, error, stack trace, "it broke" | both |
| `pr-writeup` | open a PR, describe the change | both |
| `secure-coding-baseline` | auth, input validation, secrets, dependencies, crypto | both |
| `model-selection` | which model, cost, "is this worth Opus" | both |
| `repo-onboarding` | new repo, "explain this codebase", missing `AGENTS.md` | both |
| `enterprise-compliance-gate` | before sending code/data to a non-local model in company repos | enterprise |
| `dependency-upgrade` | bump, upgrade, audit findings, advisories | both |
| `migration-playbook` | schema/data migrations, renames, API versions, framework majors | both |
| `perf-profiling` | slow, memory, timeouts, "optimise" | both |
| `release-notes` | changelog, release, "what changed since" | both |
| `sql-review` | queries, migrations, ORM code, slow query | both |
| `api-design-review` | new or changed endpoints, public functions, event schemas | both |
| `incident-postmortem` | after an outage or incident, RCA, post-incident review | both |

Validate: `scripts/validate.sh` (frontmatter, folder/name match, description length).
Write a new one by copying the smallest existing skill; keep `SKILL.md` under 200 lines.

## Third-party skills

`community.json` catalogs vetted external tools (Serena, graphify, code-review-graph, beads,
superpowers, spec-kit, compound-engineering, AI-DLC, archify, ponytail, oh-my-openagent,
caveman) with tier, license, install commands per client, what they write, and the
personal/enterprise verdict. Rule of thumb from doc 11: one methodology pack, one retrieval
tool, at most one code graph. The assessment and the vetting checklist are in
[docs/11-community-skills.md](../docs/11-community-skills.md); install with
`scripts/install-community-skills.sh --graphify --archify …` (opt-in, nothing by default).

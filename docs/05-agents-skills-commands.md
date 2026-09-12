# 05 — Designing agents, skills and commands

*Verified: 2026-09-11 against agentskills.io/specification and opencode.ai/docs.*

## Vocabulary

| Thing | Lifetime | Who triggers | Lives in | Portable? |
|---|---|---|---|---|
| **Instructions** (`AGENTS.md`) | always in context | automatic | repo root, `~` | yes, all tools |
| **Skill** (`SKILL.md` folder) | loaded on demand by the model | the model, when the description matches | `.agents/skills/` | yes (spec) |
| **Command** (`/name`) | one invocation | you | `.opencode/commands/`, `.claude/commands/` | frontmatter differs slightly |
| **Agent / subagent** | one task or one session | you (`@name`, Tab) or the primary agent | `.opencode/agents/`, `.claude/agents/` | concept portable, files not |
| **MCP server** | process/connection | the model, via tools | per-client config | declaration format differs, servers identical |

Rule of thumb: **facts about the repo → `AGENTS.md`; know-how → skill; repeatable prompt →
command; role with a tool budget → agent; external system → MCP.**

## Instructions (`AGENTS.md`)

Keep it under ~300 lines. It is loaded into every request, so every line costs tokens on
every turn and every line competes for attention. Contents, in order:

1. one paragraph: what the project is and its current goal;
2. commands: build, test (fast and full), lint, format, run — one line each, exact;
3. architecture map: top-level directories and what lives where; where to add a new X;
4. conventions the model cannot infer from code: naming, error handling, logging, commit
   style, PR expectations;
5. explicit **do not** list: files never to touch, commands never to run, patterns banned;
6. definition of done.

Do not put general programming advice in it. Do not paste style guides; link them or make
them a skill. Nested `AGENTS.md` in subpackages override for that subtree.

## Skills

A skill is `name/SKILL.md` with frontmatter (`name` = folder name, lowercase-hyphen ≤ 64
chars; `description` ≤ 1024 chars saying *what and when*; optional `license`,
`compatibility`, `metadata`, experimental `allowed-tools`) and a markdown body. Optional
`scripts/`, `references/`, `assets/`.

Progressive disclosure: name + description are always visible (~100 tokens per skill);
the body loads only when the model activates the skill; referenced files load only when
read. Therefore:

- **the description is the trigger**. Include the words a user would say. "Use when the
  user mentions commit, commit message, changelog" beats "Helps with git".
- keep the body under 200 lines; put the long reference in `references/*.md` and link it;
- give **procedures**, not lectures: numbered steps, exact commands, expected output;
- make scripts self-contained and print useful errors; the model will run them blind;
- never rely on tool-specific features in the body; if a script needs one, say so in
  `compatibility`.

Skills in this repo (`skills/`):

| Skill | When it triggers | Notes |
|---|---|---|
| `conventional-commits` | committing, writing commit messages, changelog | scope rules, breaking-change footer |
| `code-review-checklist` | reviewing a diff or PR | severity ladder, what to ignore |
| `debug-reproduce-first` | any bug report | reproduce → isolate → fix → regression test |
| `pr-writeup` | opening or describing a PR | template, what reviewers need |
| `secure-coding-baseline` | touching auth, input handling, secrets, deps | OWASP-derived checks |
| `model-selection` | choosing which alias to use, cost questions | the ladder from doc 01 |
| `repo-onboarding` | a repo has no `AGENTS.md`, or "explain this codebase" | produces an `AGENTS.md` draft |
| `enterprise-compliance-gate` | enterprise profile only: before sending data to a non-local model | classification questions, escalation |

Validate with `scripts/validate.sh` (checks frontmatter and folder/name match). The
reference validator is `skills-ref validate ./skill` from the agentskills repo.

Third-party skills (graphify for codebase graphs, archify for diagrams, ponytail's
write-less-code ruleset, AWS's AI-DLC workflow) are assessed in doc 11 with a vetting
checklist by risk tier; `skills/community.json` is the catalog and
`scripts/install-community-skills.sh` the opt-in installer.

## Commands

A command is a prompt template you invoke. Good commands:

- **inject state, not instructions**: `` !`git diff --staged` ``, `@package.json`; the model
  gets facts, the skill/agent gets the how;
- **name the agent**: `/review` runs the `reviewer` subagent, so the primary session's
  context stays clean (`subtask: true`);
- **accept arguments**: `$ARGUMENTS` for free text, `$1 $2` for positional;
- **stay short**: three to ten lines. If it grows, the how-to belongs in a skill.

Claude Code's `.claude/commands/*.md` uses the same idea with slightly different frontmatter
(`allowed-tools`, `argument-hint`, `model`). Keep the body identical; only the frontmatter
differs. `scripts/install-personal.sh` does not translate commands automatically; copy the
ones you use.

## Agents and subagents

An agent is **a role + a model + a tool budget + a prompt**. Design rules:

- **Read-only by default.** Reviewers, architects, scouts and auditors never edit. Only
  `build`, `test-writer` and `docs-writer` write, and `docs-writer` only under `docs/`.
- **Model by role, not by habit.** Exploration and summarisation → `coder-local` or
  `coder-cheap`. Judgement → `coder-fast`. Design and security → `coder-frontier` /
  `reasoning-max`. The expensive model should read a summary, not the whole tree.
- **Low temperature** (0.1–0.3) for review and tests; default for design brainstorming.
- **Bounded steps**: `steps: 30` on subagents so a confused agent cannot burn a budget.
- **One depth level**: `subagent_depth: 1`. Subagents that spawn subagents are unaccountable.
- **Descriptions are routing**: the primary agent reads them to decide whom to delegate to.
  Write "Use when…" sentences.
- **Return contracts**: tell the subagent what to return (findings list with file:line, a
  plan in a fixed shape). The primary agent's context is expensive; a rambling subagent
  report pollutes it.

Orchestration pattern that works:

```
plan (reasoning-max, read-only)  →  build (coder-fast, edits)  →  reviewer (coder-fast, read-only)
                                          ↑                              |
                                          └── test-writer ◄──────────────┘  (fix → re-review, max 2 rounds)
```

Escalate model rung only when a step fails twice; do not start on `reasoning-max`.

## MCP servers

Use MCP for **external systems** the model cannot reach with a shell: issue trackers,
documentation indexes, browsers, databases. Do not use MCP for things a CLI already does
(git, gh, docker); a shell tool with a permission pattern is cheaper, more transparent and
easier to audit. Every MCP server adds its tool descriptions to every request; five servers
can cost thousands of tokens per turn. Enable per agent, not globally. Catalog in `mcp/`.

## Testing your configuration

- **Regression evals**: `scripts/evals.sh` runs the promptfoo suite in `evals/promptfoo/`
  through the gateway. Every skill has fixture tasks with shape assertions (valid commit
  subject, `path:line`, required sections), safety assertions (a planted secret must not
  appear) and one `llm-rubric` per test graded on `coder-cheap`. `--agents` also runs the
  OpenCode agents for real against `fixtures/mini-repo`. Run it whenever `AGENTS.md`, a
  skill, an agent or an alias mapping changes.
- New skill: ask a question that should trigger it and one that should not; check the
  session log to see whether it loaded.
- New agent: run it on a known task with a known good answer; compare cost in the gateway UI.
- New command: run with and without arguments; run it twice and confirm the second run's
  prompt is cache-friendly (same prefix).
- Keep a `docs/agent-evals.md` in serious repos: a handful of prompts and expected outcomes
  you re-run after changing `AGENTS.md`.

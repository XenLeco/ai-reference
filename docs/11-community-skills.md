# 11 — Community skills and workflows

*Verified: 2026-09-11 against the GitHub READMEs and LICENSE files of Graphify-Labs/graphify,
tirth8205/code-review-graph, oraios/serena, steveyegge/beads, JuliusBrussee/caveman,
obra/superpowers, github/spec-kit, EveryInc/compound-engineering-plugin, tt-a1i/archify,
DietrichGebert/ponytail, code-yeongyu/oh-my-openagent, awslabs/aidlc-workflows and
vercel-labs/skills, plus JetBrains' July 2026 measurement of caveman. Star counts and
versions move weekly; the mechanics, licenses and verdicts are what matter.*

The skills in `skills/` are small and ours. The ecosystem has larger third-party tools that
claim two things: **less token consumption** and **more precise decisions**. This document
gives two hard gates every tool must pass, a way to evaluate what passes, and verdicts on
twelve tools that come up often. The machine-readable catalog is `skills/community.json`;
the opt-in installer is `scripts/install-community-skills.{sh,ps1}`; `scripts/validate.sh`
refuses catalog entries that fail the license gate.

## Hard gate 1 — license

Everything recommended in this repository must be usable at work without a legal
conversation. That means a permissive, OSI-approved license:

| Allowed | Not allowed |
|---|---|
| MIT, MIT-0, Apache-2.0, BSD-2-Clause, BSD-3-Clause, ISC, 0BSD, Unlicense, Zlib, PostgreSQL | GPL/LGPL/AGPL (copyleft), SSPL, RSALv2, BSL/BUSL, SUL, Elastic, "source-available", "free for personal use", custom or missing licenses |

Rules:

- The license is read from the repository's `LICENSE` file, not from a marketplace card.
  Dual-licensed projects count as the most permissive option *only if that option covers the
  part you use* (caveman: the skill is MIT, its proxy is BSL-1.1; only the skill would pass).
- Open-weights models need a permissive model license too: Gemma 4 and Qwen3-Coder are
  Apache-2.0 at verification; re-check when a new version lands.
- Hosted services you merely call (GitHub, Sentry, Atlassian, context7's endpoint) have
  terms, not licenses; they are governed by the vendor checklist in doc 08 §7 and are
  marked `service` in the catalogs.
- Vendor CLIs (Claude Code is proprietary; Codex CLI and Gemini CLI are Apache-2.0; OpenCode
  is MIT) are tools you run under their commercial terms, not code you import; the office
  accepts those terms when it buys the product. The gate applies to community code that
  lands in repos or on machines.
- Infrastructure here already passes: LiteLLM MIT (its `enterprise/` directory is under a
  separate commercial license and is not used by either profile), Postgres (PostgreSQL
  License), **Valkey** BSD-3 (the compose file uses Valkey, not Redis: Redis 7.4+ moved to
  RSALv2/SSPL and Redis 8 to AGPL, none of which pass), Ollama MIT, vLLM Apache-2.0,
  Presidio MIT, Caddy Apache-2.0, the `skills` CLI MIT, every MCP server in `mcp/catalog.json`.

`scripts/validate.py` checks the `license` field of every entry in `skills/community.json`
and `mcp/catalog.json` against the allowlist; an entry that fails must sit under `excluded`
with a reason, or the validation fails.

## Hard gate 2 — safety

A tool is a danger when it can run code you did not read, reach the network on its own, or
change what the agent is told. Every entry records these facts under `safety`, and the
verdict follows from them:

| Property | Acceptable | Needs review (enterprise: platform team) | Excluded |
|---|---|---|---|
| **executes code** | instructions only | CLI you install; scripts the agent runs | code that runs on session start without a way to read it first |
| **hooks / always-on** | none | client hooks or always-on rules, pinned version | unpinned, auto-updating |
| **outbound network** | none, or the gateway only | documented endpoints you can block | bundled third-party search/fetch you cannot disable |
| **telemetry** | none | opt-out, disabled by managed environment | cannot be disabled |
| **writes instruction files** | no | appends a reviewable snippet to `AGENTS.md` | rewrites instruction files silently |
| **install** | package manager with a pinned version, or vendored clone | download-then-run with a printed checksum | `curl … \| sh` on managed machines |
| **permissions it asks for** | read-only; writes into its own directories | write access to the repo | secrets, home directory, shell as root |

The catalog entries below all pass the license gate; the ones that fail the safety gate for
the enterprise profile say so in their verdict.

## Measure first, then use the levers you already own

Before installing anything, look at the gateway's spend page (`/ui`, per key and per model).
Most waste is one of five things, and each has a fix already in this repo:

| Symptom in the spend log | Lever already in place |
|---|---|
| frontier model doing exploration | `local-scout` / `explore` on `coder-local`; `coder-cheap` for subagents (doc 05) |
| long sessions re-sending stale tool output | `compaction.prune: true`, `subagent_depth: 1`, `steps` caps |
| every request carries thousands of tokens of tool schemas | MCP servers disabled globally, enabled per agent (`tools: {"x*": false}`) |
| the same prefix re-billed every turn | stable `AGENTS.md` and system prompts so prompt caching hits |
| verbose answers to simple steps | lower `effort` / `reasoning_effort` for routine work; terse `AGENTS.md` communication rules |

Third-party tools help beyond that in two ways: **retrieval** (read less code to answer a
question) and **memory** (stop re-deriving decisions across sessions). Everything else is a
methodology, which improves outcomes and usually *increases* tokens per task while reducing
tokens per *shipped* feature. Judge cost per completed task, never per request.

## How to evaluate what passes the gates

Three risk tiers; the tier decides the review effort.

| Tier | What it is | Examples | Review like |
|---|---|---|---|
| **Instructions only** | `SKILL.md` and reference files; nothing executes | most of skills.sh, superpowers' skill bodies | a document: read it, check it does not contradict `AGENTS.md` |
| **Skill with scripts / CLI** | code the agent runs or a CLI you install | graphify, archify, spec-kit, beads | a dependency: license, maintenance, reads/writes, network, pin the version |
| **Plugin / MCP / hooks / always-on** | code loaded by the client every session, tools in every request, or rules injected every turn | Serena, code-review-graph (MCP), ponytail, superpowers (plugin), compound-engineering, AI-DLC | a build tool: full review, pinned, distributed by the platform team in enterprise |

Also check: maintenance (commits in the last 90 days, issues answered); **always-present
overhead** (each MCP tool costs roughly 100–300 tokens of schema on every request, each
skill's metadata ~100 tokens, always-on rulesets 1–2k; keep the total under ~10k and enable
heavy tool sets only for the agents that use them); **conflicts** with our agent, command
and skill names; and what the tool writes into the repo (add it to `AGENTS.md` → *Generated
directories*).

## Do not stack methodology packs

superpowers, compound-engineering, spec-kit and AI-DLC each answer "what must happen before
code is written". Two of them at once means two brainstorm gates, two plan formats, two
review passes and double the skill metadata. Rule: **one methodology pack, one retrieval
tool, at most one code graph, plus memory if work spans sessions.** The lightweight loop in
this repo (`/plan → build → /review → /test → /commit`) is itself a minimal methodology; the
packs replace it for bigger work, they do not sit on top.

## Recommended stacks

| Need | Personal | Enterprise |
|---|---|---|
| retrieval (read less) | **Serena** | **Serena**, vendored |
| code graph | **graphify** (visual, docs/PDFs) *or* **code-review-graph** (auto-updating MCP, blast radius) | either, pinned; code-review-graph if you want zero LLM calls |
| methodology, day to day | **superpowers** (or compound-engineering for the learnings ledger) | superpowers with telemetry off, or compound-engineering, after plugin review |
| methodology, features > 1 day | **spec-kit** | **spec-kit** (pinned tag) or **AI-DLC** for regulated work |
| memory across sessions | **beads** when work spans days or agents | beads (repo-local data, MIT) |
| diagrams | archify | archify |
| scope restraint | ponytail (try) | ponytail after plugin review |
| excluded | caveman, oh-my-openagent | caveman, oh-my-openagent |

## Installing: the `skills` CLI and alternatives

`npx skills add <owner/repo> -g` (vercel-labs/skills, MIT) installs Agent Skills into the
global skill directory of every detected agent. `npx skills list`, `update`, `remove`
manage them. Right for instruction-only skills and personal machines. Plugins install
through each client's plugin mechanism; MCP tools through MCP config; CLIs through
`uv tool install` with a pinned version.

Enterprise: **vendor**. Clone at a reviewed commit into an internal `approved-skills`
repository, distribute from there, record the upstream SHA in `metadata`. Works offline,
leaves an audit trail.

---

## Part A — reducing consumption

### Serena — symbol-level retrieval and editing (MCP) · MIT

**What.** An MCP server that gives the agent IDE-grade tools over language servers:
`find_symbol`, `find_referencing_symbols`, read a symbol's body, replace or insert at
symbol level, plus project memories. The agent fetches the one function it needs instead of
the file, and edits by symbol instead of by string match. 40+ languages via LSP (a paid
JetBrains backend is optional and not needed).

**Install.** `uv tool install -p 3.13 serena-agent`. Register it as an MCP server in each
client with `serena start-mcp-server --context <client> --project <path>`; contexts exist
for Claude Code, Codex and generic IDE assistants (`serena start-mcp-server --help` lists
them for your version). Index once per project: `serena project index`. The README says
explicitly *not* to install it from plugin marketplaces. OpenCode:

```json
"mcp": {
  "serena": {
    "type": "local",
    "command": ["serena", "start-mcp-server", "--context", "ide-assistant", "--project", "."],
    "enabled": true
  }
},
"tools": { "serena*": false },
"agent": { "build": { "tools": { "serena*": true } } }
```

**Safety.** Local only; no model calls, no network, no hooks, no telemetry. Writes `.serena/`.
Around 25 tools in every request when enabled: several thousand tokens of schema, so enable
it for `build` (and `test-writer`), not for read-only subagents that use `rg`.

**Verdict.** Personal: **recommended**; the single biggest retrieval win for medium and
large codebases. Enterprise: **recommended**, vendored.

### Code graphs — graphify vs code-review-graph

Both build a tree-sitter graph of the repo so the agent queries structure instead of
reading files. Pick one.

**graphify** (Graphify-Labs) · Apache-2.0 / MIT. Python CLI + skill. `/graphify .` writes
`graphify-out/` (`graph.json`, interactive `graph.html`, `GRAPH_REPORT.md`); `/graphify
query|path|explain` answer from the graph. Also ingests docs, PDFs, images and video, which
uses an LLM: set `OPENAI_BASE_URL=http://localhost:4000/v1` and a virtual key so it goes
through the gateway, or `OLLAMA_BASE_URL` for free local extraction. Install: `uv tool
install graphifyy` (double y), `graphify install --platform agents` → `~/.agents/skills/`.
Commit `graphify-out/` (ignore `cache/`), install its merge driver (`graphify hook
install`), run `graphify update .` after pulls. Ignore `graphify-out/**` in watchers and
`.claudeignore` (done in the OpenCode configs here). Safety: network only through the
gateway or Ollama when you choose to extract documents; optional git hooks you install
yourself; a commercial platform exists but is not needed.

**code-review-graph** (tirth8205) · MIT. Python CLI + MCP server. `uv tool install
code-review-graph`, then `code-review-graph install --platform opencode` (or claude-code,
codex, cursor, gemini-cli) writes MCP config and injects graph-aware rules into the client's
instruction files: **review that diff**. Stores `.code-review-graph/` (SQLite). Re-parses
only files whose hash changed, on save or commit; exposes ~30 tools including **blast
radius** (callers, dependents and tests affected by a change). No LLM calls, no network.
Its published numbers (median 65× fewer tokens per question on six repos) come from a
documented, reproducible method.

**Choosing.** graphify when you want a visual map and to fold docs/PDFs into the same
graph; code-review-graph when you want it always current, zero model calls, and
blast-radius for reviews. Serena plus one graph is not redundant: Serena is precise
navigation and editing, a graph is whole-repo structure and impact.

**Verdict.** Personal: **recommended** (one of the two) for repos over a few thousand lines.
Enterprise: **allowed**, pinned.

### claude-context — semantic code search for very large repos (MCP) · MIT

**What.** Zilliz's MCP server: hybrid BM25 + dense-vector search over AST-chunked code,
Merkle-tree incremental sync, backed by Milvus (Apache-2.0, runs locally in Docker) and an
embedding model from Ollama (`nomic-embed-code`, Qwen3-Embedding; Apache-2.0) or any
OpenAI-compatible endpoint, which means the gateway. Where Serena is precise navigation and
a graph is structure, this is search by meaning across millions of lines.

**Safety.** Local server and local index; embedding traffic goes to Ollama or the gateway.
Check the telemetry environment variables for your version. Index contents are code
embeddings: keep Milvus and the embedding model local for Confidential and Restricted repos.

**Verdict.** Personal: **optional**, worth it only when a repo outgrows Serena plus a
graph. Enterprise: **allowed** with local embeddings. Details and setup in doc 12 §E.

### beads — persistent task graph (memory across sessions) · MIT

**What.** `bd`, a CLI issue tracker built for agents: hash ids (`bd-a1b2`), dependencies,
epics, atomic claiming for parallel agents, `bd remember` for project facts. Storage is an
embedded Dolt/SQLite database exported to JSONL that lives in git, so the graph travels with
the repo and merges without conflicts. Replaces `PLAN.md` files that go stale.

**Install.** `brew install beads` or `npm install -g @beads/bd`; `bd init` in the repo.
`bd init` **appends a workflow snippet to `AGENTS.md`**; review the diff and move the
snippet under a heading of ours.

**Safety.** Local only; no network, no hooks, no telemetry. `.beads/` is repository content
(Internal class in enterprise). Young project with fast-moving storage internals; read the
migration notes before upgrading.

**Verdict.** Personal: **recommended** for work that spans sessions, days or agents.
Enterprise: **allowed**.

---

## Part B — sharpening decisions

### superpowers — the methodology pack · MIT

**What.** Jesse Vincent's skills library: `brainstorming` (before any creative work),
`writing-plans`, `executing-plans`, `test-driven-development` (strict red-green-refactor),
`systematic-debugging`, `verification-before-completion`, `subagent-driven-development`,
`dispatching-parallel-agents`, `requesting-code-review`, `using-git-worktrees`,
`finishing-a-development-branch`, `writing-skills`. Skills trigger automatically and are
framed as mandatory workflows. In Anthropic's official plugin marketplace.

**Install.** Claude Code: `/plugin install superpowers@claude-plugins-official`. Codex:
`/plugins` → Superpowers. OpenCode: follow `.opencode/INSTALL.md` in the repository.

**Safety.** A plugin with hooks in Claude Code (review the hook scripts; pin the version).
Telemetry is opt-out: set `SUPERPOWERS_DISABLE_TELEMETRY=1` in the managed environment.
No other network. Overlaps three skills in this repo (`debug-reproduce-first`,
`code-review-checklist`, `pr-writeup`); remove those from `~/.agents/skills` if you adopt
it, to avoid duplicate triggers.

**Verdict.** Personal: **recommended**. Enterprise: **allowed after plugin review**,
telemetry disabled.

### spec-kit — spec-driven development (GitHub) · MIT

**What.** GitHub's toolkit: `specify` CLI plus slash commands in the order
`/speckit.constitution` → `/speckit.specify` → `/speckit.clarify` → `/speckit.plan` →
`/speckit.tasks` → `/speckit.analyze` → `/speckit.implement` → `/speckit.converge`.
Writes `.specify/`, `specs/<feature>/` and `memory/constitution.md`. 30+ agent
integrations including OpenCode, Codex, Claude Code, Cursor, Gemini, Copilot.
Python 3.11+, uv, git.

**Install.** Pin a release tag:

```bash
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@vX.Y.Z
cd repo && specify init . --integration opencode --force     # claude | codex | cursor | gemini | copilot …
```

**Safety.** CLI + Markdown templates; no hooks, no network after install, no telemetry.
Writes only into its own directories.

**Verdict.** Personal: **recommended** for features over a day of work. Enterprise:
**recommended**; GitHub-maintained, pinned tag, artifacts auditable in PRs.

### compound-engineering — plan/work/review plus a learnings ledger · MIT

**What.** Every's plugin: 35 skills and the loop `/ce-brainstorm → /ce-plan → /ce-work →
/ce-simplify-code → /ce-code-review → /ce-compound`, plus `/ce-debug`, `/ce-explain`, `/lfg`.
The distinctive step is **compound**: learnings are written to `docs/solutions/` where the
next task reads them. Plans go to `docs/plans/`; config in `.compound-engineering/config.yaml`.

**Install.** Claude Code: `/plugin marketplace add EveryInc/compound-engineering-plugin`,
`/plugin install compound-engineering`. Codex: `codex plugin add
compound-engineering@compound-engineering-plugin`. OpenCode: add
`"compound-engineering@git+https://github.com/EveryInc/compound-engineering-plugin.git#<sha>"`
to `plugin`, pinned to a commit. Cursor: `/add-plugin compound-engineering`.

**Safety.** Plugin (review, pin). No network of its own, no telemetry found. Cost: 35 skill
descriptions ride along on every request (~3–4k tokens), more than superpowers.

**Verdict.** Personal: **good alternative** to superpowers (same slot). Enterprise:
**allowed**, pinned; `docs/solutions/` is exactly the artifact reviewers want.

### AI-DLC workflows — AWS's structured lifecycle · MIT-0

**What.** A methodology and runtime from AWS Labs: `/aidlc <request>` selects a workflow
profile (11 profiles), asks for missing decisions, and walks 5 phases / 33 stages with
**approval gates after each stage**, 14 agents, and an audit trail. Artifacts under
`aidlc/`. Version 2.8.2 at verification. Upstream recommends Claude Opus 4.8; through the
gateway use `coder-frontier` for inception, `coder-fast` for construction.

**Install.** Download the release installer, check it, run it, then configure per project:

```bash
tmp="$(mktemp -d)"
curl -fsSL https://github.com/awslabs/aidlc-workflows/releases/latest/download/install.sh -o "$tmp/install.sh"
sha256sum "$tmp/install.sh"          # compare with the release page before running
sh "$tmp/install.sh" && rm -rf "$tmp"
cd your-project && aidlc config --harness opencode     # claude | codex | cursor | kiro | kiro-ide | copilot
aidlc doctor
```

Windows: `install.ps1` from the same release. OpenCode ≥ 1.17 uses a split `.aidlc/` +
`.opencode/` layout; Codex ≥ 0.145 uses `$aidlc`. Enterprise: the
`aidlc-runtime-X.Y.Z.tar.gz` release and `runtime/<harness>/`, vendored.

**Safety.** Runtime with hooks and its own agents (review, pin). No network during
workflows beyond the model calls through the gateway. Whether `aidlc config` edits an
existing `AGENTS.md` is undocumented; diff after configuring.

**Verdict.** Personal: **optional**, for multi-week builds. Enterprise: **strong
candidate** for Confidential-class and regulated projects, installed from the vendored
tarball.

### archify — verifiable architecture diagrams · MIT

**What.** Skill + Node renderer. The agent writes typed JSON; archify validates it against
schema and layout rules and renders self-contained HTML (PNG/SVG/WebM export). Diagram
types: architecture, workflow, sequence, data-flow, lifecycle. CLI
`node archify/bin/archify.mjs validate|preview|deliver|guide|compare`.

**Install.** `npx skills add tt-a1i/archify -g`. Node.js required.

**Safety.** No model calls of its own, no network at render, no hooks. Confirm generated
HTML loads no remote assets before publishing internally (the project states files are
self-contained).

**Verdict.** Personal: **recommended**. Enterprise: **allowed**.

### ponytail — scope restraint · MIT

**What.** An always-on decision ladder before writing code: does this need to exist →
already in the codebase → stdlib → platform feature → installed dependency → one line →
only then the minimum that works. Commands `/ponytail lite|full|ultra|off`,
`/ponytail-review`, `/ponytail-audit`, `/ponytail-debt`.

**Install.** OpenCode: `"plugin": ["@dietrichgebert/ponytail@<version>"]`. Claude Code:
`/plugin marketplace add DietrichGebert/ponytail`, `/plugin install ponytail@ponytail`.
Codex: `codex plugin marketplace add …`, `codex plugin add ponytail@ponytail`. Cursor and
similar: copy the rule file. Node on PATH for the hooks.

**Safety.** Always-on rules (tokens every turn) and a plugin with hooks (review, pin). No
network, no telemetry found. When its rules conflict with `AGENTS.md`, `AGENTS.md` wins;
the project template says so. Its headline numbers are the project's own.

**Verdict.** Personal: **try** for two weeks in `full`. Enterprise: **review as a plugin**,
pin; `/ponytail-review` alone can be adopted by copying its checklist into a project skill.

---

## Excluded

Listed so nobody re-evaluates them from scratch. They stay in `skills/community.json` under
`excluded` with the reason, and the validator keeps them out of the recommended sets.

| Tool | Reason |
|---|---|
| **oh-my-openagent** (formerly oh-my-opencode) | License SUL-1.0 ("sustainable use"), not OSI-approved: fails gate 1. Also bundles a third-party web-search MCP (Exa) that cannot be routed through the gateway, and replaces the agent set in this repo. The fork `oh-my-opencode-slim` inherits the question; check its LICENSE before considering it. |
| **caveman** | The skill is MIT but the measured benefit is 8.5% of output tokens on real agentic tasks (JetBrains, July 2026) against 1–1.5k input tokens of rules every turn; the proxy component is BSL-1.1. Not dangerous, just not worth it. Write `AGENTS.md` tersely instead. |

---

## Summary

| Tool | Category | License | Tier | Network | Personal | Enterprise |
|---|---|---|---|---|---|---|
| Serena | retrieval | MIT | MCP | none | recommended | recommended, vendored |
| graphify | code graph | Apache-2.0 / MIT | CLI + skill | gateway or Ollama, optional | recommended (pick one graph) | allowed, pinned |
| code-review-graph | code graph | MIT | CLI + MCP | none | recommended (pick one graph) | allowed, pinned |
| claude-context | retrieval (vector) | MIT | MCP + Milvus | local or gateway (embeddings) | optional, very large repos | allowed, local embeddings |
| beads | memory | MIT | CLI | none | recommended for long work | allowed |
| superpowers | methodology | MIT | plugin + skills | telemetry opt-out | recommended | allowed after review, telemetry off |
| spec-kit | methodology (features) | MIT | CLI + commands | none | recommended | recommended, pinned tag |
| compound-engineering | methodology + ledger | MIT | plugin + skills | none | alternative to superpowers | allowed, pinned |
| AI-DLC | methodology (lifecycle) | MIT-0 | runtime + hooks | none | optional | strong candidate, vendored |
| archify | diagrams | MIT | skill + renderer | none | recommended | allowed |
| ponytail | scope restraint | MIT | plugin, always-on | none | try | review as plugin |
| oh-my-openagent | harness | SUL-1.0 | plugin + MCPs | third-party search | excluded | excluded |
| caveman | output brevity | MIT (skill) / BSL-1.1 (proxy) | instructions | none | excluded | excluded |

Add new entries to `skills/community.json` with the same fields; `scripts/validate.sh`
enforces the license allowlist, and the installer reads the catalog.

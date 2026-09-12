# 12 — What else to add: research and prioritised backlog

*Researched: 2026-09-11. Sources: docs.litellm.ai (mcp, mcp_control, auto_routing, release
notes v1.78), code.claude.com/docs (sandboxing, llm-gateway), opencode.ai/docs (github),
developers.openai.com/codex (github-action, noninteractive), github.com READMEs and LICENSE
files of anthropic-experimental/sandbox-runtime, anthropics/claude-agent-sdk-python,
promptfoo/promptfoo, UKGovernmentBEIS/inspect_ai, zilliztech/claude-context,
langfuse/langfuse, blog.google (Gemma 4 MTP drafters), Linux Foundation / AAIF
announcements, Linux kernel `Assisted-by` discussions. Licenses of tools not yet catalogued
are stated from their repositories at research time; the validator re-checks anything that
enters `skills/community.json` or `mcp/catalog.json`.*

## Method

The repo was mapped against the full lifecycle of AI-assisted engineering and each gap was
scored on value, effort and the two hard gates of doc 11 (permissive license, safety).

```
set up → give context → retrieve → generate → verify → review → ship (CI) → operate → govern
```

Covered well today: set up (gateway, clients), give context (`AGENTS.md`, skills), retrieve
(Serena, graphs), generate (agents, aliases), review (reviewer, security auditor), govern
(enterprise profile, license gate). Thin or missing: **verify** (no evals of our own
config), **ship** (no CI wiring), **operate** (no observability, spend or backup
tooling), **isolation** (sandboxing is only mentioned), and **gateway features shipped
after the first pass** (MCP gateway, auto-routing).

Everything below passes the gates unless it sits in the "Excluded" section. Effort:
S = under half a day, M = one to two days, L = more.

## Prioritised backlog

| P | Item | Why | Effort | Profile |
|---|---|---|---|---|
| 0 | License audit script (`scripts/license-audit.{sh,ps1}`) | makes the hard gate checkable on any repo's dependency tree, not just our catalogs | S | both |
| 0 | Sandboxing configured, not just mentioned | Claude Code's built-in sandbox, Anthropic `sandbox-runtime` for OpenCode, Codex sandbox already on | S–M | both |
| 0 | Secret and vulnerability scanning in the project template | gitleaks pre-commit + CI, OSV-Scanner / Trivy | S | both |
| 0 | LiteLLM MCP gateway | one MCP endpoint, per-key/team tool allowlists enforced centrally, credentials server-side | M | enterprise first |
| 0 | CI workflow templates | OpenCode `/review-pr`, Claude Code Action, Codex Action, all through the gateway with a `ci` key | M | both |
| 0 | `Assisted-by:` commit trailer | de-facto attribution standard (Linux kernel); machine-readable disclosure | S | both |
| 1 | promptfoo eval suite for `AGENTS.md`, skills and agents | catches regressions when instructions change; runs in CI | M | both |
| 1 | Auto-routing alias (`auto-coder`) | LiteLLM's complexity router sends simple requests to cheap/local models with zero API calls | S | both, opt-in |
| 1 | Spend, cache-hit and backup scripts | operate the gateway with evidence instead of guesses | S | both |
| 1 | Langfuse overlay (self-hosted, MIT core) | per-session traces, prompt versions; OTel already wired in enterprise | M | both |
| 1 | Devcontainer template | reproducible agent environment with the gateway pre-wired; the office's standard isolation | M | both |
| 1 | claude-context in the catalogs | vector code search for very large repos; done in this pass | S | both |
| 2 | Model bake-off harness (`evals/`) | choose local models per hardware with data; inspect-ai for heavier runs | M | both |
| 2 | Local inference performance guide | Gemma 4 MTP drafters (up to 3× on vLLM), llama.cpp `--draft-model`, quant and VRAM tables | S–M | personal |
| 2 | More first-party skills and agents | dependency-upgrade, migration-playbook, perf-profiling, release-notes, sql-review, api-design-review; `migrator`, `release-manager` agents | S each | both |
| 2 | Claude Agent SDK example for automations | nightly triage, docs sync, through the gateway; SDK is MIT | M | both |
| 2 | `llms.txt` and doc hygiene | agents fetch project docs efficiently | S | both |
| 2 | Session affinity between OpenCode and the gateway | OpenCode ≥ 1.17 sends `X-Session-Id`; LiteLLM can pin a session to a deployment for cache locality across replicas | S | enterprise |
| 2 | Offboarding and key-hygiene script | list, expire, delete unused keys quarterly | S | enterprise |

## Findings by theme

### A. Gateway features shipped since the first pass

**MCP gateway (LiteLLM, open source since v1.78).** The gateway can register MCP servers
centrally (`mcp_servers:` block with `url`/`transport`/`auth_type`, or `command`/`args`
for stdio) and expose one `/mcp` endpoint. Access is controlled per key, team or
organisation; the `x-mcp-servers` header names which servers a client may see, and tools
are filtered accordingly. Credentials for upstream servers stay on the gateway (or are
forwarded per request with `x-mcp-<alias>-<header>`), OAuth flows are handled, and MCP tool
calls are cost-tracked per key. For the enterprise profile this replaces "MCP allowlist by
policy" with "MCP allowlist by configuration": a developer's key simply cannot list a
server it is not entitled to. Audit logging of MCP operations and SSO are tier-dependent;
the allowlisting itself is not.

```yaml
mcp_servers:
  context7:
    url: https://mcp.context7.com/mcp
    transport: http
    description: library docs
  github:
    url: https://api.githubcopilot.com/mcp/
    transport: http
    auth_type: bearer_token
    auth_value: os.environ/GITHUB_MCP_TOKEN
```

Proposal: add the block to `litellm.enterprise.yaml`, point the enterprise OpenCode config
at the gateway's `/mcp` endpoint instead of per-machine server definitions, and extend
`create-key.sh` with an `--mcp` list. Personal profile: optional.

**Auto-routing (beta, open source).** `auto_router/complexity_router` classifies each
request as SIMPLE / MEDIUM / COMPLEX / REASONING with a heuristic scorer (token count,
code presence, reasoning markers; no API call, sub-millisecond) or an LLM classifier, and
maps tiers to models. Session affinity keeps a conversation on one tier.

```yaml
- model_name: auto-coder
  litellm_params:
    model: auto_router/complexity_router
    complexity_router_config:
      tiers:
        SIMPLE: coder-local
        MEDIUM: coder-cheap
        COMPLEX: coder-fast
        REASONING: coder-frontier
      classifier_type: heuristic
      session_affinity: true
    complexity_router_default_model: coder-fast
```

Proposal: ship it as an **opt-in alias**, not the default. Mixed models inside an agent
session weaken prompt caching and consistency (ADR-0002); the router is right for chat-like
and batch traffic, and for a "cheap first" mode you switch to deliberately. Measure with
the spend script before making it a default anywhere.

**Session affinity.** OpenCode 1.17 added an `X-Session-Id` header for sticky proxies.
LiteLLM's session affinity (`router_settings.optional_pre_call_checks: ["session_affinity"]`)
reads `x-litellm-session-id`. Whether LiteLLM honours `X-Session-Id` directly needs a
check on the current version; if not, a one-line header map in the reverse proxy
(enterprise) does it. Value: cache locality when running more than one gateway replica.

### B. Isolation and safety

**Claude Code sandbox (built in).** OS-enforced filesystem and network isolation for every
Bash command and its children (Seatbelt on macOS, bubblewrap on Linux/WSL2). Writes are
confined to the working directory and temp; network goes through a proxy with no
pre-approved domains, asking on first use. Proposal: enable in
`clients/claude-code/settings.json` and require it in the managed enterprise settings.

**Anthropic `sandbox-runtime` (`srt`, Apache-2.0).** The same mechanism as a standalone
tool: wrap any process (OpenCode, an MCP server, a script) with filesystem and network
allowlists from `~/.srt-settings.json`. Community wrappers exist for OpenCode
(`opencode-sandbox` plugin, `opencodebox`, `opencode-bwrap`); their licenses were not
verified in this pass and they are small enough to vendor or reimplement. Proposal:
document `srt` as the way to run OpenCode on Linux/macOS with the network limited to the
gateway and package registries, and add an `srt` config template. Windows: WSL2 only.

**Codex** already has `sandbox_mode = "workspace-write"` with network off in our template.

**Devcontainer.** A `.devcontainer/devcontainer.json` (spec and CLI are MIT) in the project
template with OpenCode, `uv`, Node, the gateway URL and a virtual key injected from the
host, plus an optional network policy. This is the cleanest "danger contained" story for an
office: the agent runs in a container that can reach only the gateway.

**Secret scanning.** `gitleaks` (MIT) as a `pre-commit` (MIT) hook and CI step; `detect-secrets`
(Apache-2.0) as an alternative. Excluded by the gate: trufflehog (AGPL-3.0).

**Vulnerability and SBOM scanning.** `osv-scanner`, `trivy`, `syft` + `grype` (all
Apache-2.0); `pip-audit` (Apache-2.0), `npm audit`, `cargo audit` (MIT/Apache),
`govulncheck` (BSD-3). Excluded: semgrep and opengrep engines (LGPL-2.1), Renovate
(AGPL-3.0; Dependabot is a hosted service and fine).

**License audit script.** The gate needs a tool that checks a *dependency tree*, not only
our catalogs: `pip-licenses` (MIT), `license-checker` (BSD-3) for npm, `cargo-deny`
(MIT/Apache-2.0), `go-licenses` (Apache-2.0), `scancode-toolkit` (Apache-2.0) for whole
trees. Proposal: `scripts/license-audit.sh` runs whichever apply and fails on anything
outside the allowlist in `skills/community.json`.

**Guardrails beyond PII.** `llm-guard` (MIT) and NeMo Guardrails (Apache-2.0) can run as
LiteLLM custom guardrails for prompt-injection and secret-leak checks on requests. For
coding agents the permission system remains the primary control; these add a second layer
on the gateway for the enterprise profile at the cost of latency. P2.

### C. Verification and evaluation

**promptfoo (MIT; acquired by OpenAI in March 2026, stays open source).** Declarative
evals with assertions and model grading, a documented "evaluate coding agents" guide, CI
integration that fails a pipeline on regression, and a provider for any OpenAI-compatible
endpoint, so it runs through the gateway on a `ci` key. Proposal: an `evals/promptfoo/`
suite with ten golden prompts per skill and agent (does `/review` find the planted bug,
does the compliance gate refuse the planted secret, does `local-scout` return the required
shape) that runs on every change to `AGENTS.md`, `skills/` or `clients/opencode/`. This
is the missing "verify" step for our own configuration.

**inspect-ai (MIT, UK AI Security Institute).** Heavier framework with sandboxed agent
tasks, log viewer and a large evals library; the frontier labs' standard. Right for a
serious model bake-off (which local model on this GPU, which alias for this task family),
not for day-to-day config tests. P2, behind a simple `evals/bakeoff/` runner that calls the
gateway with a `tasks.yaml` and reports pass rate, tokens and latency per alias.

### D. Shipping: CI integration through the gateway

All three vendor actions accept a base URL and key, so CI uses a `ci` virtual key with a
small monthly budget and the `ci` tag; secrets never appear in workflow files, and fork PRs
run without secrets (read-only review only).

- **OpenCode**: `opencode github install` sets up the GitHub App, secrets and workflow;
  `/oc` or `/opencode` in comments triggers it; `prompt: /review-pr` runs a bundled
  read-only review agent that posts inline findings anchored to changed lines. MIT.
- **Claude Code**: `anthropics/claude-code-action` (MIT) with `ANTHROPIC_BASE_URL` and the
  key as `anthropic_api_key` (or `ANTHROPIC_AUTH_TOKEN` for bearer gateways; doc 04).
- **Codex**: `openai/codex-action` (Apache-2.0) wraps `codex exec`, the non-interactive
  mode that streams progress to stderr and the final message to stdout; the action can
  apply patches or post reviews under a chosen sandbox.

Proposal: `templates/project/.github/workflows/ai-review.yml` (OpenCode `/review-pr` on
PRs, read-only) and `ai-triage.yml` (labels new issues), both with budgets, both disabled
on forks; enterprise variant requires a human approval label before the agent may push.

**Claude Agent SDK (MIT, verified from its LICENSE file).** For automations that are more
than a prompt (nightly dependency triage, docs drift detection, changelog assembly). It
honours `ANTHROPIC_BASE_URL` and `ANTHROPIC_AUTH_TOKEN`, so it runs through the gateway
with its own key. P2: `clients/agent-sdk/` example.

### E. Retrieval: a third option for very large repos

**claude-context (MIT, Zilliz).** MCP server doing hybrid BM25 + dense-vector search over
AST-chunked code with Merkle-tree incremental sync, backed by Milvus (Apache-2.0, can run
locally) and embeddings from Ollama or any OpenAI-compatible endpoint (the gateway). Where
Serena is precise navigation and a graph is structure, this is "search by meaning" across
millions of lines. Added to `skills/community.json` and `mcp/catalog.json` in this pass;
embedding traffic stays local with Ollama (`nomic-embed-code`, Qwen3-Embedding; both
Apache-2.0) or goes through the gateway. Excluded alternative: Jina code embeddings
(CC-BY-NC).

### F. Observability

**Langfuse (MIT core).** Self-hostable traces, sessions, prompt versions and cost views;
enterprise modules live in `/ee` directories, ship in the image, and stay inert without a
license key. LiteLLM sends traces with `success_callback: ["langfuse"]`. Proposal: a
`docker-compose.observability.yml` overlay (Langfuse + its Postgres/ClickHouse) for the
personal profile and a pointer to the org's Langfuse in enterprise. Alternative: Helicone
(Apache-2.0). Already wired: OpenTelemetry collector (Apache-2.0) in enterprise, which can
feed any backend. Excluded by the gate: Arize Phoenix (Elastic-2.0), Grafana (AGPL-3.0);
Prometheus itself is Apache-2.0 but LiteLLM's Prometheus exporter is a paid feature.

**Scripts (S each).** `spend-report.sh` (per key/team/model for the last N days from the
gateway's spend endpoints), `cache-check.sh` (cache-read tokens as a share of input tokens
per model; a low number means a silent cache invalidator), `backup-db.sh` (pg_dump with
rotation; keys and spend live there).

### G. Local inference performance

**Gemma 4 MTP drafters.** Google released multi-token-prediction drafter models for
Gemma 4 (April 2026) for speculative decoding, reporting up to 3× faster generation with
identical outputs. Status at research time: native in vLLM (with a pending small config
fix on some versions), llama.cpp via `--draft-model` pending a converter patch, Ollama not
yet. Value is conditional: large gains on long, predictable outputs (code), none or
negative on short chatty turns. Proposal: a section in doc 01 or a new `docs/local-inference.md`
with a vLLM launch line for `gemma-4-26b-a4b` + drafter, `llama.cpp` server (MIT) as the
alternative to Ollama when you need `--draft-model`, SGLang (Apache-2.0) for multi-user
throughput, and a VRAM/quantization table per model.

### H. Standards and attribution

**`Assisted-by:` trailer.** The Linux kernel's policy requires an `Assisted-by:` tag
naming the model and agent on AI-assisted patches; usage went from 31 commits in 7.0 to
over 1,200 by 7.2-rc4, and `checkpatch` validates it. A July 2026 thread debates narrowing
it, so the *policy* may change; the *format* is the de-facto standard. Proposal: adopt
`Assisted-by: <tool> (<model alias>)` as the commit trailer in the `conventional-commits`
skill and the PR templates, alongside the existing `Co-Authored-By` some tools add. It is
machine-readable, which the enterprise disclosure requirement wants.

**Agentic AI Foundation.** Since December 2025 `AGENTS.md`, MCP and goose are governed
under the Linux Foundation's AAIF with OpenAI, Anthropic and Block as founders. ADR-0003
and ADR-0004 can cite this: the two formats this repo builds on are foundation-stewarded,
not one vendor's convention.

**`llms.txt`.** A root `llms.txt` pointing agents at the right docs in the right order is
cheap and now widely honoured by fetch tools; add to the project template.

### I. More first-party content (MIT, zero external risk)

Skills: `dependency-upgrade` (audit → changelog read → staged bumps → tests),
`migration-playbook` (data and API migrations with rollback), `perf-profiling`
(measure → hypothesis → change → re-measure), `release-notes`, `sql-review`,
`api-design-review`, `incident-postmortem`. Agents: `migrator` (edits under a plan with
checkpoints), `release-manager` (changelog, version bump, tag; asks before push). Each is
an afternoon and follows the existing patterns.

## Excluded in this research (fail a gate)

| Tool | Reason |
|---|---|
| trufflehog | AGPL-3.0 → use gitleaks (MIT) or detect-secrets (Apache-2.0) |
| semgrep / opengrep engines | LGPL-2.1 → use ecosystem linters (bandit, gosec, eslint-plugin-security), CodeQL as a hosted service where licensed |
| Renovate | AGPL-3.0 → Dependabot (service) or manual with the `dependency-upgrade` skill |
| Grafana | AGPL-3.0 → Langfuse (MIT) / Helicone (Apache-2.0) for LLM views; OTel to whatever the org runs |
| Arize Phoenix | Elastic-2.0 |
| Daytona sandboxes | AGPL-3.0 → `sandbox-runtime` (Apache-2.0), devcontainers (MIT), Firecracker/microsandbox (Apache-2.0) |
| PR-Agent / Qodo | AGPL-3.0 → the vendor actions above with our reviewer agent |
| Jina code embeddings | CC-BY-NC → nomic-embed-code, Qwen3-Embedding (Apache-2.0) |
| LiteLLM Prometheus exporter, SSO | paid tier → OTel + Langfuse, reverse-proxy OIDC |

## Status

Priority 0 landed on 2026-09-12:

| Item | Where |
|---|---|
| License audit | `scripts/license_audit.py` (+ `.sh`/`.ps1`), lists in `skills/community.json`; used by the template's `security-scan.yml` |
| Sandboxing configured | `clients/claude-code/settings.json` and `managed-settings.enterprise.json` (`sandbox` block); `clients/opencode/srt-settings{,.enterprise}.json` installed to `~/.srt-settings.json`; doc 07 section |
| Secret and vulnerability scanning | `templates/project/.pre-commit-config.yaml`, `templates/project/.github/workflows/security-scan.yml` |
| MCP gateway | `mcp_servers` block in `litellm.enterprise.yaml` (optional in personal), `create-key.sh` 7th argument, enterprise OpenCode configs point at `<gateway>/mcp` |
| CI workflow templates | `templates/project/.github/workflows/ai-review.yml`, `ai-assist.yml`, `ai-review-claude.yml.example`; `templates/enterprise/workflows/ai-review.yml` |
| `Assisted-by:` trailer | `conventional-commits` skill, `/commit` command, both PR templates, enterprise `AGENTS.md` and policy |

Note on the trailer: the kernel's documented format is now `Assisted-by: LLM [tools…]`
without model names (the July 2026 simplification); the model and client go in the
separate `AI-Tool:` trailer where a policy needs them.

Priority 1 landed on 2026-09-12:

| Item | Where |
|---|---|
| promptfoo eval suite | `evals/promptfoo/` (skills suite through the gateway, agents suite via `opencode run`, fixtures with planted defects), `scripts/evals.{sh,ps1}` |
| Auto-routing alias | `auto-coder` in `litellm.personal.yaml` and `clients/opencode/opencode.json`; doc 01 ladder, doc 02 |
| Spend, cache-hit, backup scripts | `gateway/scripts/spend-report.{sh,ps1}`, `cache-check.sh`, `backup-db.{sh,ps1}` |
| Observability overlay | `gateway/docker-compose.observability.yml` (Jaeger, Apache-2.0, fed by the `otel` callback). Langfuse documented, not bundled: its reference stack includes MinIO (AGPL-3.0) |
| Devcontainer template | `templates/project/.devcontainer/` |
| claude-context in the catalogs | done in the research pass |

Deferred from P1: the daily-activity cache fields used by `cache-check.sh` are reported as
unavailable if the running version does not expose them.

Priority 2 landed on 2026-09-12:

| Item | Where |
|---|---|
| Model bake-off harness | `evals/bakeoff/` (`bakeoff.py`, `tasks.json`, standard library only); inspect-ai noted for heavier runs |
| Local inference guide | `docs/13-local-inference.md` (sizing table, context window, Gemma 4 MTP drafters and engine support, engine choice) |
| First-party skills and agents | skills `dependency-upgrade`, `migration-playbook`, `perf-profiling`, `release-notes`, `sql-review`, `api-design-review`, `incident-postmortem`; agents `migrator`, `release-manager`; commands `/release`, `/upgrade` |
| Claude Agent SDK example | `clients/agent-sdk/nightly_triage.py` (read-only, bounded, through the gateway) |
| `llms.txt` | repo root and `templates/project/llms.txt` |
| Session affinity | `optional_pre_call_checks: ["session_affinity"]` in the enterprise config; Caddy maps `X-Session-Id` → `x-litellm-session-id` |
| Key hygiene | `gateway/scripts/key-hygiene.sh` (expired and idle keys, `--delete` with confirmation) |

Still open: verifying on a live LiteLLM that `x-litellm-session-id` is the affinity header
for your version, the exact Hugging Face ids and vLLM flags for the Gemma 4 drafters, and
the `/key/list` response shape (the hygiene script prints raw JSON if it differs).

## Suggested order of work

1. **Gate tooling and isolation** (P0, about two days): license-audit script, gitleaks +
   OSV in the template, sandbox settings for Claude Code and an `srt` template for
   OpenCode, `Assisted-by` trailer in the skill and PR templates.
2. **Ship and govern** (P0/P1, about three days): CI workflow templates, MCP gateway block
   in the enterprise config, spend/cache/backup scripts, key-hygiene script.
3. **Verify** (P1, about two days): promptfoo suite over our skills and agents, wired into
   `scripts/validate.sh` as an optional step.
4. **Operate and tune** (P1/P2, as needed): Langfuse overlay, auto-router alias, devcontainer,
   local-inference guide, bake-off harness, new skills and agents.

Each item lands as its own commit with the docs updated in the same change, and anything
that enters the catalogs goes through `scripts/validate.sh`.

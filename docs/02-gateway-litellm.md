# 02 — The gateway: LiteLLM

*Verified: 2026-09-11 against docs.litellm.ai (proxy/configs, routing, virtual_keys,
guardrails, anthropic_unified, tutorials/opencode_integration).*

## Why a gateway, why LiteLLM

A gateway is the one place where *many clients × many vendors* can be handled once.
LiteLLM was chosen because it:

- speaks **three wire formats on one port**: OpenAI Chat Completions (`/v1/chat/completions`),
  OpenAI Responses (`/v1/responses`) and Anthropic Messages (`/v1/messages`). OpenCode and
  Cursor use the first, Codex the second, Claude Code the third. One deployment serves all.
- has a **router** with load balancing, retries, cooldowns, fallbacks and context-window
  fallbacks;
- issues **virtual keys** with per-key model allowlists, budgets, rate limits and tags, backed
  by Postgres, with teams and spend reports;
- supports **guardrails** (PII masking with Presidio, content filters, custom hooks);
- is open source (MIT) and runs as a single container. Some features (Prometheus metrics,
  SSO, some enterprise guardrails) live in its `enterprise/` directory under a separate
  commercial license; neither profile here uses them, so the whole stack stays under the
  permissive-license gate of doc 11 (Valkey replaces Redis for the same reason).

If you replace it later, the client side changes only its base URL: everything here uses
standard wire formats.

## Topology

**Personal**: `docker compose` on the machine you work from, or a small always-on box
(home server, mini PC). Port 4000 on localhost or the LAN. Postgres in the same compose for
keys and spend. Ollama runs natively on the host (GPU access is simpler) and the gateway
reaches it via `host.docker.internal:11434`.

**Enterprise**: same container behind TLS on an internal hostname, managed Postgres, Redis
when running more than one replica (shared rate-limit and cooldown state), config file
mounted from a reviewed git repo, secrets from the org's vault. See 08.

## Endpoints you will use

| Endpoint | Who calls it |
|---|---|
| `POST /v1/chat/completions` | OpenCode, Cursor, Continue, most SDK code |
| `POST /v1/responses` | Codex CLI, OpenAI SDK users on Responses |
| `POST /v1/messages` | Claude Code, Anthropic SDK users (`ANTHROPIC_BASE_URL` = gateway root, no `/v1`) |
| `GET /v1/models` | model discovery; returns only what the key may use |
| `POST /v1/embeddings` | embeddings if you add an embedding deployment |
| `GET /health/liveliness`, `/health/readiness` | probes |
| `POST /key/generate`, `/key/delete`, `/key/info` | key management with the master key |
| `POST /team/new`, `/team/update` | teams (enterprise) |
| `GET /ui` | admin UI (uses `UI_USERNAME`/`UI_PASSWORD`) |

## Config anatomy

`gateway/config/litellm.personal.yaml` is the personal profile, `litellm.enterprise.yaml`
the hardened one. Both have the same four sections.

### `model_list` — deployments

Each entry maps a **public name** (`model_name`) to a **deployment** (`litellm_params.model`
plus credentials). Two kinds of public names coexist:

```yaml
model_list:
  # vendor-native name: for tools that must see the real ID (Claude Code)
  - model_name: claude-sonnet-5
    litellm_params:
      model: anthropic/claude-sonnet-5
      api_key: os.environ/ANTHROPIC_API_KEY

  # role alias: what agents and docs reference
  - model_name: coder-fast
    litellm_params:
      model: anthropic/claude-sonnet-5
      api_key: os.environ/ANTHROPIC_API_KEY
    model_info:
      role: coder-fast          # free-form metadata, shows in /model/info
```

Provider prefixes used in this repo:

| Prefix | Backend |
|---|---|
| `anthropic/` | Anthropic API |
| `openai/` | OpenAI API |
| `ollama_chat/` | Ollama (`/api/chat`, tool calling supported) — set `api_base` |
| `hosted_vllm/` | any vLLM server (OpenAI-compatible) — set `api_base` |
| `openrouter/` | OpenRouter hosted open models |
| `openai/` + `api_base` | any other OpenAI-compatible server (LM Studio, llama.cpp server, TGI) |

Two deployments with the **same `model_name`** are load-balanced. This repo does not use that
for aliases (an alias is one primary deployment + explicit fallbacks) because agents behave
more predictably when the same model answers a whole session.

`os.environ/NAME` reads an environment variable at load time. Never write a key literal.

### `router_settings` — routing, retries, fallbacks

```yaml
router_settings:
  routing_strategy: simple-shuffle   # only matters with duplicate model_names
  num_retries: 2
  timeout: 600                       # seconds; frontier models can take minutes
  allowed_fails: 3                   # failures/minute before a deployment cools down
  cooldown_time: 30
  enable_pre_call_checks: true       # skip deployments whose context window is too small
  fallbacks:
    - coder-fast: ["gpt-5.6-terra", "claude-haiku-4-5"]
  context_window_fallbacks:
    - coder-cheap: ["coder-fast"]
  model_group_alias:
    gpt-4o: coder-fast               # legacy name some tools hardcode
```

Strategies: `simple-shuffle` (default; weighted random, lowest overhead), `least-busy`,
`latency-based-routing`, `usage-based-routing-v2` (needs Redis), `cost-based-routing`.
For a single-user gateway the strategy is irrelevant; fallbacks are what matter.

Fallback semantics: on a retriable error (429, 5xx, timeout) the router retries the same
deployment `num_retries` times with backoff, then walks the fallback list left to right.
`context_window_fallbacks` fires only on context-length errors. `content_policy_fallbacks`
exists for provider refusals.

### `litellm_settings` — library behaviour

```yaml
litellm_settings:
  drop_params: true          # silently drop params a provider does not support
  request_timeout: 600
  num_retries: 2
  json_logs: true
  success_callback: []       # e.g. ["langfuse"], ["otel"]
  failure_callback: []
```

OpenCode sends a `reasoningSummary` parameter that some providers reject; per-model
`additional_drop_params: ["reasoningSummary"]` handles it (already in both configs).

### `general_settings` — the server

```yaml
general_settings:
  master_key: os.environ/LITELLM_MASTER_KEY
  database_url: os.environ/DATABASE_URL
  store_model_in_db: false   # config-as-code: the YAML is the truth, not the UI
```

### `guardrails` — enterprise only

See 08 and `litellm.enterprise.yaml`: Presidio PII masking `pre_call`, on by default.

## Naming policy

- **Aliases** (`coder-*`, `reasoning-max`, `local-small`) are the public API of the gateway.
  Agent files and docs use them. Renaming an alias is a breaking change; re-pointing it is not.
- **Vendor names** are exposed unchanged so tools that pin (Claude Code's
  `ANTHROPIC_DEFAULT_*_MODEL`, Codex's `model`) work.
- **Local models** get short stable names (`qwen3-coder-30b`, `gemma4-26b`) rather than raw
  Ollama tags, so a quantization change is invisible to clients.
- `model_group_alias` absorbs legacy hardcoded names (`gpt-4o`, `claude-3-5-sonnet-latest`).

## Keys and budgets

The **master key** starts the server and creates other keys. It is never configured in a
client. Each client gets a **virtual key** with an alias, an allowlist and a budget:

```bash
gateway/scripts/create-key.sh opencode-laptop 50 30d "coder-*,local-*,claude-*,gpt-*"
```

Personal: one key per tool (`opencode`, `claude-code`, `codex`, `cursor`, `ci`) so `/ui`
shows where money goes. Enterprise: one key per developer per tool, under a team with a
team budget; see 08.

Keys carry `tags` and `metadata`. Tags feed **tag-based routing** (`enable_tag_filtering`),
which the enterprise profile uses to force `restricted` keys onto local deployments.

## Local models

Ollama is the simplest host. Pull once, the gateway does the rest:

```bash
ollama pull qwen3-coder:30b
ollama pull gemma4:26b
ollama pull gemma4:12b
```

Set `OLLAMA_API_BASE` in `gateway/.env` (`http://host.docker.internal:11434` when the gateway
runs in Docker on the same machine; the LAN address of your GPU box otherwise). Raise
Ollama's context: `OLLAMA_CONTEXT_LENGTH=65536` (or per model with a Modelfile) — the default
4K/8K window is far too small for agents. `num_ctx` can also be passed per deployment in
`litellm_params`.

vLLM for a shared GPU server: `hosted_vllm/Qwen/Qwen3-Coder-30B-A3B-Instruct` with
`api_base: http://gpu-box:8000/v1`. vLLM gives better throughput for multiple developers;
Ollama is better for one person.

## Observability

- **Spend logs** in Postgres; `/ui` shows per-key/team/model spend and request logs.
- **Callbacks**: `langfuse` (self-hostable, traces + prompts) or `otel` (OpenTelemetry to any
  collector) are the open options. `prometheus` requires a LiteLLM enterprise license.
- **Alerting**: `general_settings.alerting: ["slack"]` with `SLACK_WEBHOOK_URL` for budget
  and outage alerts.
- For coding agents, disable response caching (`cache: false`); identical prompts are rare and
  a cached answer to "run the tests" is wrong by definition. Prompt caching (Anthropic
  `cache_control`, OpenAI automatic) still works because it is a provider feature, not a
  gateway one.

## Operations

- Pin the image tag (`ghcr.io/berriai/litellm:main-stable` floats; for reproducibility pin
  `main-v1.x.y` after testing).
- Back up Postgres; it holds keys and spend. Losing it means re-issuing keys.
- Rotate the master key by setting a new `LITELLM_MASTER_KEY` and restarting; virtual keys
  are unaffected. `LITELLM_SALT_KEY` encrypts stored credentials — never change it after
  first start.
- `docker compose logs -f litellm` and `--detailed_debug` when something is off.
- `scripts/smoke-test.sh` exercises all three wire formats; run it after every config change.

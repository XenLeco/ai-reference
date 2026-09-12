# 10 — Troubleshooting

*Verified: 2026-09-11.*

| Symptom | Likely cause | Fix |
|---|---|---|
| OpenCode `/models` shows no gateway models | `LITELLM_API_KEY` unset, or model keys in `opencode.json` do not match gateway `model_name`s | `echo $LITELLM_API_KEY`; compare with `curl $BASE/v1/models` |
| `401` from the gateway | wrong key, or key sent in the wrong header | OpenAI-format clients: `Authorization: Bearer`; Claude Code: use `ANTHROPIC_AUTH_TOKEN` (Bearer) not `ANTHROPIC_API_KEY` unless the gateway expects `x-api-key` |
| `model not found` for a valid alias | key's `models` allowlist excludes it | `curl $BASE/key/info` with the key; re-create with the right list or access group |
| Requests fail with an unknown-parameter error (`reasoningSummary`) | OpenCode sends reasoning options the provider rejects | ensure `additional_drop_params: ["reasoningSummary"]` on the deployment and `drop_params: true` globally |
| Ollama models time out or return garbage after a few turns | Ollama context window too small (default 4K–8K) | `OLLAMA_CONTEXT_LENGTH=65536` in Ollama's environment, or `num_ctx` in `litellm_params`; restart Ollama |
| Gateway in Docker cannot reach Ollama | `localhost` inside the container is the container | `OLLAMA_API_BASE=http://host.docker.internal:11434` (Linux: add `extra_hosts: host.docker.internal:host-gateway`, already in compose) |
| Fallback never triggers | error is not retriable (400), or fallback list references a name not in `model_list` | check gateway logs; every fallback target must be a `model_name` |
| Claude Code ignores the gateway | settings file precedence; env var in the wrong scope | `claude` → Status tab shows the base URL and auth token source; managed settings override user settings |
| Claude Code says a model is unsupported / features disabled | pinned model unknown to that Claude Code version | `ANTHROPIC_DEFAULT_*_MODEL_SUPPORTED_CAPABILITIES` env vars, or upgrade Claude Code |
| Codex `unsupported wire_api` | provider block uses `"chat"` | only `"responses"` is supported; the gateway serves `/v1/responses` |
| Vision inputs rejected in OpenCode | provider models default to text-only | add `"modalities": {"input": ["text","image"], "output": ["text"]}` to the model |
| Costs higher than expected | subagents on frontier models; MCP tool descriptions inflating every request; no prompt caching | check `/ui` per key/model; move subagents to `coder-cheap`/`coder-local`; disable unused MCP servers; keep system prompt stable |
| Presidio guardrail masks code identifiers (enterprise) | entity thresholds too low | raise `presidio_score_thresholds`, restrict `pii_entities_config` to the entities that matter |
| Restricted key gets `no deployments available` (enterprise) | no local deployment carries the `restricted` tag, or Ollama is down | check tags in `litellm.enterprise.yaml`; `curl $OLLAMA_API_BASE/api/tags` |
| `LITELLM_SALT_KEY` changed → stored credentials unreadable | salt rotated after first start | restore the original salt; salt is permanent per database |
| Skill never triggers | description too generic; skill folder name ≠ `name`; wrong directory | rewrite description with trigger words; `scripts/validate.sh`; confirm `~/.agents/skills/<name>/SKILL.md` |
| Two sessions clobber each other's files | same working tree | `git worktree add`; one session per worktree |
| Agent keeps "fixing" CI config instead of code | `AGENTS.md` and CI disagree on commands | make them identical; put the exact command in `AGENTS.md` |

Diagnostics: `docker compose logs -f litellm`, `litellm --config … --detailed_debug`,
`gateway/scripts/smoke-test.sh`, OpenCode session logs under `~/.local/share/opencode/`.

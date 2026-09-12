# clients/codex/ — Codex CLI through the gateway

Codex speaks the OpenAI Responses API only (`wire_api = "responses"`). LiteLLM serves it on
`/v1/responses` and bridges to Chat Completions for backends that lack it, so Claude and local
models work as well as GPT. Details: [docs/04-other-clients.md](../../docs/04-other-clients.md).

| File | Installed as |
|---|---|
| `config.toml` | `~/.codex/config.toml` (personal) |
| `../../templates/enterprise/codex-config.toml` | `~/.codex/config.toml` (enterprise; distributed) |

Setup:

```bash
gateway/scripts/create-key.sh codex 50 30d
export LITELLM_API_KEY=sk-...        # the provider's env_key
cp clients/codex/config.toml ~/.codex/config.toml
codex
```

Codex reads `AGENTS.md` natively and skills from `.agents/skills/`. Change `model` to any
gateway name; `model_reasoning_effort` applies to models that support it (`minimal` to `xhigh`).

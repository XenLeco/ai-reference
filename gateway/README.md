# gateway/ — LiteLLM

The single entry point for every client. See [docs/02-gateway-litellm.md](../docs/02-gateway-litellm.md)
for the design and [docs/08-enterprise-profile.md](../docs/08-enterprise-profile.md) for the hardened profile.

## Files

| File | Purpose |
|---|---|
| `docker-compose.yml` | personal profile: LiteLLM + Postgres; optional `cache` (Redis) and `local` (Ollama) profiles |
| `docker-compose.enterprise.yml` | overlay: enterprise config, Presidio PII services, localhost-only bind, OTel env |
| `.env.example` | every variable the configs read; copy to `.env` |
| `config/litellm.personal.yaml` | aliases, vendor models, local models, fallbacks |
| `config/litellm.enterprise.yaml` | allowlist, access groups, tag routing, guardrails, logging off |
| `scripts/smoke-test.{sh,ps1}` | exercises `/health`, `/v1/models`, chat, responses, messages |
| `scripts/create-key.{sh,ps1}` | issues a virtual key with alias, budget, duration, models/tags |

## Run (personal)

```bash
cp .env.example .env            # fill ANTHROPIC_API_KEY, OPENAI_API_KEY, LITELLM_MASTER_KEY, LITELLM_SALT_KEY
docker compose up -d
docker compose logs -f litellm  # wait for "Uvicorn running"
LITELLM_MASTER_KEY=... ./scripts/create-key.sh opencode 50 30d
LITELLM_API_KEY=<the key> ./scripts/smoke-test.sh
```

Local models: run Ollama natively on the host (best GPU support) and leave
`OLLAMA_API_BASE=http://host.docker.internal:11434`, or start the bundled one with
`docker compose --profile local up -d` and set `OLLAMA_API_BASE=http://ollama:11434`.

```bash
ollama pull qwen3-coder:30b && ollama pull gemma4:12b && ollama pull gemma4:26b
```

Raise Ollama's context window or agents will fail after a few turns:
`OLLAMA_CONTEXT_LENGTH=65536` in Ollama's environment (the bundled service sets it).

## Run (enterprise)

```bash
docker compose -f docker-compose.yml -f docker-compose.enterprise.yml up -d
```

Port 4000 binds to localhost only; put a TLS reverse proxy (Caddy, nginx, the org ingress)
in front, with SSO on `/ui`. Provide `PRESIDIO_*`, `OTEL_*`, `SLACK_WEBHOOK_URL` and the
database URL from the org vault instead of `.env`.

## Admin UI

`http://localhost:4000/ui` with `UI_USERNAME` / `UI_PASSWORD`. Use it to read spend and
logs, not to add models: `store_model_in_db` is `false`, the YAML is the source of truth.

## Licenses

Everything in this directory is permissively licensed and usable at work: LiteLLM MIT
(its `enterprise/` directory is under a separate commercial license and neither profile
uses those features), Postgres (PostgreSQL License), Valkey BSD-3 (used instead of Redis,
whose 7.4+ releases are RSALv2/SSPL and 8.x AGPL), Presidio MIT, Caddy Apache-2.0, Ollama
MIT, vLLM Apache-2.0. Gemma 4 and Qwen3-Coder weights are Apache-2.0 at verification
(2026-09-11); re-check when new versions land. The hard gate is in docs/11.

## Upgrading

Pin the image tag once the setup is stable (`main-v1.x.y`), read the LiteLLM changelog,
bump via a commit, run the smoke test.

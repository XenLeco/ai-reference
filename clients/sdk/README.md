# clients/sdk/ — scripts, services and CI through the gateway

Anything that can set a base URL can use the gateway. Two examples:

| File | Format | Model |
|---|---|---|
| `python_openai_and_anthropic.py` | OpenAI SDK on `/v1` and Anthropic SDK on the root | `coder-fast` / `claude-opus-5` |
| `typescript_openai.ts` | OpenAI SDK, streaming | `coder-fast` |

Conventions:

- Each service or pipeline gets its own virtual key (`create-key.sh <service> <budget> 30d`).
- CI gets a key with a small budget and the `ci` tag; store it as a CI secret.
- Send `x-litellm-tags` when you want spend broken down further (`repo=foo,job=review`).
- Do not add retries in the client for 429/5xx; the gateway already retries and falls back.
  Client retries multiply load.
- Use streaming for anything that may produce long output; frontier models can take minutes.

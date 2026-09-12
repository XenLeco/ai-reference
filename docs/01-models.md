# 01 — Model catalog and selection

*Verified: 2026-09-11 against Anthropic model docs, developers.openai.com/api/docs/models,
ai.google.dev (Gemma 4 model card), github.com/QwenLM/Qwen3-Coder, ollama.com library pages.
Prices are list prices per 1M tokens in USD and change; treat them as order-of-magnitude.*

## The ladder

Think of models as rungs on a ladder. Start low, climb only when the task demands it.

| Rung | Alias (gateway) | Default resolution | Fallback | Use for |
|---|---|---|---|---|
| 0 | `local-small` | Gemma 4 12B (Ollama) | Gemma 4 E4B | commit messages, titles, summaries, quick rewrites, anything with private data |
| 1 | `coder-local` | Qwen3-Coder 30B-A3B (Ollama) | Gemma 4 26B-A4B | exploration, boilerplate, tests, offline work, restricted data |
| 2 | `coder-cheap` | Claude Haiku 4.5 | GPT-5.6 Luna | subagents, bulk edits, explain-this-file, high-volume steps |
| 3 | `coder-fast` | Claude Sonnet 5 | GPT-5.6 Terra → Haiku 4.5 | **daily driver**: features, fixes, refactors, reviews |
| 4 | `coder-frontier` | Claude Opus 5 | GPT-6 Astra → Sonnet 5 | hard multi-file changes, migrations, debugging that resisted rung 3 |
| 5 | `reasoning-max` | Claude Fable 5.1 | GPT-6 Astra → Opus 5 | architecture, gnarly concurrency/perf bugs, long autonomous runs |

The aliases are defined in `gateway/config/litellm.*.yaml`. Clients and agent definitions use
the alias; only the gateway knows the vendor. Vendor-native names are also exposed for tools
that require them.

## Anthropic

| Model ID | Context / max out | Input / output $ per 1M | Notes |
|---|---|---|---|
| `claude-fable-5-1` | 1M / 128K | 10.00 / 50.00 | Most capable widely available model. Thinking is always on; control depth with `output_config.effort` (`low`…`max`). No forced `tool_choice`. **Requires 30-day data retention** — not available to zero-data-retention orgs unless Anthropic authorizes it (matters for the enterprise profile). |
| `claude-opus-5` | 1M / 128K | 5.00 / 25.00 | Adaptive thinking on by default. Best price/capability for hard coding work. Fast mode available at premium price. |
| `claude-sonnet-5` | 1M / 128K | 2.00 / 10.00 | Daily driver. Adaptive thinking; effort `low`…`max`. |
| `claude-haiku-4-5` | 200K / 64K | 1.00 / 5.00 | Cheap and quick; still uses `budget_tokens`-style thinking, no `effort`. |

Older still-served IDs (`claude-opus-4-8`, `claude-opus-4-7`, `claude-sonnet-4-6`) are useful
as fallbacks when a new model misbehaves; they are listed but not aliased.

Effort mapping through the gateway: send OpenAI-style `reasoning_effort` (`low|medium|high`)
and LiteLLM translates it for Anthropic; for `xhigh`/`max` set the Anthropic parameter
directly in the gateway's per-model `litellm_params` (see 02).

## OpenAI

| Model ID | Context / max out | Input / output $ per 1M | Notes |
|---|---|---|---|
| `gpt-6-astra` | 1.05M / 128K | 10.00 / 50.00 | Flagship for reasoning and agentic coding. |
| `gpt-5.6-sol` | 1.05M / 128K | see pricing page | "Complex professional work" tier of the 5.6 family (GA 2026-07-09). |
| `gpt-5.6-terra` | 1.05M / 128K | see pricing page | Balanced; the natural fallback for `coder-fast`. |
| `gpt-5.6-luna` | 1.05M / 128K | see pricing page | Cost-optimised; fallback for `coder-cheap`. |
| `gpt-5.5` / `gpt-5.5-pro` | 1.05M / 128K | 5.00 / 30.00 · 30.00 / 180.00 | Previous generation, still served. |
| `gpt-5.4` (+ `-mini`, `-nano`) | 1.05M / 128K | 2.50 / 15.00 | Previous generation. |

OpenAI's newest models are Responses-API first. LiteLLM exposes both `/v1/responses` and
`/v1/chat/completions` for every model, so clients can use whichever they speak.
Reasoning depth: `reasoning_effort` (`minimal|low|medium|high|xhigh`).

## Google Gemma 4 (open weights, Apache-2.0 since 2026-04-02)

| Variant | Params | Context | Modalities | Ollama tag | Runs comfortably on |
|---|---|---|---|---|---|
| E2B | ~2B effective | 128K | text, image, audio | `gemma4:e2b` | phones, 8 GB laptops |
| E4B | ~4B effective | 128K | text, image, audio | `gemma4:e4b` | 8–16 GB laptops (Ollama default `gemma4:latest`) |
| 12B | 12B dense | 256K | text, image, audio | `gemma4:12b` | 16 GB RAM or 12 GB VRAM (q4) |
| 26B A4B | 26B MoE, 4B active | 256K | text, image | `gemma4:26b` | 24 GB RAM/VRAM; fast because only 4B active |
| 31B | 31B dense | 256K | text, image | `gemma4:31b` | 24 GB VRAM (q4) or 32+ GB unified memory |

QAT (quantization-aware) builds exist for every size and are the right default for local use.
Gemma 4 is strong at general reasoning, multilingual work and multimodal input; for pure code
generation Qwen3-Coder at the same memory budget is usually better, which is why `coder-local`
defaults to Qwen and `local-small` to Gemma.

## Qwen3-Coder (open weights, Apache-2.0)

| Variant | Params | Context | Ollama tag | Notes |
|---|---|---|---|---|
| Qwen3-Coder-30B-A3B-Instruct | 30B MoE, 3B active | 256K native | `qwen3-coder:30b` (default `qwen3-coder:latest`, ~19 GB q4) | Best local coding model per GB; agentic tool use works well. |
| Qwen3-Coder-480B-A35B-Instruct | 480B MoE, 35B active | 256K native, 1M with extrapolation | `qwen3-coder:480b` (~290 GB q4) | Server class. Use hosted (OpenRouter, vendor APIs) unless you own the hardware. |
| Qwen3-Coder-Next | 80B-A3B base, hybrid attention | 256K | not on Ollama at verification time; vLLM or hosted | Newest line; verify availability before aliasing. |

## Selecting a model: the questions

1. **Is the data allowed to leave the machine?** No → `coder-local` / `local-small` only
   (enterprise: enforced by gateway tags, see 08).
2. **How much context does the task need?** > 200K tokens → not Haiku; > 256K → not local.
3. **Is it a judgement task or a typing task?** Typing (rename, boilerplate, tests from a
   spec) → rung 1–2. Judgement (design, ambiguous bug) → rung 3+.
4. **Did the previous rung fail twice?** Climb one rung, not three.
5. **Is latency the bottleneck?** Local small models and Haiku/Luna are fastest; Fable and
   Astra can take minutes on hard tasks — plan for streaming and long timeouts.

## Cost intuition

A typical feature on `coder-fast` (Sonnet 5) consumes 200K–2M tokens end to end and costs
roughly $1–5. The same on `reasoning-max` costs 5×. Subagents that read a lot of code are
where cost hides: give them `coder-cheap` or `coder-local`. Prompt caching (automatic for
Anthropic through the gateway when the client sends `cache_control`, and automatic on OpenAI)
cuts repeated-context cost by up to 90%; keep system prompts and `AGENTS.md` stable so the
prefix hits.

## Keeping this table honest

- Anthropic: `GET /v1/models` on the gateway (`scripts/smoke-test.sh` prints it) and the
  Anthropic models page.
- OpenAI: `developers.openai.com/api/docs/models` and `/pricing`.
- Gemma: `ai.google.dev/gemma/docs/core/model_card_4`, `ollama.com/library/gemma4`.
- Qwen: `github.com/QwenLM/Qwen3-Coder`, `ollama.com/library/qwen3-coder`.

When you change an alias's resolution, update the ladder table here and the fallback list in
the gateway config in the same commit.

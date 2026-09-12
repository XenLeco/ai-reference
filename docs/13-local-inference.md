# 13 — Local inference: hardware, quantisation, speed

*Verified: 2026-09-12 against ollama.com/library (gemma4, qwen3-coder), Google's Gemma 4
multi-token-prediction announcement (2026-04), vLLM and llama.cpp documentation. Exact
drafter model names and engine flags change; treat the commands as templates and check
`--help`.*

Local models are rungs 0 and 1 of the ladder (doc 01): free per token, private, offline.
This guide is about making them fast enough to be useful and choosing the right size for
the hardware you have. All engines here are permissively licensed: Ollama (MIT),
llama.cpp (MIT), vLLM (Apache-2.0), SGLang (Apache-2.0).

## Sizing: which model fits

Rule of thumb for 4-bit quantisation (Q4_K_M / QAT): weights need ~0.55–0.6 GB per
billion *total* parameters, plus KV cache that grows with context. MoE models
(Gemma 4 26B-A4B, Qwen3-Coder 30B-A3B) still need all weights in memory but run at the
speed of their *active* parameters.

| Model | Weights at Q4 | Comfortable with | Tokens/s class (single user) | Best at |
|---|---|---|---|---|
| Gemma 4 E2B / E4B | 3–5 GB | 8 GB RAM, any laptop | fast | titles, summaries, rewrites |
| Gemma 4 12B | ~7.5 GB | 12 GB VRAM or 16 GB unified | fast | general assistant, `local-small` |
| Qwen3-Coder 30B-A3B | ~19 GB | 24 GB VRAM, or 32 GB unified/RAM with CPU offload | fast (3B active) | coding, `coder-local` |
| Gemma 4 26B-A4B | ~19 GB | 24 GB VRAM or 32 GB unified | fast (4B active) | general + multimodal |
| Gemma 4 31B | ~20 GB | 24 GB VRAM (tight) or 32–48 GB unified | moderate (dense) | quality when speed matters less |
| Qwen3-Coder 480B-A35B | ~290 GB | multi-GPU server | server class | rent it (doc 01) |

Context costs memory too: at 64K tokens a 30B-class model adds several GB of KV cache.
If a model fits but the agent fails after a few turns, the context window is the problem,
not the model (see below).

Quantisation guidance: prefer the vendor's **QAT** builds for Gemma 4 (quantisation-aware,
near-bf16 quality at Q4). Q4_K_M is the default sweet spot; Q8_0 when memory allows and
you want fewer subtle errors in code; Q3 and below only for chat.

## Context window: the setting everyone forgets

Ollama's default context is small and agents fail silently past it. Set it once:

```bash
# systemd (Linux): /etc/systemd/system/ollama.service.d/override.conf
[Service]
Environment="OLLAMA_CONTEXT_LENGTH=65536"
Environment="OLLAMA_KEEP_ALIVE=30m"
Environment="OLLAMA_FLASH_ATTENTION=1"
Environment="OLLAMA_KV_CACHE_TYPE=q8_0"    # halves KV memory with little quality loss
```

The gateway also passes `num_ctx` per deployment (`litellm.personal.yaml`), but the server
limit wins. 64K is enough for agent work on most repos; 128K+ only on 32 GB+ machines.

## Speed: speculative decoding with Gemma 4 MTP drafters

Google published multi-token-prediction (MTP) **drafter** models for Gemma 4 (26B MoE,
31B dense, E2B, E4B). A tiny drafter proposes several tokens, the main model verifies them
in one pass; output is identical to the main model, only faster. Google reports up to 3×
on server GPUs and ~2.2× locally on Apple Silicon at batch 4–8. Support at verification:

| Engine | Status | How |
|---|---|---|
| vLLM | native | `--speculative-config` with the drafter as draft model (template below) |
| SGLang | native | `--speculative-algorithm` with the drafter; see SGLang docs |
| llama.cpp | drafter conversion pending a converter patch at verification; engine supports draft models | `llama-server -m main.gguf -md drafter.gguf --draft-max 8 --draft-min 1` once GGUFs exist |
| Ollama | not yet | wait, or use llama.cpp's server for this case |
| MLX (Apple) | native | `mlx_lm.server --draft-model …` |

When it helps: long, predictable outputs (code, structured text) with a batch of 1–8.
When it does not: short chatty turns, very high batch sizes, or when the drafter does not
fit next to the main model. Measure with `evals/bakeoff/bakeoff.py --models` before and after.

vLLM template (fill in the exact Hugging Face ids of the model and its drafter):

```bash
vllm serve google/gemma-4-26b-a4b-it \
  --max-model-len 65536 \
  --speculative-config '{"model": "google/<gemma-4-26b-a4b-mtp-drafter>", "num_speculative_tokens": 4}' \
  --gpu-memory-utilization 0.90
```

Then in the gateway: `hosted_vllm/google/gemma-4-26b-a4b-it` with `api_base` pointing at
`http://host:8000/v1` (the enterprise config already uses this shape).

## Which engine

| Need | Engine |
|---|---|
| one developer, one machine, zero fuss | **Ollama**: `ollama pull qwen3-coder:30b gemma4:26b gemma4:12b` |
| draft models, fine-grained control, Vulkan/ROCm/Metal builds | **llama.cpp** `llama-server` (MIT), OpenAI-compatible on `:8080` |
| a shared GPU box for a team, concurrency, continuous batching, MTP | **vLLM** (Apache-2.0) |
| highest throughput at scale, structured output, RadixAttention cache | **SGLang** (Apache-2.0) |

All four expose OpenAI-compatible endpoints; the gateway prefixes are `ollama_chat/`,
`openai/` + `api_base` (llama.cpp), `hosted_vllm/`, and `openai/` + `api_base` (SGLang).

## Measuring

1. `python evals/bakeoff/bakeoff.py --models coder-local,gemma4-26b,gemma4-12b --runs 3`
   for pass rate, p50 latency and tokens on your tasks.
2. `gateway/scripts/spend-report.sh 7` to see how much cloud spend the local rungs
   displaced.
3. If local pass rate is below ~70% on your tasks, keep local models for exploration and
   tests (`local-scout`, `test-writer` on `coder-local`) and let `coder-fast` do judgement
   work; that split still saves most of the tokens that matter.

## Windows notes

Ollama runs natively on Windows with NVIDIA/AMD GPUs. vLLM and SGLang need Linux or WSL2.
The gateway in Docker reaches a native Ollama at `host.docker.internal:11434` (already the
default in `gateway/.env.example`).

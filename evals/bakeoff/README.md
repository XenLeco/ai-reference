# evals/bakeoff/ — compare models on your own tasks and hardware

`bakeoff.py` sends the same tasks to several gateway aliases and reports pass rate, latency
and tokens per alias. Use it to answer "which local model on this GPU", "is `coder-cheap`
good enough for tests", or "did the new Sonnet change behaviour" with numbers instead of
impressions. Standard library only; no install.

```bash
export LITELLM_API_KEY=sk-...                                   # a virtual key
python evals/bakeoff/bakeoff.py --models coder-local,gemma4-26b,coder-cheap,coder-fast --runs 3
python evals/bakeoff/bakeoff.py --tasks evals/bakeoff/tasks.json --models coder-local --runs 5 --json
```

Output: a table per alias (pass %, median latency, mean input/output tokens, judge pass
%) and a JSON file under `evals/bakeoff/results/` with every response, for diffing later.

## Tasks

`tasks.json` holds eight small coding tasks with deterministic checks (`expect_regex`,
`expect_contains`, `expect_not_contains`, `max_lines`) and an optional `judge` rubric,
graded by `coder-cheap` through the gateway. Deterministic checks decide pass/fail; the
judge is reported separately so a cheap grader cannot flip the headline number.

Add tasks that look like *your* work: the shape of code you write, the languages, the
size. Ten to twenty tasks with three runs each is enough to rank models; more runs
narrow the variance on local models, which are the noisiest.

## Reading the results

- **Pass %** is the headline. A model below ~70% on your tasks is not a daily driver for
  them, whatever the benchmarks say.
- **Latency** on local models is throughput-bound: if `coder-local` is 4× slower than
  `coder-cheap` and only 10% cheaper per completed task in your spend log, it is not
  cheaper.
- **Output tokens** show verbosity; a model that passes with half the output is better in
  an agent loop.
- Compare **cost per passed task**, not per request; the spend log has the prices.

## Heavier evaluations

For sandboxed, multi-turn agent tasks with a log viewer, use inspect-ai (MIT, UK AI
Security Institute): `uv tool install inspect-ai`, then point its OpenAI-compatible
provider at the gateway (`INSPECT_EVAL_MODEL=openai/coder-fast`, `OPENAI_BASE_URL`).
This harness is deliberately smaller.

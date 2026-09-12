---
name: perf-profiling
description: Diagnose and fix performance problems by measuring first - profile, form a hypothesis, change one thing, re-measure. Use when something is slow, uses too much memory, times out, when asked to optimise, or when a latency or throughput target is missed.
license: MIT
metadata:
  version: "1.0"
---

# Performance: measure, then change

No optimisation without a number before and a number after, on the same input.

## 1. Define the number

- What is slow: an endpoint, a job, a query, a test suite, startup. Which input size.
- The metric: p50/p95 latency, throughput, peak RSS, CPU seconds. One primary metric.
- The target, if any. "Faster" is not a target.

## 2. Reproduce and baseline

- A repeatable command on a fixed input (`hyperfine`, a benchmark script, `EXPLAIN
  ANALYZE`, a load tool at fixed RPS). Run it 3–5 times; record median and spread.
- Same machine, same data, nothing else running. Note the environment in the report.

## 3. Profile before guessing

| Language | Profilers (all permissive) |
|---|---|
| Python | `py-spy record -o out.svg -- python …` (sampling, no code change), `cProfile` + `snakeviz`, `tracemalloc`, `scalene` |
| Node | `node --cpu-prof`, `clinic flame`, `--heap-prof` |
| Go | `pprof` (`go test -cpuprofile`, `net/http/pprof`), `go tool trace` |
| Rust | `cargo flamegraph`, `perf`, `criterion` for micro-benchmarks |
| JVM | `async-profiler`, JFR |
| SQL | `EXPLAIN (ANALYZE, BUFFERS)`; look for seq scans on big tables, nested loops on large row counts, sorts spilling to disk |
| Browser | DevTools Performance panel, Lighthouse |

Read the flame graph top-down: the widest frames are the cost, not the deepest.

## 4. Hypothesis → one change → re-measure

- Write the hypothesis in one line ("80% of time is JSON re-parsing per row").
- Change exactly one thing. Re-run the baseline command. Keep the change only if the
  primary metric improved and tests pass.
- Typical wins in order of likelihood: an N+1 query or missing index; work inside a loop
  that belongs outside; repeated I/O or parsing; unbounded data structures; wrong
  algorithmic class; synchronous waits that could overlap. Micro-optimisations last.

## 5. Guard it

- Add a benchmark or a test with a generous threshold so the regression is caught.
- Note the trade-off if any (memory for speed, complexity, cache staleness).

## Report

```
Metric: <p95 latency of /orders at 100 RPS>
Before: <value ± spread>   After: <value ± spread>   Change: <x%>
Cause: <one line, with profile evidence>
Change: <files>
Trade-off: <...>
Guard: <benchmark/test added>
```

## Do not

- Do not optimise code that the profile shows is not on the hot path.
- Do not compare runs across different machines, datasets or warm/cold caches.
- Do not remove correctness (validation, locking, error handling) for speed without
  saying so explicitly.

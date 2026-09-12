# evals/promptfoo/ — regression evals for our own configuration

[promptfoo](https://github.com/promptfoo/promptfoo) (MIT) runs declarative evals: a prompt,
a provider, assertions. Two suites here:

| Suite | What it tests | Needs |
|---|---|---|
| `promptfooconfig.yaml` | the **skills** in `skills/`: each `SKILL.md` is the system prompt, a fixture task is the user turn, assertions check the required shape and behaviour | the gateway and `LITELLM_API_KEY` |
| `promptfooconfig.agents.yaml` | the **agents** in `clients/opencode/agents/`: `opencode run --agent … --dir fixtures/mini-repo` through an `exec:` provider | the above plus OpenCode installed with the repo's global config |

Run them when `AGENTS.md`, a skill, an agent or the gateway's alias mapping changes:

```bash
export LITELLM_API_KEY=sk-...                      # a virtual key; the eval runs on coder-fast, grading on coder-cheap
export LITELLM_BASE_URL=http://localhost:4000       # optional; default in the config
scripts/evals.sh                                    # skills suite
scripts/evals.sh --agents                           # both suites
npx -y promptfoo@latest view                        # browse results
```

`scripts/evals.sh` pins nothing; pin `promptfoo@<version>` in it once the suite is stable.

## Assertions used

- `javascript` / `regex` / `contains` for shape: a valid Conventional Commits subject, the
  `Assisted-by: LLM` trailer, `path:line` references, section headings an agent must return.
- `not-contains` for safety: the planted fake secret must never appear in output.
- `llm-rubric` for judgement: "identifies the off-by-one", "reproduces before fixing". The
  grader is `coder-cheap` through the gateway (`defaultTest.options.provider`).

Thresholds: every test must pass; a failure means the skill or agent regressed or the
model behind the alias changed behaviour. Re-run twice before blaming the model.

## Fixtures

`fixtures/tasks/*.md` are user turns for the skill suite. `fixtures/mini-repo/` is a tiny
Python project with planted defects (an off-by-one that skips the first item, a bare
`except`, string-built SQL) and its own `AGENTS.md`, used by the agent suite. It is not a
git repository; agents that need `git diff` are asked to review files by path instead.

## Adding a test

Copy a block in `promptfooconfig.yaml`, point `skill` at the `SKILL.md`, write the task in
`fixtures/tasks/`, and add at most one `llm-rubric` per test (they cost a call each). Keep
the suite under ~20 calls so it stays cheap enough to run on every change.

## CI

The template workflow `security-scan.yml` does not run evals (they need the gateway).
Add a job on a self-hosted runner with the `ci` key when you want them on every PR; expect
about $0.05–0.20 per run on the skills suite.

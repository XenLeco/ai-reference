# clients/opencode/ — global OpenCode configuration

Installed to `~/.config/opencode/` by `scripts/install-personal.sh` (Windows:
`%USERPROFILE%\.config\opencode\`). Design and every key explained in
[docs/03-opencode.md](../../docs/03-opencode.md).

| File | Installed as | Notes |
|---|---|---|
| `opencode.json` | `~/.config/opencode/opencode.json` | personal profile: LiteLLM provider, aliases, agent models, permissions |
| `opencode.enterprise.json` | same path, enterprise machines | `share` disabled, no auto-update, `ask` by default, secrets unreadable, gateway-only providers |
| `AGENTS.md` | `~/.config/opencode/AGENTS.md` | personal preferences that should not be committed to project repos |
| `srt-settings.json` | `~/.srt-settings.json` | Anthropic `sandbox-runtime` policy (Apache-2.0): run `srt opencode` to confine every command to the working tree, temp and OpenCode's state dirs, with network only to the gateway, GitHub and registries. `npm i -g @anthropic-ai/sandbox-runtime`; Linux needs `bubblewrap socat` |
| `srt-settings.enterprise.json` | same path on company machines | network = internal gateway and registries only; `infra/` and `deploy/` unwritable |
| `agents/*.md` | `~/.config/opencode/agents/` | subagents: architect, reviewer, test-writer, docs-writer, security-auditor, local-scout |
| `commands/*.md` | `~/.config/opencode/commands/` | `/plan /review /test /commit /pr /explain /fix /docs /security` |

Before first run: `export LITELLM_API_KEY=<virtual key for opencode>` in your shell profile.
The base URL defaults to `http://localhost:4000/v1`; edit `provider.litellm.options.baseURL`
if the gateway runs elsewhere (or use `{env:LITELLM_BASE_URL}` and set that variable).

Optional output-shaping: the `i-have-adhd` skill (MIT; docs/11 Part C) is installed on
demand by `scripts/install-community-skills.sh --i-have-adhd` and invoked with
`/i-have-adhd`. For always-on, clone the repo, add the absolute path of its
`.opencode/plugins/i-have-adhd.mjs` to a `"plugin"` array in `opencode.json`, and create
`~/.config/opencode/.i-have-adhd-always`. It is not in the shipped config because it
injects its ruleset every turn.

Model entries in `provider.litellm.models` **must** match gateway `model_name`s. When you add
an alias to the gateway, add it here too or it will not appear in `/models`.

JSON has no comments; the reasoning for each value is in docs/03. Older OpenCode releases
read `agent/` and `command/` (singular); current releases read both.

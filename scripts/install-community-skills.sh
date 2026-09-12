#!/usr/bin/env bash
# Opt-in installer for the third-party tools assessed in docs/11-community-skills.md.
# Every tool here passes the permissive-license and safety gates (skills/community.json).
# Nothing runs unless you name it. Enterprise machines: vendor at a pinned commit instead.
#
# Usage: install-community-skills.sh [flags]
#   retrieval / graphs / memory:  --serena --graphify --code-review-graph --beads
#   methodology:                  --superpowers --spec-kit[=vX.Y.Z] --compound --aidlc
#   other:                        --archify --ponytail
#   --recommended   = --serena --code-review-graph --beads --spec-kit --archify   (no plugins, no methodology pack)
# Plugin-based tools (superpowers, compound, ponytail) are installed inside the client; this
# script prints the exact commands instead of editing plugin state blindly.
set -euo pipefail

declare -A want=()
speckit_ref=""
[[ $# -gt 0 ]] || { sed -n '2,12p' "$0"; exit 1; }
for a in "$@"; do
  case "$a" in
    --serena|--graphify|--code-review-graph|--beads|--superpowers|--compound|--aidlc|--archify|--ponytail) want["${a#--}"]=1 ;;
    --spec-kit) want[spec-kit]=1 ;;
    --spec-kit=*) want[spec-kit]=1; speckit_ref="${a#--spec-kit=}" ;;
    --recommended) want[serena]=1; want[code-review-graph]=1; want[beads]=1; want[spec-kit]=1; want[archify]=1 ;;
    *) echo "unknown flag: $a" >&2; exit 1 ;;
  esac
done

need() { command -v "$1" >/dev/null 2>&1 || { echo "missing: $1 ($2)" >&2; return 1; }; }
hr() { printf '\n== %s ==\n' "$1"; }
uv_tool() {  # uv_tool <args...>: uv tool install, else pipx install
  if command -v uv >/dev/null 2>&1; then uv tool install "$@"
  elif command -v pipx >/dev/null 2>&1; then pipx install "${@: -1}"
  else echo "install uv (https://docs.astral.sh/uv/) or pipx first" >&2; exit 1; fi
}

# ---------------------------------------------------------------- retrieval / graphs / memory
if [[ -n "${want[serena]:-}" ]]; then
  hr "Serena (LSP symbol tools over MCP)"
  uv_tool -p 3.13 serena-agent
  cat <<'EOT'
  In each project:  serena project index
  OpenCode (opencode.json):
    "mcp": { "serena": { "type": "local", "command": ["serena","start-mcp-server","--context","ide-assistant","--project","."], "enabled": true } },
    "tools": { "serena*": false }, "agent": { "build": { "tools": { "serena*": true } } }
  Claude Code:  claude mcp add serena -- serena start-mcp-server --context claude-code --project "$PWD"
  Codex (config.toml): [mcp_servers.serena] command = "serena"  args = ["start-mcp-server","--context","codex","--project","."]
  Check context names for your version: serena start-mcp-server --help
EOT
fi

if [[ -n "${want[graphify]:-}" ]]; then
  hr "graphify (code graph + skill -> ~/.agents/skills)"
  uv_tool graphifyy
  graphify install --platform agents
  cat <<'EOT'
  In a repo: /graphify .   then commit graphify-out/ (ignore graphify-out/cache/); graphify hook install
  Document extraction through the gateway:
    export OPENAI_BASE_URL=http://localhost:4000/v1 OPENAI_API_KEY=$LITELLM_API_KEY
EOT
fi

if [[ -n "${want[code-review-graph]:-}" ]]; then
  hr "code-review-graph (self-updating code graph over MCP)"
  uv_tool code-review-graph
  cat <<'EOT'
  In a repo:  code-review-graph install --platform opencode    # or claude-code | codex | cursor | gemini-cli
  It writes MCP config and injects rules into instruction files: review the AGENTS.md diff.
  Scope its ~30 tools per agent ("tools": { "code-review-graph*": false } globally, true on build).
EOT
fi

if [[ -n "${want[beads]:-}" ]]; then
  hr "beads (bd: task graph memory for agents)"
  if command -v brew >/dev/null 2>&1; then brew install beads
  elif command -v npm >/dev/null 2>&1; then npm install -g @beads/bd
  else echo "install Homebrew or npm first" >&2; exit 1; fi
  echo "  In a repo: bd init   (it appends a snippet to AGENTS.md; review the diff)"
fi

# ---------------------------------------------------------------- methodology
if [[ -n "${want[superpowers]:-}" ]]; then
  hr "superpowers (methodology plugin) — install inside the client"
  cat <<'EOT'
  Claude Code:  /plugin install superpowers@claude-plugins-official
  Codex:        /plugins  → Superpowers
  OpenCode:     follow https://github.com/obra/superpowers/blob/main/.opencode/INSTALL.md
  Telemetry off: export SUPERPOWERS_DISABLE_TELEMETRY=1
  Then remove overlapping local skills: rm -rf ~/.agents/skills/{debug-reproduce-first,code-review-checklist,pr-writeup}
EOT
fi

if [[ -n "${want[spec-kit]:-}" ]]; then
  hr "spec-kit (GitHub spec-driven development CLI)"
  need git "install git"
  src="git+https://github.com/github/spec-kit.git${speckit_ref:+@$speckit_ref}"
  [[ -n "$speckit_ref" ]] || echo "  note: no tag given; installing HEAD. Pin with --spec-kit=vX.Y.Z (see releases)."
  uv_tool specify-cli --from "$src"
  echo "  In a repo:  specify init . --integration opencode --force    # claude | codex | cursor | gemini | copilot"
fi

if [[ -n "${want[compound]:-}" ]]; then
  hr "compound-engineering (methodology plugin) — install inside the client"
  cat <<'EOT'
  Claude Code:  /plugin marketplace add EveryInc/compound-engineering-plugin  then  /plugin install compound-engineering
  Codex:        codex plugin add compound-engineering@compound-engineering-plugin
  OpenCode:     add "compound-engineering@git+https://github.com/EveryInc/compound-engineering-plugin.git#<sha>" to "plugin"
  Cursor:       /add-plugin compound-engineering
  Do not combine with superpowers / AI-DLC (one methodology pack).
EOT
fi

if [[ -n "${want[aidlc]:-}" ]]; then
  hr "AI-DLC workflows (release installer, then per-project config)"
  need curl "install curl"
  tmp="$(mktemp -d)"
  curl -fsSL https://github.com/awslabs/aidlc-workflows/releases/latest/download/install.sh -o "$tmp/install.sh"
  echo "  installer sha256: $( (sha256sum "$tmp/install.sh" 2>/dev/null || shasum -a 256 "$tmp/install.sh") | cut -d' ' -f1)"
  sh "$tmp/install.sh"
  rm -rf "$tmp"
  cat <<'EOT'
  In a project:  aidlc config --harness opencode   # claude | codex | cursor | kiro | kiro-ide | copilot
                 aidlc doctor
  Then /aidlc <describe the work>. Diff AGENTS.md afterwards; it stays authoritative.
EOT
fi

# ---------------------------------------------------------------- other
if [[ -n "${want[archify]:-}" ]]; then
  hr "archify (validated diagrams; skill + Node renderer)"
  need npx "install Node.js"
  npx -y skills add tt-a1i/archify -g -y
fi

if [[ -n "${want[ponytail]:-}" ]]; then
  hr "ponytail (always-on ruleset; plugin per client)"
  cfg="${XDG_CONFIG_HOME:-$HOME/.config}/opencode/opencode.json"
  if [[ -f "$cfg" ]] && command -v python3 >/dev/null 2>&1; then
    python3 - "$cfg" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p, encoding="utf-8"))
plugins = d.setdefault("plugin", [])
if not any(x.startswith("@dietrichgebert/ponytail") for x in plugins):
    plugins.append("@dietrichgebert/ponytail")
    with open(p, "w", encoding="utf-8") as f:
        json.dump(d, f, indent=2); f.write("\n")
    print(f"  added @dietrichgebert/ponytail to {p} (pin a version, e.g. @dietrichgebert/ponytail@4.7.0)")
else:
    print("  already present in opencode.json")
PY
  else
    echo "  OpenCode: add \"plugin\": [\"@dietrichgebert/ponytail\"] to $cfg"
  fi
  cat <<'EOT'
  Claude Code: /plugin marketplace add DietrichGebert/ponytail  then  /plugin install ponytail@ponytail
  Codex:       codex plugin marketplace add DietrichGebert/ponytail && codex plugin add ponytail@ponytail
  Mode:        export PONYTAIL_DEFAULT_MODE=full   (lite|full|ultra|off)
EOT
fi

printf '\ndone\n'

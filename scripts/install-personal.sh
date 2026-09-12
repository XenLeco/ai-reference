#!/usr/bin/env bash
# Install the personal profile on this machine:
#   - OpenCode global config, agents, commands  -> ~/.config/opencode/
#   - skills                                     -> ~/.agents/skills/  (+ ~/.claude/skills symlink)
#   - Claude Code key helper + settings fragment -> ~/.claude/
#   - Codex config                               -> ~/.codex/config.toml
# Never overwrites an existing opencode.json / settings.json / config.toml without --force;
# writes a *.new file next to it instead.
set -euo pipefail

FORCE=0
for a in "$@"; do [[ "$a" == "--force" ]] && FORCE=1; done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
OC="$CFG/opencode"
SK="$HOME/.agents/skills"
CL="$HOME/.claude"
CX="$HOME/.codex"

place() {  # place <src> <dst>: copy, or write <dst>.new when dst exists and not --force
  local src="$1" dst="$2"
  if [[ -e "$dst" && $FORCE -eq 0 ]]; then
    cp "$src" "$dst.new"; echo "  exists: $dst  -> wrote $dst.new (merge by hand or use --force)"
  else
    cp "$src" "$dst"; echo "  wrote:  $dst"
  fi
}

echo "OpenCode -> $OC"
mkdir -p "$OC/agents" "$OC/commands"
place "$ROOT/clients/opencode/opencode.json" "$OC/opencode.json"
place "$ROOT/clients/opencode/AGENTS.md" "$OC/AGENTS.md"
cp "$ROOT"/clients/opencode/agents/*.md "$OC/agents/"   && echo "  agents:   $(ls "$ROOT"/clients/opencode/agents | tr '\n' ' ')"
cp "$ROOT"/clients/opencode/commands/*.md "$OC/commands/" && echo "  commands: $(ls "$ROOT"/clients/opencode/commands | tr '\n' ' ')"

echo "Skills -> $SK"
mkdir -p "$SK"
for d in "$ROOT"/skills/*/; do
  n="$(basename "$d")"
  rm -rf "$SK/$n"; cp -r "$d" "$SK/$n"; echo "  $n"
done
if [[ ! -e "$HOME/.claude/skills" ]]; then
  mkdir -p "$HOME/.claude"; ln -s "$SK" "$HOME/.claude/skills" && echo "  linked ~/.claude/skills -> $SK"
fi

echo "Sandbox policy -> $HOME/.srt-settings.json"
place "$ROOT/clients/opencode/srt-settings.json" "$HOME/.srt-settings.json"
echo "  use: npm i -g @anthropic-ai/sandbox-runtime && srt opencode   (Linux: apt-get install bubblewrap socat)"

echo "Claude Code -> $CL"
mkdir -p "$CL"
cp "$ROOT/clients/claude-code/get-gateway-key.sh" "$CL/get-gateway-key.sh"; chmod +x "$CL/get-gateway-key.sh"
cp "$ROOT/clients/claude-code/settings.json" "$CL/settings.gateway.json"
echo "  wrote:  $CL/get-gateway-key.sh, $CL/settings.gateway.json (merge into settings.json)"

echo "Codex -> $CX"
mkdir -p "$CX"
place "$ROOT/clients/codex/config.toml" "$CX/config.toml"

cat <<'EOT'

Next:
  1. Create keys on the gateway host:
       gateway/scripts/create-key.sh opencode 50 30d
       gateway/scripts/create-key.sh claude-code 50 30d
       gateway/scripts/create-key.sh codex 50 30d
  2. In your shell profile:
       export LITELLM_API_KEY=<opencode or codex key>
       export LITELLM_CLAUDE_CODE_KEY=<claude-code key>
  3. If the gateway is not on localhost:4000, edit provider.litellm.options.baseURL in
     ~/.config/opencode/opencode.json, ANTHROPIC_BASE_URL in Claude Code settings, base_url in ~/.codex/config.toml.
  4. opencode -> /models should list the gateway aliases.
EOT

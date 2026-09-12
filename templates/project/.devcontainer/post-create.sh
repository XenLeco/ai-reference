#!/usr/bin/env bash
# Runs once when the devcontainer is created. Installs the agent tooling; project dependencies
# are installed by the project's own install command from AGENTS.md.
set -euo pipefail

# OpenCode (MIT) and uv (MIT/Apache-2.0)
curl -fsSL https://opencode.ai/install | bash
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"

# pre-commit (MIT) + gitleaks hook, if the repo ships a config
if [ -f .pre-commit-config.yaml ]; then
  uv tool install pre-commit
  pre-commit install || true
fi

# Sandbox runtime (Apache-2.0) for wrapping agent commands; bubblewrap + socat are its deps
sudo apt-get update -qq && sudo apt-get install -y -qq bubblewrap socat ripgrep >/dev/null
npm install -g @anthropic-ai/sandbox-runtime >/dev/null 2>&1 || true

cat <<'EOT'

devcontainer ready.
  gateway:  $LITELLM_BASE_URL (host.docker.internal:4000 -> your host's gateway)
  opencode: config mounted read-only from your host; run `opencode` in the repo
  sandbox:  `srt opencode` to confine commands (policy: ~/.srt-settings.json on the host)
EOT

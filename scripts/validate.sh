#!/usr/bin/env bash
# Lint JSON/YAML/TOML, check skill and agent frontmatter, check gateway alias consistency.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
if command -v python3 >/dev/null 2>&1; then PY=python3; elif command -v python >/dev/null 2>&1; then PY=python; else
  echo "python 3.11+ required" >&2; exit 1
fi
exec "$PY" scripts/validate.py "$@"

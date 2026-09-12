#!/usr/bin/env bash
# Audit a project's dependency licenses against the permissive allowlist (docs/11 gate 1).
# Usage: license-audit.sh [path] [--strict] [--json] [--ecosystem npm|python|go|rust]
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if command -v python3 >/dev/null 2>&1; then PY=python3; elif command -v python >/dev/null 2>&1; then PY=python; else
  echo "python 3.11+ required" >&2; exit 2
fi
exec "$PY" "$here/license_audit.py" "$@"

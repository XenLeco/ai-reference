#Requires -Version 7
# Audit a project's dependency licenses against the permissive allowlist (docs/11 gate 1).
# Usage: ./license-audit.ps1 [path] [--strict] [--json] [--ecosystem npm|python|go|rust]
$ErrorActionPreference = "Stop"
$py = (Get-Command python3 -ErrorAction SilentlyContinue) ?? (Get-Command python -ErrorAction SilentlyContinue)
if (-not $py) { throw "python 3.11+ required" }
& $py.Source (Join-Path $PSScriptRoot "license_audit.py") @args
exit $LASTEXITCODE

#Requires -Version 7
# Lint JSON/YAML/TOML, check skill and agent frontmatter, check gateway alias consistency.
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")
$py = (Get-Command python3 -ErrorAction SilentlyContinue) ?? (Get-Command python -ErrorAction SilentlyContinue)
if (-not $py) { throw "python 3.11+ required" }
& $py.Source scripts/validate.py @args
exit $LASTEXITCODE

#Requires -Version 7
# Run the promptfoo regression evals against the gateway.
# Usage: ./evals.ps1 [-Agents]
param([switch]$Agents)
$ErrorActionPreference = "Stop"
if (-not $env:LITELLM_API_KEY) { throw "set LITELLM_API_KEY to a virtual key" }
Set-Location (Join-Path $PSScriptRoot "..\evals\promptfoo")
Write-Host "== skills suite ==" -ForegroundColor Cyan
npx -y promptfoo@latest eval -c promptfooconfig.yaml --no-cache
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
if ($Agents) {
  Write-Host "== agents suite (opencode run) ==" -ForegroundColor Cyan
  npx -y promptfoo@latest eval -c promptfooconfig.agents.yaml --no-cache
  if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
Write-Host "browse: npx -y promptfoo@latest view"

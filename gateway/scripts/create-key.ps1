#Requires -Version 7
<#
.SYNOPSIS
  Issue a virtual key. Requires the master key in LITELLM_MASTER_KEY.
.EXAMPLE
  ./create-key.ps1 -Alias opencode -MaxBudget 50 -BudgetDuration 30d
.EXAMPLE
  ./create-key.ps1 -Alias alice-restricted -MaxBudget 20 -Models local -Tags restricted -TeamId team-payments
#>
param(
  [Parameter(Mandatory)][string]$Alias,
  [double]$MaxBudget = 25,
  [string]$BudgetDuration = "30d",
  [string[]]$Models = @(),
  [string[]]$Tags = @(),
  [string]$TeamId = "",
  [string]$Base = $(if ($env:LITELLM_BASE_URL) { $env:LITELLM_BASE_URL } else { "http://localhost:4000" })
)
$ErrorActionPreference = "Stop"
if (-not $env:LITELLM_MASTER_KEY) { throw "set LITELLM_MASTER_KEY" }

$payload = @{
  key_alias       = $Alias
  max_budget      = $MaxBudget
  budget_duration = $BudgetDuration
  metadata        = @{ created_by = "create-key.ps1" }
}
if ($Models.Count -gt 0) { $payload.models = $Models }
if ($Tags.Count -gt 0)   { $payload.tags = $Tags }
if ($TeamId)             { $payload.team_id = $TeamId }

$resp = Invoke-RestMethod -Method Post -Uri "$Base/key/generate" `
  -Headers @{ Authorization = "Bearer $($env:LITELLM_MASTER_KEY)" } `
  -ContentType "application/json" -Body ($payload | ConvertTo-Json -Depth 5)

"alias: $Alias"
"key:   $($resp.key)"
""
"`$env:LITELLM_API_KEY = `"$($resp.key)`""
